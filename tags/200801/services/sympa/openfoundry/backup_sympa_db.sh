#!/bin/sh

#for mysqlhotcopy 
THIS_DATE=`date '+%Y-%m-%d'`
BACKUP_LOCATION=/home/backup

mkdir -p $BACKUP_LOCATION/sympa-$THIS_DATE
/usr/local/bin/mysqlhotcopy sympa $BACKUP_LOCATION/sympa-$THIS_DATE

#find one-month-ago backup and delete it
find $BACKUP_LOCATION -maxdepth 1 \( -not -newerct '1 month ago' \) -exec rm -rf {} \;
