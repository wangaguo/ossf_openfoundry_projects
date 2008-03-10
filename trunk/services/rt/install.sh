#!/bin/sh

DB_HOST=$1            # 192.168.0.10
DB_PASSWORD=$2        # rt_pass (for rt_user)
TEMP_DBA_USER=$3      # temp_dba_user
TEMP_DBA_PASSWORD=$4  # temp_dba_pass

echo "Reminder: don't forget to enable DBA user on the 'data' site"
echo "  mysql -u root -e \"grant all on *.* to '${TEMP_DBA_USER}'@'%' identified by '${TEMP_DBA_PASSWORD}' with grant option\""
sleep 10


if [ ! -d /usr/ports ] ; then
	portsnap -s ${PORTSNAP_SITE='portsnap.tw.freebsd.org'} fetch
	portsnap extract
fi
[ ${MASTER_SITE_OVERRIDE='ftp://ftp.tw.freebsd.org/pub/FreeBSD/distfiles/${DIST_SUBDIR}/'} ]
export MASTER_SITE_OVERRIDE


( cd /usr/ports/www/apache22 ; make BATCH=yes install )
( cd /usr/ports/databases/mysql50-client ; make WITH_CHARSET=utf8 WITH_XCHARSET=complex WITH_COLLATION=utf8_general_ci install )


( cd /usr/ports/www/rt36 ; make -DWITH_FASTCGI -DWITH_APACHE2 -DBATCH DB_HOST=${DB_HOST} DB_PASSWORD=${DB_PASSWORD} DB_DBA_USER=${TEMP_DBA_USER} DB_DBA_PASSWORD=${TEMP_DBA_PASSWORD} -DINITIAL_INSTALL install)

echo "You can now disable DBA user on the 'data' site"
echo "  mysql -u root -e \"REVOKE ALL PRIVILEGES, GRANT OPTION FROM ${TEMP_DBA_USER}\""



# for debugging only
mysqldump -h ${DB_HOST} -u rt_user -p${DB_PASSWORD} --skip-extended-insert rt3 > /root/rt_initial.sql
