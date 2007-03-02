#!/bin/sh

sympa_co=/usr/local/checkout/trunk/services/sympa

mysubst()
{
	env INSTALLDIR= INSTALLNAME=$2 `cat $sympa_co/openfoundry/subst.env` perl $sympa_co/source/subst.pl $1
}

mysubst $sympa_co/source/wwsympa/wwsympa.fcgi /usr/local/sympa/cgi-bin/wwsympa.fcgi
