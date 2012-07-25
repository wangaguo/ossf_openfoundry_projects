#!/bin/sh
PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

DB_USER="%%DB_USER%%"
DB_PASS="%%DB_PASS%%"
DB_HOST="%%DB_HOST%%"
INSTALL_DIR="%%INSTALL_DIR%%"

LOG_FILE="ftp_sync.log"
SQL_FILE="sync_ftp_users.sql"
LOCK_FILE="sync_ftp_users.lock"

cd $INSTALL_DIR;

if [ -f $LOCK_FILE ]; then
	echo "lock on `date`" >> $MIRROR_NAME".log"
else
	echo "starting mirror on `date`" >> $LOG_FILE
	touch $LOCK_FILE
	mysql --default-character-set=utf8 -u $DB_USER -p$DB_PASS -h $DB_HOST < $SQL_FILE >> $LOG_FILE 2>&1 
	rm $LOCK_FILE
fi
