#!/bin/sh

OPENFOUNDRY_HOME=/usr/local/vcs
OPENFOUNDRY_ETC="${OPENFOUNDRY_HOME}/etc"
OPENFOUNDRY_CHECKOUT="${OPENFOUNDRY_HOME}/checkout"
OPENFOUNDRY_BIN="${OPENFOUNDRY_HOME}/bin"
OPENFOUNDRY_PM_CHECKOUT="${OPENFOUNDRY_CHECKOUT}/module"
VCS_CHECKOUT="${OPENFOUNDRY_CHECKOUT}/vcs"

mkdir -p "${OPENFOUNDRY_HOME}"
mkdir -p "${OPENFOUNDRY_ETC}"
mkdir -p "${OPENFOUNDRY_BIN}"

#
# configure
#

replace_out()
{
	perl -pe 's/--(\w+)--/exists $ENV{$1} ? $ENV{$1} : die "no $1 in env"/ge' $1
}

replace()
{
	if [ ! -f $1 ]; then
		echo "input file $1 does not exist"
		exit 1
	fi
	if [ ! -d $2 ]; then
		echo "output directory $2 does not exist"
		exit 1
	fi
	# $1 must be a full path
	# $2 must be a directory
	output_file=$2/`basename $1`
	echo "Input: $1 Output: $output_file"
	replace_out $1 > $output_file
	if [ -n "$3" ]; then
		chmod $3 $output_file
	else
		chmod ugo-w $output_file
	fi
}


ln -sf "${VCS_CHECKOUT}/etc/rc.conf" /etc/

# OpenFoundry
export OPENFOUNDRY_ETC
export OPENFOUNDRY_BIN
replace "${OPENFOUNDRY_PM_CHECKOUT}/OpenFoundry.pm" /usr/local/lib/perl5/site_perl/5.8.8/

# export conf to env
envs=`perl -MOpenFoundry -e '%conf = %{OpenFoundry::loadConf()}; while (($k, $v) = each %conf) { print "$k=\"$v\"; export $k\n"}'`
if [ "$?" = "0" ]; then
	eval $envs
else
	echo "Please check your config file"
	exit 1
fi

ln -sf "${VCS_CHECKOUT}/usr/local/openfoundry/bin/openfoundry_sync_cache.sh" "${OPENFOUNDRY_BIN}/"

# libnss-mysql
/usr/local/etc/rc.d/mysql-server restart
until /usr/local/etc/rc.d/mysql-server status | grep 'is running'; do echo 'waitiing for mysql..'; sleep 1; done
replace_out "${VCS_CHECKOUT}/usr/local/etc/nss_database.sql" | mysql
replace "${VCS_CHECKOUT}/usr/local/etc/libnss-mysql.cfg" /usr/local/etc/
replace "${VCS_CHECKOUT}/usr/local/etc/libnss-mysql-root.cfg" /usr/local/etc/ 0400
ln -sf "${VCS_CHECKOUT}/etc/nsswitch.conf" /etc/
ln -sf "${VCS_CHECKOUT}/usr/local/openfoundry/bin/openfoundry_sync_nss.pl" "${OPENFOUNDRY_BIN}/"

# cvs / svn
ln -sf "${VCS_CHECKOUT}/usr/local/openfoundry/bin/cvs_svn_only.sh" "${OPENFOUNDRY_BIN}/"
ln -sf "${VCS_CHECKOUT}/usr/local/openfoundry/bin/openfoundry_sync_repos.pl" "${OPENFOUNDRY_BIN}/"
ln -sf "${VCS_CHECKOUT}/usr/local/openfoundry/bin/openfoundry_backup_repos.pl" "${OPENFOUNDRY_BIN}/"

# cvs
mkdir -p "$CVSROOT"
cvs -d "$CVSROOT" init
# TODO: file permission?
chown -R $CVSOWNER:$CVSGROUP "$CVSROOT"
ln -sf "${VCS_CHECKOUT}/cvs/CVSROOT/commitcheck.pl" "$CVSROOT/CVSROOT/"
ln -sf "${VCS_CHECKOUT}/cvs/CVSROOT/commitinfo" "$CVSROOT/CVSROOT/"
ln -sf "${VCS_CHECKOUT}/etc/ssh/sshd_config" /etc/ssh/

# svn
mkdir $SVN_PARENT_PATH
mkdir -p "$SVN_PARENT_PATH/.default/hooks"
ln -sf "${VCS_CHECKOUT}/svn/hooks/pre-commit" "$SVN_PARENT_PATH/.default/hooks/"
ln -sf "${VCS_CHECKOUT}/svn/hooks/pre-revprop-change" "$SVN_PARENT_PATH/.default/hooks/"

ln -sf "${VCS_CHECKOUT}/usr/local/etc/apache22/httpd.conf" /usr/local/etc/apache22/
replace "${VCS_CHECKOUT}/usr/local/etc/apache22/Includes/vcs.conf" /usr/local/etc/apache22/Includes/
# uncomment to enable SSL
#replace "${VCS_CHECKOUT}/usr/local/etc/apache22/Includes/ssl.conf" /usr/local/etc/apache22/Includes/
#mkdir -p /usr/local/etc/apache22/ssl


# viewvc
replace "${VCS_CHECKOUT}/usr/local/viewvc/viewvc.conf" /usr/local/viewvc/
ln -sf "${VCS_CHECKOUT}/viewvc/templates/include/header.ezt" /usr/local/viewvc/templates/include/
ln -sf "${VCS_CHECKOUT}/viewvc/templates/include/footer.ezt" /usr/local/viewvc/templates/include/
ln -sf "${VCS_CHECKOUT}/viewvc/templates/query.ezt" /usr/local/viewvc/templates/
ln -sf "${VCS_CHECKOUT}/viewvc/templates/docroot/help_log.html" /usr/local/viewvc/templates/docroot/
ln -sf "${VCS_CHECKOUT}/viewvc/templates/docroot/help_rootview.html" /usr/local/viewvc/templates/docroot/
ln -sf "${VCS_CHECKOUT}/viewvc/templates/docroot/help_dirview.html" /usr/local/viewvc/templates/docroot/
ln -sf "${VCS_CHECKOUT}/viewvc/templates/docroot/help_query.html" /usr/local/viewvc/templates/docroot/
ln -sf "${VCS_CHECKOUT}/viewvc/templates/docroot/of.js" /usr/local/viewvc/templates/docroot/

# crontab
replace "${VCS_CHECKOUT}/etc/crontab" /etc/
# log rotate
ln -sf "${VCS_CHECKOUT}/etc/newsyslog.conf" /etc/

# start
/usr/local/etc/rc.d/apache22 restart
/etc/rc.d/sshd restart
