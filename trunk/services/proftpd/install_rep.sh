#!/bin/sh

if [ ! -d /usr/ports ] ; then
	portsnap -s ${PORTSNAP_SITE='portsnap.tw.freebsd.org'} fetch
	portsnap extract
fi
[ ${MASTER_SITE_OVERRIDE='ftp://ftp.tw.freebsd.org/pub/FreeBSD/distfiles/${DIST_SUBDIR}/'} ]
export MASTER_SITE_OVERRIDE


( cd /usr/ports/www/apache22 ; make BATCH=yes install )
( cd /usr/ports/databases/mysql50-client ; make WITH_CHARSET=utf8 WITH_XCHARSET=complex WITH_COLLATION=utf8_general_ci install )
( cd /usr/ports/ftp/proftpd; make BATCH=yes WITH_OPENSSL=true WITH_QUOTA=true WITH_MYSQL=true WITH_NLS=true install clean distclean )

/usr/local/etc/rc.d/apache22 rcvar | grep YES || echo 'apache22_enable="YES"' >> /etc/rc.conf
/usr/local/etc/rc.d/apache22 start

/usr/local/etc/rc.d/proftpd rcvar | grep YES || echo 'proftpd_enable="YES"' >> /etc/rc.conf
/usr/local/etc/rc.d/proftpd start
