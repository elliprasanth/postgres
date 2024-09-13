
# Define variables
PRIMARY_HOST="10.2.0.22"
PORT="6444"
REPLICA_USER="postgres"
REPLICA_HOST="10.2.0.21"
OLD_PRIMARY_HOST="10.2.0.22"
OLD_PORT="6444"
NEW_PRIMARY_HOST="10.2.0.21"
REPLICA_USER="postgres"
PRIMARY_DATA_DIR="postgres/data"
REPLICA_DATA_DIR="/postgres/data"
# Connect to the primary server and check replication status
echo "Checking the replication  on  PR..."
psql -h "$PRIMARY_HOST" -p "$PORT" -U "$REPLICA_USER" -c \ "SELECT pid, application_name, client_addr, state, sync_state, sent_lsn, write_lsn, flush_lsn, replay_lsn FROM pg_stat_replication pg_stat_replication;"
# Connect to the DR server and check replication status
echo "Checking  the replication on   DR..."
psql -h "$NEW_PRIMARY_HOST" -p "$PORT" -U "$REPLICA_USER" -c \ "SELECT pid,status,receive_start_lsn,written_lsn,last_msg_send_time,last_msg_receipt_time,latest_end_lsn,latest_end_time FROM  pg_stat_wal_receiver;"
