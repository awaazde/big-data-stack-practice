.PHONY: help start stop restart clean logs status \
        postgres-start postgres-stop postgres-restart postgres-logs postgres-status postgres-psql postgres-clean \
        glue-shell trino-cli minio-ui network-create build health

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Docker Compose Files
MAIN_COMPOSE := docker-compose.yml
POSTGRES_COMPOSE := docker-compose.postgres.yml

# Default target
.DEFAULT_GOAL := help

##@ General

help: ## Display this help message
	@echo ""
	@echo "$(GREEN)Big Data Stack - Makefile Commands$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf ""} /^[a-zA-Z_-]+:.*?##/ { printf "  $(BLUE)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Service URLs:$(NC)"
	@echo "  MinIO Console:   http://localhost:9001 (minio/minio123)"
	@echo "  Trino UI:        http://localhost:8080"
	@echo "  Spark UI:        http://localhost:4040"
	@echo "  PostgreSQL:      postgresql://awaazde:awaazde@localhost:5432/awaazde"
	@echo ""

##@ Main Stack (MinIO, Trino, Glue, Hive)

start: network-create ## Start all services (MinIO, Trino, Glue, Hive)
	@echo "$(GREEN)[INFO]$(NC) Starting main stack..."
	@docker compose -f $(MAIN_COMPOSE) up -d
	@echo "$(GREEN)[INFO]$(NC) Initializing MinIO buckets..."
	@sleep 5
	@docker exec local-minio mc alias set myminio http://localhost:9000 minio minio123 > /dev/null 2>&1 || true
	@docker exec local-minio mc mb myminio/datalake > /dev/null 2>&1 || echo "$(YELLOW)[INFO]$(NC) Bucket 'datalake' already exists"
	@docker exec local-minio mc mb myminio/test > /dev/null 2>&1 || echo "$(YELLOW)[INFO]$(NC) Bucket 'test' already exists"
	@echo "$(GREEN)[INFO]$(NC) Services starting up (waiting for Hive to initialize)..."
	@sleep 10
	@$(MAKE) --no-print-directory status

stop: ## Stop all main stack services
	@echo "$(YELLOW)[INFO]$(NC) Stopping main stack..."
	@docker compose -f $(MAIN_COMPOSE) down
	@echo "$(GREEN)[INFO]$(NC) Main stack stopped"

restart: ## Restart all main stack services
	@echo "$(YELLOW)[INFO]$(NC) Restarting main stack..."
	@docker compose -f $(MAIN_COMPOSE) restart
	@echo "$(GREEN)[INFO]$(NC) Main stack restarted"

build: ## Build the Glue container image
	@echo "$(GREEN)[INFO]$(NC) Building Glue container..."
	@docker compose -f $(MAIN_COMPOSE) build glue
	@echo "$(GREEN)[INFO]$(NC) Build complete"

clean: ## Stop and remove all containers and volumes (WARNING: DELETES ALL DATA!)
	@echo ""
	@echo "$(RED)[WARNING]$(NC) This will stop ALL services and DELETE ALL DATA!"
	@read -p "Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "$(YELLOW)[INFO]$(NC) Cleaning up main stack..."; \
		docker compose -f $(MAIN_COMPOSE) down -v; \
		echo "$(GREEN)[INFO]$(NC) Main stack cleaned"; \
	else \
		echo "$(GREEN)[INFO]$(NC) Cancelled"; \
	fi

logs: ## Show logs for all main stack services
	@docker compose -f $(MAIN_COMPOSE) logs -f

status: ## Show status of all services
	@echo "$(GREEN)[INFO]$(NC) Main Stack Status:"
	@docker compose -f $(MAIN_COMPOSE) ps
	@echo ""
	@if docker ps --filter "name=awaazde-postgres" --filter "status=running" | grep -q awaazde-postgres 2>/dev/null; then \
		echo "$(GREEN)[INFO]$(NC) PostgreSQL Status:"; \
		docker ps --filter "name=awaazde-postgres" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"; \
	fi

health: ## Check health status of all services
	@echo "$(GREEN)[INFO]$(NC) Checking service health..."
	@echo ""
	@echo "$(BLUE)MinIO:$(NC)"
	@curl -s http://localhost:9000/minio/health/live > /dev/null 2>&1 && echo "  ✓ Live" || echo "  ✗ Not responding"
	@echo ""
	@echo "$(BLUE)Trino:$(NC)"
	@curl -s http://localhost:8080/v1/info > /dev/null 2>&1 && echo "  ✓ Live" || echo "  ✗ Not responding"
	@echo ""
	@echo "$(BLUE)Hive Metastore:$(NC)"
	@nc -zv localhost 9083 > /dev/null 2>&1 && echo "  ✓ Live" || echo "  ✗ Not responding"
	@echo ""

##@ Service Access

glue-shell: ## Access Glue PySpark shell
	@if docker ps --filter "name=glue-interactive" --filter "status=running" | grep -q glue-interactive; then \
		echo "$(GREEN)[INFO]$(NC) Connecting to Glue PySpark shell..."; \
		docker exec -it glue-interactive pyspark; \
	else \
		echo "$(RED)[ERROR]$(NC) Glue container is not running. Start it with: make start"; \
		exit 1; \
	fi

trino-cli: ## Access Trino CLI
	@if docker ps --filter "name=local-trino" --filter "status=running" | grep -q local-trino; then \
		echo "$(GREEN)[INFO]$(NC) Connecting to Trino CLI..."; \
		docker exec -it local-trino trino; \
	else \
		echo "$(RED)[ERROR]$(NC) Trino container is not running. Start it with: make start"; \
		exit 1; \
	fi

minio-ui: ## Open MinIO console in browser
	@echo "$(GREEN)[INFO]$(NC) Opening MinIO console..."
	@echo "URL: http://localhost:9001"
	@echo "Username: minio"
	@echo "Password: minio123"
	@which xdg-open > /dev/null 2>&1 && xdg-open http://localhost:9001 || echo "Open http://localhost:9001 in your browser"

##@ PostgreSQL

postgres-start: network-create ## Start PostgreSQL container
	@echo "$(GREEN)[INFO]$(NC) Starting PostgreSQL..."
	@docker compose -f $(POSTGRES_COMPOSE) up -d
	@echo "$(GREEN)[INFO]$(NC) Waiting for PostgreSQL to be ready..."
	@sleep 3
	@if docker exec awaazde-postgres pg_isready -U awaazde > /dev/null 2>&1; then \
		echo "$(GREEN)[INFO]$(NC) PostgreSQL is ready!"; \
		echo ""; \
		echo "Connection: postgresql://awaazde:awaazde@localhost:5432/awaazde"; \
		echo ""; \
		echo "Quick commands:"; \
		echo "  • Connect with psql:  make postgres-psql"; \
		echo "  • View logs:          make postgres-logs"; \
		echo "  • Stop:               make postgres-stop"; \
	else \
		echo "$(YELLOW)[WARN]$(NC) PostgreSQL container started but not yet ready"; \
		echo "$(GREEN)[INFO]$(NC) Check status with: make postgres-status"; \
	fi

postgres-stop: ## Stop PostgreSQL container
	@echo "$(YELLOW)[INFO]$(NC) Stopping PostgreSQL..."
	@docker compose -f $(POSTGRES_COMPOSE) down
	@echo "$(GREEN)[INFO]$(NC) PostgreSQL stopped"

postgres-restart: ## Restart PostgreSQL container
	@echo "$(YELLOW)[INFO]$(NC) Restarting PostgreSQL..."
	@docker compose -f $(POSTGRES_COMPOSE) restart
	@echo "$(GREEN)[INFO]$(NC) PostgreSQL restarted"

postgres-logs: ## Show PostgreSQL logs
	@docker compose -f $(POSTGRES_COMPOSE) logs -f

postgres-status: ## Show PostgreSQL status
	@if docker ps --filter "name=awaazde-postgres" --filter "status=running" | grep -q awaazde-postgres; then \
		echo "$(GREEN)[INFO]$(NC) PostgreSQL is running"; \
		docker exec awaazde-postgres pg_isready -U awaazde; \
		echo ""; \
		docker ps --filter "name=awaazde-postgres" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"; \
	else \
		echo "$(YELLOW)[WARN]$(NC) PostgreSQL is not running"; \
		echo ""; \
		echo "Start with: make postgres-start"; \
	fi

postgres-psql: ## Connect to PostgreSQL with psql
	@if docker ps --filter "name=awaazde-postgres" --filter "status=running" | grep -q awaazde-postgres; then \
		docker exec -it awaazde-postgres psql -U awaazde -d awaazde; \
	else \
		echo "$(RED)[ERROR]$(NC) PostgreSQL is not running. Start it first with: make postgres-start"; \
		exit 1; \
	fi

postgres-clean: ## Stop PostgreSQL and remove volume (DELETES DATA!)
	@echo ""
	@echo "$(RED)[WARNING]$(NC) This will stop PostgreSQL and DELETE ALL DATA!"
	@read -p "Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "$(YELLOW)[INFO]$(NC) Stopping PostgreSQL and removing volume..."; \
		docker compose -f $(POSTGRES_COMPOSE) down -v; \
		echo "$(GREEN)[INFO]$(NC) PostgreSQL data removed"; \
		echo ""; \
		echo "Start fresh with: make postgres-start"; \
	else \
		echo "$(GREEN)[INFO]$(NC) Cancelled"; \
	fi

##@ Network

network-create: ## Create glue-network (automatically called by start commands)
	@if ! docker network inspect glue-network > /dev/null 2>&1; then \
		echo "$(GREEN)[INFO]$(NC) Creating glue-network..."; \
		docker network create glue-network; \
	fi

##@ Development

all-start: start postgres-start ## Start everything (main stack + PostgreSQL)
	@echo ""
	@echo "$(GREEN)[INFO]$(NC) All services started!"
	@echo ""
	@$(MAKE) --no-print-directory status

all-stop: stop postgres-stop ## Stop everything
	@echo "$(GREEN)[INFO]$(NC) All services stopped"

all-clean: ## Clean everything (WARNING: DELETES ALL DATA!)
	@echo ""
	@echo "$(RED)[WARNING]$(NC) This will DELETE ALL DATA from all services!"
	@read -p "Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "$(YELLOW)[INFO]$(NC) Cleaning everything..."; \
		docker compose -f $(MAIN_COMPOSE) down -v; \
		docker compose -f $(POSTGRES_COMPOSE) down -v; \
		echo "$(GREEN)[INFO]$(NC) All data cleaned"; \
	else \
		echo "$(GREEN)[INFO]$(NC) Cancelled"; \
	fi
