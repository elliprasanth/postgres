cd `dirname $0`
. `dirname $0`/parameter.env
${POSTGREBIN}/psql -p ${PORT} -d ${DBNAME} -U ${DBUSERNAME} -w -c "select pg_is_in_recovery();" -q
echo "The above query should give value $RECOVERYVALUE"
${POSTGREBIN}/pg_ctl -D ${POSTGREDATAPATH} stop -mf
loopcnt=0
while true 
do
sleep 1
loopcnt=`expr ${loopcnt} + 1`
PRCCNT=`ps -ef | grep ${DBEXENAME} | grep -v grep|wc -l`
if [ ${PRCCNT} -eq 0 ] 
then
	echo "PostgreSQL process stopped sucessfully"
	exit
fi
if [ ${loopcnt} -gt 11 ] 
then
	echo "PostgreSQL process not stopped sucessfully"
	echo "su to postgres and run ${POSTGREBIN}/pg_ctl -D ${POSTGREDATAPATH} stop -mf"
	exit
fi
done


t8


cd `dirname $0`
. `dirname $0`/parameter.env
${POSTGREBIN}/pg_ctl -D ${POSTGREDATAPATH} start
loopcnt=0
while true 
do
sleep 1
loopcnt=`expr ${loopcnt} + 1`
PRCCNT=`ps -ef | grep ${DBEXENAME} | grep -v grep|wc -l`
if [ ${PRCCNT} -eq 1 ] 
then
	echo "PostgreSQL process started sucessfully"
	exit
fi
if [ ${loopcnt} -gt 11 ] 
then
	echo "PostgreSQL process not started sucessfully"
	echo "su to postgres and run ${POSTGREBIN}/pg_ctl -D ${POSTGREDATAPATH} restart"
	exit
fi
done