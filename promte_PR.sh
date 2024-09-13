
#!/bin/bash

# Configuration variables
PGDATA="/postgres/data/" # Path to PostgreSQL data directory
PGUSER="postgres" # PostgreSQL superuser
PGCTL="/usr/pgsql-16/bin/pg_ctl" # Path to pg_ctl command
PORT=6444
DBNAME=postgres
DBUSERNAME=postgres
# Function to promote standby to primary
promote_standby() {
  echo "Promoting standby to primary..."
  $PGCTL promote -D "$PGDATA"

  if [ $? -eq 0 ]; then
    echo "Standby promotion successful."
  else
    echo "Standby promotion failed."
    exit 1
  fi
}

# Check if the server is currently in standby mode
is_standby() {
  local status
  status=$($psql -p 6444 -t -c "SELECT pg_is_in_recovery();" | tr -d '[:space:]')
 
if [ "$status" = "t" ]; then
  echo "The server is in recovery mode."
else
  echo "The server is not in recovery mode."
fi
}

# Main script execution
echo "Checking if the server is in standby mode..."
if is_standby; then
  promote_standby
else
  echo "The server is not in standby mode. Promotion is not necessary."
  exit 0
fi

