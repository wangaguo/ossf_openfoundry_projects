# Language.pm - This module does just the initial setup for the international messages
# RCS Identication ; $Revision: 1.58.2.2 $ ; $Date: 2006/06/08 12:53:26 $ 
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997, 1998, 1999, 2000, 2001 Comite Reseau des Universites
# Copyright (c) 1997,1998, 1999 Institut Pasteur & Christophe Wolfhugel
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

package Language;

require Exporter;
use Carp;
@ISA = qw(Exporter);
@EXPORT = qw(&gettext);

use strict;
use Log;
use Version;
use POSIX qw (setlocale);
use Locale::Messages qw (:locale_h :libintl_h !gettext);

BEGIN {
    ## Using the Pure Perl implementation of gettext
    ## This is required on Solaris : native implementation of gettext does not map ll_CC with ll
    Locale::Messages->select_package ('gettext_pp');
}

my %msghash;     # Hash organization is like Messages file: File>>Sections>>Messages
my %set_comment; #sets-of-messages comment   

## The lang is the NLS catalogue name ; locale is the locale preference
## Ex: lang = fr ; locale = fr_FR
my ($current_lang, $current_locale, @previous_locale);
my $default_lang;
## This was the old style locale naming, used for templates, nls, scenario
my %language_equiv = ( 'zh_CN' => 'cn',
		       'zh_TW' => 'tw',
		       'cs'    => 'cz',
		       'en_US' => 'us',
		       );

## Supported languages are defined by 'supported_lang' sympa.conf parameter

my %lang2locale = ('cz' => 'cs_CZ',
		   'de' => 'de_DE',
		   'us' => 'en_US',
		   'el' => 'el_GR',
		   'es' => 'es_ES',
		   'et' => 'et_EE',
		   'fi' => 'fi_FI',
		   'fr' => 'fr_FR',
		   'hu' => 'hu_HU',
		   'it' => 'it_IT',
		   'ja' => 'ja_JP',
		   'nb' => 'nb_NO',
		   'nl' => 'nl_NL',
		   'oc' => 'oc_FR',
		   'pl' => 'pl_PL',
		   'pt' => 'pt_PT',
		   'ro' => 'ro_RO',
		   'sv' => 'sv_SE',
		   'cn' => 'zh_CN',
		   'cs' => 'cs_CZ',
		   'tr' => 'tr_TR',
		   'tw' => 'zh_TW');

## Used to perform setlocale on FreeBSD / Solaris
my %locale2charset = ('cs_CZ' => 'utf-8',
		      'de_DE' => 'iso8859-1',
		      'el_GR' => 'utf-8',
		      'en_US' => 'utf-8',
		      'es_ES' => 'iso8859-1',
		      'et_EE' => 'iso8859-4',
		      'fi_FI' => 'iso8859-1',
		      'fr_FR' => 'iso8859-1',
		      'hu_HU' => 'iso8859-2',
		      'it_IT' => 'iso8859-1',
		      'ja_JP' => 'utf-8',
		      'nb_NO' => 'utf-8',
		      'nl_NL' => 'iso8859-1',
		      'oc_FR' => 'iso8859-1',		      
		      'pl_PL' => 'iso8859-2',
		      'pt_BR' => 'utf-8',
		      'pt_PT' => 'iso8859-1',
		      'ro_RO' => 'iso8859-2',
		      'sv_SE' => 'utf-8',
		      'tr_TR' => 'utf-8',
		      'zh_CN' => 'utf-8',
		      'zh_TW' => 'big5',
		      );

my $recode;

sub GetSupportedLanguages {
    my $robot = shift;
    my @lang_list;
    
    foreach my $l (split /,/,&Conf::get_robot_conf($robot, 'supported_lang')) {
	push @lang_list, $lang2locale{$l}||$l;
    }
    return \@lang_list;
}

## Keep the previous lang ; can be restored with PopLang
sub PushLang {
    my $locale = shift;
    &do_log('debug', 'Language::PushLang(%s)', $locale);

    push @previous_locale, $current_locale;
    &SetLang($locale);

    return 1;
}

sub PopLang {
    &do_log('debug', 'Language::PopLang(%s)');

    my $locale = pop @previous_locale;
    &SetLang($locale);

    return 1;
}

sub SetLang {
###########
    my $locale = shift;
    &do_log('debug2', 'Language::SetLang(%s)', $locale);

    my $lang = $locale;

    unless ($lang) {
	&do_log('err','Language::SetLang(), missing locale parameter');
	return undef;
    }

    if (length($lang) == 2) {
	$locale = $lang2locale{$lang};
    }else {
	## uppercase the country part if needed
	my @items = split /_/, $locale;
	$items[1] = uc($items[1]);
	$locale = join '_', @items;

	## Get the NLS equivalent for the lang
	$lang = &Locale2Lang($locale);
    }
   
    ## Set Locale::Messages context
    my $locale_dashless = $locale.'.'.$locale2charset{$locale}; 
    $locale_dashless =~ s/-//g;
    foreach my $type (&POSIX::LC_ALL, &POSIX::LC_TIME) {
	my $success;
	foreach my $try ($locale.'.'.$locale2charset{$locale},
			 $locale.'.'.uc($locale2charset{$locale}),  ## UpperCase required for FreeBSD
			 $locale_dashless, ## Required on HPUX
			 $locale,
			 $lang
			 ) {
	    if (&setlocale($type, $try)) {
		$success = 1;
		last;
	    }	
	}
	unless ($success) {
	    &do_log('err','Failed to setlocale(%s) ; you either have a problem with the catalogue .mo files or you should extend available locales in  your /etc/locale.gen (or /etc/sysconfig/i18n) file', $locale);
	    return undef;
	}
    }
    
    ## Define what catalog is used
    &Locale::Messages::textdomain("sympa");
    &Locale::Messages::bindtextdomain('sympa','--LOCALEDIR--');
    &Locale::Messages::bind_textdomain_codeset('sympa',$recode) if $recode;
    #bind_textdomain_codeset sympa => 'iso-8859-1';

    $current_lang = $lang;
    $current_locale = $locale;

    return $locale;
}#SetLang

sub set_recode {
    $recode = shift;
}

sub GetLang {
############

    return $current_lang;
}

sub Locale2Lang {
    my $locale = shift;
    my $lang;

    if (defined $language_equiv{$locale}) {
	$lang = $language_equiv{$locale};
    }else {
	## remove the country part 
	$lang = $locale;
	$lang =~ s/_\w{2}$//;
    }

    return $lang;
}

sub Lang2Locale {
    my $lang = shift;

    return $lang2locale{$lang} || $lang;
}

sub maketext {
    my $msg = shift;

#    &do_log('notice','Maketext: %s', $msg);

    my $translation = &gettext ($msg);

    ## replace parameters in string
    $translation =~ s/\%\%/'_ESCAPED_'.'%_'/eg; ## First escape '%%'
    $translation =~ s/\%(\d+)/$_[$1-1]/eg;
    $translation =~ s/_ESCAPED_%\_/'%'/eg; ## Unescape '%%'

    return $translation;
}

sub gettext {
    &do_log('debug3', 'Language::gettext(%s)', $_[0]);

    ## This prevents meta information to be returned if the string to translate is empty
    if ($_[0] eq '') {
	return '';
	
	## return meta information on the catalogue (language, charset, encoding,...)
    }elsif ($_[0] =~ '^_(\w+)_$') {
	my $var = $1;
	foreach (split /\n/,&Locale::Messages::gettext('')) {
	    if ($var eq 'language') {
		if (/^Language-Team:\s*(.+)$/i) {
		    my $language = $1;
		    $language =~ s/\<\S+\>//;
		    return $language;
		}
	    }elsif ($var eq 'charset') {
		if ($recode) {
		    return $recode;
		} elsif (/^Content-Type:\s*.*charset=(\S+)$/i) {
		    return $1;
		}
	    }elsif ($var eq 'encoding') {
		if (/^Content-Transfer-Encoding:\s*(.+)$/i) {
		    return $1;
		}
	    }
	}
	return '';
    }

    &Locale::Messages::gettext(@_);
}

1;

