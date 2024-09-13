#!/bin/sh
cd dirname $0
. dirname $0/parameter.env
STATUS_FILE="dirname $0/SCP_RECOVERY_IS_IN_PROGRESS"
SCP_SYNC_LOG="dirname $0/SCP_SYN.log"
if [ -f $STATUS_FILE ]
then
        echo "SCP Recovery is in progress using Script"
else
        #REMOTE_HOST=""
        REMOTE_HOST=cat $POSTGREDATAPATH/postgresql.auto.conf | grep "^primary_conninfo" | tr -d "'" | cut -d"=" -f3- | cut -d" " -f1
        echo $REMOTE_HOST
        LOCAL_WAL_DEST=$PG_XLOG_DIR
        echo $LOCAL_WAL_DEST
        touch $STATUS_FILE
        parent_id=`ps -ef|grep  "$POSTGREDATAPATH" |grep -v grep  |awk '{print $2}' `
        REQ_WAL=ps -ef|grep -v grep |grep recovering |grep $parent_id | awk '{print $11}'

        if [ "$REQ_WAL" == "" ]
        then
                REQ_WAL=$1
                echo date $REQ_WAL >> /tmp/walfile_name.txt
        fi
        echo $REQ_WAL
        WAL_FILE_LEN=echo $REQ_WAL|wc -c
        WAL_FILE_LEN_TO_PROCESS=$(( $WAL_FILE_LEN - 3 ))
        WAL_FILE_LAST_POS=$(( $WAL_FILE_LEN - 1 ))
        WAL_FILE_2ND_LAST_POS=$(( $WAL_FILE_LEN - 2 ))
        WAL_REG_EXP="echo $REQ_WAL|cut -c-$WAL_FILE_LEN_TO_PROCESS"
        WAL_FILE_LAST_CHAR="echo $REQ_WAL|cut -c$WAL_FILE_LAST_POS"
        WAL_FILE_2ND_LAST_CHAR="echo $REQ_WAL|cut -c$WAL_FILE_2ND_LAST_POS"

         if [ "$WAL_FILE_LAST_CHAR" == "F" ] && [ "$WAL_FILE_2ND_LAST_CHAR" == "F" ]
         then
                 sh dirname $0/wal_ready_to_done.sh
         fi
         if [ "$WAL_FILE_LAST_CHAR" == "0" ] && [ "$WAL_FILE_2ND_LAST_CHAR" == "0" ]
         then
                 WAL_LIST_FILE="dirname $0/wal_list.txt"
                 loop_cnt=$SCP_thread_count
                 ssh  -o StrictHostKeyChecking=no $REMOTE_HOST "cd $REMOTE_ARCHIVE_DEST;ls -lrt *00" |awk '{print $9}'|cut -c 1-22 |sort -u > ${WAL_LIST_FILE}
                 cnt=wc -l ${WAL_LIST_FILE} | awk '{print $1}'
                 stln=grep -nr $WAL_REG_EXP ${WAL_LIST_FILE}|awk -F':' '{print $1}'
                 reqln=expr $cnt - $stln
                 processed_cnt=1
                 if [ $reqln -le 1 ]
                 then
                         scp -p  -C  -o StrictHostKeyChecking=no $REMOTE_HOST:$REMOTE_ARCHIVE_DEST$WAL_REG_EXP?? $LOCAL_WAL_DEST
                         echo "$WAL_REG_EXP fore ground" >> ${SCP_SYNC_LOG}
                 else
tail  -expr $reqln + 1 ${WAL_LIST_FILE} | head -$reqln|while read line
                         do
                                  pro_mod=expr $processed_cnt % $loop_cnt
                                  if [ $pro_mod -eq 0 ] || [ $processed_cnt -eq $reqln ]
                                  then
                                         echo "$line fore ground- date" >> ${SCP_SYNC_LOG}
                                        scp -p  -o StrictHostKeyChecking=no $REMOTE_HOST:$REMOTE_ARCHIVE_DEST${line}?? $LOCAL_WAL_DEST
                                         sleep 1
                                 else
                                         echo "$line back group- date" >> ${SCP_SYNC_LOG}
                                         scp -p -o StrictHostKeyChecking=no $REMOTE_HOST:$REMOTE_ARCHIVE_DEST${line}?? $LOCAL_WAL_DEST &
                                 fi
                                 processed_cnt=expr $processed_cnt + 1
                         done
                         last_wal=tail -1 $WAL_LIST_FILE
                         echo "$last_wal fore group- date" >> ${SCP_SYNC_LOG}
                         scp -p  -o StrictHostKeyChecking=no $REMOTE_HOST:$REMOTE_ARCHIVE_DEST$last_wal?? $LOCAL_WAL_DEST

                         sh dirname $0/wal_ready_to_done.sh
                 fi

         else
         case $WAL_FILE_LAST_CHAR in
         [1-9])
                 scp -p  -o StrictHostKeyChecking=no $REMOTE_HOST:$REMOTE_ARCHIVE_DEST$WAL_REG_EXP$WAL_FILE_2ND_LAST_CHAR[$WAL_FILE_LAST_CHAR-9] $LOCAL_WAL_DEST
scp -p  -o StrictHostKeyChecking=no $REMOTE_HOST:$REMOTE_ARCHIVE_DEST$WAL_REG_EXP$WAL_FILE_2ND_LAST_CHAR"[A-F]" $LOCAL_WAL_DEST
                 ;;
         A|B|C|D|E|F)
                 scp -p  -o StrictHostKeyChecking=no $REMOTE_HOST:$REMOTE_ARCHIVE_DEST$WAL_REG_EXP$WAL_FILE_2ND_LAST_CHAR[$WAL_FILE_LAST_CHAR-F] $LOCAL_WAL_DEST
                 ;;
         0)
                 scp -p  -o StrictHostKeyChecking=no $REMOTE_HOST:$REMOTE_ARCHIVE_DEST$WAL_REG_EXP$WAL_FILE_2ND_LAST_CHAR? $LOCAL_WAL_DEST
                 ;;
         esac
         case $WAL_FILE_2ND_LAST_CHAR in
         [0-8])
                 scp -p   -o StrictHostKeyChecking=no $REMOTE_HOST:$REMOTE_ARCHIVE_DEST$WAL_REG_EXP"[$(( $WAL_FILE_2ND_LAST_CHAR + 1 ))-9]"? $LOCAL_WAL_DEST
                 scp -p   -o StrictHostKeyChecking=no $REMOTE_HOST:$REMOTE_ARCHIVE_DEST$WAL_REG_EXP"[A-F]"? $LOCAL_WAL_DEST
                 ;;
         9)
                 scp -p   -o StrictHostKeyChecking=no $REMOTE_HOST:$REMOTE_ARCHIVE_DEST$WAL_REG_EXP"[A-F]"? $LOCAL_WAL_DEST
                 ;;
         A)
                 scp -p   -o StrictHostKeyChecking=no $REMOTE_HOST:$REMOTE_ARCHIVE_DEST$WAL_REG_EXP"[B-F]"? $LOCAL_WAL_DEST
                 ;;
         B)
                 scp -p   -o StrictHostKeyChecking=no $REMOTE_HOST:$REMOTE_ARCHIVE_DEST$WAL_REG_EXP"[C-F]"? $LOCAL_WAL_DEST
                 ;;
         C)
                 scp -p   -o StrictHostKeyChecking=no $REMOTE_HOST:$REMOTE_ARCHIVE_DEST$WAL_REG_EXP"[D-F]"? $LOCAL_WAL_DEST
                 ;;
         D)
                 scp -p   -o StrictHostKeyChecking=no $REMOTE_HOST:$REMOTE_ARCHIVE_DEST$WAL_REG_EXP"[E-F]"? $LOCAL_WAL_DEST
                 ;;
         E)
                 scp -p   -o StrictHostKeyChecking=no $REMOTE_HOST:$REMOTE_ARCHIVE_DEST$WAL_REG_EXP"F"? $LOCAL_WAL_DEST
                 ;;
         esac
    fi
   rm $STATUS_FILE
fi