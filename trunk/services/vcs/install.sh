#!/bin/sh

date

#portsnap -s portsnap.tw.freebsd.org fetch
#portsnap extract

#
# install
#
# we have the following assumptions about ports..
#
DISTDIR=/usr/ports_distfiles
export DISTDIR
WRKDIRPREFIX=/usr/ports_work
export WRKDIRPREFIX
MASTER_SITE_OVERRIDE='ftp://ftp.tw.freebsd.org/pub/FreeBSD/distfiles/${DIST_SUBDIR}/'
export MASTER_SITE_OVERRIDE



( cd /usr/ports/www/apache22 ; make BATCH=yes install )
cp /usr/local/etc/apache22/httpd.conf /root/httpd.conf.dist

( cd /usr/ports/devel/subversion ; make BATCH=yes -DWITH_APACHE2_APR -DWITHOUT_BDB -DWITH_MOD_DAV_SVN -DWITH_PYTHON install )
cp /usr/local/etc/apache22/httpd.conf /root/httpd.conf.subversion

svn co http://svn.openfoundry.org/openfoundry /usr/local/checkout

( cd /usr/ports/databases/mysql50-server ; make WITH_CHARSET=utf8 WITH_XCHARSET=complex WITH_COLLATION=utf8_general_ci install )

( cd /usr/ports/net/libnss-mysql ; make install )

( cd /usr/ports/security/pwauth ; make patch ; patch $WRKDIRPREFIX/usr/ports/security/pwauth/work/pwauth-2.3.2/config.h < /usr/local/checkout/trunk/services/vcs/usr/ports/security/pwauth/config.h.diff ; make install )

( cd /usr/ports/www/mod_authnz_external ; make install )
cp /usr/local/etc/apache22/httpd.conf /root/httpd.conf.mod_authnz_external

( cd /usr/ports/devel/viewvc ; make BATCH=yes install )
#( cd /usr/ports/www/mod_python3 ; make BATCH=yes install )
#cp /usr/local/etc/apache22/httpd.conf /root/httpd.conf.mod_python3

( cd /usr/ports/www/p5-libwww ; make BATCH=yes install )
( cd /usr/ports/converters/p5-JSON-XS ; make install )
( cd /usr/ports/databases/p5-DBD-mysql50 ; make install )


csup -g -L 2 /usr/local/checkout/trunk/services/vcs/usr/src/for-cvs-supfile
patch /usr/src/contrib/cvs/src/server.c < /usr/local/checkout/trunk/services/vcs/usr/src/contrib/cvs/src/server.c.diff
( cd /usr/src/gnu/usr.bin/cvs ; make )
install -s -o root -g wheel -m 555 -b /usr/src/gnu/usr.bin/cvs/cvs/cvs /usr/bin


openfoundry_etc=/usr/local/etc/openfoundry/
mkdir -p "$openfoundry_etc"
ln -sf /usr/local/checkout/trunk/services/vcs/usr/local/etc/openfoundry.conf.dist "$openfoundry_etc"
ln -sf /usr/local/checkout/trunk/services/vcs/usr/local/etc/openfoundry_root.conf.dist "$openfoundry_etc"
cp "$openfoundry_etc/openfoundry.conf.dist" "$openfoundry_etc/openfoundry.conf"
cp "$openfoundry_etc/openfoundry_root.conf.dist" "$openfoundry_etc/openfoundry_root.conf"
chmod 600 "$openfoundry_etc/openfoundry_root.conf"

echo "*******************************************************************"
echo " Don't forget to modify $openfoundry_etc/openfoundry[_root].conf "
echo "*******************************************************************"

echo date


#
# backup
#
#date
#if [ ! -f /backup.tgz ]; then
#  ( cd / ; tar --exclude './dev/*' --exclude './usr/ports*/*' --exclude './var/run/log*' --exclude './backup*.tgz' -zcf backup.tgz . )
#fi
#date
