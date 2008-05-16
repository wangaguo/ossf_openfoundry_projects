# Conf.pm - This module does the sympa.conf and robot.conf parsing
# RCS Identication ; $Revision: 1.138.2.2 $ ; $Date: 2006/08/24 15:05:36 $ 
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

## This module handles the configuration file for Sympa.

package Conf;

use Log;
use Language;
use wwslib;
use CAS;

require Exporter;
use Carp;

@ISA = qw(Exporter);
@EXPORT = qw(%Conf);

my @valid_options = qw(
		       avg bounce_warn_rate bounce_halt_rate bounce_email_prefix chk_cert_expiration_task expire_bounce_task
		       cache_list_config
		       clean_delay_queue clean_delay_queueauth clean_delay_queuemod clean_delay_queuesubscribe clean_delay_queuetopic default_remind_task
		       cookie cookie_cas_expire create_list crl_dir crl_update_task db_host db_env db_name db_timeout
		       db_options db_passwd db_type db_user db_port db_additional_subscriber_fields db_additional_user_fields
		       default_shared_quota default_archive_quota default_list_priority distribution_mode edit_list email etc
		       global_remind home host domain lang listmaster listmaster_email localedir log_socket_type log_level 
		       logo_html_definition misaddressed_commands misaddressed_commands_regexp max_size maxsmtp nrcpt 
		       owner_priority pidfile pidfile_distribute
		       spool queue queuedistribute queueauth queuetask queuebounce queuedigest 
		       queuemod queuetopic queuesubscribe queueoutgoing tmpdir
		       loop_command_max loop_command_sampling_delay loop_command_decrease_factor loop_prevention_regex
		       purge_user_table_task  purge_orphan_bounces_task eval_bouncers_task process_bouncers_task
		       minimum_bouncing_count minimum_bouncing_period bounce_delay 
		       default_bounce_level1_rate default_bounce_level2_rate 
		       remind_return_path request_priority return_path_suffix rfc2369_header_fields sendmail sendmail_args sleep 
		       sort sympa_priority supported_lang syslog log_smtp umask verp_rate welcome_return_path wwsympa_url
                       openssl capath cafile  key_passwd ssl_cert_dir remove_headers
		       antivirus_path antivirus_args antivirus_notify anonymous_header_fields sendmail_aliases
		       dark_color light_color text_color bg_color error_color selected_color shaded_color
		       color_0 color_1 color_2 color_3 color_4 color_5 color_6 color_7 color_8 color_9 color_10 color_11 color_12 color_13 color_14 color_15
 		       css_url css_path
		       ldap_export_name ldap_export_host ldap_export_suffix ldap_export_password
		       ldap_export_dnmanager ldap_export_connection_timeout update_db_field_types urlize_min_size
		       list_check_smtp list_check_suffixes  spam_protection web_archive_spam_protection soap_url
		       web_recode_to
);

my %old_options = ('trusted_ca_options' => 'capath,cafile',
		   'msgcat' => 'localedir',
		   'queueexpire' => '');

my %valid_options = ();
map { $valid_options{$_}++; } @valid_options;

my %Default_Conf = 
    ('home'    => '--EXPL_DIR--',
     'etc'     => '--ETCDIR--',
     'key_passwd' => '',
     'ssl_cert_dir' => '--EXPL_DIR--/X509-user-certs',
     'crl_dir' => '--EXPL_DIR--/crl',
     'umask'   => '027',
     'syslog'  => 'LOCAL1',
     'log_level'  => 0,
     'nrcpt'   => 25,
     'avg'     => 10,
     'maxsmtp' => 20,
     'sendmail'=> '/usr/sbin/sendmail',
     'sendmail_args' => '-oi -odi -oem',
     'sendmail_aliases' => '--SENDMAIL_ALIASES--',
     'openssl' => '',
     'host'    => undef,
     'domain'  => undef,
     'email'   => 'sympa',
     'pidfile' => '--PIDDIR--/sympa.pid',
     'pidfile_distribute' => '--PIDDIR--/sympa-distribute.pid',
     'localedir'  => '--LOCALEDIR--',
     'sort'    => 'fr,ca,be,ch,uk,edu,*,com',
     'spool'   => '--SPOOLDIR--',
     'queue'   => undef,
     'queuedistribute' => undef,
     'queuedigest'=> undef,
     'queuemod'   => undef,
     'queuetopic' => undef,
     'queueauth'  => undef,
     'queueoutgoing'  => undef,
     'queuebounce'  => undef,    
     'queuetask' => undef,
     'queuesubscribe' => undef,
     'tmpdir'  => undef,     
     'sleep'      => 5,
     'clean_delay_queue'    => 1,
     'clean_delay_queuemod' => 10,
     'clean_delay_queuetopic' => 7,
     'clean_delay_queuesubscribe' => 10,
     'clean_delay_queueauth' => 3,
     'log_socket_type'      => 'unix',
     'log_smtp'      => '',
     'remind_return_path' => 'owner',
     'welcome_return_path' => 'owner',
     'db_type' => '',
     'db_name' => '',
     'db_host' => '',
     'db_user' => '', 
     'db_passwd'  => '',
     'db_options' => '',
     'db_env' => '',
     'db_port' => '',
     'db_timeout' => '',
     'db_additional_subscriber_fields' => '',
     'db_additional_user_fields' => '',
     'distribution_mode' => 'single',
     'listmaster' => undef,
     'listmaster_email' => 'listmaster',
     'default_list_priority' => 5,
     'sympa_priority' => 1,
     'request_priority' => 0,
     'owner_priority' => 9,
     'lang' => 'en_US',
     'misaddressed_commands' => 'reject',
     'misaddressed_commands_regexp' => '(subscribe|unsubscribe|signoff|set\s+(\S+)\s+(mail|nomail|digest))',
     'max_size' => 5242880,
     'edit_list' => 'owner',
     'create_list' => 'public_listmaster',
     'global_remind' => 'listmaster',
     'wwsympa_url' => undef,
     'bounce_warn_rate' => '30',
     'bounce_halt_rate' => '50',
     'bounce_email_prefix' => 'bounce',
     'cookie' => undef,
     'cookie_cas_expire' => '6',
     'loop_command_max' => 200,
     'loop_command_sampling_delay' => 3600,
     'loop_command_decrease_factor' => 0.5,
     'loop_prevention_regex' => 'mailer-daemon|sympa|listserv|majordomo|smartlist|mailman',
     'rfc2369_header_fields' => 'help,subscribe,unsubscribe,post,owner,archive',
     'remove_headers' => 'Return-Receipt-To,Precedence,X-Sequence,Disposition-Notification-To',
     'antivirus_path' => '',
     'antivirus_args' => '',
     'antivirus_notify' => 'sender',
     'anonymous_header_fields' => 'Sender,X-Sender,Received,Message-id,From,X-Envelope-To,Resent-From,Reply-To,Organization,Disposition-Notification-To,X-Envelope-From,X-X-Sender',
     'dark_color' => 'silver',
     'light_color' => '#aaddff',
     'text_color' => '#000000',
     'bg_color' => '#ffffcc',
     'error_color' => '#ff6666',
     'selected_color' => 'silver',
     'shaded_color' => '#66cccc',
     'color_0' => '#F0F0F0', # very light grey use in tables
     'color_1' => '#999', # main menu button color                       
     'color_2' => '#333', # font color                                   
     'color_3' => '#929292', # top boxe and footer box bacground color   
     'color_4' => 'silver', #  page backgound color                      
     'color_5' => '#fff', # ??                                           
     'color_6' => '#99ccff', # list menu current button                  
     'color_7' => '#ff99cc', # eroorbackground color,          
     'color_8' => '#3366CC', #                                           
     'color_9' => '#DEE7F7',
     'color_10' => '#777777', # inactive button
     'color_11' => '#3366CC', #                                          
     'color_12' => '#000',
     'color_13' => '#ffffcc',                                        # input backgound  | transparent
     'color_14' => '#000',
     'color_15' => '#000',
     'chk_cert_expiration_task' => '',
     'crl_update_task' => '',
     'ldap_export_name' => '',
     'ldap_export_host' => '',
     'ldap_export_suffix' => '',
     'ldap_export_password' => '',
     'ldap_export_dnmanager' => '',
     'ldap_export_connection_timeout' => '',
     'list_check_smtp' => '',
     'list_check_suffixes' => 'request,owner,editor,unsubscribe,subscribe',
     'expire_bounce_task' => 'daily',
     'purge_user_table_task' => 'monthly',
     'purge_orphan_bounces_task' => 'monthly',
     'eval_bouncers_task' => 'daily',
     'process_bouncers_task' => 'weekly',
     'default_archive_quota' => '',
     'default_shared_quota' => '',
     'capath' => '',
     'cafile' => '',
     'spam_protection' => 'javascript',
     'web_archive_spam_protection' => 'cookie',
     'minimum_bouncing_count' => 10,
     'minimum_bouncing_period' => 10,
     'bounce_delay' => 0,
     'default_bounce_level1_rate' => 45,
     'default_bounce_level2_rate' => 75,
     'soap_url' => '',
     'css_url' => '',
     'css_path' => '',
     'urlize_min_size' => 10240, ## 10Kb
     'supported_lang' => 'de,cs,el,es,et_EE,en_US,fr,hu,it,ja_JP,nl,oc,pt_BR,sv,tr',
     'web_recode_to' => '',
     'default_remind_task' => '',
     'update_db_field_types' => 'auto',
     'logo_html_definition' => '',
     'return_path_suffix' => '-owner',
     'verp_rate' => '0%',
     'cache_list_config' => 'none',
     );
   
my $wwsconf;
%Conf = ();

## Loads and parses the configuration file. Reports errors if any.
sub load {
    my $config = shift;
    my $line_num = 0;
    my $config_err = 0;
    my($i, %o);
    
    ## Open the configuration file or return and read the lines.
    unless (open(IN, $config)) {
	printf STDERR  "load: Unable to open %s: %s\n", $config, $!;
	return undef;
    }
    while (<IN>) {
	$line_num++;
	next if (/^\s*$/o || /^[\#\;]/o);
#	if (/^(\S+)\s+(\S+|\`.*\`)\s*$/io) {
	if (/^(\S+)\s+(.+)$/io) {
	    my($keyword, $value) = ($1, $2);
	    $value =~ s/\s*$//;
	    ##  'tri' is a synonime for 'sort' (for compatibily with old versions)
	    $keyword = 'sort' if ($keyword eq 'tri');
	    ##  'key_password' is a synonime for 'key_passwd' (for compatibily with old versions)
	    $keyword = 'key_passwd' if ($keyword eq 'key_password');
	    ## Special case: `command`
	    if ($value =~ /^\`(.*)\`$/) {
		$value = qx/$1/;
		chomp($value);
	    }
	    $o{$keyword} = [ $value, $line_num ];
	}else {
	    printf STDERR gettext("Error at line %d : %s"), $line_num, $config, $_;
	    $config_err++;
	}
    }
    close(IN);

    ## Defaults
    unless (defined $o{'wwsympa_url'}) {
	$o{'wwsympa_url'}[0] = "http://$o{'host'}[0]/wws";
    }
    unless (defined $o{'css_url'}) {
	$o{'css_url'}[0] = "$o{'wwsympa_url'}[0]/css/";
    }

    # 'host' and 'domain' are mandatory and synonime.$Conf{'host'} is
    # still wydly use even if the doc require domain.
 
    $o{'host'} = $o{'domain'} if (defined $o{'domain'}) ;
    $o{'domain'} = $o{'host'} if (defined $o{'host'}) ;
    
    unless ( (defined $o{'cafile'}) || (defined $o{'capath'} )) {
	$o{'cafile'}[0] = '--ETCBINDIR--/ca-bundle.crt';
    }   

    my $spool = $o{'spool'}[0] || $Default_Conf{'spool'};

    unless (defined $o{'queuedigest'}) {
	$o{'queuedigest'}[0] = "$spool/digest";
    }
    unless (defined $o{'queuedistribute'}) {
	$o{'queuedistribute'}[0] = "$spool/distribute";
    }
    unless (defined $o{'queuemod'}) {
	$o{'queuemod'}[0] = "$spool/moderation";
    }
    unless (defined $o{'queuetopic'}) {
	$o{'queuetopic'}[0] = "$spool/topic";
    }
    unless (defined $o{'queueauth'}) {
	$o{'queueauth'}[0] = "$spool/auth";
    }
    unless (defined $o{'queueoutgoing'}) {
	$o{'queueoutgoing'}[0] = "$spool/outgoing";
    }
    unless (defined $o{'queuesubscribe'}) {
	$o{'queuesubscribe'}[0] = "$spool/subscribe";
    }
    unless (defined $o{'queuetask'}) {
	$o{'queuetask'}[0] = "$spool/task";
    }
    unless (defined $o{'tmpdir'}) {
	$o{'tmpdir'}[0] = "$spool/tmp";
    }

    ## Check if we have unknown values.
    foreach $i (sort keys %o) {
	next if ($valid_options{$i});
	if (defined $old_options{$i}) {
	    if ($old_options{$i}) {
		printf STDERR  "Line %d of sympa.conf, parameter %s is no more available, read documentation for new parameter(s) %s\n", $o{$i}[1], $i, $old_options{$i};
	    }else {
		printf STDERR  "Line %d of sympa.conf, parameter %s is now obsolete\n", $o{$i}[1], $i;
		next;
	    }
	}else {
	    printf STDERR  "Line %d, unknown field: %s in sympa.conf\n", $o{$i}[1], $i;
	}
	$config_err++;
    }
    ## Do we have all required values ?
    foreach $i (keys %valid_options) {
	unless (defined $o{$i} or defined $Default_Conf{$i}) {
	    printf "Required field not found in sympa.conf: %s\n", $i;
	    $config_err++;
	    next;
	}
	$Conf{$i} = $o{$i}[0] || $Default_Conf{$i};
    }

    
    my $robots_conf = &load_robots ;    
    $Conf{'robots'} = $robots_conf ;
    my $nrcpt_by_domain =  &load_nrcpt_by_domain ;
    $Conf{'nrcpt_by_domain'} = $nrcpt_by_domain ;
    
    foreach my $robot (keys %{$Conf{'robots'}}) {
	my $config;
	unless ($config = &tools::get_filename('etc', 'auth.conf', $robot)) {
	    &do_log('err',"_load_auth: Unable to find auth.conf");
	    next;
	}

	$Conf{'auth_services'}{$robot} = &_load_auth($robot, $config);	
    }

    if ($Conf{'ldap_export_name'}) {    
	##Export
	$Conf{'ldap_export'} = {$Conf{'ldap_export_name'} => { 'host' => $Conf{'ldap_export_host'},
							   'suffix' => $Conf{'ldap_export_suffix'},
							       'password' => $Conf{'ldap_export_password'},
							       'DnManager' => $Conf{'ldap_export_dnmanager'},
							       'connection_timeout' => $Conf{'ldap_export_connection_timeout'}
							   }
			    };
    }
        
    my $p = 1;
    foreach (split(/,/, $Conf{'sort'})) {
	$Conf{'poids'}{$_} = $p++;
    }
    $Conf{'poids'}{'*'} = $p if ! $Conf{'poids'}{'*'};
    
    if ($config_err) {
	return undef;
    }

    if ($Conf{'rfc2369_header_fields'} eq 'none') {
	delete $Conf{'rfc2369_header_fields'};
    }else {
	$Conf{'rfc2369_header_fields'} = [split(/,/, $Conf{'rfc2369_header_fields'})];
    }

    if ($Conf{'anonymous_header_fields'} eq 'none') {
	delete $Conf{'anonymous_header_fields'};
    }else {
	$Conf{'anonymous_header_fields'} = [split(/,/, $Conf{'anonymous_header_fields'})];
    }

    if ($Conf{'remove_headers'} eq 'none') {
	delete $Conf{'remove_headers'};
    }else {
	$Conf{'remove_headers'} = [split(/,/, $Conf{'remove_headers'})];
    }
    $Conf{'listmaster'} =~ s/\s//g ;
    @{$Conf{'listmasters'}} = split(/,/, $Conf{'listmaster'});

    
    ## Set Regexp for accepted list suffixes
    if (defined ($Conf{'list_check_suffixes'})) {
	$Conf{'list_check_regexp'} = $Conf{'list_check_suffixes'};
	$Conf{'list_check_regexp'} =~ s/,/\|/g;
    }

    $Conf{'sympa'} = "$Conf{'email'}\@$Conf{'host'}";
    $Conf{'request'} = "$Conf{'email'}-request\@$Conf{'host'}";
    
    return 1;
}

## load nrcpt file (limite receipient par domain
sub load_nrcpt_by_domain {
  my $config = $Conf{'etc'}.'/nrcpt_by_domain.conf';
  my $line_num = 0;
  my $config_err = 0;
  my %nrcpt_by_domain ; 
  my $valid_dom = 0;

  


  return undef unless (-f $config) ;
  &do_log('notice',"load_nrcpt: loading $config");

  ## Open the configuration file or return and read the lines.
  unless (open(IN, $config)) {
      printf STDERR  "load: Unable to open %s: %s\n", $config, $!;
      return undef;
  }
  while (<IN>) {
      $line_num++;
      next if (/^\s*$/o || /^[\#\;]/o);
      if (/^(\S+)\s+(\d+)$/io) {
	  my($domain, $value) = ($1, $2);
	  chomp $domain; chomp $value;
	  $nrcpt_by_domain->{$domain} = $value;
	  $valid_dom +=1;
      }else {
	  printf STDERR gettext("Error at line %d : %s"), $line_num, $config, $_;
	  $config_err++;
      }
  } 
  close(IN);
  &do_log('debug',"load_nrcpt: loaded $valid_dom config lines from $config");
  return ($nrcpt_by_domain);
}


## load each virtual robots configuration files
sub load_robots {
    
    my %robot_conf ;
    my %valid_robot_key_words = ( 'http_host'     => 1, 
				  listmaster      => 1,
				  email           => 1,
				  host            => 1,
				  wwsympa_url     => 1,
				  'title'         => 1,
				  logo_html_definition        => 1,
				  lang            => 1,
				  default_home    => 1,
				  cookie_domain   => 1,
				  log_smtp        => 1,
				  log_level       => 1,
				  create_list     => 1,
				  dark_color      => 1,
				  light_color     => 1,
				  text_color      => 1, 
				  bg_color        => 1,
				  error_color     => 1,
				  selected_color  => 1,
				  shaded_color    => 1,
				  list_check_smtp => 1,
				  list_check_suffixes => 1,
				  spam_protection => 1,
				  web_archive_spam_protection => 1,
				  bounce_level1_rate => 1,
				  bounce_level2_rate => 1,
				  soap_url => 1,
				  css_url => 1,
 				  css_path => 1,
 				  color_0 => 1, color_1 => 1, color_2 => 1, color_3 => 1, color_4 => 1, color_5 => 1,color_6 => 1, 
				  color_7 => 1, color_8 => 1, color_9 => 1,
				  color_10 => 1, color_11 => 1, color_12 => 1,color_13 => 1, color_14 => 1, color_15 => 1,
				  supported_lang => 1,
				  default_shared_quota => 1,
				  verp_rate => 1,
				  loop_prevention_regex => 1,
				  );

    ## Load wwsympa.conf
    unless ($wwsconf = &wwslib::load_config('--WWSCONFIG--')) {
	print STDERR "Unable to load config file --WWSCONFIG--\n";
    }

    unless (opendir DIR,$Conf{'etc'} ) {
	printf STDERR "Unable to open directory $Conf{'etc'} for virtual robots config\n" ;
	return undef;
    }

    ## Set the defaults based on sympa.conf and wwsympa.conf first
    foreach my $key (keys %valid_robot_key_words) {
	$robot_conf->{$Conf{'domain'}}{$key} = $Conf{$key};
    }

    foreach $robot (readdir(DIR)) {
	next unless (-d "$Conf{'etc'}/$robot");
	next unless (-r "$Conf{'etc'}/$robot/robot.conf");
	unless (open (ROBOT_CONF,"$Conf{'etc'}/$robot/robot.conf")) {
	    printf STDERR "load robots config: Unable to open $Conf{'etc'}/$robot/robot.conf\n"; 
	    next ;
	}
	
	while (<ROBOT_CONF>) {
	    next if (/^\s*$/o || /^[\#\;]/o);
	    if (/^\s*(\S+)\s+(.+)\s*$/io) {
		my($keyword, $value) = ($1, $2);
		$value =~ s/\s*$//;
		$keyword = lc($keyword);

		## Not all parameters should be lowercased
		## We should define which parameter needs to be lowercased
		#$value = lc($value) unless ($keyword eq 'title' || $keyword eq 'logo_html_definition' || $keyword eq 'lang');

		if ($valid_robot_key_words{$keyword}) {
		    $robot_conf->{$robot}{$keyword} = $value;
		    # printf STDERR "load robots config: $keyword = $value\n";
		}else{
		    printf STDERR "load robots config: unknown keyword $keyword\n";
		    # printf STDERR "load robots config: unknown keyword $keyword\n";
		}
	    }
	}
	# listmaster is a list of email separated by commas
	$robot_conf->{$robot}{'listmaster'} =~ s/\s//g;
	@{$robot_conf->{$robot}{'listmasters'}} = split(/,/, $robot_conf->{$robot}{'listmaster'})
	    if $robot_conf->{$robot}{'listmaster'};

	## Default for 'host' is the domain
	$robot_conf->{$robot}{'host'} ||= $robot;

	$robot_conf->{$robot}{'title'} ||= $wwsconf->{'title'};
	$robot_conf->{$robot}{'default_home'} ||= $wwsconf->{'default_home'};

	$robot_conf->{$robot}{'lang'} ||= $Conf{'lang'};
	$robot_conf->{$robot}{'email'} ||= $Conf{'email'};
	$robot_conf->{$robot}{'log_smtp'} ||= $Conf{'log_smtp'};
	$robot_conf->{$robot}{'log_level'} ||= $Conf{'log_level'};
	$robot_conf->{$robot}{'wwsympa_url'} ||= 'http://'.$robot_conf->{$robot}{'http_host'}.'/wws';
	$robot_conf->{$robot}{'css_url'} ||= $robot_conf->{$robot}{'wwsympa_url'}.'/css';
	$robot_conf->{$robot}{'sympa'} = $robot_conf->{$robot}{'email'}.'@'.$robot_conf->{$robot}{'host'};
	$robot_conf->{$robot}{'request'} = $robot_conf->{$robot}{'email'}.'-request@'.$robot_conf->{$robot}{'host'};
	$robot_conf->{$robot}{'cookie_domain'} ||= 'localhost';
	#$robot_conf->{$robot}{'soap_url'} ||= $Conf{'soap_url'};
	$robot_conf->{$robot}{'verp_rate'} ||= $Conf{'verp_rate'};

	my ($host, $path);
	if ($robot_conf->{$robot}{'http_host'} =~ /^([^\/]+)(\/.*)$/) {
	    ($host, $path) = ($1,$2);
	}else {
	    ($host, $path) = ($robot_conf->{$robot}{'http_host'}, '/');
	}
	$Conf{'robot_by_http_host'}{$host}{$path} = $robot ;
	
	## Create a hash to deduce robot from SOAP url
	if ($robot_conf->{$robot}{'soap_url'}) {
	    my $url = $robot_conf->{$robot}{'soap_url'};
	    $url =~ s/^http(s)?:\/\/(.+)$/$2/;
	    $Conf{'robot_by_soap_url'}{$url} = $robot;
	}

	close (ROBOT_CONF);
    }
    closedir(DIR);
    
    ## Default SOAP URL corresponds to default robot
    if ($Conf{'soap_url'}) {
	my $url = $Conf{'soap_url'};
	$url =~ s/^http(s)?:\/\/(.+)$/$2/;
	$Conf{'robot_by_soap_url'}{$url} = $Conf{'domain'};
    }

    return ($robot_conf);
}

## Check required files and create them if required
sub checkfiles_as_root {

    ## Check aliases file
    unless (-f $Conf{'sendmail_aliases'}) {
	unless (open ALIASES, ">$Conf{'sendmail_aliases'}") {
	    &do_log('err',"Failed to create aliases file %s", $Conf{'sendmail_aliases'});
	    return undef;
	}

	print ALIASES "## This aliases file is dedicated to Sympa Mailing List Manager\n";
	print ALIASES "## You should edit your sendmail.mc or sendmail.cf file to declare it\n";
	close ALIASES;
	&do_log('notice', "Created missing file %s", $Conf{'sendmail_aliases'});
	`chown --USER-- $Conf{'sendmail_aliases'}`;
	`chgrp --GROUP-- $Conf{'sendmail_aliases'}`;
	chmod 0644, $Conf{'sendmail_aliases'}
	
    }

}

## Check a few files
sub checkfiles {
    my $config_err = 0;
    
    foreach my $p ('sendmail','openssl','antivirus_path') {
	next unless $Conf{$p};
	
	unless (-x $Conf{$p}) {
	    do_log('err', "File %s does not exist or is not executable", $Conf{$p});
	    $config_err++;
	}
    }
    
    foreach my $qdir ('spool','queue','queuedigest','queuemod','queuetopic','queueauth','queueoutgoing','queuebounce','queuesubscribe','queuetask','queuedistribute','tmpdir')
    {
	unless (-d $Conf{$qdir}) {
	    do_log('info', "creating spool $Conf{$qdir}");
	    unless ( mkdir ($Conf{$qdir}, 0775)) {
		do_log('err', 'Unable to create spool %s', $Conf{$qdir});
		$config_err++;
	    }
	}
    }

    ## Also create msg/bad/
    unless (-d $Conf{'queue'}.'/bad') {
	    do_log('info', "creating spool $Conf{'queue'}/bad");
	    unless ( mkdir ($Conf{'queue'}.'/bad', 0775)) {
		do_log('err', 'Unable to create spool %s', $Conf{'queue'}.'/bad');
		$config_err++;
	    }
	}
    ## Also create distribute/bad/
    unless (-d $Conf{'queuedistribute'}.'/bad') {
	    do_log('info', "creating spool $Conf{'queuedistribute'}/bad");
	    unless ( mkdir ($Conf{'queuedistribute'}.'/bad', 0775)) {
		do_log('err', 'Unable to create spool %s', $Conf{'queuedistribute'}.'/bad');
		$config_err++;
	    }
	}

    ## Check cafile and capath access
    if (defined $Conf{'cafile'} && $Conf{'cafile'}) {
	unless (-f $Conf{'cafile'} && -r $Conf{'cafile'}) {
	    &do_log('err', 'Cannot access cafile %s', $Conf{'cafile'});
	    unless (&List::send_notify_to_listmaster('cannot_access_cafile', $Conf{'domain'}, [$Conf{'cafile'}])) {
		&do_log('err', 'Unable to send notify "cannot access cafile" to listmaster');	
	    }
	    $config_err++;
	}
    }

    if (defined $Conf{'capath'} && $Conf{'capath'}) {
	unless (-d $Conf{'capath'} && -x $Conf{'capath'}) {
	    &do_log('err', 'Cannot access capath %s', $Conf{'capath'});
	    unless (&List::send_notify_to_listmaster('cannot_access_capath', $Conf{'domain'}, [$Conf{'capath'}])) {
		&do_log('err', 'Unable to send notify "cannot access capath" to listmaster');	
	    }
	    $config_err++;
	}
    }

    ## queuebounce and bounce_path pointing to the same directory
    if ($Conf{'queuebounce'} eq $wwsconf->{'bounce_path'}) {
	&do_log('err', 'Error in config : queuebounce and bounce_path parameters pointing to the same directory (%s)', $Conf{'queuebounce'});
	unless (&List::send_notify_to_listmaster('queuebounce_and_bounce_path_are_the_same', $Conf{'domain'}, [$Conf{'queuebounce'}])) {
	    &do_log('err', 'Unable to send notify "queuebounce_and_bounce_path_are_the_same" to listmaster');	
	}
	$config_err++;
    }

    return undef if ($config_err);
    return 1;
}

## Loads and parses the authentication configuration file.
##########################################

sub _load_auth {
    
    my $robot = shift;
    my $config = shift;
    &do_log('notice', 'Conf::_load_auth(%s)', $config);

    my $line_num = 0;
    my $config_err = 0;
    my @paragraphs;
    my %result;
    my $current_paragraph ;

    my %valid_keywords = ('ldap' => {'regexp' => '.*',
				     'negative_regexp' => '.*',
				     'host' => '[\w\.\-]+(:\d+)?(\s*,\s*[\w\.\-]+(:\d+)?)*',
				     'timeout' => '\d+',
				     'suffix' => '.+',
				     'bind_dn' => '.+',
				     'bind_password' => '.+',
				     'get_dn_by_uid_filter' => '.+',
				     'get_dn_by_email_filter' => '.+',
				     'email_attribute' => '\w+',
				     'alternative_email_attribute' => '(\w+)(,\w+)*',
				     'scope' => 'base|one|sub',
				     'authentication_info_url' => 'http(s)?:/.*',
				     'use_ssl' => '1',
				     'ssl_version' => 'sslv2/3|sslv2|sslv3|tlsv1',
				     'ssl_ciphers' => '[\w:]+' },
			  
			  'user_table' => {'regexp' => '.*',
					   'negative_regexp' => '.*'},
			  
			  'cas' => {'base_url' => 'http(s)?:/.*',
				    'non_blocking_redirection' => 'on|off',
				    'login_path' => '.*',
				    'logout_path' => '.*',
				    'service_validate_path' => '.*',
				    'proxy_path' => '.*',
				    'proxy_validate_path' => '.*',
				    'auth_service_name' => '.*',
				    'authentication_info_url' => 'http(s)?:/.*',
				    'ldap_host' => '[\w\.\-]+(:\d+)?(\s*,\s*[\w\.\-]+(:\d+)?)*',
				    'ldap_bind_dn' => '.+',
				    'ldap_bind_password' => '.+',
				    'ldap_timeout'=> '\d+',
				    'ldap_suffix'=> '.+',
				    'ldap_scope' => 'base|one|sub',
				    'ldap_get_email_by_uid_filter' => '.+',
				    'ldap_email_attribute' => '\w+',
				    'ldap_use_ssl' => '1',
				    'ldap_ssl_version' => 'sslv2/3|sslv2|sslv3|tlsv1',
				    'ldap_ssl_ciphers' => '[\w:]+'
				    },
			  'generic_sso' => {'service_name' => '.+',
					    'service_id' => '\S+',
					    'http_header_prefix' => '\w+',
					    'email_http_header' => '\w+',
					    'ldap_host' => '[\w\.\-]+(:\d+)?(\s*,\s*[\w\.\-]+(:\d+)?)*',
					    'ldap_bind_dn' => '.+',
					    'ldap_bind_password' => '.+',
					    'ldap_timeout'=> '\d+',
					    'ldap_suffix'=> '.+',
					    'ldap_scope' => 'base|one|sub',
					    'ldap_get_email_by_uid_filter' => '.+',
					    'ldap_email_attribute' => '\w+',
					    'ldap_use_ssl' => '1',
					    'ldap_ssl_version' => 'sslv2/3|sslv2|sslv3|tlsv1',
					    'ldap_ssl_ciphers' => '[\w:]+',
					    'force_email_verify' => '1',
					    'internal_email_by_netid' => '1',
					    'netid_http_header' => '\w+',
					}
			  );
    


    ## Open the configuration file or return and read the lines.
    unless (open(IN, $config)) {
	do_log('notice',"_load_auth: Unable to open %s: %s", $config, $!);
	return undef;
    }
    
    $Conf{'cas_number'}{$robot} = 0;
    $Conf{'generic_sso_number'}{$robot} = 0;
    $Conf{'ldap_number'}{$robot} = 0;
    $Conf{'use_passwd'}{$robot} = 0;
    
    ## Parsing  auth.conf
    while (<IN>) {

	$line_num++;
	next if (/^\s*[\#\;]/o);		

	if (/^\s*(ldap|cas|user_table|generic_sso)\s*$/io) {
	    $current_paragraph->{'auth_type'} = lc($1);
	}elsif (/^\s*(\S+)\s+(.*\S)\s*$/o){
	    my ($keyword,$value) = ($1,$2);
	    unless (defined $valid_keywords{$current_paragraph->{'auth_type'}}{$keyword}) {
		do_log('err',"_load_auth: unknown keyword '%s' in %s line %d", $keyword, $config, $line_num);
		next;
	    }
	    unless ($value =~ /^$valid_keywords{$current_paragraph->{'auth_type'}}{$keyword}$/) {
		do_log('err',"_load_auth: unknown format '%s' for keyword '%s' in %s line %d", $value, $keyword, $config,$line_num);
		next;
	    }

	    ## Allow white spaces between hosts
	    if ($keyword =~ /host$/) {
		$value =~ s/\s//g;
	    }
	    
	    $current_paragraph->{$keyword} = $value;
	}

	## process current paragraph
	if (/^\s+$/o || eof(IN)) {
	    if (defined($current_paragraph)) {
		
		if ($current_paragraph->{'auth_type'} eq 'cas') {
		    unless (defined $current_paragraph->{'base_url'}) {
			&do_log('err','Incorrect CAS paragraph in auth.conf');
			next;
		    }

		    my %cas_param = (casUrl => $current_paragraph->{'base_url'});

		    ## Optional parameters
		    ## We should also cope with X509 CAs
		    $cas_param->{'loginPath'} = $current_paragraph->{'login_path'} 
		    if (defined $current_paragraph->{'login_path'});
		    $cas_param->{'logoutPath'} = $current_paragraph->{'logout_path'} 
		    if (defined $current_paragraph->{'logout_path'});
		    $cas_param->{'serviceValidatePath'} = $current_paragraph->{'service_validate_path'} 
		    if (defined $current_paragraph->{'service_validate_path'});
		    $cas_param->{'proxyPath'} = $current_paragraph->{'proxy_path'} 
		    if (defined $current_paragraph->{'proxy_path'});
		    $cas_param->{'proxyValidatePath'} = $current_paragraph->{'proxy_validate_path'} 
		    if (defined $current_paragraph->{'proxy_validate_path'});
		    
		    $current_paragraph->{'cas_server'} = new CAS(%cas_param);
		    unless (defined $current_paragraph->{'cas_server'}) {
			&do_log('err', 'Failed to create CAS object for %s : %s', 
				$current_paragraph->{'base_url'}, &CAS::get_errors());
			next;
		    }

		    $Conf{'cas_number'}{$robot}  ++ ;
		    $Conf{'cas_id'}{$robot}{$current_paragraph->{'auth_service_name'}} =  $#paragraphs+1 ; 
		}elsif($current_paragraph->{'auth_type'} eq 'generic_sso') {
		    $Conf{'generic_sso_number'}{$robot}  ++ ;
		    $Conf{'generic_sso_id'}{$robot}{$current_paragraph->{'service_id'}} =  $#paragraphs+1 ; 
		}elsif($current_paragraph->{'auth_type'} eq 'ldap') {
		    $Conf{'ldap'}{$robot}  ++ ;
		    $Conf{'use_passwd'}{$robot} = 1;
		}elsif($current_paragraph->{'auth_type'} eq 'user_table') {
		    $Conf{'use_passwd'}{$robot} = 1;
		}
		# setting default
		$current_paragraph->{'regexp'} = '.*' unless (defined($current_paragraph->{'regexp'})) ;
		$current_paragraph->{'non_blocking_redirection'} = 'on' unless (defined($current_paragraph->{'non_blocking_redirection'})) ;
		push(@paragraphs,$current_paragraph);
		
		undef $current_paragraph;
	    } 
	    next ;
	}
    }
    close(IN); 

    return \@paragraphs;
    
}

## returns a robot conf parameter
sub get_robot_conf {
    my ($robot, $param) = @_;

    if ($robot ne '*') {
	if (defined $Conf{'robots'}{$robot} && defined $Conf{'robots'}{$robot}{$param}) {
	    return $Conf{'robots'}{$robot}{$param};
	}
    }
    
    ## default
    return $Conf{$param} || $wwsconf->{$param};
}

## Packages must return true.
1;
