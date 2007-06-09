#!/bin/sh

date

portsnap -s portsnap.tw.freebsd.org fetch
portsnap extract

#
# install
#

MASTER_SITE_OVERRIDE='ftp://ftp.tw.freebsd.org/pub/FreeBSD/distfiles/${DIST_SUBDIR}/'
export MASTER_SITE_OVERRIDE

( cd /usr/ports/www/apache22 ; make BATCH=yes install )
cp /usr/local/etc/apache22/httpd.conf /root/httpd.conf.dist

( cd /usr/ports/devel/subversion ; make -DWITH_APACHE2_APR -DWITHOUT_BDB -DWITH_MOD_DAV_SVN install )
cp /usr/local/etc/apache22/httpd.conf /root/httpd.conf.subversion

date
svn co http://svn.openfoundry.org/openfoundry /usr/local/checkout
date

( cd /usr/ports/databases/mysql50-server ; make WITH_CHARSET=utf8 WITH_XCHARSET=complex WITH_COLLATION=utf8_general_ci install )

( cd /usr/ports/net/libnss-mysql ; make install )

( cd /usr/ports/security/pwauth ; make patch ; patch work/pwauth-2.3.2/config.h < /usr/local/checkout/trunk/services/vcs/usr/ports/security/pwauth/config.h.diff ; make install )

( cd /usr/ports/www/mod_authnz_external ; make install )
cp /usr/local/etc/apache22/httpd.conf /root/httpd.conf.mod_authnz_external

( cd /usr/ports/www/mod_python3 ; make BATCH=yes install )
cp /usr/local/etc/apache22/httpd.conf /root/httpd.conf.mod_python3

date

( cd / ; tar --exclude './dev' --exclude './backup.tgz' zcf backup.tgz . )

date


#( cd /usr/ports/security/pam-mysql ; make install )
#ln -sf /usr/local/lib/pam_mysql.so /usr/lib/pam_mysql.so
#( cd /usr/ports/www/mod_auth_pam2 ; make install)


#
# configure
#


ln -sf /usr/local/checkout/trunk/services/vcs/etc/rc.conf /etc/rc.conf


# libnss-mysql
/usr/local/etc/rc.d/mysql-server start
mysql < /usr/local/checkout/trunk/services/vcs/usr/local/etc/nss_database.sql
ln -sf /usr/local/checkout/trunk/services/vcs/usr/local/etc/libnss-mysql.cfg /usr/local/etc/libnss-mysql.cfg
ln -sf /usr/local/checkout/trunk/services/vcs/usr/local/etc/libnss-mysql-root.cfg /usr/local/etc/libnss-mysql-root.cfg
ln -sf /usr/local/checkout/trunk/services/vcs/etc/nsswitch.conf /etc/nsswitch.conf

# TODO: disable remote cvs init

# cvs 
#cvs -d /cvs init
#chown -R www:www /cvs
# TODO: commit hook for projects

# mod_auth_pam2 for basic authentication
#ln -sf /usr/local/checkout/trunk/services/vcs/usr/local/etc/apache22/httpd.conf /usr/local/etc/apache22/httpd.conf


