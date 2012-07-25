#!/bin/sh

portsnap -s portsnap.tw.freebsd.org fetch
portsnap extract

[ ${MASTER_SITE_OVERRIDE='ftp://ftp.tw.freebsd.org/pub/FreeBSD/distfiles/${DIST_SUBDIR}/'} ]
export MASTER_SITE_OVERRIDE

(cd /usr/ports/www/apache22; make BATCH=yes WITHOUT_APACHE_OPTIONS=yes WITH_PROXY_MODULES=yes install)

echo 'apache22_enable="YES"' >> /etc/rc.conf

/usr/local/etc/rc.d/apache22 start
