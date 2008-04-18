#!/bin/sh

DB_HOST=$1            # 192.168.0.10
DB_PASSWORD=$2        # rt_pass (for rt_user)
TEMP_DBA_USER=$3      # temp_dba_user
TEMP_DBA_PASSWORD=$4  # temp_dba_pass


OPENFOUNDRY_HOME=/usr/local/openfoundry
OPENFOUNDRY_CHECKOUT="${OPENFOUNDRY_HOME}/checkout"
RT_CHECKOUT="${OPENFOUNDRY_CHECKOUT}/trunk/services/rt"

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
( cd /usr/ports/devel/subversion ; make BATCH=yes -DWITH_APACHE2_APR -DWITHOUT_BDB install )

svn co http://svn.openfoundry.org/openfoundry/trunk/services/rt "${OPENFOUNDRY_CHECKOUT}/trunk/services/rt"




( cd /usr/ports/www/rt36 ; make -DWITH_FASTCGI -DWITH_APACHE2 -DBATCH DB_HOST=${DB_HOST} DB_PASSWORD=${DB_PASSWORD} DB_DBA_USER=${TEMP_DBA_USER} DB_DBA_PASSWORD=${TEMP_DBA_PASSWORD} -DINITIAL_INSTALL CONFIGURE_ARGS=--with-db-rt-host=`ifconfig lo0 | tail +2 | awk '{print $2}'` install)

echo "patching for LONGTEXT..."
mysql -h ${DB_HOST} -u rt_user "-p${DB_PASSWORD}" -e "ALTER TABLE sessions MODIFY a_session longblob"
mysql -h ${DB_HOST} -u rt_user "-p${DB_PASSWORD}" -e "ALTER TABLE Attachments MODIFY content longblob"

echo "You can now disable DBA user on the 'data' site"
echo "  mysql -u root -e \"REVOKE ALL PRIVILEGES, GRANT OPTION FROM ${TEMP_DBA_USER}\""


# for debugging only
mysqldump -h ${DB_HOST} -u rt_user "-p${DB_PASSWORD}" --skip-extended-insert rt3 > /root/rt_initial.sql


# web interface
ln -s "${RT_CHECKOUT}/usr/local/etc/apache22/Includes/rt.conf" /usr/local/etc/apache22/Includes
/usr/local/etc/rc.d/apache22 rcvar | grep YES || echo 'apache22_enable="YES"' >> /etc/rc.conf
/usr/local/etc/rc.d/apache22 start

