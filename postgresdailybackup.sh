#!/bin/bash

# Define variables
BACKUP_DIR="/path/to/backup/directory/$(date +%Y%m%d)"
PG_HOST="localhost"
PG_USER="your_username"
PG_LOGFILE="/path/to/backup/logs/backup_$(date +%Y%m%d).log"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Perform the base backup
pg_basebackup -h "$PG_HOST" -p "portnumber"-U "$PG_USER" -D "$BACKUP_DIR" -Fp -Xs -P >> "$PG_LOGFILE" 2>&1

# Verify if the backup was successful
if [ $? -eq 0 ]; then
    echo "Backup successful: $(date)" >> "$PG_LOGFILE"
else
    echo "Backup failed: $(date)" >> "$PG_LOGFILE"
fi
