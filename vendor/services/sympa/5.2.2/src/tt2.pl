# $Id: tt2.pl,v 1.24 2006/01/31 10:08:23 olivier.salaun Exp $
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

# TT2 adapter for sympa's template system - Chia-liang Kao <clkao@clkao.org>
# usage: replace require 'parser.pl' in wwwsympa and other .pl

package Sympa::Template::Compat;

use strict;
use base 'Template::Provider';

my @other_include_path;
my $allow_absolute;

sub _load {
	my ($self, $name, $alias) = @_;
	my ($data, $error) = $self->SUPER::_load($name, $alias);
	$data->{text} = _translate($data->{text});

=comment

	my $newname = $name;
	$newname =~ s|(.*)/([^/]+)$|$2|;

	open my $fh, ">/tmp/tt2/$newname";
	print $fh $data->{text};
	close $fh;

=cut

	return ($data, $error);
}

sub _translate {
    local $_ = join('', @_);

    # if / endif
    s/\[\s*(ELSIF|IF)\s+(.*?)\s*=\s*(.*?)\s*\]/[% \U$1\E $2 == '$3' %]/ig;
    s/\[\s*(ELSIF|IF)\s+(.*?)\s*<>\s*(.*?)\s*\]/[% \U$1\E $2 != '$3' %]/ig;
    s/\[\s*(ELSIF|IF)\s+(.*?)\s*\]/[% \U$1\E $2 %]/ig;
    s/\[\s*ELSE\s*\]/[% ELSE %]/ig;
    s/\[\s*ENDIF\s*\]/[% END %]/ig;

    # parse -> process
    s/\[\s*PARSE\s*('.*?')\s*\]/[% PROCESS $1 %]/ig;
    s/\[\s*PARSE\s*(.*?)\]/[% PROCESS \$$1 IF $1 %]/ig;

    # variable access
    while(s/\[(.*?)([^\]-]+?)->(\d+)(.*)\]/[$1$2.item('$3')$4]/g){};
    while(s/\[(.*?)([^\]-]+?)->(\w+)(.*)\]/[$1$2.$3$4]/g){};
    s/\[\s*SET\s+(\w+)=(.*?)\s*\]/[% SET $1 = $2 %]/ig;

    # foreach
    s/\[\s*FOREACH\s*(\w+)\s*IN\s*([\w.()\'\/]+)\s*\]/[% FOREACH $1 = $2 %]
    [% SET tmp = $1.key $1 = $1.value $1.NAME = tmp IF $1.key.defined %]/ig;
    s/\[\s*END\s*\]/[% END %]/ig;

    # sanity check before including file
    s/\[\s*INCLUDE\s*('.*?')\s*\]/[% INSERT $1 %]/ig;
    s/\[\s*INCLUDE\s*(\w+?)\s*\]/[% INSERT \$$1 IF $1 %]/ig;

    ## Be careful to absolute path
    if (/\[%\s*(PROCESS|INSERT)\s*\'(\S+)\'\s*%\]/) {
	my $file = $2;
	my $new_file = $file;
	$new_file =~ s/\.tpl$/\.tt2/;
	my @path = split /\//, $new_file;
	$new_file = $path[$#path];
	s/\'$file\'/\'$new_file\'/;
    }

    # setoption
    s/\[\s*SETOPTION\s(escape_)?html.*?\]/[% FILTER html_entity %]/ig;
    s/\[\s*SETOPTION\signore_undef.*?\]/[% IF 1 %]/ig;
    s/\[\s*UNSETOPTION.*?\]/[% END %]/ig;

    s/\[\s*([\w.()\'\/]+)\s*\]/[% $1 %]/g;

    s/\[\s*(STOP|START)PARSE\s*\]//ig;

    $_;
}

1;

package tt2;

use strict;
use Template;
use CGI::Util;
use Log;
use Language;

my $current_lang;
my $last_error;

sub qencode {
    my $string = shift;
    
    my $encoded_string = MIME::Words::encode_mimewords($string, ('Encode' => 'Q', 'Charset' => gettext("_charset_")));
    $encoded_string =~ s/\?=\s+=\?/_\?= =?/g; ## Fix bug 5462 of MIME::Words

    return $encoded_string;
}

sub escape_url {

    my $string = shift;
    
    $string =~ s/ /%20/g;
    
    return $string;
}

sub escape_xml {
    my $string = shift;
    
    $string =~ s/&/&amp;/g; 
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/\'/&apos;/g;
    $string =~ s/\"/&quot;/g;
    
    return $string;
}

sub escape_quote {
    my $string = shift;

    $string =~ s/\'/\\\'/g; 
    $string =~ s/\"/\\\"/g;

    return $string;
}

sub maketext {
    my ($context, @arg) = @_;

    return sub {
	&Language::maketext($_[0], @arg);
    }	
}

## To add a directory to the TT2 include_path
sub add_include_path {
    my $path = shift;

    push @other_include_path, $path;
}

## Get current INCLUDE_PATH
sub get_include_path {
    return @other_include_path;
}

## Allow inclusion/insertion of file with absolute path
sub allow_absolute_path {
    $allow_absolute = 1;
}

## Return the last error message
sub get_error {

    return $last_error;
}

## The main parsing sub
## Parameters are   
## data: a HASH ref containing the data   
## template : a filename or a ARRAY ref that contains the template   
## output : a Filedescriptor or a SCALAR ref for the output

sub parse_tt2 {
    my ($data, $template, $output, $include_path, $options) = @_;
    $include_path ||= ['--ETCBINDIR--'];

    ## Add directories that may have been added
    push @{$include_path}, @other_include_path;
    @other_include_path = (); ## Reset it

    my $wantarray;

    ## An array can be used as a template (instead of a filename)
    if (ref($template) eq 'ARRAY') {
	$template = \join('', @$template);
    }

    # Do we need to recode strings
    # maketext will check the $recode variable
    if (defined $options &&
	$options->{'recode'}) {
	&Language::set_recode( $options->{'recode'});
    }

    # quick hack! wrong layer!
#    s|^/home/sympa/bin/etc/wws_templates/(.*?)(\...)?(\.tpl)|$1.tt2|
#	for values %$data;

#    &do_log('notice', 'TPL: %s ; LANG: %s', $template, $data->{lang});

    &Language::SetLang($data->{lang}) if ($data->{'lang'});

    my $config = {
	# ABSOLUTE => 1,
	INCLUDE_PATH => $include_path,
#	PRE_CHOMP  => 1,
	
	FILTERS => {
	    unescape => \&CGI::Util::unescape,
	    l => [\&tt2::maketext, 1],
	    loc => [\&tt2::maketext, 1],
	    qencode => [\&qencode, 0],
 	    escape_xml => [\&escape_xml, 0],
	    escape_url => [\&escape_url, 0],
	    escape_quote => [\&escape_quote, 0],
	    }
    };
    
    if ($allow_absolute) {
	$config->{'ABSOLUTE'} = 1;
	$allow_absolute = 0;
    }

    my $tt2 = Template->new($config) or die $!;

    unless ($tt2->process($template, $data, $output)) {
	$last_error = $tt2->error();
	&do_log('err', 'Failed to parse %s : %s', $template, $tt2->error());
	&do_log('err', 'Looking for TT2 files in %s', join(',',@{$include_path}));

	# Reset $recode
	&Language::set_recode();

	return undef;
    } 

    # Reset $recode
    &Language::set_recode();

    return 1;
}


1;
