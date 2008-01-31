#!/bin/sh
OPENFOUNDRY_HOME=/usr/local/openfoundry
OPENFOUNDRY_CHECKOUT="${OPENFOUNDRY_HOME}/checkout"
OPENFOUNDRY_ETC="${OPENFOUNDRY_HOME}/etc"

date

#
# ports tree
#
if [ ! -d /usr/ports ] || test -w /usr/ports ; then
	echo "Using stand-alone ports tree"
	portsnap -s portsnap.tw.freebsd.org fetch
	portsnap extract
else
	echo "Using shared ports tree"
	DISTDIR=/usr/ports_distfiles
	export DISTDIR
	WRKDIRPREFIX=/usr/ports_work
	export WRKDIRPREFIX
fi
[ ${MASTER_SITE_OVERRIDE='ftp://ftp.tw.freebsd.org/pub/FreeBSD/distfiles/${DIST_SUBDIR}/'} ]
export MASTER_SITE_OVERRIDE
date


( cd /usr/ports/www/apache22 ; make BATCH=yes install )
cp /usr/local/etc/apache22/httpd.conf /root/httpd.conf.dist

( cd /usr/ports/devel/subversion ; make BATCH=yes -DWITH_APACHE2_APR -DWITHOUT_BDB -DWITH_MOD_DAV_SVN -DWITH_PYTHON install )
cp /usr/local/etc/apache22/httpd.conf /root/httpd.conf.subversion

svn co http://svn.openfoundry.org/openfoundry "${OPENFOUNDRY_CHECKOUT}"

( cd /usr/ports/databases/mysql50-server ; make WITH_CHARSET=utf8 WITH_XCHARSET=complex WITH_COLLATION=utf8_general_ci install )

( cd /usr/ports/net/libnss-mysql ; make install )

( cd /usr/ports/security/pwauth ; make patch ; patch $WRKDIRPREFIX/usr/ports/security/pwauth/work/pwauth-*/config.h < "${OPENFOUNDRY_CHECKOUT}/trunk/services/vcs/usr/ports/security/pwauth/config.h.diff" ; make install )

( cd /usr/ports/www/mod_authnz_external ; make install )
cp /usr/local/etc/apache22/httpd.conf /root/httpd.conf.mod_authnz_external

( cd /usr/ports/devel/viewvc ; make BATCH=yes install )
#( cd /usr/ports/www/mod_python3 ; make BATCH=yes install )
#cp /usr/local/etc/apache22/httpd.conf /root/httpd.conf.mod_python3

( cd /usr/ports/www/p5-libwww ; make BATCH=yes install )
( cd /usr/ports/converters/p5-JSON-XS ; make install )
( cd /usr/ports/databases/p5-DBD-mysql50 ; make install )


csup -g -L 2 "${OPENFOUNDRY_CHECKOUT}/trunk/services/vcs/usr/src/for-cvs-supfile"
patch /usr/src/contrib/cvs/src/server.c < "${OPENFOUNDRY_CHECKOUT}/trunk/services/vcs/usr/src/contrib/cvs/src/server.c.diff"
( cd /usr/src/gnu/usr.bin/cvs ; make )
install -s -o root -g wheel -m 555 -b /usr/src/gnu/usr.bin/cvs/cvs/cvs /usr/bin


mkdir -p "${OPENFOUNDRY_ETC}"
ln -sf "${OPENFOUNDRY_CHECKOUT}/trunk/services/vcs/usr/local/openfoundry/etc/openfoundry.conf.dist" "${OPENFOUNDRY_ETC}"
ln -sf "${OPENFOUNDRY_CHECKOUT}/trunk/services/vcs/usr/local/openfoundry/etc/openfoundry_root.conf.dist" "${OPENFOUNDRY_ETC}"
cp "${OPENFOUNDRY_ETC}/openfoundry.conf.dist" "${OPENFOUNDRY_ETC}/openfoundry.conf"
cp "${OPENFOUNDRY_ETC}/openfoundry_root.conf.dist" "${OPENFOUNDRY_ETC}/openfoundry_root.conf"
chmod 600 "${OPENFOUNDRY_ETC}/openfoundry_root.conf"

fetch -o /root/config.sh http://svn.openfoundry.org/openfoundry/trunk/services/vcs/config.sh


echo "*************************************************************************************************"
echo " Don't forget to modify ${OPENFOUNDRY_ETC}/openfoundry[_root].conf and execute config.sh "
echo "*************************************************************************************************"

date
