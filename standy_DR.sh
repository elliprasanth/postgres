
#!/bin/bash

# Variables
STANDBY_DATA_DIR="/postgres/data/"
NEW_PRIMARY_HOST="10.2.0.22"
REPLICATION_USER="postgres"
PG_CTL="/usr/pgsql-16/bin/pg_ctl"  # Path to pg_ctl binary
PG_BIN_DIR="/usr/pgsql-16/bin/"  # Path to PostgreSQL binaries
LOG_FILE="/postgres/standby.log"  # Path to PostgreSQL log file
PORT=6444
PG_PORT=6444
DR_HOST="10.2.0.21"
PRIMARY_HOST="10.2.0.22"

# Function to check for errors
check_error() {
    if [ $? -ne 0 ]; then
        echo "Error: $1" >&2
        exit 1
    fi
}

# Stop PostgreSQL on the old standby (now the standby)
echo "Stopping PostgreSQL service on the standby server..."
$PG_CTL stop -D $STANDBY_DATA_DIR -s -m fast
check_error "Failed to stop PostgreSQL service on the standby server."

# Start PostgreSQL in single-user mode to update configuration
echo "Updating replication settings in postgresql.auto.conf..."
$PG_CTL start -D $STANDBY_DATA_DIR -l $LOG_FILE -w
check_error "Failed to start PostgreSQL service in single-user mode."

# Apply replication settings
echo "Applying replication settings using ALTER SYSTEM..."
PGPASSWORD=postgres@12345 $PG_BIN_DIR/psql -U $REPLICATION_USER  -p ${PORT} -d postgres -c "ALTER SYSTEM SET primary_conninfo TO 'host=${NEW_PRIMARY_HOST} port=${PG_PORT} user=${REPLICATION_USER} password=postgres@123';"

check_error "Failed to update primary_conninfo."

# Reload configuration
echo "Reloading PostgreSQL configuration..."
PGPASSWORD=postgres@12345 $PG_BIN_DIR/psql -U $REPLICATION_USER -p ${PORT} -d postgres -c "SELECT pg_reload_conf();"
check_error "Failed to reload PostgreSQL configuration."
touch $STANDBY_DATA_DIR/standby.signal
echo "DR changes  complete now execute promte script on new PR"
