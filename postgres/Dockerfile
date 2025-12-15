FROM postgres:16

# Copy initialization script
COPY init-db.sh /docker-entrypoint-initdb.d/

# Make sure the script is executable
RUN chmod +x /docker-entrypoint-initdb.d/init-db.sh