#!/bin/sh

sympa_co=/usr/local/checkout/trunk/services/sympa

mysubst()
{
	env INSTALLDIR= INSTALLNAME=$2 UMASK=$3 `cat $sympa_co/openfoundry/subst.env` perl $sympa_co/source/subst.pl $1
}

readsecret()
{
	eval VAR_IS_DEFINED=\${$1+XXX}
	if [ -z $VAR_IS_DEFINED ]; then
	        echo "$1 = ?"
		stty_orig=`stty -g`
		stty -echo
		read $1
		stty $stty_orig
		export $1
	fi
}

readsecret SYMPA_DB_PASSWD
# workaround ...
readsecret FOUNDRY_DUMP_SECRET

mysubst $sympa_co/source/wwsympa/wwsympa.fcgi /usr/local/sympa/cgi-bin/wwsympa.fcgi 0755
mysubst $sympa_co/openfoundry/usr/local/etc/sympa/sympa.conf /usr/local/etc/sympa/sympa.conf 0644
mysubst $sympa_co/source/src/Conf.pm /usr/local/lib/sympa/Conf.pm 0644
mysubst $sympa_co/source/src/Language.pm /usr/local/lib/sympa/Language.pm 0644
mysubst $sympa_co/openfoundry/usr/local/share/sympa/data_sources/openfoundry.incl /usr/local/share/sympa/data_sources/openfoundry.incl 0644
mysubst $sympa_co/source/src/sympa.pl /usr/local/sbin/sympa.pl 0755
mysubst $sympa_co/openfoundry/root/.my.cnf /root/.my.cnf 0600

# workaround ...
mysubst /usr/local/checkout/trunk/openfoundry/OpenFoundry.pm /usr/local/lib/perl5/site_perl/5.8.8/OpenFoundry.pm 0644
