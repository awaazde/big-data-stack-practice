#!/bin/bash
set -e

# Create hstore extension in template1 so all new databases will have it
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname template1 <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS hstore;
EOSQL

# Create the awaazde database
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE awaazde;
EOSQL

# Create the awaazde user with the specified password
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE ROLE awaazde WITH LOGIN ENCRYPTED PASSWORD 'awaazde' CREATEDB;
EOSQL

# Grant all privileges on the awaazde database to the awaazde user
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    GRANT ALL PRIVILEGES ON DATABASE awaazde TO awaazde;
EOSQL

# Since we added hstore to template1, awaazde already has it
# But we can explicitly ensure it's there
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname awaazde <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS hstore;
EOSQL

# Grant permissions on public schema to awaazde user (required for PG15+)
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname awaazde <<-EOSQL
    GRANT ALL ON SCHEMA public TO awaazde;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO awaazde;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO awaazde;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO awaazde;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO awaazde;
EOSQL

echo "Database initialization completed successfully"