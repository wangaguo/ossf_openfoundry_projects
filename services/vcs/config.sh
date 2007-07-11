#!/bin/sh

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

openfoundry_etc=/usr/local/etc/openfoundry/

ln -sf /usr/local/checkout/trunk/services/vcs/etc/rc.conf /etc/

# OpenFoundry
ln -sf /usr/local/checkout/trunk/openfoundry/OpenFoundry.pm /usr/local/lib/perl5/site_perl/5.8.8/
ln -sf /usr/local/checkout/trunk/services/vcs/usr/local/etc/openfoundry.conf.dist "$openfoundry_etc/"
ln -sf /usr/local/checkout/trunk/services/vcs/usr/local/etc/openfoundry_root.conf.dist "$openfoundry_etc/"

# export conf to env
envs=`perl -MOpenFoundry -e '%conf = %{OpenFoundry::loadConf()}; while (($k, $v) = each %conf) { print "$k=\"$v\"; export $k\n"}'`
if [ "$?" = "0" ]; then
	eval $envs
else
	echo "Please check your config file"
	exit 1
fi

ln -sf /usr/local/checkout/trunk/services/vcs/usr/local/bin/openfoundry_sync_cache.sh /usr/local/bin/

# libnss-mysql
/usr/local/etc/rc.d/mysql-server restart
until /usr/local/etc/rc.d/mysql-server status | grep 'is running'; do echo 'waitiing for mysql..'; sleep 1; done
replace_out /usr/local/checkout/trunk/services/vcs/usr/local/etc/nss_database.sql | mysql
replace /usr/local/checkout/trunk/services/vcs/usr/local/etc/libnss-mysql.cfg /usr/local/etc/
replace /usr/local/checkout/trunk/services/vcs/usr/local/etc/libnss-mysql-root.cfg /usr/local/etc/ 0400
ln -sf /usr/local/checkout/trunk/services/vcs/etc/nsswitch.conf /etc/
ln -sf /usr/local/checkout/trunk/services/vcs/usr/local/bin/openfoundry_sync_nss.pl /usr/local/bin/

# cvs / svn
ln -sf /usr/local/checkout/trunk/services/vcs/usr/local/bin/cvs_svn_only.sh /usr/local/bin/
ln -sf /usr/local/checkout/trunk/services/vcs/usr/local/bin/openfoundry_sync_repos.pl /usr/local/bin/
ln -sf /usr/local/checkout/trunk/services/vcs/usr/local/bin/openfoundry_backup_repos.pl /usr/local/bin/

# cvs
mkdir -p "$CVSROOT"
cvs -d "$CVSROOT" init
# TODO: file permission?
chown -R $CVSOWNER:$CVSGROUP "$CVSROOT"
ln -sf /usr/local/checkout/trunk/services/vcs/cvs/CVSROOT/commitcheck.pl "$CVSROOT/CVSROOT/"
ln -sf /usr/local/checkout/trunk/services/vcs/cvs/CVSROOT/commitinfo "$CVSROOT/CVSROOT/"
ln -sf /usr/local/checkout/trunk/services/vcs/etc/ssh/sshd_config /etc/ssh/

# svn
mkdir $SVN_PARENT_PATH
mkdir -p "$SVN_PARENT_PATH/.default/hooks"
ln -sf /usr/local/checkout/trunk/services/vcs/svn/hooks/pre-commit "$SVN_PARENT_PATH/.default/hooks/"
ln -sf /usr/local/checkout/trunk/services/vcs/svn/hooks/pre-revprop-change "$SVN_PARENT_PATH/.default/hooks/"

ln -sf /usr/local/checkout/trunk/services/vcs/usr/local/etc/apache22/httpd.conf /usr/local/etc/apache22/
replace /usr/local/checkout/trunk/services/vcs/usr/local/etc/apache22/Includes/vcs.conf /usr/local/etc/apache22/Includes/
replace /usr/local/checkout/trunk/services/vcs/usr/local/etc/apache22/Includes/ssl.conf /usr/local/etc/apache22/Includes/
mkdir -p /usr/local/etc/apache22/ssl


# viewvc
replace /usr/local/checkout/trunk/services/vcs/usr/local/viewvc/viewvc.conf /usr/local/viewvc/
ln -sf /usr/local/checkout/trunk/services/vcs/viewvc/templates/include/header.ezt /usr/local/viewvc/templates/include/
ln -sf /usr/local/checkout/trunk/services/vcs/viewvc/templates/query.ezt /usr/local/viewvc/templates/
ln -sf /usr/local/checkout/trunk/services/vcs/viewvc/templates/docroot/help_log.html /usr/local/viewvc/templates/docroot/
ln -sf /usr/local/checkout/trunk/services/vcs/viewvc/templates/docroot/help_rootview.html /usr/local/viewvc/templates/docroot/
ln -sf /usr/local/checkout/trunk/services/vcs/viewvc/templates/docroot/help_dirview.html /usr/local/viewvc/templates/docroot/
ln -sf /usr/local/checkout/trunk/services/vcs/viewvc/templates/docroot/help_query.html /usr/local/viewvc/templates/docroot/
ln -sf /usr/local/checkout/trunk/services/vcs/viewvc/templates/docroot/of.js /usr/local/viewvc/templates/docroot/

# crontab
ln -sf /usr/local/checkout/trunk/services/vcs/etc/crontab /etc/

# start
/usr/local/etc/rc.d/apache22 restart
/etc/rc.d/sshd restart
