# Big Data Stack - Docker Environment

A complete dockerized big data stack with AWS Glue 5.0, Apache Trino, Apache Hive, MinIO (S3), and PostgreSQL.

## Architecture

This stack provides a complete local big data environment:

- **AWS Glue 5.0** - Serverless ETL service with PySpark
- **Apache Trino** - Distributed SQL query engine
- **Apache Hive** - Data warehouse with Hive Metastore
- **MinIO** - S3-compatible object storage
- **PostgreSQL** - Relational database
- **MySQL** - Backend for Hive Metastore

## Prerequisites

- Docker and Docker Compose installed
- Make utility (usually pre-installed on Linux/Mac)
- At least 8GB RAM available for Docker

## Setup

### Configure Environment Variables

Before starting the stack, you need to configure the `.env` file:

1. **REPORTS_PATH**: Update this to point to your reports directory. You have two options:

   ```bash
   # In .env file, set to your actual reports path
   REPORTS_PATH=/path/to/your/reports
   
   Eg: REPORTS_PATH=/home/awaazde/Desktop/awaazde.awaazde2/backend/awaazde/web/common/integrations/reports

   ```

   The REPORTS_PATH is mounted into the Glue container at `/home/glue_user/workspace/reports` and is added to the PYTHONPATH for importing Python modules.

## Quick Start

```bash
# Start the entire stack
make all-start

# Check service status
make status

# Access services
make glue-shell      # PySpark shell
make trino-cli       # Trino SQL CLI
make postgres-psql   # PostgreSQL CLI
```

## Service URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| MinIO Console | http://localhost:9001 | minio / minio123 |
| Trino UI | http://localhost:8080 | - |
| Spark UI | http://localhost:4040 | - |
| PostgreSQL | postgresql://localhost:5432/awaazde | awaazde / awaazde |

## Makefile Commands

### General

| Command | Description |
|---------|-------------|
| `make help` | Display help message with all available commands |

### Main Stack Management

Commands for managing MinIO, Trino, Glue, and Hive services.

| Command | Description |
|---------|-------------|
| `make start` | Start all main stack services (MinIO, Trino, Glue, Hive, MySQL). Creates Docker network and volumes if they don't exist. |
| `make stop` | Stop all running main stack services. Keeps data volumes intact. |
| `make restart` | Restart all main stack services without losing data. |
| `make build` | Build or rebuild the Glue container image from Dockerfile.glue. Run this after modifying Glue configuration. |
| `make clean` | **[DESTRUCTIVE]** Stop all services and delete all volumes. Requires confirmation. Use when you want a fresh start. |
| `make logs` | Stream logs from all main stack services. Press Ctrl+C to exit. |
| `make status` | Display status of all running containers including main stack and PostgreSQL. |
| `make health` | Check health endpoints of MinIO, Trino, and Hive Metastore services. |

### Service Access

Interactive shell access to services.

| Command | Description |
|---------|-------------|
| `make glue-shell` | Launch interactive PySpark shell in Glue container. Use for data processing, testing Spark jobs, and ETL development. Exit with `Ctrl+D`. |
| `make trino-cli` | Launch interactive Trino SQL CLI. Query data from multiple sources using SQL. Exit with `quit;` or `Ctrl+D`. |
| `make minio-ui` | Open MinIO web console in browser. Manage S3 buckets, upload files, and browse object storage. |

### PostgreSQL Management

Dedicated commands for PostgreSQL container.

**Note:** PostgreSQL is automatically configured with the **HSTORE extension** enabled on `template1`, `awaazde`, and `cai` databases. This means all new databases created will have HSTORE available by default.

| Command | Description |
|---------|-------------|
| `make postgres-start` | Start PostgreSQL container. Displays connection string and quick commands when ready. HSTORE extension is automatically enabled. |
| `make postgres-stop` | Stop PostgreSQL container. Data is preserved in Docker volume. |
| `make postgres-restart` | Restart PostgreSQL container without data loss. |
| `make postgres-logs` | Stream PostgreSQL logs. Useful for debugging connection issues. Press Ctrl+C to exit. |
| `make postgres-status` | Check if PostgreSQL is running and accepting connections. Shows container status and health check. |
| `make postgres-psql` | Connect to PostgreSQL using psql CLI. Default database: awaazde. Exit with `\q` or `Ctrl+D`. |
| `make postgres-clean` | **[DESTRUCTIVE]** Stop PostgreSQL and delete its data volume. Requires typing 'yes' to confirm. |

### Network Management

| Command | Description |
|---------|-------------|
| `make network-create` | Create Docker bridge network 'glue-network'. Automatically called by start commands. All services communicate via this network. |

### Development Shortcuts

Convenient commands to manage the entire stack.

| Command | Description |
|---------|-------------|
| `make all-start` | Start everything at once (main stack + PostgreSQL). One command to get the entire environment running. |
| `make all-stop` | Stop all services (main stack + PostgreSQL). Data volumes are preserved. |
| `make all-clean` | **[DESTRUCTIVE]** Stop and delete all data from all services. Requires typing 'yes' to confirm. Complete reset of the environment. |

## Common Workflows

### Starting Fresh

```bash
# Clean everything and start fresh
make all-clean
make all-start
```

### Daily Development

```bash
# Start services
make all-start

# Check everything is running
make status

# Work with your data...
make glue-shell      # For Spark/ETL work
make trino-cli       # For SQL queries
make postgres-psql   # For PostgreSQL work

# Stop when done
make all-stop
```

### Debugging Issues

```bash
# Check service status
make status
make health

# View logs
make logs                # All services
make postgres-logs       # Just PostgreSQL

# Restart if needed
make restart
make postgres-restart
```

### Rebuilding After Configuration Changes

```bash
# After changing Glue config
make build
make restart

# After changing docker-compose.yml
make stop
make start
```

## What is Glue Shell?

The `make glue-shell` command launches **PySpark**, an interactive Python shell with Apache Spark. It's used for:

### Data Processing
```python
# Read data
df = spark.read.csv("s3a://bucket/data.csv", header=True)
df.show()

# Transform data
df_filtered = df.filter(df.age > 30)
df_filtered.show()

# Write results
df_filtered.write.parquet("s3a://bucket/output/")
```

### SQL Queries
```python
# Register temp table
df.createOrReplaceTempView("people")

# Run SQL
spark.sql("SELECT * FROM people WHERE age > 30").show()
```

### Database Connections
```python
# PostgreSQL
jdbc_url = "jdbc:postgresql://postgres:5432/awaazde"
props = {"user": "awaazde", "password": "awaazde"}
df = spark.read.jdbc(jdbc_url, "table_name", properties=props)

# Write to PostgreSQL
df.write.jdbc(jdbc_url, "output_table", mode="overwrite", properties=props)
```

### Pre-configured Variables
- `spark` - SparkSession (main entry point)
- `sc` - SparkContext (lower-level API)
- `sqlContext` - SQL operations

## Port Mappings

| Service | Internal Port | Host Port | Purpose |
|---------|---------------|-----------|---------|
| MinIO API | 9000 | 9000 | S3-compatible API |
| MinIO Console | 9001 | 9001 | Web UI |
| Trino | 8080 | 8080 | Query engine + Web UI |
| Hive Metastore | 9083 | 9083 | Metadata service |
| Hive Server | 10000 | 10000 | HiveServer2 |
| Hive Server UI | 10002 | 10002 | Web UI |
| PostgreSQL | 5432 | 5432 | Database |
| Spark UI | 4040 | 4040 | Job monitoring |
| Spark History | 18080 | 18080 | Historical jobs |

## Data Persistence

Data is stored in Docker volumes:
- `big-data-stack-practice_minio-data` - MinIO object storage
- `big-data-stack-practice_metastore-data` - Hive metadata (MySQL)
- `big-data-stack-practice_warehouse-data` - Hive warehouse data
- `big-data-stack-practice_postgres-data` - PostgreSQL data

To view volumes:
```bash
docker volume ls | grep big-data-stack-practice
```

## PostgreSQL Configuration

### HSTORE Extension

PostgreSQL is pre-configured with the **HSTORE extension** for key-value storage within PostgreSQL columns.

**What is HSTORE?**
- Stores key-value pairs within a single column
- Useful for semi-structured data
- Faster than JSON for simple key-value operations

**Automatic Setup:**
- HSTORE is enabled on `template1` database (template for all new databases)
- HSTORE is enabled on the default `awaazde` database
- Any new database created will automatically have HSTORE available

**Example Usage:**
```sql
-- Connect to PostgreSQL
-- Run: make postgres-psql

-- Create table with HSTORE column
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    attributes HSTORE
);

-- Insert data with HSTORE
INSERT INTO products (name, attributes) VALUES
    ('Laptop', 'brand=>Dell, ram=>16GB, cpu=>i7'),
    ('Phone', 'brand=>Apple, model=>iPhone 14, color=>Black');

-- Query HSTORE data
SELECT name, attributes->'brand' AS brand FROM products;
SELECT * FROM products WHERE attributes->'ram' = '16GB';

-- Update HSTORE values
UPDATE products SET attributes = attributes || 'discount=>10%'::hstore WHERE id = 1;
```

**Initialization Script:**
The HSTORE extension is enabled via the initialization script in `postgres-init/01-enable-hstore.sql`, which runs automatically when PostgreSQL starts for the first time.

## MinIO Configuration

### Automatic Bucket Creation

When you run `make start` or `make all-start`, the following happens automatically:

1. **MinIO starts** - S3-compatible object storage
2. **Bucket initialization** - Two buckets are automatically created:
   - `datalake` - Used by Hive Metastore for warehouse data
   - `test` - Used by Django tests and development

**Why is this needed?**

Hive Metastore requires an S3 bucket to store its warehouse data. Without these buckets, you'll encounter errors:
```
Bucket datalake does not exist
Bucket test does not exist
```

**Bucket Details:**

| Bucket | Purpose | Used By |
|--------|---------|---------|
| `datalake` | Production warehouse data | Hive Metastore, Hive Server, Trino |
| `test` | Test data and Django tests | Django test suite, development |

**Access**: All buckets available via MinIO console at http://localhost:9001

**Manual Bucket Management:**
```bash
# View buckets
docker exec local-minio mc ls myminio

# Create additional buckets
docker exec local-minio mc mb myminio/my-bucket

# Remove a bucket
docker exec local-minio mc rb myminio/my-bucket
```

## Troubleshooting

### Services won't start
```bash
# Check what's already running
docker ps -a

# Check logs
make logs

# Clean start
make all-clean
make all-start
```

### Out of disk space
```bash
# Check Docker disk usage
docker system df

# Clean unused resources
docker system prune -a

# Full cleanup
make all-clean
```

### Port conflicts
If ports are already in use, stop conflicting services or modify port mappings in `docker-compose.yml` and `docker-compose.postgres.yml`.

### Connection issues
```bash
# Verify network exists
docker network ls | grep glue-network

# Recreate network if needed
docker network rm glue-network
make network-create
```

### Hive Server not responding

If you get connection errors when trying to connect to HiveServer2 (port 10000):

**Symptoms:**
- `Connection refused` or `Connection reset by peer`
- Django tests fail with Thrift/Impala connection errors
- HiveServer2 logs show "Could not connect to meta store"

**Root Cause:**
HiveServer2 requires both Hive Metastore AND the MinIO `datalake` bucket to be available.

**Solution:**
```bash
# 1. Check if datalake bucket exists
docker exec local-minio mc ls myminio/datalake

# 2. If bucket doesn't exist, restart services
make stop
make start  # This automatically creates the datalake bucket

# 3. Verify Hive Metastore is running
docker logs hive-metastore --tail 20

# 4. Verify HiveServer2 is running
docker logs hive-server --tail 20

# 5. Check HiveServer2 is listening on port 10000
docker exec hive-server cat /tmp/hive/hive.log | grep "Started.*10000"
```

**Expected output when healthy:**
```
Service:HiveServer2 is started.
Starting ThriftBinaryCLIService on port 10000
```

**Startup time:**
- Hive Metastore: ~15-20 seconds
- HiveServer2: ~20-30 seconds (after Metastore is ready)

## Files Structure

```
.
├── Makefile                          # All management commands
├── docker-compose.yml                # Main stack configuration
├── docker-compose.postgres.yml       # PostgreSQL configuration
├── Dockerfile.glue                   # Glue container image
├── glue-config/
│   ├── spark-defaults.conf          # Spark configuration
│   ├── hive-site.xml                # Hive configuration
│   └── jars/                        # Additional JARs (PostgreSQL driver)
├── glue-jobs/                       # Your Glue/Spark scripts
├── output/                          # Job outputs
├── trino/catalog/                   # Trino catalog configurations
└── hive/                            # Hive configurations and libraries
```

## Environment Variables

Key environment variables (defined in docker-compose.yml):

- `AWS_ACCESS_KEY_ID=minio` - MinIO access key
- `AWS_SECRET_ACCESS_KEY=minio123` - MinIO secret key
- `AWS_REGION=ap-south-1` - AWS region
- `DISABLE_SSL=true` - Disable SSL for local development

## Next Steps

1. **Upload data to MinIO**: Use `make minio-ui` to create buckets and upload files
2. **Create tables in Hive**: Use `make glue-shell` to define table schemas
3. **Query with Trino**: Use `make trino-cli` to query across data sources
4. **Store results in PostgreSQL**: Use PySpark JDBC to write results
5. **Build ETL pipelines**: Create PySpark scripts in `glue-jobs/` directory

## Contributing

Feel free to modify configurations, add new services, or enhance the Makefile commands to suit your needs.

## License

This is a development environment setup. Refer to individual component licenses for production use.
