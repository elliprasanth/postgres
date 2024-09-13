
# Configuration variables
PGDATA="/postgres/data/" # Path to PostgreSQL data directory
PGUSER="postgres" # PostgreSQL superuser
PGCTL="/usr/pgsql-16/bin/pg_ctl" # Path to pg_ctl command
POSTGREBIN="/usr/pgsql-16/bin/"
POSTGREDATAPATH="/postgres/data/"
PORT="6444"
DBUSERNAME="postgres"
DBNAME="postgres"
echo "Verify the current active server ip"
RECOVERY_STATUS=$(${POSTGREBIN}/psql -p ${PORT} -d ${DBNAME} -U ${DBUSERNAME} -w -c "select pg_is_in_recovery();"  -q)
value=$(echo $RECOVERY_STATUS | cut -d " " -f3);
if [ $value == "f" ]
then
     echo "Server is in Started State with master mode cannot able execute Standby.signal"
else

touch ${POSTGREDATAPATH}/standby.signal

fi

cat ${POSTGREDATAPATH}/postgresql.auto.conf | grep "^primary_conninfo" | tr -d "'" | cut -d"=" -f3- | cut -d" " -f4
