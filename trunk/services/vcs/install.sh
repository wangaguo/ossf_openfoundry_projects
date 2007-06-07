#!/bin/sh

portsnap -s portsnap.tw.freebsd.org fetch
portsnap extract

( cd /usr/ports/www/apache22 ; make BATCH=yes install )
( cd /usr/ports/devel/subversion ; make -DWITH_APACHE2_APR -DWITHOUT_BDB -DWITH_MOD_DAV_SVN install )
( cd /usr/ports/databases/mysql50-server ; make WITH_CHARSET=utf8 WITH_XCHARSET=complex WITH_COLLATION=utf8_general_ci install )
( cd /usr/ports/net/libnss-mysql ; make install )
( cd /usr/ports/www/mod_python3 ; make install )
