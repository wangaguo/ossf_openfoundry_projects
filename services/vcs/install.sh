#!/bin/sh

portsnap -s portsnap.tw.freebsd.org fetch
portsnap extract

( cd /usr/ports/www/apache22 ; make BATCH=yes install )
( cd /usr/ports/devel/subversion ; make -DWITH_APACHE2_APR -DWITHOUT_BDB -DWITH_MOD_DAV_SVN install )
( cd /usr/ports/databases/mysql50-server ; make WITH_CHARSET=utf8 WITH_XCHARSET=complex WITH_COLLATION=utf8_general_ci install )
( cd /usr/ports/net/libnss-mysql ; make install )
( cd /usr/ports/www/mod_python3 ; make BATCH=yes install )
( cd /usr/ports/security/pam-mysql ; make install )
#ln -sf /usr/local/lib/pam_mysql.so /usr/lib/pam_mysql.so
( cd /usr/ports/www/mod_auth_pam2 ; make install)
