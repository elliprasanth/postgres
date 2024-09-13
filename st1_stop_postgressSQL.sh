cd `dirname $0`
. `dirname $0`/parameter.env
${POSTGREBIN}/psql -p ${PORT} -d ${DBNAME} -U ${DBUSERNAME} -w -c "select pg_is_in_recovery();" -q > output.txt
cat output.txt