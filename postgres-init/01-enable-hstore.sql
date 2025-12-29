-- Enable HSTORE extension for template databases
-- This ensures all newly created databases have HSTORE available

-- Connect to template1 and enable HSTORE
\c template1
CREATE EXTENSION IF NOT EXISTS hstore;

-- Connect to the default database and enable HSTORE
\c awaazde
CREATE EXTENSION IF NOT EXISTS hstore;

-- Create cai database and enable HSTORE
CREATE DATABASE cai;
\c cai
CREATE EXTENSION IF NOT EXISTS hstore;

-- Display confirmation
SELECT 'HSTORE extension enabled on template1, awaazde, and cai databases' AS status;
