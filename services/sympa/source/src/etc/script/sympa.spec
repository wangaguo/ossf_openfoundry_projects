%define name sympa
%define version --VERSION--
%define release 8--SUFFIX--
%define home_s --HOMEDIR--
%define data_s --DATADIR--
%define conf_s --CONFDIR--
%define etc_s --ETCDIR--
%define spoo_s --SPOOLDIR--

Summary:  Sympa is a powerful multilingual List Manager - LDAP and SQL features.
Summary(fr): Sympa est un gestionnaire de listes électroniques. 
Name:  %{name}
Version:  %{version}
Release:  %{release}
Copyright:  GPL
Group: --APPGROUP--
Source:  http://www.sympa.org/distribution/%{name}-%{version}.tar.--ZIPEXT--
URL: http://www.sympa.org/
Requires: --MTA--
Requires: perl >= 0:5.005
Requires: perl-MailTools >= 1.14
Requires: perl-MIME-Base64   >= 1.0
Requires: perl-IO-stringy    >= 1.0
Requires: perl-MIME-tools    >= 5.209
Requires: perl-CGI    >= 2.52
Requires: perl-DBI    >= 1.06
Requires: perl-DB_File    >= 1.73
Requires: perl-ldap >= 0.10
Requires: perl-CipherSaber >= 0.50
## Also requires a DBD for the DBMS : we choose MySQL 
## (perl-DBD-Pg or Perl- Msql-Mysql-modules)
Requires: MySQL
Requires: perl-Mysql
Requires: perl-FCGI    >= 0.48
Requires: perl-Digest-MD5
Requires: perl-Convert-ASN1
Requires: perl-HTML-Parser
Requires: perl-HTML-Tagset
Requires: perl-IO-Socket-SSL
Requires: perl-Net_SSLeay
Requires: perl-URI
Requires: perl-libwww-perl
Requires: MHonArc >= 2.4.6
Requires: webserver
Requires: openssl >= 0.9.5a
Prereq: /usr/sbin/useradd
Prereq: /usr/sbin/groupadd
BuildRoot: %{_tmppath}/%{name}-%{version}
#BuildRequires: openssl-devel >= 0.9.5a
Prefix: %{_prefix}

%description
Sympa is scalable and highly customizable mailing list manager. It can cope with big lists
(200,000 subscribers) and comes with a complete (user and admin) Web interface. It is
internationalized, and supports the us, fr, de, es, it, fi, and chinese locales. A scripting
language allows you to extend the behavior of commands. Sympa can be linked to an
LDAP directory or an RDBMS to create dynamic mailing lists. Sympa provides
S/MIME-based authentication and encryption.

Documentation is available under HTML and Latex (source) formats. 


%prep
rm -rf $RPM_BUILD_ROOT

%setup -q

%build

./configure \
--prefix=--HOMEDIR-- \
--with-confdir=--CONFDIR-- \
--with-etcdir=--ETCDIR-- \
--with-cgidir=--CGIDIR-- \
--with-iconsdir=--ICONSDIR-- \
--with-bindir=--BINDIR-- \
--with-sbindir=--SBINDIR-- \
--with-mandir=%{_mandir} \
--with-libexecdir=--SCRIPTDIR-- \
--with-libdir=--LIBDIR-- \
--with-datadir=--DATADIR-- \
--with-expldir=--EXPLDIR-- \
--with-piddir=--PIDDIR-- \
--with-localedir=--LOCALEDIR-- \
--with-scriptdir=--SCRIPTDIR-- \
--with-sampledir=--SAMPLEDIR-- \
--with-spooldir=--SPOOLDIR-- \
;make sources 

%install
rm -rf $RPM_BUILD_ROOT

make HOST=MYHOST DESTDIR=$RPM_BUILD_ROOT install

# Create bounce and archive directories
for dir in bounce wwsarchives wwsbounce ; do
  if [ ! -d $RPM_BUILD_ROOT%{spoo_s}/$dir ] ; then
    mkdir -p $RPM_BUILD_ROOT%{spoo_s}/$dir
    chown sympa $RPM_BUILD_ROOT%{spoo_s}/$dir
    chgrp sympa $RPM_BUILD_ROOT%{spoo_s}/$dir
    chmod 770 $RPM_BUILD_ROOT%{spoo_s}/$dir
  fi
done

%pre

# Create "sympa" group if it is not already there
if ! grep -q "^sympa:" /etc/group; then
  echo "Adding system group: sympa."
  /usr/sbin/groupadd sympa
fi
 
# Add "apache" in group "sympa" so that it could access
# /etc/sympa/wwsympa.conf and therefore a working wwsympa ;-)
if ! grep -q "^sympa:.*\<apache\>" /etc/group; then
  echo "Adding apache in group sympa."
  comma="";
  [ -n "$(grep '^sympa:' /etc/group | sed -e 's/^sympa:.*:.*://')" ] && comma=",";
  perl -pi -e "s/^(sympa:.*)/\1${comma}apache/" /etc/group
fi
 
# Create "sympa" user if it is not already there
home_s_pw=`sed -n -e "/^sympa:[^:]*:[^:]*:[^:]*:[^:]*:\([^:]*\):.*/s//\1/p" /etc/passwd`
if [ -z "$home_s_pw" ]; then
  echo "Adding system user: sympa."
  /usr/sbin/useradd -m -g sympa -d %{home_s} sympa -c "Sympa mailing-list manager" -s "/bin/bash"
elif [ "$home_s_pw" != "%{home_s}" ]; then
  echo "Problem: user \"sympa\" already exists with a home different from %{home_s}"
  exit 0
fi

%post
 
## Setting Runlevels
for I in 0 1 2 6; do
        mkdir -p $RPM_BUILD_ROOT/etc/rc.d/rc$I.d
        ln -s $RPM_BUILD_ROOT--INITDIR--/%{name} $RPM_BUILD_ROOT/etc/rc.d/rc$I.d/K25%{name}
done
for I in 3 5; do
        mkdir -p $RPM_BUILD_ROOT/etc/rc.d/rc$I.d
        ln -s $RPM_BUILD_ROOT--INITDIR--/%{name} $RPM_BUILD_ROOT/etc/rc.d/rc$I.d/S95%{name}
done

if [ -e "/var/log/sympa" ] && [ ! -f "/var/log/sympa" ]; then
  echo "Problem: /var/log/sympa already exists but it is not a file!"
fi
touch /var/log/sympa || /bin/true
chown sympa.sympa /var/log/sympa
chmod 0640 /var/log/sympa
 
# Setup log facility for Sympa
if [ -f /etc/syslog.conf ] ;then
  if [ `grep -c sympa /etc/syslog.conf` -eq 0 ] ;then
    typeset -i cntlog
    cntlog=0
    while [ `grep -c local${cntlog} /etc/syslog.conf` -gt 0 ];do cntlog=${cntlog}+1;done
    if [ ${cntlog} -le 9 ];then
      echo "# added by %{name}-%{version} rpm $(date)" >> /etc/syslog.conf
      echo "local${cntlog}.*       -/var/log/%{name}" >> /etc/syslog.conf
    fi
    perl -pi -e "s|^\*\.info;|\*\.info;local${cntlog}.none;|" /etc/syslog.conf

    # Fix syslog variable for the correct subsystem to use in config files
    # cntlog=`sed -n -e "/^local.*sympa/s|^local\([0-9][0-9]*\)\.\*[ \t]*/var/log/sympa|\1|p" < /etc/syslog.conf`
    for conffile in %{conf_s}/sympa.conf; do
      perl -pi -e "s|syslog(\s+)LOCAL[0-9]+|syslog\1LOCAL${cntlog}|" $conffile
    done
  fi
fi
 

# rotate log for sympa
# a inclure dans les fichiers...
if [ -d /etc/logrotate.d ] ;then
  if [ ! -f /etc/logrotate.d/sympa ] ;then
    echo "/var/log/sympa {" > /etc/logrotate.d/sympa
    echo "    missingok" >> /etc/logrotate.d/sympa
    echo "    notifempty" >> /etc/logrotate.d/sympa
    echo "    copytruncate" >> /etc/logrotate.d/sympa
    echo "    rotate 10" >> /etc/logrotate.d/sympa
    echo "}" >> /etc/logrotate.d/sympa
  fi
fi

#the directory where sendmail can call queue and bouncequeue
bin_queue=--BINDIR--

# eventually, add queue and bouncequeue to sendmail security shell
if [ -d /etc/smrsh ]; then
  bin_queue=/etc/smrsh
  if [ ! -e /etc/smrsh/queue ]; then
    ln -s --BINDIR--/queue /etc/smrsh/queue
  fi
 
  if [ ! -e /etc/smrsh/bouncequeue ]; then
    ln -s --BINDIR--/bouncequeue /etc/smrsh/bouncequeue
  fi
fi

# Try to add some sample entries in /etc/aliases for sympa
for a_file in /etc/aliases /etc/postfix/aliases; do
  if [ -f ${a_file} ]; then
    if [ `grep -c sympa ${a_file}` -eq 0 ]; then
      cp -f ${a_file} ${a_file}.rpmorig
      echo >> ${a_file}
      echo "# added by %{name}-%{version} rpm " $(date) >> ${a_file}
      if [ `grep -c listmaster ${a_file}` -eq 0 ]; then
	echo "# listmaster: \"|${bin_queue}/queue listmaster\"" >> ${a_file}
      fi
      echo "# sympa: \"|${bin_queue}/queue sympa\"" >> ${a_file}
      echo "# bounce+*: \"|${bin_queue}/bouncequeue sympa\"" >> ${a_file}
      echo "# sympa-request:  listmaster@${HOSTNAME}" >> ${a_file}
      echo "# sympa-owner:    listmaster@${HOSTNAME}" >> ${a_file}
      echo "" >> ${a_file}
      # (gb) The user have to manually comment out the new aliases
      # and then invoke: /usr/bin/newaliases
      echo "Your new aliases have been set up in ${a_file}. Please check them out before running /usr/bin/newaliases"
      echo "You must configure your MTA (sendmail, postfix,...) for using a second aliases file, the one modified by sympa for his lists : /etc/mail/sympa_aliases"
      echo "Refer to INSTALL file for more setup information..."
    fi
  fi
done

# create the alias file used by sympa for his lists
if [ ! -f "/etc/mail/sympa_aliases" ]; then
  if [ ! -d "/etc/mail" ]; then
    mkdir -p /etc/mail
  fi
  touch /etc/mail/sympa_aliases || /bin/true
  chown sympa.sympa /etc/mail/sympa_aliases
  chmod 0640 /etc/mail/sympa_aliases
fi

# reset the default cookie
typeset -x secret
secret=`perl -e "print int(rand(time))"`
perl -pi -e "s|'cookie',\n|'cookie',|" --SBINDIR--/sympa_wizard.pl
perl -pi -e "s|'cookie',.*\n|'cookie', 'default' => '${secret}',\n|" --SBINDIR--/sympa_wizard.pl


%postun

## user
if [ ! -d %{home_s} ]; then
  /usr/sbin/userdel sympa
  /usr/sbin/groupdel sympa  
fi

## links in /etc/smrsh
if [ $1 = 0 -a -d /etc/smrsh ]; then
  if [ -L /etc/smrsh/queue ]; then
    rm -f /etc/smrsh/queue
  fi
  if [ -L /etc/smrsh/bouncequeue ]; then
    rm -f /etc/smrsh/bouncequeue
  fi

fi

## links in runlevels
for I in 0 1 2 6; do
  if [ -L $RPM_BUILD_ROOT/etc/rc.d/rc$I.d/K25%{name} ]; then
    rm -f $RPM_BUILD_ROOT/etc/rc.d/rc$I.d/K25%{name}
  fi
done
for I in 3 5; do
  if [ -L $RPM_BUILD_ROOT/etc/rc.d/rc$I.d/S95%{name} ]; then
    rm -f $RPM_BUILD_ROOT/etc/rc.d/rc$I.d/S95%{name}
  fi
done

%files

%defattr(-,sympa,sympa)

# Home directory
%dir %{home_s}

# Where to store the data & config files of the lists
%dir --EXPLDIR--
 
# Documentation
%doc %attr(-,root,root) INSTALL README AUTHORS COPYING NEWS ChangeLog
%doc %attr(-,root,root) doc/sympa.tex doc/sympa.ps doc/sympa.pdf
%doc %attr(-,root,root) --DOCDIR--/*
%attr(-,root,root) %{_mandir}/man8/*
 
# Spools
%dir %{spoo_s}
%dir %{spoo_s}/msg
%dir %{spoo_s}/bounce
#%dir %{spoo_s}/wwsarchives
#%dir %{spoo_s}/wwsbounce
%dir %{spoo_s}/digest
%dir %{spoo_s}/moderation
%dir %{spoo_s}/expire
%dir %{spoo_s}/auth
%dir %{spoo_s}/outgoing
%dir %{spoo_s}/tmp
%dir %{spoo_s}/task
 
 
# Config file
#%dir %{conf_s}
%config(noreplace) %attr(0640,sympa,sympa) %{conf_s}/sympa.conf
%config(noreplace) %attr(0640,sympa,sympa) %{conf_s}/wwsympa.conf
 
# Config directories populated by the user
%dir %{etc_s}/create_list_templates
%dir %{etc_s}/scenari
%dir %{etc_s}/mail_tt2
%dir %{etc_s}/web_tt2
%dir %{etc_s}/general_task_models
%dir %{etc_s}/task_models
 
# Binaries
# We use a configure where BINDIR = SBINDIR = LIBDIR = LIBEXECDIR
# aliaswrapper is owned by root, don't change it
%attr(-,-,-) --BINDIR--/*
%attr(-,-,-) --SBINDIR--/*
%attr(-,-,-) --LIBDIR--/*
%attr(-,-,-) --LIBEXECDIR--/*

# Locales
#%dir --LOCALEDIR--
--LOCALEDIR--/

# ATTENTION A VOIR %{_libdir}/sympa/locale/*.po
 
# Data
%{data_s}/
#%dir %{data_s}
#%{data_s}/ca-bundle.crt
#%{data_s}/create_list.conf
#%{data_s}/edit_list.conf
#%{data_s}/mhonarc-ressources
#%{data_s}/list_aliases.tt2
#%dir %{data_s}/create_list_templates
#%{data_s}/create_list_templates/*
#%dir %{data_s}/scenari
#%{data_s}/scenari/*
#%dir %{data_s}/tt2s
#%{data_s}/tt2/*
#%dir %{data_s}/web_tt2
#%{data_s}/web_tt2/*
#%dir %{data_s}/list_task_models
#%{data_s}/list_task_models/*
#%dir %{data_s}/global_task_models
#%{data_s}/global_task_models/*
 
# Icons and binaries for Apache
--CGIDIR--/wwsympa.fcgi
--CGIDIR--/sympa_soap_server.fcgi
--ICONSDIR--/
 
# Init scripts
%config(noreplace) %attr(0755,root,root) --INITDIR--/sympa

# Examples
#%dir --SAMPLEDIR--
#--SAMPLEDIR--/


%clean
rm -rf $RPM_BUILD_ROOT

%changelog

* Mon Feb 17 2003 Guy Paressant - Academie de Nantes - <rpm-sympa@ac-nantes.fr> 3.4.3.1-8
- Rebuilt for 3.4.3.1
- Adding doc and sample
- Fix spool directories and create bounce and archive

* Fri Jan 31 2003 Guy Paressant - Academie de Nantes - <rpm-sympa@ac-nantes.fr> 3.4.2-7.3
- reset of the default cookie in sympa_wizard.pl
- keep owner for binaries (user root for aliaswrapper)
- set /bin/bash as shell for user sympa

* Tue Dec 31 2002 Guy PARESSANT - Academie de Nantes - <rpm-sympa@ac-nantes.fr> 3.4.2-7.2
- corrections for runlevels + remove in %postun

* Tue Dec 24 2002 Guy PARESSANT - Academie de Nantes - <rpm-sympa@ac-nantes.fr> 3.4.2-7.1
- Rebuild for sympa 3.4.2
- cleaning
- store the files on directories choosed by Mandrake
- the options used before building the rpm for Mandrake 9 :
./configure --prefix=/var/lib/sympa \
--with-confdir=/etc/sympa \
--with-etcdir=/etc/sympa \
--with-cgidir=/var/www/cgi-bin \
--with-iconsdir=/var/www/icons/sympa \
--with-bindir=/usr/lib/sympa/bin \
--with-sbindir=/usr/lib/sympa/bin \
--with-libexecdir=/usr/lib/sympa/bin \
--with-libdir=/usr/lib/sympa/bin \
--with-datadir=/usr/share/sympa \
--with-expldir=/var/lib/sympa/expl \
--with-mandir=/usr/share/man \
--with-piddir=/var/run/sympa \
--with-openssl=/usr/bin/openssl \
--with-localedir=/usr/lib/sympa/locale \
--with-scriptdir=/usr/lib/sympa/bin \
--with-sampledir=/usr/share/sympa/examples \
--with-spooldir=/var/spool/sympa

* Mon May 13 2002 Zenon Panoussis <oracle@xs4all.nl>
- Added check and aliases file and link for Courier
- Changed "Requires: apache" to "Requires: webserver" for compatibility 
  with apache2

* Wed Nov 15 2001 Olivier Salaun <olivier.salaun@cru.fr> 3.3b.3
- HOMEPAGE is /var/sympa/
- install binaries with SetUID in /etc/smrsh
- new lib/ sbin/ directories

* Wed Sep 26 2001 Olivier Salaun <olivier.salaun@cru.fr> 3.3a.vhost
- add bouncequeue-related
- add perl-Cipher-saber

* Thu Jun  5 2001 Olivier Salaun <olivier.salaun@cru.fr> 3.2
- perl-CGI.pm becomes perl-CGI

* Thu Feb  8 2001 Olivier Salaun <olivier.salaun@cru.fr> 3.1b.3
- Requires MHOnArc 2.4.6

* Tue Nov 21 2000 Olivier Salaun <olivier.salaun@cru.fr> 3.0b
- Requires perl-DB_File and perl-perl-ldap
- Set sympa user shell to /bin/false 
- Directories (etc expl spool) now created by sympa

* Wed Sep 06 2000 Olivier Salaun <olivier.salaun@cru.fr> 3.0a
- No more nls/ in docs
- generalize %{home_s}
- use DESTDIR
- changed the description ; french version abandoned
- sample conf files now installed by Makefile
- no more patches (Openssl, Mhonarc)
- set correct right in %files
- use $RPM_SOURCE_DIR
- install SYSV init script
- openssl-devel NOT required

* Wed Aug 30 2000 Geoffrey Lee <snailtalk@mandrakesoft.com> 2.7.3-5mdk
- requires apache because of wwsympa.
- buildrequires apache to fix building for machines without apache (sic).

* Fri Aug 18 2000 Geoffrey Lee <snailtalk@mandrakesoft.com> 2.7.3-4mdk
- rebuild to enable openssl.
- add requires and buildrequires for {openssl,openssl-devel}
- copy the wwsympa configuration file on postun if none is present in /etc.

* Thu Aug 17 2000 Geoffrey Lee <snailtalk@mandrakesoft.com> 2.7.3-3mdk
- rebuild to fix some more annoying bugs.

* Mon Aug 14 2000 Geoffrey Lee <snailtalk@mandrakesoft.com> 2.7.3-2mdk
- rebuild for sympa disaster

* Tue Aug 01 2000 Geoffrey Lee <snailtalk@mandrakesoft.com> 2.7.3-1mdk
- big shiny new version and got this ugly fucking piece of shit to package
- rebuild for BM

* Tue Apr 18 2000 Jerome Dumonteil <jd@mandrakesoft.com>
- change group
* Fri Mar 31 2000 Jerome Dumonteil <jd@mandrakesoft.com>
- change group
- modif postun
* Wed Dec 29 1999 Jerome Dumonteil <jd@mandrakesoft.com>
- version 2.4
* Fri Dec 17 1999 Jerome Dumonteil <jd@mandrakesoft.com>
- added link /etc/smrsh/queue
- added link for /home/sympa/expl/helpfile
* Thu Dec 09 1999 Jerome Dumonteil <jd@mandrakesoft.com>
- remove backup files from sources
- strip binary
* Mon Dec  6 1999 Jerome Dumonteil <jd@mandrakesoft.com>
- added prereq info.
- little cleanup.
* Fri Dec  3 1999 Jerome Dumonteil <jd@mandrakesoft.com>
- first version of rpm.

