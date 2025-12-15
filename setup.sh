#!/bin/bash

echo "Creating directory structure..."
mkdir -p trino/catalog
mkdir -p hive/conf
mkdir -p glue-jobs
mkdir -p output

# Prompt for reports path
read -p "Enter the path to your reports directory (e.g., /home/harsh/AD/awaazde2/backend/awaazde/web/common/integrations/reports): " REPORTS_PATH

if [ -z "$REPORTS_PATH" ]; then
    echo "Error: Reports path is required"
    exit 1
fi

if [ ! -d "$REPORTS_PATH" ]; then
    echo "Error: Directory '$REPORTS_PATH' does not exist"
    exit 1
fi

export REPORTS_PATH

echo "Updating .env for REPORTS_PATH"
echo "REPORTS_PATH=$REPORTS_PATH" > .env
exit

echo "Using reports path: $REPORTS_PATH"

echo "Starting all services (MinIO, PostgreSQL, Hive Metastore, HiveServer2, Trino, Glue)..."
docker-compose up -d

echo "Waiting for services to be ready..."
sleep 5

echo "Creating buckets in MinIO..."
docker run --rm --network glue-network \
  --entrypoint /bin/sh \
  minio/mc:RELEASE.2020-04-25T00-43-23Z -c "\
    mc config host add myminio http://minio:9000 minio minio123 && \
    mc mb myminio/glue --ignore-existing && \
    mc mb myminio/hive --ignore-existing && \
    mc mb myminio/default --ignore-existing && \
    mc mb myminio/test --ignore-existing && \
    mc mb myminio/development --ignore-existing && \
    mc mb myminio/datalake --ignore-existing && \
    echo 'All buckets created successfully'"

echo "Waiting for all services to initialize..."
sleep 5

echo ""
echo "Setup complete!"
echo ""
echo "Services:"
echo "  PostgreSQL: localhost:5432 (postgres/postgres, awaazde db created)"
echo "  MinIO Console: http://localhost:9001 (minio/minio123)"
echo "  MinIO API: http://localhost:9000"
echo "  Trino UI: http://localhost:8080"
echo "  Hive Metastore: localhost:9083"
echo "  HiveServer2 (Impala): localhost:10000"
echo "  Spark UI: http://localhost:4040 (when job running)"
echo ""
echo "To enter Glue interactive shell:"
echo "  docker exec -it glue-interactive /bin/bash"
echo ""
echo "To test Trino connection:"
echo "  docker exec -it local-trino trino"
echo ""