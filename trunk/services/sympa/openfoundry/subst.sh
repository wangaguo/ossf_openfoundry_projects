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

mysubst $sympa_co/source/wwsympa/wwsympa.fcgi /usr/local/sympa/cgi-bin/wwsympa.fcgi 0755
mysubst $sympa_co/openfoundry/usr/local/etc/sympa/sympa.conf /usr/local/etc/sympa/sympa.conf 0644
