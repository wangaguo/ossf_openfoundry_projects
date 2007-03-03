#!--PERL-- --PERLOPT--

# wwsympa.fcgi - This script provides the web interface to Sympa 
# RCS Identication ; $Revision: 1.652.2.9 $ ; $Date: 2006/09/15 09:04:57 $ 
#
# Sympa - SYsteme de Multi-Postage Automatique
# Copyright (c) 1997-2003 Comite Reseau des Universites
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

## Copyright 1999 Comit� R�seaux des Universit�s
## web interface to Sympa mailing lists manager
## Sympa: http://www.sympa.org/

## Authors :
##           Serge Aumont <sa AT cru.fr>
##           Olivier Sala�n <os AT cru.fr>

## Change this to point to your Sympa bin directory
use lib '--LIBDIR--';
use Getopt::Long;
use Archive::Zip;

use strict 'vars';
use Time::Local;
use Text::Wrap;

## Template parser
require "--LIBDIR--/tt2.pl";

## Sympa API
use List;
use mail;
use mail;
use Conf;
use Commands;
use Language;
use Log;
use Auth;
use admin;
use SharedDocument;
use report;

use Mail::Header;
use Mail::Address;

require "--LIBDIR--/tools.pl";
require "--LIBDIR--/time_utils.pl";

## WWSympa librairies
use wwslib;
use cookielib;
my %options;


## OpenFoundry
use CGI::Cookie ();
use CGI::Util ();
use Data::Dumper;
{
package OpenFoundry;
require 'OpenFoundry.pm';
}






## Configuration
my $wwsconf = {};

## Change to your wwsympa.conf location
my $conf_file = '--WWSCONFIG--';
my $sympa_conf_file = '--CONFIG--';



my $loop = 0;
my $list;
my $param = {};
my $robot ;
my $ip ; 
my $rss ;


## Load config 
unless ($wwsconf = &wwslib::load_config($conf_file)) {
    &fatal_err('Unable to load config file %s', $conf_file);
}

## Load sympa config
unless (&Conf::load( $sympa_conf_file )) {
    &fatal_err('Unable to load sympa config file %s', $sympa_conf_file);
}

$log_level = $Conf{'log_level'} if ($Conf{'log_level'});

&mail::set_send_spool($Conf{'queue'});

if ($wwsconf->{'use_fast_cgi'}) {
    require CGI::Fast;
}else {
    require CGI;
}
my $mime_types = &wwslib::load_mime_types();


# hash of all the description files already loaded
# format :
#     $desc_files{pathfile}{'date'} : date of the last load
#     $desc_files{pathfile}{'desc_hash'} : hash which describes
#                         the description file

#%desc_files_map; NOT USED ANYMORE

# hash of the icons linked with a type of file
my %icon_table;

  # application file
$icon_table{'unknown'} = $wwsconf->{'icons_url'}.'/unknown.png';
$icon_table{'folder'} = $wwsconf->{'icons_url'}.'/folder.png';
$icon_table{'current_folder'} = $wwsconf->{'icons_url'}.'/folder.open.png';
$icon_table{'application'} = $wwsconf->{'icons_url'}.'/unknown.png';
$icon_table{'octet-stream'} = $wwsconf->{'icons_url'}.'/binary.png';
$icon_table{'audio'} = $wwsconf->{'icons_url'}.'/sound1.png';
$icon_table{'image'} = $wwsconf->{'icons_url'}.'/image2.png';
$icon_table{'text'} = $wwsconf->{'icons_url'}.'/text.png';
$icon_table{'video'} = $wwsconf->{'icons_url'}.'/movie.png';
$icon_table{'father'} = $wwsconf->{'icons_url'}.'/back.png';
$icon_table{'sort'} = $wwsconf->{'icons_url'}.'/down.png';
$icon_table{'url'} = $wwsconf->{'icons_url'}.'/link.png';
$icon_table{'left'} = $wwsconf->{'icons_url'}.'/left.png';
$icon_table{'right'} = $wwsconf->{'icons_url'}.'/right.png';
## Shared directory and description file

#$shared = 'shared';
#$desc = '.desc';


## subroutines
my %comm = ('home' => 'do_home',
	 'logout' => 'do_logout',
	 'loginrequest' => 'do_loginrequest',
	 'login' => 'do_login',
	 'sso_login' => 'do_sso_login',
	 'sso_login_succeeded' => 'do_sso_login_succeeded',
	 'subscribe' => 'do_subscribe',
	 'subrequest' => 'do_subrequest',
	 'subindex' => 'do_subindex',
	 'suboptions' => 'do_suboptions',
	 'signoff' => 'do_signoff',
	 'sigrequest' => 'do_sigrequest',
	 'ignoresub' => 'do_ignoresub',
	 'which' => 'do_which',
	 'lists' => 'do_lists',
	 'latest_lists' => 'do_latest_lists',   
	 'active_lists' => 'do_active_lists',
	 'info' => 'do_info',
	 'subscriber_count' => 'do_subscriber_count',   
	 'review' => 'do_review',
	 'search' => 'do_search',
	 'pref', => 'do_pref',
	 'setpref' => 'do_setpref',
	 'setpasswd' => 'do_setpasswd',
	 'remindpasswd' => 'do_remindpasswd',
	 'sendpasswd' => 'do_sendpasswd',
	 'choosepasswd' => 'do_choosepasswd',	
	 'viewfile' => 'do_viewfile',
	 'set' => 'do_set',
	 'admin' => 'do_admin',
	 'add_request' => 'do_add_request',
	 'add' => 'do_add',
	 'del' => 'do_del',
	 'modindex' => 'do_modindex',
	 'reject' => 'do_reject',
	 'reject_notify' => 'do_reject_notify',
         'd_reject_shared' =>'admin',
         'reject_notify_shared' =>'admin',
         'd_install_shared' =>'admin',
	 'distribute' => 'do_distribute',
	 'viewmod' => 'do_viewmod',
	 'd_reject_shared' => 'do_d_reject_shared',
	 'reject_notify_shared' => 'do_reject_notify_shared',
	 'd_install_shared' => 'do_d_install_shared',
	 'editfile' => 'do_editfile',
	 'savefile' => 'do_savefile',
	 'arc' => 'do_arc',
         'latest_arc' => 'do_latest_arc',
	 'latest_d_read' => 'do_latest_d_read',
	 'arc_manage' => 'do_arc_manage',                             
	 'remove_arc' => 'do_remove_arc',
	 'send_me' => 'do_send_me',
	 'arcsearch_form' => 'do_arcsearch_form',
	 'arcsearch_id' => 'do_arcsearch_id',
	 'arcsearch' => 'do_arcsearch',
	 'rebuildarc' => 'do_rebuildarc',
	 'rebuildallarc' => 'do_rebuildallarc',
	 'arc_download' => 'do_arc_download',
	 'arc_delete' => 'do_arc_delete',
	 'serveradmin' => 'do_serveradmin',
	 'skinsedit' => 'do_skinsedit',
	 'css' => 'do_css',
	 'help' => 'do_help',
	 'edit_list_request' => 'do_edit_list_request',
	 'edit_list' => 'do_edit_list',
	 'create_list_request' => 'do_create_list_request',
	 'create_list' => 'do_create_list',
	 'get_pending_lists' => 'do_get_pending_lists', 
	 'get_closed_lists' => 'do_get_closed_lists', 
	 'get_latest_lists' => 'do_get_latest_lists', 
	 'get_inactive_lists' => 'do_get_inactive_lists', 
	 'set_pending_list_request' => 'do_set_pending_list_request', 
	 'install_pending_list' => 'do_install_pending_list', 
	 'submit_list' => 'do_submit_list',
	 'editsubscriber' => 'do_editsubscriber',
	 'viewbounce' => 'do_viewbounce',
	 'redirect' => 'do_redirect',
	 'rename_list_request' => 'do_rename_list_request',
	 'rename_list' => 'do_rename_list',
	 'reviewbouncing' => 'do_reviewbouncing',
	 'resetbounce' => 'do_resetbounce',
	 'scenario_test' => 'do_scenario_test',
	 'search_list' => 'do_search_list',
	 'show_cert' => 'show_cert',
	 'close_list_request' => 'do_close_list_request',
	 'close_list' => 'do_close_list',
	 'purge_list' => 'do_purge_list',	    
	 'restore_list' => 'do_restore_list',
	 'd_read' => 'do_d_read',
	 'd_create_dir' => 'do_d_create_dir',
	 'd_upload' => 'do_d_upload',   
	 'd_unzip' => 'do_d_unzip',   
	 'd_editfile' => 'do_d_editfile',
         'd_properties' => 'do_d_properties',
	 'd_overwrite' => 'do_d_overwrite',
	 'd_savefile' => 'do_d_savefile',
	 'd_describe' => 'do_d_describe',
	 'd_delete' => 'do_d_delete',
	 'd_rename' => 'do_d_rename',   
	 'd_control' => 'do_d_control',
	 'd_change_access' => 'do_d_change_access',
	 'd_set_owner' => 'do_d_set_owner',
	 'd_admin' => 'do_d_admin',
	 'dump_scenario' => 'do_dump_scenario',
	 'dump' => 'do_dump',
	 'arc_protect' => 'do_arc_protect',
	 'remind' => 'do_remind',
	 'change_email' => 'do_change_email',
	 'load_cert' => 'do_load_cert',
	 'compose_mail' => 'do_compose_mail',
	 'send_mail' => 'do_send_mail',
	 'request_topic' => 'do_request_topic',
	 'tag_topic_by_sender' =>'do_tag_topic_by_sender', 
	 'search_user' => 'do_search_user',
	 'unify_email' => 'do_unify_email',
	 'record_email' => 'do_record_email',	    
	 'set_lang' => 'do_set_lang',
	 'attach' => 'do_attach',
	 'change_identity' => 'do_change_identity',
	 'stats' => 'do_stats',
	 'viewlogs'=> 'do_viewlogs',
	 'wsdl'=> 'do_wsdl',
	 'sync_include' => 'do_sync_include',
	 'review_family' => 'do_review_family',
	 'ls_templates' => 'do_ls_templates',
	 'remove_template' => 'do_remove_template',
	 'copy_template' => 'do_copy_template',	   
	 'view_template' => 'do_view_template',
	 'edit_template' => 'do_edit_template',
	 'rss_request' => 'do_rss_request',
	    'maintenance' => 'do_maintenance',
# OpenFoundry
'lists_by_project' => 'do_lists_by_project',
'create_project_list_request' => 'do_create_project_list_request',
'create_project_list' => 'do_create_project_list',
	 );

my %auth_action = ('logout' => 1,
		   'loginrequest' => 1,
		   'login' => 1,
		   'sso_login' => 1,
		   'sso_login_succeeded' => 1,
		   'remindpasswd' => 1,
		   'choosepasswd' => 1,
		   'sendssopasswd' => 1,
		   );		  

## Arguments awaited in the PATH_INFO, depending on the action 
my %action_args = ('default' => ['list'],
		'editfile' => ['list','file'],
		'viewfile' => ['list','file'],
		'sendpasswd' => ['email'],
		'choosepasswd' => ['email','passwd'],
		'lists' => ['topic','subtopic'],
		'latest_lists' => ['topic','subtopic'],   
		'active_lists' => ['topic','subtopic'],  
		'login' => ['email','passwd','previous_action','previous_list'],
		'sso_login' => ['auth_service_name','subaction','previous_action','previous_list', 'email', 'passwd'],
		'sso_login_succeeded' => ['auth_service_name','previous_action','previous_list'],
		'loginrequest' => ['previous_action','previous_list'],
		'logout' => ['previous_action','previous_list'],
		'remindpasswd' => ['previous_action','previous_list'],
		'css' => ['file'],
		'pref' => ['previous_action','previous_list'],
		'reject' => ['list','id'],
		'distribute' => ['list','id'],
		'dump_scenario' => ['list','pname'],
		'd_reject_shared' => ['list','id'],
		'd_install_shared' => ['list','id'],
		'modindex' => ['list'],
		'viewmod' => ['list','id','file'],
		'viewfile' => ['list','file'],
		'add' => ['list','email'],
		'add_request' => ['list'],
		'del' => ['list','email'],
		'editsubscriber' => ['list','email','previous_action'],
		'viewbounce' => ['list','email'],
		'resetbounce' => ['list','email'],
		'review' => ['list','page','size','sortby'],
		'reviewbouncing' => ['list','page','size'],
		'arc' => ['list','month','@arc_file'],
		'latest_arc' => ['list'],
		'arc_manage' => ['list'],                                          
		'arcsearch_form' => ['list','archive_name'],
		'arcsearch_id' => ['list','archive_name','msgid'],
		'rebuildarc' => ['list','month'],
		'rebuildallarc' => [],
		'arc_download' => ['list'],
		'arc_delete' => ['list','zip'],
		'home' => [],
		'help' => ['help_topic'],
		'show_cert' => [],
		'subscribe' => ['list','email','passwd'],
		'subrequest' => ['list','email'],
		'subrequest' => ['list'],
		'subindex' => ['list'],
                'ignoresub' => ['list','@email','@gecos'],
		'signoff' => ['list','email','passwd'],
		'sigrequest' => ['list','email'],
		'set' => ['list','email','reception','gecos'],
		'serveradmin' => [],
		'skinsedit' => [],
		'get_pending_lists' => [],
		'get_closed_lists' => [],
		'get_latest_lists' => [],
		'get_inactive_lists' => [],
		'search_list' => ['filter'],
		'shared' => ['list','@path'],
		'd_read' => ['list','@path'],
		'latest_d_read' => ['list'],
		'd_admin' => ['list','d_admin'],
		'd_delete' => ['list','@path'],
		'd_rename' => ['list','@path'],
		'd_create_dir' => ['list','@path'],
		'd_overwrite' => ['list','@path'],
		'd_savefile' => ['list','@path'],
		'd_describe' => ['list','@path'],
		'd_editfile' => ['list','@path'],
		'd_properties' => ['list','@path'],
		'd_control' => ['list','@path'],
		'd_change_access' =>  ['list','@path'],
		'd_set_owner' =>  ['list','@path'],
		'dump' => ['list','format'],
		'search' => ['list','filter'],
		'search_user' => ['email'],
		'set_lang' => ['lang'],
		'attach' => ['list','dir','file'],
		'change_identity' => ['email','previous_action','previous_list'],
		'edit_list_request' => ['list','group'],
		'rename_list' => ['list','new_list','new_robot'],
		'redirect' => [],
#		'viewlogs' => ['list'],
		'wsdl' => [],
		'sync_include' => ['list'],
		'review_family' => ['family_name'],
		'ls_templates' => [],
 		'view_template' => [],
 		'remove_template' => [],
 		'copy_template' => [],
 		'edit_template' => [],
		'rss_request' => ['list'],
		'request_topic' => ['list','authkey'],
		'tag_topic_by_sender' => ['list']   
# OpenFoundry
,
'lists_by_project' => ['projectUnixName'],
'create_project_list_request' => ['projectUnixName'],

		);

my %action_type = ('editfile' => 'admin',
		'review' => 'admin',
		'search' => 'admin',
		'viewfile' => 'admin',
		'admin' => 'admin',
		'add_request' =>'admin',
		'add' =>'admin',
		'del' =>'admin',
#		'modindex' =>'admin',
		'reject' =>'admin',
		'reject_notify' =>'admin',
		'add_request' =>'admin',
		'distribute' =>'admin',
		'viewmod' =>'admin',
		'savefile' =>'admin',
		'rebuildarc' =>'admin',
		'rebuildallarc' =>'admin',
		'reviewbouncing' =>'admin',
		'edit_list_request' =>'admin',
		'edit_list' =>'admin',
		'editsubscriber' =>'admin',
		'viewbounce' =>'admin',
		'resetbounce'  =>'admin',
		'scenario_test' =>'admin',
		'close_list_request' =>'admin',
		'close_list' =>'admin',
		'restore_list' => 'admin',
		'd_admin' => 'admin',
                'dump_scenario' => 'admin',
## 
		'dump' => 'admin',
		'remind' => 'admin',
#		'subindex' => 'admin',
		'stats' => 'admin',
		'ignoresub' => 'admin',
		'rename_list' => 'admin',
		'rename_list_request' => 'admin',
		'arc_manage' => 'admin',
		'sync_include' => 'admin',
		'ls_templates' => 'admin',
		'view_template' => 'admin',
		'remove_template' => 'admin',
		'copy_template' => 'admin',
		'edit_template' => 'admin',
#		'viewlogs' => 'admin'
);

## Regexp applied on incoming parameters (%in)
## The aim is not a strict definition of parameter format
## but rather a security check
my %in_regexp = (
		 ## Default regexp
		 '*' => '[\w\-\.]+', 
				 
		 ## List config parameters
		 'single_param' => '.+',
		 'multiple_param' => '.+',

		 ## Textarea content
		 'content' => '.+',
		 'body' => '.+',
		 'info' => '.+',
		 'new_scenario_content' => '.+',

		 ## Integer
		 'page' => '\d+',
		 'size' => '\d+',

		 ## Free data
		 'subject' => '[^<>\\\*\$]+',
		 'gecos' => '[^<>\\\*\$]+',
		 'additional_field' => '[^<>\\\*\$]+',
		 'dump' => '[^<>\\\*\$]+', # contents email + gecos

		 ## Search
		 'filter' => '[^<>\\\[\]\(\)\$]+', # search list
		 'key_word' => '[^<>\\\*\[\]\(\)\$]+',
		 'format' => '[^<>\\\$]+', # dump format/filter string

		 ## File names
		 'file' => '[^<>\*\$]+',
		 'template_path' => '[\w\-\.\/_]+',
		 'arc_file' => '[^<>\\\*\$]+',
		 'path' => '[^<>\\\*\$]+',
		 'uploaded_file' => '[^<>\*\$]+', # Could be precised (use of "'")
		 'dir' => '[^<>\\\*\$]+',
		 'name_doc' => '[^<>\\\*\$]+',
		 'shortname' => '[^<>\\\*\$]+',
		 'new_name' => '[^<>\\\*\$]+',
		 'id' => '[^<>\\\*\$]+',

		 ## URL
		 'referer' => '[^\\\$\*\"\'\`\^\|\<\>]+',
		 'failure_referer' => '[^\\\$\*\"\'\`\^\|\<\>]+',
		 'url' => '[^\\\$\*\"\'\`\^\|\<\>]+',

		 ## Msg ID
		 'msgid' => '[^\\\*\"\'\`\^\|]+',
		 'in_reply_to' => '[^\\\*\"\'\`\^\|]+',
		 'message_id' => '[^\\\*\"\'\`\^\|]+',

		 ## Password
		 'passwd' => '.+',
		 'password' => '.+',
		 'newpasswd1' => '.+',
		 'newpasswd2' => '.+',
		 'new_password' => '.+',
		 
		 ## Topics
		 'topic' => '[\w\/]+',
		 'topics' => '[\w\/]+',
		 'subtopic' => '[\w\/]+',
		 

		 ## List names
		 'list' => '[\w\-\.\+]*', ## $tools::regexp{'listname'} + uppercase
		 'previous_list' => '[\w\-\.\+]*',
		 'new_list' =>  '[\w\-\.\+]*',
		 'listname' => '[\w\-\.\+]*',
		 'new_listname' => '[\w\-\.\+]*',
		 'selected_lists' => '[\w\-\.\+]*',

		 ## Family names
		 'family_name' => $tools::regexp{'family_name'},

		 ## Email addresses
		 'email' => $tools::regexp{'email'}.'|'.$tools::regexp{'uid'},
		 'init_email' => $tools::regexp{'email'},
		 'new_alternative_email' => $tools::regexp{'email'},
		 'new_email' => $tools::regexp{'email'},
		 'pending_email' => $tools::regexp{'email'}.',.*', # Email address is followed by ',' + gecos data
		 'sender' => $tools::regexp{'email'},
		 'to' => '([\w\-\_\.\/\+\=\']+|\".*\")\s[\w\-]+(\.[\w\-]+)+',

		 ## Host
		 'new_robot' => $tools::regexp{'host'},
		 'remote_host' => $tools::regexp{'host'},
		 'remote_addr' => $tools::regexp{'host'},

		 ## Scenario name
		 'scenario' => $tools::regexp{'scenario'},
		 'read_access' => $tools::regexp{'scenario'},
		 'edit_access' => $tools::regexp{'scenario'},
                 ## RSS URL or blank
                 'active_lists' => '.*',
                 'latest_lists' => '.*',
                 'latest_arc' => '.*',
                 'latest_d_read' => '.*',

# OpenFoundry
'projectUnixName' => '.*', # TODO: should be the real regex

		 );

## Open log
$wwsconf->{'log_facility'}||= $Conf{'syslog'};

&Log::do_openlog($wwsconf->{'log_facility'}, $Conf{'log_socket_type'}, 'wwsympa');
&do_log('info', 'WWSympa started');

## Set locale configuration	 
$Language::default_lang = $Conf{'lang'};	 

## Important to leave this there because it defined defaults for user_data_source
$List::use_db = &List::check_db_connect();

my $pinfo = &List::_apply_defaults();

## Check that the data structure is uptodate
## If not, set the web interface to maintenance mode
my $maintenance_mode;
unless (&List::data_structure_uptodate()) {
    $maintenance_mode = 1;
    &do_log('notice',"Web interface set to maintenance mode");
}

&tools::ciphersaber_installed();

%::changed_params;

my (%in, $query);

my $birthday = time ;

## If using fast_cgi, it is usefull to initialize all list context
if ($wwsconf->{'use_fast_cgi'}) {

    my $all_lists = &List::get_lists('*') unless ($maintenance_mode);
}

 ## Main loop
 my $loop_count;
 my $start_time = &POSIX::strftime("%d %b %Y at %H:%M:%S", localtime(time));
 while ($query = &new_loop()) {

     undef %::changed_params;
     
     undef $param;
     undef $list;
     undef $robot;
     undef $ip;
     undef $rss;

     undef $log_level;
     $log_level = $Conf{'log_level'} if ($Conf{'log_level'}); 
     $log_level ||= 0;

     &Language::SetLang($Language::default_lang);

     ## Check effective ID
     unless ($> eq (getpwnam('--USER--'))[2]) {
	 &report::reject_report_web('intern_quiet','incorrect_server_config',{},'','');
	 &wwslog('err','Config error: wwsympa should run with UID %s (instead of %s)', (getpwnam('--USER--'))[2], $>);
     }

     unless ($List::use_db = &List::check_db_connect()) {
	 &report::reject_report_web('system_quiet','no_database',{},'','');
	 &do_log('info','WWSympa requires a RDBMS to run');
     }

     &List::init_list_cache();

     ## If in maintenance mode, check if the data structure is now uptodate
     if ($maintenance_mode && &List::data_structure_uptodate()) {
	 $maintenance_mode = undef;
	 &do_log('notice',"Data structure seem updated, setting OFF maintenance mode");
     }

     ## Get params in a hash
 #    foreach ($query->param) {
 #      $in{$_} = $query->param($_);
 #    }
     %in = $query->Vars;

     foreach my $k (keys %::changed_params) {
         &do_log('debug3', 'Changed Param: %s', $k);
     }

     ## Free terminated sendmail processes
 #    &smtp::reaper;

     ## Parse CGI parameters
 #    &CGI::ReadParse();

     if (defined $Conf{'robot_by_http_host'}{&get_header_field('SERVER_NAME')}) {
	 my ($selected_robot, $selected_path);
	 my ($k,$v);
	 while (($k, $v) = each %{$Conf{'robot_by_http_host'}{&get_header_field('SERVER_NAME')}}) {
	     if ($ENV{'REQUEST_URI'} =~ /^$k/) {
		 ## Longer path wins
		 if (length($k) > length($selected_path)) {
		     ($selected_robot, $selected_path) = ($v, $k);
		 }
	     }
	 }
	 $robot = $selected_robot;
     }
     
     $robot = $Conf{'host'} unless $robot;
 
     $param->{'cookie_domain'} = $Conf{'robots'}{$robot}{'cookie_domain'} if $Conf{'robots'}{$robot};
     $param->{'cookie_domain'} ||= $wwsconf->{'cookie_domain'};
     $ip = $ENV{'REMOTE_HOST'};
     $ip = $ENV{'REMOTE_ADDR'} unless ($ip);
     $ip = 'undef' unless ($ip);
      ## In case HTTP_HOST does not match cookie_domain
    my $http_host = &get_header_field('HTTP_HOST');
     $http_host =~ s/:\d+$//; ## suppress port
     unless (($http_host =~ /$param->{'cookie_domain'}$/) || 
             ($param->{'cookie_domain'} eq 'localhost')) {
         &wwslog('notice', 'Cookie_domain(%s) does NOT match HTTP_HOST; setting cookie_domain to %s', $param->{'cookie_domain'}, $http_host);
         $param->{'cookie_domain'} = $http_host;
     }

     $log_level = $Conf{'robots'}{$robot}{'log_level'};

     ## Sympa parameters in $param->{'conf'}
     $param->{'conf'} = {};
     foreach my $p ('email','host','sympa','request','soap_url','wwsympa_url','listmaster_email','logo_html_definition',
		    'dark_color','light_color','text_color','bg_color','error_color',
                    'selected_color','shaded_color','web_recode_to','color_0','color_1','color_2','color_3','color_4','color_5','color_6','color_7','color_8','color_9','color_10','color_11','color_12','color_13','color_14','color_15') {
	 $param->{'conf'}{$p} = &Conf::get_robot_conf($robot, $p);
	 $param->{$p} = &Conf::get_robot_conf($robot, $p) if (($p =~ /_color$/)|| ($p =~ /color_/));
     }


     foreach my $auth (keys  %{$Conf{'cas_id'}{$robot}}) {
	 &do_log('debug2', "cas authentication service $auth");
	 $param->{'sso'}{$auth} = $auth;
     }

     foreach my $auth (keys  %{$Conf{'generic_sso_id'}{$robot}}) {
	 &do_log('debug', "Generic SSO authentication service $auth");
	 $param->{'sso'}{$auth} = $Conf{'auth_services'}{$robot}[$Conf{'generic_sso_id'}{$robot}{$auth}]{'service_name'};
     }

     $param->{'sso_number'} = $Conf{'cas_number'}{$robot} + $Conf{'generic_sso_number'}{$robot};
     $param->{'use_passwd'} = $Conf{'use_passwd'}{$robot};
     $param->{'use_sso'} = 1 if ($param->{'sso_number'});
     $param->{'wwsconf'} = $wwsconf;

     $param->{'path_cgi'} = $ENV{'SCRIPT_NAME'};
     $param->{'version'} = $Version::Version;
     $param->{'date'} = &POSIX::strftime("%d %b %Y at %H:%M:%S", localtime(time));
     $param->{'time'} = &POSIX::strftime("%H:%M:%S", localtime(time));

     my $tmp_lang = &Language::GetLang();
     &Language::SetLang('en_US');
     $param->{'RFC822_date'} = &POSIX::strftime("%a, %d %b %Y %H:%M:%S %z", localtime(time));
     &Language::SetLang($tmp_lang);
     
     my @tmp_split = split(/_/,$tmp_lang);
     $param->{'ISO639_language'} = $tmp_split[0];
     
     ## Change to list root
     unless (chdir($Conf{'home'})) {
	 &report::reject_report_web('intern','chdir_error',{},'','','',$robot);
         &wwslog('info','unable to change directory');
         exit (-1);
     }

     ## Sets the UMASK
     umask(oct($Conf{'umask'}));

     ## Authentication 
     ## use https client certificat information if define.  

     ## Default auth method (for scenarios)
     $param->{'auth_method'} = 'md5';

     &report::init_report_web();

     ## Get PATH_INFO parameters
     &get_parameters();


# OpenFoundry
($ENV{HTTP_COOKIE}, $in{'FOUNDRY_ROLE'}) = foundry_auth($ENV{HTTP_COOKIE}, $in{'projectUnixName'});



     ## CSS related
     $param->{'css_path'} = &Conf::get_robot_conf($robot, 'css_path');
     $param->{'css_url'} = &Conf::get_robot_conf($robot, 'css_url');
     ## If CSS file not found, let Sympa do the job...
     unless (-f $param->{'css_path'}.'/style.css') {
 	 &wwslog('err','Could not find CSS file %s, using default CSS', $param->{'css_path'}.'/style.css');
 	 $param->{'css_url'} = $param->{'base_url'}.$param->{'path_cgi'}.'/css';
     }
     
     &wwslog('info', "parameter css_url '%s' seems strange, it must be the url of a directory not a css file", $param->{'css_url'}) if ($param->{'css_url'} =~ /\.css$/);

     ## RSS does not require user authentication
     unless ($rss) {
	 
	 if (($ENV{'SSL_CLIENT_VERIFY'} eq 'SUCCESS') &&
	     ($in{'action'} ne 'sso_login')) { ## Do not check client certificate automatically if in sso_login 
	     
	     &do_log('debug2', "SSL verified, S_EMAIL = %s,"." S_DN_Email = %s", $ENV{'SSL_CLIENT_S_EMAIL'}, $ENV{'SSL_CLIENT_S_DN_Email'});
	     if (($ENV{'SSL_CLIENT_S_EMAIL'})) {
		 ## this is the X509v3 SubjectAlternativeName, and requires
		 ## a patch to mod_ssl -- cm@coretec.at
		 $param->{'user'}{'email'} = lc($ENV{'SSL_CLIENT_S_EMAIL'});
	     }elsif ($ENV{SSL_CLIENT_S_DN_Email}) {
		 $param->{'user'}{'email'} = lc($ENV{'SSL_CLIENT_S_DN_Email'});
	     }elsif ($ENV{'SSL_CLIENT_S_DN'} =~ /\+MAIL=([^\+\/]+)$/) {
		 ## Compatibility issue with old a-sign.at certs
		 $param->{'user'}{'email'} = lc($1);
	     }
	     
	     if($param->{user}{email}) {
		 $param->{'auth_method'} = 'smime';
		 $param->{'auth'} = 'x509';
		 $param->{'ssl_client_s_dn'} = $ENV{'SSL_CLIENT_S_DN'};
		 $param->{'ssl_client_v_end'} = $ENV{'SSL_CLIENT_V_END'};
		 $param->{'ssl_client_i_dn'} =  $ENV{'SSL_CLIENT_I_DN'};
		 $param->{'ssl_cipher_usekeysize'} =  $ENV{'SSL_CIPHER_USEKEYSIZE'};
	     }
	     
	 }elsif ($ENV{'HTTP_COOKIE'} =~ /(user|sympauser)\=/) {
	     ($param->{'user'}{'email'}, $param->{'auth'}) = &wwslib::get_email_from_cookie($Conf{'cookie'});
	     
	 }elsif($in{'ticket'}=~/(S|P)T\-/){ # the request contain a CAS named ticket that use CAS ticket format
	     &cookielib::set_do_not_use_cas($wwsconf->{'cookie_domain'},0,'now'); #reset the cookie do_not_use_cas because this client probably use CAS
	     # select the cas server that redirect the user to sympa and check the ticket
	     do_log ('notice',"CAS ticket is detected. in{'ticket'}=$in{'ticket'} in{'checked_cas'}=$in{'checked_cas'}");
	     if ($in{'checked_cas'} =~ /^(\d+)\,?/) {
		 my $cas_id = $1;
		 my $ticket = $in{'ticket'};
		 my $cas_server = $Conf{'auth_services'}{$robot}[$cas_id]{'cas_server'};
		 
		 my $service_url = &wwslib::get_my_url();
		 $service_url =~ s/\&ticket\=.+$//;
		 
		 my $net_id = $cas_server->validateST($service_url, $ticket);
		 
		 if(defined $net_id) { # the ticket is valid net-id
		     do_log('notice',"login CAS OK server netid=$net_id" );
		     $param->{'user'}{'email'} = lc(&Auth::get_email_by_net_id($robot, $cas_id, {'uid' => $net_id}));
		     $param->{'auth'} = 'cas';
		     
		     &cookielib::set_cas_server($wwsconf->{'cookie_domain'},$cas_id);
		     
		     
		 }else{
		     do_log('err',"CAS ticket validation failed : %s", &CAS::get_errors()); 
		 }
	     }else{
		 do_log ('notice',"Internal error while receiving a CAS ticket $in{'checked_cas'} ");
	     }
	 }elsif(($Conf{'cas_number'}{$robot} > 0) &&
		($in{'action'} !~ /^login|sso_login|wsdl$/)) { # some cas server are defined but no CAS ticket detected
	     if (&cookielib::get_do_not_use_cas($ENV{'HTTP_COOKIE'})) {
		 &cookielib::set_do_not_use_cas($wwsconf->{'cookie_domain'},1,$Conf{'cookie_cas_expire'}); # refresh CAS cookie;
	     }else{
		 # user not taggued as not using cas
		 do_log ('debug',"no cas ticket detected");
		 foreach my $auth_service (@{$Conf{'auth_services'}{$robot}}){
		     # skip auth services not related to cas
		     next unless ($auth_service->{'auth_type'} eq 'cas');
		     next unless ($auth_service->{'non_blocking_redirection'} eq 'on');
		     
		     ## skip cas server where client as been already redirect to 
		     ## (redirection carry the list of cas servers already checked
		     &do_log ('debug',"check_cas checker_cas : $in{'checked_cas'} current cas_id $Conf{'cas_id'}{$robot}{$auth_service->{'auth_service_name'}}");
		     next if ($in{'checked_cas'} =~  /$Conf{'cas_id'}{$robot}{$auth_service->{'auth_service_name'}}/) ;
		     
		     # before redirect update the list of already checked cas server to prevent loop
		     my $cas_server = $auth_service->{'cas_server'};
		     my $return_url = &wwslib::get_my_url();
		     
		     if ($ENV{'REQUEST_URI'} =~ /checked_cas\=/) {
			 $return_url =~ s/checked_cas\=/checked_cas\=$Conf{'cas_id'}{$robot}{$auth_service->{'auth_service_name'}},/;
		     }else{		 
			 $return_url .= '?checked_cas='.$Conf{'cas_id'}{$robot}{$auth_service->{'auth_service_name'}};
		     }
		     
		     my $redirect_url = $cas_server->getServerLoginGatewayURL($return_url);
		     
		     if ($redirect_url =~ /http(s)+\:\//i) {
			 $in{'action'} = 'redirect';
			 $param->{'redirect_to'} = $redirect_url;
			 last
			 }elsif($redirect_url == -1) { # CAS server auth error
			     do_log('notice',"CAS server auth error $auth_service->{'auth_service_name'}" );
			 }else{
			     do_log('notice',"Strange CAS ticket detected and validated check sympa code !" );
			 }
		 }
		 &cookielib::set_do_not_use_cas($wwsconf->{'cookie_domain'},1,$Conf{'cookie_cas_expire'}) unless ($param->{'redirect_to'} =~ /http(s)+\:\//i) ; #set the cookie do_not_use_cas because all cas server as been checked without success
	     }
	 }
	 
	 
	 ##Cookie extern : sympa_altemails
	 ## !!
	 $param->{'alt_emails'} = &cookielib::check_cookie_extern($ENV{'HTTP_COOKIE'},$Conf{'cookie'},$param->{'user'}{'email'});
	 
	 if ($param->{'user'}{'email'}) {
#         $param->{'auth'} = $param->{'alt_emails'}{$param->{'user'}{'email'}} || 'classic';
	     
	     if (&List::is_user_db($param->{'user'}{'email'})) {
             $param->{'user'} = &List::get_user_db($param->{'user'}{'email'});
         }
	     
	     ## For the parser to display an empty field instead of [xxx]
	     $param->{'user'}{'gecos'} ||= '';
	     unless (defined $param->{'user'}{'cookie_delay'}) {
		 $param->{'user'}{'cookie_delay'} = $wwsconf->{'cookie_expire'};
	     }
	     ## get sub crition using cookie and set param for use in templates
	     #@{$param->{'get_which'}}  =  &cookielib::get_which_cookie($ENV{'HTTP_COOKIE'});
	     
	     # if no cookie was received, look for subscriptions
#         unless (defined $param->{'get_which'}) {
	     
	     
	     ## Skip get_which if either in a list context or accessing the CSS
	     unless ($in{'action'} eq 'css' || defined $in{'list'}) {
		 @{$param->{'get_which'}} = &List::get_which($param->{'user'}{'email'},$robot,'member') ; 
		 @{$param->{'get_which_owner'}} = &List::get_which($param->{'user'}{'email'},$robot,'owner') ; 
		 @{$param->{'get_which_editor'}} = &List::get_which($param->{'user'}{'email'},$robot,'editor') ; 
	     }
#         }
	     
	 }else{
	     
	     ## Get lang from cookie
	     $param->{'cookie_lang'} = &cookielib::check_lang_cookie($ENV{'HTTP_COOKIE'});
	 }
     } ## END if RSS

     ## Action
     my $action = $in{'action'};
     $action ||= $Conf{'robots'}{$robot}{'default_home'}
     if ($Conf{'robots'}{$robot});
     $action ||= $wwsconf->{'default_home'} ;
 #    $param->{'lang'} = $param->{'user'}{'lang'} || $Conf{'lang'};
     $param->{'remote_addr'} = $ENV{'REMOTE_ADDR'} ;
     $param->{'remote_host'} = $ENV{'REMOTE_HOST'};
     $param->{'http_user_agent'} = $ENV{'HTTP_USER_AGENT'};
     $param->{'htmlarea_url'} = $wwsconf->{'htmlarea_url'} ;
     # if ($wwsconf->{'export_topics'} =~ /all/i);

     if ($in{'action'} eq 'css') {
	 &do_css();
	 $param->{'action'} = 'css';
     }elsif ($maintenance_mode) {
	 &do_maintenance();
	 $param->{'action'} = 'maintenance';
     }else {
	 ## Session loop
	 while ($action) {
	     unless (&check_param_in()) {
		 &report::reject_report_web('user','wrong_param',{},$action,$list);
		 &wwslog('info','Wrong parameters');
		 last;
	     }
	     
	     $param->{'host'} = $list->{'admin'}{'host'} if (ref($list) eq 'List');
	     $param->{'host'} ||= $robot;
	     $param->{'domain'} = $list->{'domain'} if (ref($list) eq 'List');
	     
	     ## language ( $ENV{'HTTP_ACCEPT_LANGUAGE'} not used !)
	     $param->{'list_lang'} = $list->{'admin'}{'lang'} if (ref($list) eq 'List');
	     $param->{'user_lang'} = $param->{'user'}{'lang'} if (defined $param->{'user'});
	     
	     
	     $param->{'lang'} = $param->{'cookie_lang'} || $param->{'user_lang'} || 
		 $param->{'list_lang'} || &Conf::get_robot_conf($robot, 'lang');
	     $param->{'locale'} = &Language::SetLang($param->{'lang'});
	     
	     &export_topics ($robot);
	     
	     ## use default_home parameter
	     if ($action eq 'home') {
		 $action = $Conf{'robots'}{$robot}{'default_home'} || $wwsconf->{'default_home'};
		 
		 if (! &tools::get_filename('etc', 'topics.conf', $robot) &&
		     ($action eq 'home')) {
		     $action = 'lists';
		 }
	     }
	     
	     unless ($comm{$action}) {
		 &report::reject_report_web('user','unknown_action',{},$action,$list);
		 &wwslog('info','unknown action %s', $action);
		 last;
	     }
	     
	     $param->{'action'} = $action;
	 
	     my $old_action = $action;
	     
	     ## Execute the action ## 
	     $action = &{$comm{$action}}();
	 
	     delete($param->{'action'}) if (! defined $action);
	 
	     last if ($action =~ /redirect/) ; # after redirect do not send anything, it will crash fcgi lib

	     
	     if ($action eq $old_action) {
		 &wwslog('info','Stopping loop with %s action', $action);
		 #undef $action;
		 $action = 'home';
	     }

	     undef $action if ($action == 1);
	 }
     }

     ## Prepare outgoing params
     &check_param_out();

     ## Params 
     $param->{'action_type'} = $action_type{$param->{'action'}};
     $param->{'action_type'} = 'none' unless ($param->{'is_priv'});

     $param->{'lang'} ||= $param->{'cookie_lang'};
     $param->{'lang'} ||= $param->{'user'}{'lang'} if (defined $param->{'user'});
     $param->{'lang'} ||= &Conf::get_robot_conf($robot, 'lang');

     if ($param->{'list'}) {
	 $param->{'list_title'} = $list->{'admin'}{'subject'};
	 $param->{'list_protected_email'} = &get_protected_email_address($param->{'list'}, $list->{'admin'}{'host'});
	 $param->{'title'} = &get_protected_email_address($param->{'list'}, $list->{'admin'}{'host'});
	 $param->{'title_clear_txt'} = "$param->{'list'}";

	 if ($param->{'subtitle'}) {
	     $param->{'main_title'} = "$param->{'list'} - $param->{'subtitle'}";
	 }

     }else {
	 $param->{'main_title'} = $param->{'title'} = &Conf::get_robot_conf($robot,'title');
	 $param->{'title_clear_txt'} = $param->{'title'};
     }
     $param->{'robot_title'} = &Conf::get_robot_conf($robot,'title');

     ## Do not manage cookies at this level if content was already sent
     unless ($param->{'bypass'} eq 'extreme' || 
	     $param->{'action'} eq 'css' || 
	     $maintenance_mode ||
	     $rss) {

	 ## Set cookies "your_subscribtions" unless in one list page
	 if ($param->{'user'}{'email'} && ref($list) ne 'List') {

	     ## In case get_which was not set
	     @{$param->{'get_which'}} = &List::get_which($param->{'user'}{'email'},$robot,'member') unless (defined $param->{'get_which'}); 
	     @{$param->{'get_which_owner'}} = &List::get_which($param->{'user'}{'email'},$robot,'owner')  unless (defined $param->{'get_which_owner'}); 
	     @{$param->{'get_which_editor'}} = &List::get_which($param->{'user'}{'email'},$robot,'editor')  unless (defined $param->{'get_which_editor'}); 	     

	     # if at least one element defined in get_which tab
	     &cookielib::set_which_cookie ($wwsconf->{'cookie_domain'},@{$param->{'get_which'}});

	     ## Add lists information to 'which_info'
	     foreach my $list (@{$param->{'get_which'}}) {
		 ## Evaluate AuthZ scenario first
		 my $result = $list->check_list_authz('visibility', $param->{'auth_method'},
						      {'sender' =>$param->{'user'}{'email'} ,
						       'remote_host' => $param->{'remote_host'},
						       'remote_addr' => $param->{'remote_addr'}});
		 next unless (ref($result) eq 'HASH' && $result->{'action'} eq 'do_it');

		 my $l = $list->{'name'};

		 $param->{'which_info'}{$l}{'subject'} = $list->{'admin'}{'subject'};
		 $param->{'which_info'}{$l}{'host'} = $list->{'admin'}{'host'};
		 $param->{'which_info'}{$l}{'info'} = 1;
	     }
	     foreach my $list (@{$param->{'get_which_owner'}}) {
		 my $l = $list->{'name'};

		 $param->{'which_info'}{$l}{'subject'} = $list->{'admin'}{'subject'};
		 $param->{'which_info'}{$l}{'host'} = $list->{'admin'}{'host'};
		 $param->{'which_info'}{$l}{'info'} = 1;
		 $param->{'which_info'}{$l}{'admin'} = 1;
	     }
	     foreach my $list (@{$param->{'get_which_editor'}}) {
		 my $l = $list->{'name'};

		 $param->{'which_info'}{$l}{'subject'} = $list->{'admin'}{'subject'};
		 $param->{'which_info'}{$l}{'host'} = $list->{'admin'}{'host'};
		 $param->{'which_info'}{$l}{'info'} = 1;
		 $param->{'which_info'}{$l}{'admin'} = 1;
	     }
	 }
	 ## Set cookies unless client use https authentication
	 if ($param->{'user'}{'email'}) {
	     if ($param->{'user'}{'email'} ne 'x509') {
		 my $delay = $param->{'user'}{'cookie_delay'};
		 unless (defined $delay) {
		     $delay = $wwsconf->{'cookie_expire'};
		 }
		 
		 if ($delay == 0) {
		     $delay = 'session';
		 }
		 
		 $param->{'auth'} ||= 'classic';
		 
		 unless (&cookielib::set_cookie($param->{'user'}{'email'}, $Conf{'cookie'}, $param->{'cookie_domain'},$delay, $param->{'auth'} )) {
		     &wwslog('notice', 'Could not set HTTP cookie');
		     exit -1;
		 }
		 $param->{'cookie_set'} = 1;
		 
		 ##Cookie extern : sympa_altemails
		 my $number = 0;
		 foreach my $element (keys %{$param->{'alt_emails'}}){
		     $number ++ if ($element);
		 }  
		 $param->{'unique'} = 1 if($number <= 1);
		 
		 unless ($number == 0) {
		     unless(&cookielib::set_cookie_extern($Conf{'cookie'},$param->{'cookie_domain'},%{$param->{'alt_emails'}})){
			 &wwslog('notice', 'Could not set HTTP cookie for external_auth');
		     }
		 }
	     }
	 }elsif ($ENV{'HTTP_COOKIE'} =~ /sympauser\=/){
	     &cookielib::set_cookie('unknown', $Conf{'cookie'}, $param->{'cookie_domain'}, 'now');
	 }
     }
	 
     ## Available languages
     my $saved_lang = &Language::GetLang();

     # Recode the language strings to the correct codeset
     &Language::set_recode ($Conf{'web_recode_to'} || &Language::gettext('_charset_'));
     
     foreach my $l (@{&Language::GetSupportedLanguages($robot)}) {
	 &Language::SetLang($l) || next;

	 ## Decode from the language charset...later we will encode to the appropriate encoding
	 $param->{'languages'}{$l}{'complete'} = &Encode::decode(gettext("_charset_"), gettext("_language_"));

	 if ($param->{'locale'} eq $l) {
	     $param->{'languages'}{$l}{'selected'} = 'selected="selected"';
	 }else {
	     $param->{'languages'}{$l}{'selected'} = '';
	 }
     }
     &Language::set_recode (); ## Unset recoding
     &Language::SetLang($saved_lang);

     ## Encode language names to the current charset
     foreach my $l (keys %{$param->{'languages'}}) {
	 $param->{'languages'}{$l}{'complete'} = &Encode::encode(gettext("_charset_"), $param->{'languages'}{$l}{'complete'});
     }

     # if bypass is defined select the content-type from various vars
     if ($param->{'bypass'}) {

	## if bypass = 'extreme' leave the action send the content-type and the content itself
	unless ($param->{'bypass'} eq 'extreme') {

	     ## if bypass = 'asis', file content-type is in the file itself as is define by the action in $param->{'content_type'};
	     unless ($param->{'bypass'} eq 'asis') {
		 my $type = $param->{'content_type'} || $mime_types->{$param->{'file_extension'}} || 'application/octet-stream';
		 printf "Content-Type: %s\n\n", $type;
	     }

	     #  $param->{'file'} or $param->{'error'} must be define in this case.

	     if (open (FILE, $param->{'file'})){
		 print <FILE>;
		 close FILE;
	     }elsif(&report::is_there_any_reject_report_web()){
		 ## for compatibility : it could be better
		 my $intern = &report::get_intern_error_web();
		 my $system =  &report::get_system_error_web();
		 my $user = &report::get_user_error_web();
		 my $auth = &report::get_auth_reject_web();
		
		 if (ref($intern) eq 'ARRAY'){
		     printf "INTERNAL SERVER ERROR\n";
		 };
		 if (ref($system) eq 'ARRAY'){
		     printf "SYSTEM ERROR\n";
		 };
		 if (ref($user) eq 'ARRAY'){
		     foreach my $err (@$user){
			 printf "ERROR : $err\n";
		     }
		 };
		 if (ref($user) eq 'ARRAY'){
		     foreach my $err (@$auth){
			 printf "NON UTHORISATION : $err\n";
		     }
		 };

	     }else{
		 printf "Internal error content-type nor file defined\n";
		 &do_log('err', 'Internal error content-type nor file defined');
	     }
	 }

      }elsif ($rss) {
 	 ## Send RSS 
 	 print "Cache-control: no-cache\n";
 	 my $charset = gettext("_charset_");
 	 print "Content-Type: application/rss+xml; charset=$charset\n\n";
 
 	 ## Icons
 	 $param->{'icons_url'} = $wwsconf->{'icons_url'};
 
 	 ## Retro compatibility concerns
 	 $param->{'active'} = 1;
 
 	 if (defined $list) {
 	     $param->{'list_conf'} = $list->{'admin'};
 	 }

	 my $lang = &Language::Lang2Locale($param->{'lang'});
	 my $tt2_include_path = &tools::make_tt2_include_path($robot,'web_tt2',$lang,$list);
	 
	 ## Recode to utf-8 for RSS
	 my $tt2_options = {};
	 if ($Conf{'web_recode_to'}) {
	     $tt2_options =  {'recode' => $Conf{'web_recode_to'}};
	 }    

 	 unless (&tt2::parse_tt2($param,'rss.tt2' ,\*STDOUT, $tt2_include_path, $tt2_options)) {
 	     my $error = &tt2::get_error();
 	     $param->{'tt2_error'} = $error;
 	     unless (&List::send_notify_to_listmaster('web_tt2_error', $robot, [$error])) {
 		 &wwslog('notice','Unable to send notify "web_tt2_error" to listmaster');
 	     }
 	 }
# 	 close FILE;
     }elsif ($param->{'redirect_to'}) {
	 do_log ('debug',"Redirecting to $param->{'redirect_to'}");
	 print "Location: $param->{'redirect_to'}\n\n";
     }else {
	 &prepare_report_user();
	 &send_html('main.tt2');
     }    

     # exit if wwsympa.fcgi itself has changed
     if ((stat($ENV{'SCRIPT_FILENAME'}))[9] > $birthday ) {
	  do_log('notice',"Exiting because $ENV{'SCRIPT_FILENAME'} has changed since fastcgi server started");
	  exit(0);
     }

 }

 ##############################################################
 #-#\#|#/#-#\#|#/#-#\#|#/#-#\#|#/#-#\#|#/#-#\#|#/#-#\#|#/#-#\#|#/
 ##############################################################


 ## Write to log
 sub wwslog {
     my $facility = shift;
     my $msg = shift;

     my $remote = $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'};

     $msg = "[list $param->{'list'}] " . $msg
	 if $param->{'list'};

	
     if ($param->{'alt_emails'}) {
	 my @alts;
	 foreach my $alt (keys %{$param->{'alt_emails'}}) {
	     push @alts, $alt
		 unless ($alt eq $param->{'user'}{'email'});
	 }

	 if ($#alts >= 0) {
	     my $alt_list = join ',', @alts;
	     $msg = "[alt $alt_list] " . $msg;
	 }
     }

     $msg = "[user $param->{'user'}{'email'}] " . $msg
	 if $param->{'user'}{'email'};

     $msg = "[rss] ".$msg
	 if $rss;

     $msg = "[client $remote] ".$msg
	 if $remote;

     $msg = "[robot $robot] ".$msg;

     return &Log::do_log($facility, $msg, @_);
 }


 sub new_loop {
     $loop++;
     my $query;

     if ($wwsconf->{'use_fast_cgi'}) {
	 $query = new CGI::Fast;
	 $loop_count++;
     }else {	
	 return undef if ($loop > 1);

	 $query = new CGI;
     }

     return $query;
 }

sub get_header_field {
    my $field = shift;

    ## HTTP_X_ header fields set when using a proxy
    if ($field eq 'SERVER_NAME') {
	return $ENV{'HTTP_X_FORWARDED_SERVER'} || $ENV{'SERVER_NAME'};
    }elsif ($field eq 'HTTP_HOST') {
	return $ENV{'HTTP_X_FORWARDED_HOST'} || $ENV{'HTTP_HOST'};
    }else {
	return $ENV{$field};
    }
}

 sub get_parameters {
 #    &wwslog('debug4', 'get_parameters');

     ## CGI URL
     if ($ENV{'HTTPS'} eq 'on') {
	 $param->{'base_url'} = sprintf 'https://%s', &get_header_field('HTTP_HOST');
	 $param->{'use_ssl'} = 1;
     }else {
	 $param->{'base_url'} = sprintf 'http://%s', &get_header_field('HTTP_HOST');
	 $param->{'use_ssl'} = 0;
     }

     $param->{'path_info'} = $ENV{'PATH_INFO'};
     $param->{'robot_domain'} = $wwsconf->{'robot_domain'}{&get_header_field('SERVER_NAME')};


     if ($ENV{'REQUEST_METHOD'} eq 'GET') {
	 my $path_info = $ENV{'PATH_INFO'};
	 &do_log('debug', "PATH_INFO: %s",$ENV{'PATH_INFO'});

	 $path_info =~ s+^/++;

	 my $ending_slash = 0;
	 if ($path_info =~ /\/$/) {
	     $ending_slash = 1;
	 }

	 my @params = split /\//, $path_info;

 #	foreach my $i(0..$#params) {
 #	    $params[$i] = &tools::unescape_chars($params[$i]);
 #	}

	 if ($params[0] eq 'nomenu') {
	     $param->{'nomenu'} = 1;
	     shift @params;
	 }

	 ## debug mode
	 if ($params[0] =~ /debug(\d)?/) {
	     shift @params;
	     if ($1) { 
		 $main::options{'debug_level'} = $1 if ($1);
	     }else{
		 $main::options{'debug_level'} = 1 ;
	     }
	 }else{
	     $main::options{'debug_level'} = 0 ;
	 } 
	 do_log ('debug2', "debug level $main::options{'debug_level'}");



	 ## rss mode
########### /^rss$/ ???
	 if ($params[0] eq 'rss') {
	     shift @params;
	     $rss = 1;
	 } 

	 if ($#params >= 0) {
	     $in{'action'} = $params[0];

	     my $args;
	     if (defined $action_args{$in{'action'}}) {
		 $args = $action_args{$in{'action'}};
	     }else {
		 $args = $action_args{'default'};
	     }

	     my $i = 1;
	     foreach my $p (@$args) {
		 my $pname;
		 ## More than 1 param
		 if ($p =~ /^\@(\w+)$/) {
		     $pname = $1;

		     $in{$pname} = join '/', @params[$i..$#params];
		     $in{$pname} .= '/' if $ending_slash;
		     last;
		 }else {
		     $pname = $p;
		     $in{$pname} = $params[$i];
		 }
		 $i++;
	     }
	 }
     }elsif ($ENV{'REQUEST_METHOD'} eq 'POST') {
	 ## POST

	 if ($in{'javascript_action'}) { 
	     ## because of incompatibility javascript
	     $in{'action'} = $in{'javascript_action'};
	 }
	 foreach my $p (keys %in) {
	     do_log('debug2',"POST key $p value $in{$p}");
	     if ($p =~ /^action_(\w+)((\.\w+)*)$/) {
		 
		 $in{'action'} = $1;
		 if ($2) {
		     foreach my $v (split /\./, $2) {
			 $v =~ s/^\.?(\w+)\.?/$1/;
			 $in{$v} = 1;
		     }
		 }

		 undef $in{$p};
	     }
	 }

	 $param->{'nomenu'} = $in{'nomenu'};
     }	

     ## Lowercase email addresses
     $in{'email'} = lc ($in{'email'});

     ## Don't get multiple listnames
     if ($in{'list'}) {
	 my @lists = split /\0/, $in{'list'};
	 $in{'list'} = $lists[0];
     }

     ## Check parameters format
     foreach my $p (keys %in) {

	 ## Skip empty parameters
 	 next if ($in{$p} =~ /^$/);

	 ## Remove DOS linefeeds (^M) that cause problems with Outlook 98, AOL, and EIMS:
	 $in{$p} =~ s/\015//g;	 

	 ## Convert from the web encoding to unicode string
	 if ($Conf{'web_recode_to'}){ 
	     if (require "Encode.pm") {
		 $p = &Encode::decode($Conf{'web_recode_to'}, $p);
	     }
	 }

	 my @tokens = split /\./, $p;
	 my $pname = $tokens[0];
	 my $regexp;
	 if ($pname =~ /^additional_field/) {
	     $regexp = $in_regexp{'additional_field'};
	 }elsif ($in_regexp{$pname}) {
	     $regexp = $in_regexp{$pname};
	     }else {
		 $regexp = $in_regexp{'*'};
	     }
	 foreach my $one_p (split /\0/, $in{$p}) {
	     unless ($one_p =~ /^$regexp$/m) {
		 ## Dump parameters in a tmp file for later analysis
		 my $dump_file =  &Conf::get_robot_conf($robot, 'tmpdir').'/sympa_dump.'.time.'.'.$$;
		 unless (open DUMP, ">$dump_file") {
		     &wwslog('err','get_parameters: failed to create %s : %s', $dump_file, $!);		     
		 }
		 &tools::dump_var(\%in, 0, \*DUMP);
		 close DUMP;

		 &report::reject_report_web('user','syntax_errors',{'params' => $p},'','');
		 &wwslog('err','get_parameters: syntax error for parameter %s value \'%s\' not conform to regexp /^%s$/ ; dumped vars in %s', $pname, $one_p, $regexp,  $dump_file);
		 $in{$p} = '';
		 next;
	     }
	 }
     }

     return 1;
 }

## Send HTML output
sub send_html {

    my $tt2_file = shift;

    ## Send HTML
    if ($param->{'date'}) {
	printf "Date: %s\n", &POSIX::strftime('%a, %d %b %Y %R %z',localtime($param->{'date'}));
    }
    print "Cache-control: no-cache\n"  unless ( $param->{'action'} eq 'arc')  ;
    print "Content-Type: text/html\n\n";
    
    ## Icons
    $param->{'icons_url'} = $wwsconf->{'icons_url'};
    
    
    ## Retro compatibility concerns
    $param->{'active'} = 1;
    
    if (defined $list) {
	$param->{'list_conf'} = $list->{'admin'};
    }
    
    my $lang = &Language::Lang2Locale($param->{'lang'});
    my $tt2_include_path = &tools::make_tt2_include_path($robot,'web_tt2',$lang,$list);
    
    my $tt2_options = {};
    if ($Conf{'web_recode_to'}) {
	$tt2_options =  {'recode' => $Conf{'web_recode_to'}};
    }
    
    unless (&tt2::parse_tt2($param,$tt2_file , \*STDOUT, $tt2_include_path, $tt2_options)) {
	my $error = &tt2::get_error();
	$param->{'tt2_error'} = $error;
	&List::send_notify_to_listmaster('web_tt2_error', $robot, [$error]);
	&tt2::parse_tt2($param,'tt2_error.tt2' , \*STDOUT, $tt2_include_path);
    }
    
}

sub prepare_report_user {
    
    $param->{'intern_errors'} = &report::get_intern_error_web();
    $param->{'system_errors'} = &report::get_system_error_web();
    $param->{'user_errors'} = &report::get_user_error_web();
    $param->{'auth_rejects'} = &report::get_auth_reject_web();
    $param->{'notices'} = &report::get_notice_web();
    $param->{'errors'} = &report::is_there_any_reject_report_web();
}
    
    


 ## Analysis of incoming parameters
 sub check_param_in {
     &wwslog('debug2', 'check_param_in');

     ## Lowercase list name
     $in{'list'} =~ tr/A-Z/a-z/;

     ## In case the variable was multiple
     if ($in{'list'} =~ /^(\S+)\0/) {
	 $in{'list'} = $1;

	 unless ($list = new List ($in{'list'}, $robot)) {
	     &report::reject_report_web('user','unknown_list',{'list' => $in{'list'}},$param->{'action'},'');
	     &wwslog('info','check_param_in: unknown list %s', $in{'list'});
	     return undef;
	 }

	 ## Set lang to list lang
	 &Language::SetLang($list->{'admin'}{'lang'});
     }

     ## listmaster has owner and editor privileges for the list
     if (&List::is_listmaster($param->{'user'}{'email'},$robot)) {
	 $param->{'is_listmaster'} = 1;
     }

    if ($in{'list'}) {
	unless ($list = new List ($in{'list'}, $robot, {})) {
	    &report::reject_report_web('user','unknown_list',{'list' => $in{'list'}},$param->{'action'},'');
	    &wwslog('info','check_param_in: unknown list %s', $in{'list'});
	    return undef;
	}

	$param->{'list'} = $in{'list'};
	$param->{'subtitle'} = $list->{'admin'}{'subject'};
	$param->{'subscribe'} = $list->{'admin'}{'subscribe'}{'name'};
	$param->{'send'} = $list->{'admin'}{'send'}{'title'}{$param->{'lang'}};
	if (defined $param->{'total'}) {
	    $param->{'total'} = $list->get_total();
	}else {
	    $param->{'total'} = $list->get_total('nocache');
	}
	$param->{'list_as_x509_cert'} = $list->{'as_x509_cert'};
	$param->{'listconf'} = $list->{'admin'};

	## privileges
	if ($param->{'user'}{'email'}) {
	    $param->{'is_subscriber'} = $list->is_user($param->{'user'}{'email'});
	    $param->{'subscriber'} = $list->get_subscriber($param->{'user'}{'email'})
		if $param->{'is_subscriber'};
	    $param->{'is_privileged_owner'} = $param->{'is_listmaster'} || $list->am_i('privileged_owner', $param->{'user'}{'email'});
	    $param->{'is_owner'} = $param->{'is_privileged_owner'} || $list->am_i('owner', $param->{'user'}{'email'});
	    $param->{'is_editor'} = $list->am_i('editor', $param->{'user'}{'email'});
	    $param->{'is_priv'} = $param->{'is_owner'} || $param->{'is_editor'};

	    #May post:
	    my $result = $list->check_list_authz('send',$param->{'auth_method'},
						 {'sender' => $param->{'user'}{'email'},
						  'remote_host' => $param->{'remote_host'},
						  'remote_addr' => $param->{'remote_addr'}});
	    my $r_action;
	    $r_action = $result->{'action'} if (ref($result) eq 'HASH');
	    $param->{'may_post'} = 1 if ($r_action !~ /reject/);

	}else {
	    $param->{'user'}{'email'} = undef;
	    $param->{'need_login'} = 1;

	}

	$param->{'is_moderated'} = $list->is_moderated();
	$param->{'is_shared_open'} =$list->is_shared_open();

	## Privileged info

	if ($param->{'is_priv'}) {
	    $param->{'mod_message'} = $list->get_mod_spool_size();

            $param->{'mod_subscription'} = $list->get_subscription_request_count();
	   
	    $param->{'doc_mod_list'} = $list->get_shared_moderated();
	    $param->{'mod_total_shared'} = $#{$param->{'doc_mod_list'}} + 1;

	    if ($param->{'total'} > 0) {
		$param->{'bounce_total'} = $list->get_total_bouncing();
		$param->{'bounce_rate'} = $param->{'bounce_total'} * 100 / $param->{'total'};
		$param->{'bounce_rate'} = int ($param->{'bounce_rate'} * 10) / 10;
	    }else {
		$param->{'bounce_rate'} = 0;
	    }
	    $param->{'mod_total'} = $param->{'mod_total_shared'}+$param->{'mod_message'}+$param->{'mod_subscription'};
	}

	## (Un)Subscribing 
	if ($list->{'admin'}{'user_data_source'} eq 'include') {
	    $param->{'may_signoff'} = $param->{'may_suboptions'} = $param->{'may_subscribe'} = 0;
	}else {
	    ## May signoff
	    my $result = $list->check_list_authz('unsubscribe',$param->{'auth_method'},
						 {'sender' =>$param->{'user'}{'email'},
						  'remote_host' => $param->{'remote_host'},
						  'remote_addr' => $param->{'remote_addr'}});
	    $main::action = $result->{'action'} if (ref($result) eq 'HASH');
	    
	    if (! $param->{'user'}{'email'}) {
		$param->{'may_signoff'} = 1 if ($main::action =~ /do_it|owner|request_auth/);
		
	    }elsif ($param->{'is_subscriber'} &&
		    ($param->{'subscriber'}{'subscribed'} == 1)) {
		$param->{'may_signoff'} = 1 if ($main::action =~ /do_it|owner|request_auth/);
		$param->{'may_suboptions'} = 1;
	    }
	    
	    ## May Subscribe
	    my $result = $list->check_list_authz('subscribe',$param->{'auth_method'},
						 {'sender' =>$param->{'user'}{'email'},
						  'remote_host' => $param->{'remote_host'},
						  'remote_addr' => $param->{'remote_addr'}});
	    $main::action = $result->{'action'} if (ref($result) eq 'HASH');
	    
	    $param->{'may_subscribe'} = 1 if ($main::action =~ /do_it|owner|request_auth/);
	}
	
    	## Shared documents
	my %mode;
	$mode{'read'} = 1;
	my %access = &d_access_control(\%mode,"");
	$param->{'may_d_read'} = $access{'may'}{'read'};

	if (-e $list->{'dir'}.'/shared') {
	    $param->{'shared'}='exist';
	}elsif (-e $list->{'dir'}.'/pending.shared') {
	    $param->{'shared'}='deleted';
	}else{
	    $param->{'shared'}='none';
	}
    }

     my $result = &List::request_action ('create_list',$param->{'auth_method'},$robot,
					 {'sender' => $param->{'user'}{'email'},
					  'remote_host' => $param->{'remote_host'},
					  'remote_addr' => $param->{'remote_addr'}}); 
     my $r_action;
     my $reason;
     if (ref($result) eq 'HASH') {
	 $r_action = $result->{'action'};
	 $reason = $result->{'reason'};
     }
     $param->{'create_list_reason'} = $reason;

     if ($param->{'user'}{'email'} && 
	 (($param->{'create_list'} = $r_action ) =~ /do_it|listmaster/)
# OpenFoundry
&& ($in{'FOUNDRY_ROLE'} eq 'Admin')   ) {
	 $param->{'may_create_list'} = 1;
     }else{
	 undef ($param->{'may_create_list'});
     }

     return 1;

 }

 ## Prepare outgoing params
 sub check_param_out {
     &wwslog('debug2', 'check_param_out');

     $param->{'loop_count'} = $loop_count;
     $param->{'start_time'} = $start_time;
     $param->{'process_id'} = $$;

     ## Email addresses protection
     if (&Conf::get_robot_conf($robot,'spam_protection') eq 'at') {
	 $param->{'hidden_head'} = '';	$param->{'hidden_at'} = ' AT ';	$param->{'hidden_end'} = '';
     }elsif(&Conf::get_robot_conf($robot,'spam_protection') eq 'javascript') {
	 $param->{'protection_type'} = 'javascript';
	 $param->{'hidden_head'} = '
 <script type="text/javascript">
 <!-- 
 document.write("';
		 $param->{'hidden_at'} ='" + "@" + "';
		 $param->{'hidden_end'} ='")
 // -->
 </script>';
     }else {
	 $param->{'hidden_head'} = '';	$param->{'hidden_at'} = '@';	$param->{'hidden_end'} = '';
     }

     ## listmaster has owner and editor privileges for the list
     if (&List::is_listmaster($param->{'user'}{'email'},$robot)) {
	 $param->{'is_listmaster'} = 1;
     }else {
	 undef $param->{'is_listmaster'};
     }

     if ($list->{'name'}) {
	 &wwslog('debug2', "list-name $list->{'name'}");

	 ## Email addresses protection
 	 if ($in{'action'} eq 'arc') {
	     $param->{'protection_type'} = undef;
	     if ($list->{'admin'}{'web_archive_spam_protection'} eq 'at') {
		 $param->{'hidden_head'} = '';	$param->{'hidden_at'} = ' AT ';	$param->{'hidden_end'} = '';
	     }elsif($list->{'admin'}{'web_archive_spam_protection'} eq 'javascript') {
		 $param->{'protection_type'} = 'javascript';
		 $param->{'hidden_head'} = '
 <script type="text/javascript">
 <!-- 
 document.write("';
		 $param->{'hidden_at'} ='" + "@" + "';
		 $param->{'hidden_end'} ='")
 // -->
 </script>';
	     }else {
		 $param->{'hidden_head'} = '';	$param->{'hidden_at'} = '@';	$param->{'hidden_end'} = '';
	     }
	 }else {
	     if ($list->{'admin'}{'spam_protection'} eq 'at') {
		 $param->{'hidden_head'} = '';	$param->{'hidden_at'} = ' AT ';	$param->{'hidden_end'} = '';
	     }elsif($list->{'admin'}{'spam_protection'} eq 'javascript') {
		 $param->{'hidden_head'} = '
 <script type="text/javascript">
 <!-- 
 document.write("';
		 $param->{'hidden_at'} ='" + "@" + "';
		 $param->{'hidden_end'} ='")
 // -->
 </script>';
	     }else {
		 $param->{'hidden_head'} = '';	$param->{'hidden_at'} = '@';	$param->{'hidden_end'} = '';
	     }	     
	 }
 
	 ## Owners
	 my $owners = $list->get_owners();
	 foreach my $o (@{$owners}) {
	     next unless $o->{'email'};
	     $param->{'owner'}{$o->{'email'}}{'gecos'} = $o->{'gecos'};
	     $param->{'owner'}{$o->{'email'}}{'mailto'} = &mailto($list,$o->{'email'},$o->{'gecos'});
	     ($param->{'owner'}{$o->{'email'}}{'local'},$param->{'owner'}{$o->{'email'}}{'domain'}) = split ('@',$o->{'email'});
	     my $masked_email = $o->{'email'};
	     $masked_email =~ s/\@/ AT /;
	     $param->{'owner'}{$o->{'email'}}{'masked_email'} = $masked_email;
	 }

	 ## Editors
	 if (defined $list->{'admin'}{'editor'}) {
	     my $editors = $list->get_editors();
	     foreach my $e (@{$editors}) {
		 next unless $e->{'email'};
		 $param->{'editor'}{$e->{'email'}}{'gecos'} = $e->{'gecos'};
		 $param->{'editor'}{$e->{'email'}}{'mailto'} = &mailto($list,$e->{'email'},$e->{'gecos'});
		 ($param->{'editor'}{$e->{'email'}}{'local'},$param->{'editor'}{$e->{'email'}}{'domain'}) = split ('@',$e->{'email'});
		 my $masked_email = $e->{'email'};
		 $masked_email =~ s/\@/ AT /;
		 $param->{'editor'}{$e->{'email'}}{'masked_email'} = $masked_email;
	     }  
	 }

	 ## Environment variables
	 foreach my $k (keys %ENV) {
	     $param->{'env'}{$k} = $ENV{$k};
	 }

	## privileges
	if ($param->{'user'}{'email'}) {
	    $param->{'is_subscriber'} = $list->is_user($param->{'user'}{'email'});
	    $param->{'subscriber'} = $list->get_subscriber($param->{'user'}{'email'})
		if $param->{'is_subscriber'};
	    $param->{'is_privileged_owner'} = $param->{'is_listmaster'} || $list->am_i('privileged_owner', $param->{'user'}{'email'});
	    $param->{'is_owner'} = $param->{'is_privileged_owner'} || $list->am_i('owner', $param->{'user'}{'email'});
	    $param->{'is_editor'} = $list->am_i('editor', $param->{'user'}{'email'});
	    $param->{'is_priv'} = $param->{'is_owner'} || $param->{'is_editor'};

	    #May post:
	    my $result = $list->check_list_authz('send',$param->{'auth_method'},
						 {'sender' => $param->{'user'}{'email'},
						  'remote_host' => $param->{'remote_host'},
						  'remote_addr' => $param->{'remote_addr'}});

	    my $r_action;
	    my $reason;
	    if (ref($result) eq 'HASH') {
		$r_action = $result->{'action'};
		$reason = $result->{'reason'};
	    }
	    
	    if ($r_action =~ /do_it/) {
		$param->{'may_post'} = 1 ;
	    }else {
		$param->{'may_post_reason'} = $reason;
	    }
	    
	    
 	    if (($list->{'admin'}{'user_data_source'} eq 'include2') &&
		$list->has_include_data_sources() &&
		$param->{'is_owner'}) {
		$param->{'may_sync'} = 1;
	    }
	}else {
	    ## If user not logged in && GET method && not an authN-related action
	    ## Keep track of the 'referer' parameter
	    if ($ENV{'REQUEST_METHOD'} eq 'GET' &&
		! $auth_action{$in{'action'}} ) {
		$param->{'referer'} = &tools::escape_chars(&wwslib::get_my_url());
	    }else {
		## Keep the previous value of the referer
		$param->{'referer'} = $in{'referer'};
	    }
	}

	 ## Should Not be used anymore ##
	 $param->{'may_subunsub'} = 1 
	     if ($param->{'may_signoff'} || $param->{'may_subscribe'});

	 ## May review
	 my $result = $list->check_list_authz('review',$param->{'auth_method'},
					      {'sender' => $param->{'user'}{'email'},
					       'remote_host' => $param->{'remote_host'},
					       'remote_addr' => $param->{'remote_addr'}});
	 my $r_action;
	 $r_action = $result->{'action'} if (ref($result) eq 'HASH');

	 $param->{'may_suboptions'} = 1 unless ($list->{'admin'}{'user_data_source'} eq 'include');
	 $param->{'total'} = $list->get_total();
	 $param->{'may_review'} = 1 if ($r_action =~ /do_it/);

	## (Un)Subscribing 
	if ($list->{'admin'}{'user_data_source'} eq 'include') {
	    $param->{'may_signoff'} = $param->{'may_suboptions'} = $param->{'may_subscribe'} = 0;
	}else {
	    ## May signoff
	    my $result = $list->check_list_authz('unsubscribe',$param->{'auth_method'},
						 {'sender' =>$param->{'user'}{'email'},
						  'remote_host' => $param->{'remote_host'},
						  'remote_addr' => $param->{'remote_addr'}});
	    $main::action = $result->{'action'} if (ref($result) eq 'HASH');
	    
	    if (! $param->{'user'}{'email'}) {
		$param->{'may_signoff'} = 1 if ($main::action =~ /do_it|owner|request_auth/);
		
	    }elsif ($param->{'is_subscriber'} &&
		    ($param->{'subscriber'}{'subscribed'} == 1)) {
		$param->{'may_signoff'} = 1 if ($main::action =~ /do_it|owner|request_auth/);
		$param->{'may_suboptions'} = 1;
	    }
	    
	    ## May Subscribe
	    my $result = $list->check_list_authz('subscribe',$param->{'auth_method'},
						 {'sender' =>$param->{'user'}{'email'},
						  'remote_host' => $param->{'remote_host'},
						  'remote_addr' => $param->{'remote_addr'}});
	    $main::action = $result->{'action'} if (ref($result) eq 'HASH');
	    
	    $param->{'may_subscribe'} = 1 if ($main::action =~ /do_it|owner|request_auth/);

	}

	 ## Archives Access control
	 if (defined $list->{'admin'}{'web_archive'}) {
	     $param->{'is_archived'} = 1;

	     
	     my $result = $list->check_list_authz('web_archive.access',$param->{'auth_method'},
						  {'sender' => $param->{'user'}{'email'},
						   'remote_host' => $param->{'remote_host'},
						   'remote_addr' => $param->{'remote_addr'}});
	     my $r_action;
	     $r_action = $result->{'action'} if (ref($result) eq 'HASH');

	     if ($r_action =~ /do_it/i) {
		 $param->{'arc_access'} = 1; 
	     }else{
		 undef ($param->{'arc_access'});
	     }
	 }	
     }

     $param->{'robot'} = $robot;

 }

 ## Login WWSympa
 sub do_login {
     &wwslog('info', 'do_login(%s)', $in{'email'});
     my $user;
     my $next_action;     

     if ($in{'referer'}) {
	 $param->{'redirect_to'} = &tools::unescape_chars($in{'referer'});
     }elsif ($in{'previous_action'} && 
	     $in{'previous_action'} !~ /^login|logout|loginrequest$/) {
	 $next_action = $in{'previous_action'};
	 $in{'list'} = $in{'previous_list'};
     }else {
	 $next_action = 'home';
     }
      # never return to login or logout when login.
      $next_action = 'home' if ($in{'next_action'} eq 'login') ;
      $next_action = 'home' if ($in{'next_action'} eq 'logout') ;

     if ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','already_login',{'email' => $param->{'user'}{'email'}},$param->{'action'},'');
	 &wwslog('info','do_login: user %s already logged in', $param->{'user'}{'email'});

	 if ($param->{'nomenu'}) {
	     $param->{'back_to_mom'} = 1;
	     return 1;
	 }else {
	     return $next_action;
	 }
     }     

     unless ($in{'email'}) {
	 &report::reject_report_web('user','no_email',{},$param->{'action'},'');
	 &wwslog('info','do_login: no email');
	 # &List::db_log('wwsympa','nobody',$param->{'auth_method'},$ip,'login','',$robot,'','no email');
	 return $in{'previous_action'} || 'home';
     }
     
     unless ($in{'passwd'}) {
	 my $url_redirect;
	 #Does the email belongs to an ldap directory?
	 if($url_redirect = &is_ldap_user($in{'email'})){
	     $param->{'redirect_to'} = $url_redirect
		 if ($url_redirect && ($url_redirect != 1));
	 }elsif ($in{'failure_referer'}) {
	     $param->{'redirect_to'} = $in{'failure_referer'};	    
	 }else{
	     $in{'init_email'} = $in{'email'};
	     $param->{'init_email'} = $in{'email'};
	     $param->{'escaped_init_email'} = &tools::escape_chars($in{'email'});

	     &report::reject_report_web('user','missing_arg',{'argument' => 'passwd'},$param->{'action'},'');
	     &wwslog('info','do_login: missing parameter passwd');
	     
	     return $in{'previous_action'} || undef;
	 }
     }

     ##authentication of the sender
     my $data;
     unless($data = &Auth::check_auth($robot, $in{'email'},$in{'passwd'})){
	 &report::reject_report_web('intern_quiet','',{},$param->{'action'},'');
	 # &List::db_log('wwsympa',$in{'email'},'null',$ip,'login','',$robot,'','failed');
	 &do_log('notice', "Authentication failed\n");
	 if ($in{'previous_action'}) {
	     delete $in{'passwd'};
	     $in{'list'} = $in{'previous_list'};
	     return  $in{'previous_action'};
	 }elsif ($in{'failure_referer'}) {
	     $param->{'redirect_to'} = $in{'failure_referer'};	    
	 }else {
	     return  'loginrequest';
	 }
     } 
     $param->{'user'} = $data->{'user'};
     $param->{'auth'} = $data->{'auth'};

     ## Set alt_email
     if ($data->{'alt_emails'}) {
	 foreach my $k (keys %{$data->{'alt_emails'}}) {
	     $param->{'alt_emails'}{$k} = $data->{'alt_emails'}{$k};
	 }
     }

     # &List::db_log('wwsympa',$in{'email'},'null',$ip,'login','',$robot,'','done');

     my $email = lc($param->{'user'}{'email'});
     unless($param->{'alt_emails'}{$email}){
	 unless(&cookielib::set_cookie_extern($Conf{'cookie'},$param->{'cookie_domain'},%{$param->{'alt_emails'}})){
	     # &List::db_log('wwsympa',$email,'null',$ip,'login','',$robot,'','Could not set cookie');
	     &wwslog('notice', 'Could not set HTTP cookie for external_auth');
	     return undef;
	 }
     }

     ## Current authentication mode
     #$param->{'auth'} = $param->{'alt_emails'}{$param->{'user'}{'email'}} || 'classic';

     $param->{'lang'} = $user->{'lang'} || $list->{'admin'}{'lang'} || &Conf::get_robot_conf($robot, 'lang');
     $param->{'cookie_lang'} = undef;    

     if (($param->{'auth'} eq 'classic') && ($param->{'user'}{'password'} =~ /^init/) ) {
	 &report::notice_report_web('you_should_choose_a_password',{},$param->{'action'});
     }
     
     if ($in{'newpasswd1'} && $in{'newpasswd2'}) {
	 my $old_action = $param->{'action'};
	 $param->{'action'} = 'setpasswd';
	 &do_setpasswd();
	 $param->{'action'} = $old_action;
     }

     if ($param->{'nomenu'}) {
	 $param->{'back_to_mom'} = 1;
	 return 1;
     }

     return $next_action;

 }


 ## Login WWSympa
sub do_sso_login {
    &wwslog('info', 'do_sso_login(%s)', $in{'auth_service_name'});
    
    &cookielib::set_do_not_use_cas($wwsconf->{'cookie_domain'},0,'now'); #when user require CAS login, reset do_not_use_cas cookie
    my $next_action;     
    
    if ($param->{'user'}{'email'}) {
	&report::reject_report_web('user','already_login',{'email' => $param->{'user'}{'email'}},$param->{'action'},'');
	&wwslog('err','do_login: user %s already logged in', $param->{'user'}{'email'});
	# &List::db_log('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'login','',$robot,'','already logged');
	return 'home';
    }
    
    
    unless ($in{'auth_service_name'}) {
	&report::reject_report_web('intern','no_authentication_service_name',{},$param->{'action'},'','',$robot);
	&wwslog('err','do_sso_login: no auth_service_name');
	return 'home';
    }

    ## This is a CAS service
    if (defined (my $cas_id = $Conf{'cas_id'}{$robot}{$in{'auth_service_name'}})) {
	my $cas_server = $Conf{'auth_services'}{$robot}[$cas_id]{'cas_server'};
	
	my $path = '';
	if ($param->{'nomenu'}) {
	    $path = "/nomenu";
	}
	$path .= "/sso_login_succeeded/$in{'auth_service_name'}";

	my $service = "$param->{'base_url'}$param->{'path_cgi'}".$path."?checked_cas=".$cas_id;
	
	my $redirect_url = $cas_server->getServerLoginURL($service);
	&wwslog('info', 'do_sso_login: redirect_url(%s)', $redirect_url);
	if ($redirect_url =~ /http(s)+\:\//i) {
	    $in{'action'} = 'redirect';
	    $param->{'redirect_to'} = $redirect_url;
	    $param->{'bypass'} = 'extreme';
	    print "Location: $param->{'redirect_to'}\n\n";
	}
	
    }elsif (defined (my $sso_id = $Conf{'generic_sso_id'}{$robot}{$in{'auth_service_name'}})) {
	## Generic SSO
	
	## If contacted via POST, then redirect the user to the URL for the access control to apply
	if ($ENV{'REQUEST_METHOD'} eq 'POST') {
	    my $path = '';
	    my $service;

	    if ($param->{'nomenu'}) {
		$path = "/nomenu";
	    }
	    &wwslog('info', 'do_sso_login(): POST request processing');
	    
	    if ($in{'subaction'} eq 'validateemail') {
		$path .= "/validateemail/sso_login_succeeded/$in{'auth_service_name'}/$in{'email'}";
		
	    }elsif ($in{'subaction'} eq 'confirmemail') {
		
		$path .= "/$in{'subaction'}/sso_login_succeeded/$in{'auth_service_name'}/$in{'email'}/$in{'passwd'}";
		
	    }else {
		
		$path .= "/init/sso_login_succeeded/$in{'auth_service_name'}";
	    }

	    my $service = "$param->{'base_url'}$param->{'path_cgi'}/sso_login/$in{'auth_service_name'}".$path;
	    
	    &wwslog('info', 'do_sso_login: redirect user to %s', $service);
	    $in{'action'} = 'redirect';
	    $param->{'redirect_to'} = $service;
	    $param->{'bypass'} = 'extreme';
	    print "Location: $param->{'redirect_to'}\n\n";
	    
	    return 1;
	}

	my $email;
	## We need to collect/verify the user's email address
	if (defined $Conf{'auth_services'}{$robot}[$sso_id]{'force_email_verify'}) {
	    my $email_is_trusted = 0;
	    
	    ## the subactions order is : init, requestemail, validateemail, sendssopasswd, confirmemail
	    
	    ## get email from NetiD table
	    if (defined $Conf{'auth_services'}{$robot}[$sso_id]{'internal_email_by_netid'}) {
		&wwslog('debug', 'do_sso_login(): lookup email internal: %s', $sso_id);
		if ($email = &Auth::get_email_by_net_id($robot, $sso_id, \%ENV)) {
		    $email_is_trusted = 1;
		}
	    }
	    
	    ## get email from authN module
	    if (defined $Conf{'auth_services'}{$robot}[$sso_id]{'email_http_header'} && ! $email_is_trusted) {
		$email = lc($ENV{$Conf{'auth_services'}{$robot}[$sso_id]{'email_http_header'}});
	    }
	    
	    ## Start the email validation process
	    if ($in{'subaction'} eq 'init' &&
		($email_is_trusted == 0 || ! $email)) {
		&wwslog('info', 'do_sso_login(): return request email');
		$param->{'auth'} = 'generic_sso';	
		$param->{'server'}{'key'} = $in{'auth_service_name'};
		$param->{'subaction'} = 'requestemail';
		$param->{'init_email'} = $email;
		return 1;
	    }
	    
	    if (defined($in{'email'}) and !($in{'subaction'} eq 'init')) {
		$email = $in{'email'};
	    }
	    
	    ## Send a confirmation email and request it on the web interface
	    if ($in{'subaction'} eq 'validateemail') {
		$param->{'auth'} = 'generic_sso';	
		$param->{'server'}{'key'} = $in{'auth_service_name'};
		$param->{'init_email'} = $email;

		unless (&sendssopasswd($email)) {
		    &report::reject_report_web('user','incorrect_email',{'email' => $email},$param->{'action'});
		    $param->{'subaction'} = 'requestemail';
		    return 1;
		}

		$param->{'subaction'} = 'validateemail';
		return 1;		
	    }
	    
	    if ($in{'subaction'} eq 'confirmemail') {
		$param->{'auth'} = 'generic_sso';	
		$param->{'server'}{'key'} = $in{'auth_service_name'};
		$param->{'init_email'} = $email;
		$in{'email'} = $email;
		
		#
		# Check input parameters and verify passwd for email, stolen from do_login
		#
		unless ($in{'email'}) {
		    &report::reject_report_web('user','no_email',{},$param->{'action'});
		    &wwslog('info','do_sso_login: confirmemail: no email');
		    # &List::db_log('wwsympa','nobody',$param->{'auth_method'},$ip,'login','',$robot,'','no email');
		    $param->{'subaction'} = 'validateemail';
		    return 1;
		}
		
		unless ($in{'passwd'}) {
		    $in{'init_email'} = $in{'email'};
		    $param->{'init_email'} = $in{'email'};
		    $param->{'escaped_init_email'} = &tools::escape_chars($in{'email'});
		    
		    &report::reject_report_web('user','missing_arg',{'argument' => 'passwd'},$param->{'action'});
		    &wwslog('info','do_sso_login: confirmemail: missing parameter passwd');
		    
		    $param->{'subaction'} = 'validateemail';
		    return 1;		    
		}
		
		##authentication of the sender
		my $data;
		unless($data = &Auth::check_auth($robot, $in{'email'},$in{'passwd'})){
		    &report::reject_report_web('user','auth_failed',{},$param->{'action'});
		    # &List::db_log('wwsympa',$in{'email'},'null',$ip,'login','',$robot,'','failed');
		    &wwslog('err', "Authentication failed\n");
		    
		    $param->{'subaction'} = 'validateemail';
		    return 1;		    
		} 
		
		&wwslog('info', 'do_sso_login: confirmemail: email validation succeeded');
		# need to create netid to email map entry
		$email = $in{'email'};
		
		# everything is ok to proceed to with possible sympa account created and traddional sso login
		
		
		if (defined $Conf{'auth_services'}{$robot}[$sso_id]{'internal_email_by_netid'}) {

		    my $netid = $ENV{$Conf{'auth_services'}{$robot}[$sso_id]{'netid_http_header'}};
		    my $idpname = $Conf{'auth_services'}{$robot}[$sso_id]{'service_id'};		    
		    
		    unless(&List::set_netidtoemail_db($robot, $netid, $idpname, $in{'email'})) {
			&report::reject_report_web('intern','db_update_failed',{},$param->{'action'},'',$param->{'user'}{'email'},$robot);
			&wwslog('err', 'error update netid map');
			return home;
		    }
		    
		}else {
		    &wwslog('info', 'do_sso_login: confirmemail: validation failed');

		    $param->{'subaction'} = 'validateemail';
		    return 1;		    
		}
	    }
	    
 	}else {
	    ##
	    if (defined $Conf{'auth_services'}{$robot}[$sso_id]{'email_http_header'}) {
		$email = lc($ENV{$Conf{'auth_services'}{$robot}[$sso_id]{'email_http_header'}});
	    }else {
		unless (defined $Conf{'auth_services'}{$robot}[$sso_id]{'ldap_host'} &&
			defined $Conf{'auth_services'}{$robot}[$sso_id]{'ldap_get_email_by_uid_filter'}) {
		    &report::reject_report_web('intern','auth_conf_no_identified_user',{},$param->{'action'},'','',$robot);
		    &wwslog('err','do_sso_login: auth.conf error : either email_http_header or ldap_host/ldap_get_email_by_uid_filter entries should be defined');
		    return 'home';	
		}
		
		$email = &Auth::get_email_by_net_id($robot, $sso_id, \%ENV);
	    }
	}
	
	unless ($email) {
	    &report::reject_report_web('intern_quiet','no_identified_user',{},$param->{'action'},'');
	    &wwslog('err','do_sso_login: user could not be identified, no %s HTTP header set', $Conf{'auth_services'}{$robot}[$sso_id]{'email_http_header'});
	    return 'home';	
	}
	
	$param->{'user'}{'email'} = $email;
	$param->{'auth'} = 'generic_sso';
	
	&wwslog('notice', 'User identified as %s', $email);
	my $prefix = $Conf{'auth_services'}{$robot}[$sso_id]{'http_header_prefix'};
	
	my @sso_attr;
	foreach my $k (keys %ENV) {
	    if ($k =~ /^$prefix/) {
		push @sso_attr, "$k=$ENV{$k}";
		&wwslog('notice', 'Var : %s = %s', $k, $ENV{$k});
	    }
	}
	
	my $all_sso_attr = join ';', @sso_attr;
	
	## Create user entry if required
	unless (&List::is_user_db($email)) {
	    unless (&List::add_user_db({'email' => $email})) {
		&report::reject_report_web('intern','add_user_db_failed',{'user'=>$email},$param->{'action'},'',$email,$robot);
		&wwslog('info','do_sso_login: add failed');
		return undef;
	    }
	}
	
	unless (&List::update_user_db($email,
				      {'attributes' => $all_sso_attr })) {
	    &report::reject_report_web('intern','update_user_db_failed',{'user'=>$email},$param->{'action'},'',$email,$robot);
	    &wwslog('info','do_sso_login: update failed');
	    return undef;
	}
	
	&report::notice_report_web('you_have_been_authenticated',{},$param->{'action'});
	
	return 'home';
    }else {
	## Unknown SSO service
	&report::reject_report_web('intern','unknown_authentication_service',{'name'=> $in{'auth_service_name'}},$param->{'action'},'','',$robot);
	&wwslog('err','do_sso_login: unknown authentication service %s', $in{'auth_service_name'});
	return 'home';	
    }    
    
    return 1;
}

sub do_sso_login_succeeded {
    &wwslog('info', 'do_sso_login_succeeded(%s)', $in{'auth_service_name'});

    if (defined $param->{'user'} && $param->{'user'}{'email'}) {
	&report::notice_report_web('you_have_been_authenticated',{},$param->{'action'});
    }else {
	&report::reject_report_web('user','auth_failed',{},$param->{'action'});
    }    

    ## We should refresh the main window
    if ($param->{'nomenu'}) {
	$param->{'back_to_mom'} = 1;
	return 1;
    }else {
	return 'home';
    }
}

 sub do_unify_email {

     &wwslog('info', 'do_unify_email');

     unless($param->{'user'}{'email'}){
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('notice',"error email");
     }

     ##Do you want to be considered as one user in user_table and subscriber table?
     foreach my $old_email( keys %{$param->{'alt_emails'}}){
	 next unless (&List::is_user_db($old_email));
	 next if($old_email eq $param->{'user'}{'email'});

	 unless ( &List::delete_user_db($old_email) ) {
	     &report::reject_report_web('intern','delete_email_failed',{'old_email' => $old_email},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	     &wwslog('info','do_unify_email: delete failed for the email %s',$old_email);
	 }
     }

     foreach my $role ('member','owner','editor'){
	 foreach my $email ( keys %{$param->{'alt_emails'}} ){
	     my @array;	    
	     foreach my $list (&List::get_which($email,$robot, $role)) {
		 push @array, $list->{'name'};
	     }
	     $param->{'alternative_subscribers_entries'}{$role}{$email} = \@array if($#array > -1);
	 }
     }

     foreach my $email(sort keys %{$param->{'alternative_subscribers_entries'}{'member'}}){
	 foreach my $list_name ( @{ $param->{'alternative_subscribers_entries'}{'member'}{$email} } ){ 
	     my $newlist = new List ($list_name, $robot);

	     unless ( $newlist->update_user($email,{'email' => $param->{'user'}{'email'} }) ) {
		 if ($newlist->{'admin'}{'user_data_source'} eq 'include') {
		 }else{
		     $newlist->delete_user($email);
		 }
	     }
	     
	 }
     }

     $param->{'alt_emails'} = undef;

     return 'which';
 }


 ## Declare an alternative email
 sub do_record_email{

     &wwslog('info', 'do_record_email');
     my $user;
     my $new_email;

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_record_email: no user');
	 return 'pref';
     }

     ##To verify that the user is in User_table 
     ##To verify the associated password 
     ##If not in User table we add him 

     unless(&tools::valid_email($in{'new_alternative_email'})){
	 &report::reject_report_web('user','incorrect_email',{'email' => $in{'new_alternative_email'}},$param->{'action'});
	 &wwslog('notice', "do_record_email:incorrect email %s",$in{'new_alternative_email'});
	 return 'pref';
     }

     ## Alt email is the same as main email address
     if ($in{'new_alternative_email'} eq $param->{'user'}{'email'}) {
	 &report::reject_report_web('user','incorrect_email',{'email' => $in{'new_alternative_email'}},$param->{'action'});
	 &wwslog('notice', "do_record_email:incorrect email %s",$in{'new_alternative_email'});
	 return 'pref';
     }

     my $new_user;

     $user = &List::get_user_db($in{'new_alternative_email'});
     $user->{'password'} ||= &tools::tmp_passwd($in{'new_alternative_email'});	
     unless($in{'new_password'} eq $user->{'password'}){
	 &report::reject_report_web('user','incorrect_passwd',{},$param->{'action'});
	 &wwslog('info','do_record_email: incorrect password for user %s', $in{'new_alternative_email'});
	 return 'pref';
     }  

     ##To add this alternate email in the cookie sympa_altemails   
     $param->{'alt_emails'}{$in{'new_alternative_email'}} = 'classic';
     return 'pref';

 }

 sub is_ldap_user {
     my $auth = shift; ## User email or UID
     &wwslog('debug2',"is_ldap_user ($auth)");

     unless (&tools::get_filename('etc', 'auth.conf', $robot)) {
	 return undef;
     }

     ## List all LDAP servers first
     my @ldap_servers;
     foreach my $ldap (@{$Conf{'auth_services'}{$robot}}){
	 next unless ($ldap->{'auth_type'} eq 'ldap');
	 
	 push @ldap_servers, $ldap;
     }    
     
     unless ($#ldap_servers >= 0) {
	 return undef;
     }

     unless (eval "require Net::LDAP") {
	 &wwslog ('err',"Unable to use LDAP library, Net::LDAP required,install perl-ldap (CPAN) first");
	 return undef;
     }
     require Net::LDAP;

     my ($ldap_anonymous,$host,$filter);

     foreach my $ldap (@ldap_servers){

	 # skip ldap auth service if the user id or email do not match regexp auth service parameter
	 next unless ($auth =~ /$ldap->{'regexp'}/i);

	 foreach $host (split(/,/,$ldap->{'host'})){
	     unless($host){
		 last;
	     }

	     &wwslog('debug4','Host: %s', $host);

	     my @alternative_conf = split(/,/,$ldap->{'alternative_email_attribute'});
	     my $attrs = $ldap->{'email_attribute'};

	     if (&tools::valid_email($auth)){
		 $filter = $ldap->{'get_dn_by_email_filter'};
	     }else{
		 $filter = $ldap->{'get_dn_by_uid_filter'};
	     }
	     $filter =~ s/\[sender\]/$auth/ig;

	     ## !! une fonction get_dn_by_email/uid

	     my $ldap_anonymous;
	     if ($ldap->{'use_ssl'}) {
		 unless (eval "require Net::LDAPS") {
		     &wwslog ('err',"Unable to use LDAPS library, Net::LDAPS required");
		     return undef;
		 } 
		 require Net::LDAPS;

		 my %param;
		 $param{'timeout'} = $ldap->{'timeout'} if ($ldap->{'timeout'});
		 $param{'sslversion'} = $ldap->{'ssl_version'} if ($ldap->{'ssl_version'});
		 $param{'ciphers'} = $ldap->{'ssl_ciphers'} if ($ldap->{'ssl_ciphers'});

		 $ldap_anonymous = Net::LDAPS->new($host,%param);
	     }else {
		 $ldap_anonymous = Net::LDAP->new($host,timeout => $ldap->{'timeout'});
	     }


	     unless ($ldap_anonymous ){
		 &wwslog ('err','Unable to connect to the LDAP server %s',$host);
		 next;
	     }

	     my $status = $ldap_anonymous->bind;
	     unless(defined($status) && ($status->code == 0)){
		 &wwslog('err', 'Bind failed on  %s', $host);
		 last;
	     }

	     my $mesg = $ldap_anonymous->search(base => $ldap->{'suffix'} ,
						filter => "$filter",
						scope => $ldap->{'scope'}, 
						timeout => $ldap->{'timeout'} );

	     unless($mesg->count() != 0) {
		 &wwslog('notice','No entry in the Ldap Directory Tree of %s for %s',$host,$auth);
		 $ldap_anonymous->unbind;
		 last;
	     } 

	     $ldap_anonymous->unbind;
	     my $redirect = $ldap->{'authentication_info_url'};
	     return $redirect || 1;
	 }
	 next unless ($ldap_anonymous);
	 next unless ($host);
     }
 }

 ## send back login form
 sub do_loginrequest {
     &wwslog('info','do_loginrequest');

     if ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','already_login',{'email' => $param->{'user'}{'email'}},$param->{'action'});
	 &wwslog('info','do_loginrequest: already logged in as %s', $param->{'user'}{'email'});
	 return undef;
     }

     if ($in{'init_email'}) {
	 $param->{'init_email'} = $in{'init_email'};
     }

     if ($in{'previous_action'} eq 'referer') {
	 $param->{'referer'} = &tools::escape_chars($ENV{'HTTP_REFERER'});
     }elsif (! $param->{'previous_action'}) {
	 $param->{'previous_action'} = 'loginrequest';
     }

     $param->{'title'} = 'Login'
	 if ($param->{'nomenu'});


     return 1;
 }

 ## Help / about WWSympa
 sub do_help {
     &wwslog('info','do_help(%s)', $in{'help_topic'});

     ## Contextual help
     if ($in{'help_topic'}) {
	 if ($in{'help_topic'} eq 'editlist') {
	     foreach my $pname (sort List::by_order keys %{$pinfo}) {
		 next if ($pname =~ /^comment|defaults$/);

		 $param->{'param'}{$pname}{'title'} = $pinfo->{$pname}{'title'}{$param->{'lang'}};
		 $param->{'param'}{$pname}{'comment'} = $pinfo->{$pname}{'comment'}{$param->{'lang'}};
	     }
	 }

	 $param->{'nomenu'} = 1;
	 $param->{'help_topic'} = $in{'help_topic'};
     }

     return 1;
 }

sub do_redirect {
     &wwslog('info','do_redirect(%s)', $param->{'redirect_to'});
     print "Location: $param->{'redirect_to'}\n\n";
     $param->{'bypass'} = 'extreme';
     return 1;
}

 ## Logout from WWSympa
 sub do_logout {
     &wwslog('info','do_logout(%s)', $param->{'user'}{'email'});

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_logout: user not logged in');
	 return undef;
     }

     # &List::db_log('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'logout','',$robot,'','done');

     delete $param->{'user'};
     $param->{'lang'} = $param->{'cookie_lang'} = &cookielib::check_lang_cookie($ENV{'HTTP_COOKIE'}) || $list->{'admin'}{'lang'} || &Conf::get_robot_conf($robot, 'lang');

     my $cas_id = &cookielib::get_cas_server($ENV{'HTTP_COOKIE'});
     if (defined $cas_id && (defined $Conf{'auth_services'}{$robot}[$cas_id])) {
	 # this user was logged using CAS
	 my $cas_server = $Conf{'auth_services'}{$robot}[$cas_id]{'cas_server'};

	 $in{'action'} = 'redirect';
	 my $return_url = &wwslib::get_my_url();
	 $return_url =~ s/\/logout//;
	 
	 $param->{'redirect_to'} = $cas_server->getServerLogoutURL($return_url);

	 &cookielib::set_cookie('unknown', $Conf{'cookie'}, $param->{'cookie_domain'}, 'now');
	 &cookielib::set_cas_server($wwsconf->{'cookie_domain'},$cas_id, 'now');
	 return 'redirect';
     }
     &wwslog('info','do_logout: logout performed');

     if ($in{'previous_action'} eq 'referer') {
	 $param->{'referer'} = &tools::escape_chars($in{'previous_list'});
     }

     return 'home';
 }

sub sendssopasswd {
    my $email = shift;
    do_log('info', 'sendssopasswd(%s)', $email);
    
    my ($passwd, $user);
    
    unless ($email) {
	&report::reject_report_web('user','no_email',{},$param->{'action'});
	&wwslog('info','do_sendpasswd: no email');
	return 'requestemail';
    }
    
    unless (&tools::valid_email($email)) {
	&report::reject_report_web('user','incorrect_email',{'email' => $email},$param->{'action'});
	&wwslog('info','do_sendpasswd: incorrect email %s', $email);
	return 'requestemail';
    }
    
    my $url_redirect;
    
    if ($param->{'newuser'} =  &List::get_user_db($email)) {
	
	## Create a password if none
	unless ($param->{'newuser'}{'password'}) {
	    unless ( &List::update_user_db($email,
					   {'password' => &tools::tmp_passwd($email) 
					    })) {
		&report::reject_report_web('intern','db_update_failed',{},$param->{'action'},'',$param->{'user'}{'email'},$robot);
		&wwslog('info','send_passwd: update failed');
		return undef;
	    }
	    $param->{'newuser'}{'password'} = &tools::tmp_passwd($email);
	}
	
	$param->{'newuser'}{'escaped_email'} =  &tools::escape_chars($param->{'newuser'}{'email'});
	
    }else {
	
	$param->{'newuser'} = {'email' => $email,
			       'escaped_email' => &tools::escape_chars($email),
			       'password' => &tools::tmp_passwd($email) 
			       };
	
    }
    
    $param->{'init_passwd'} = 1 
	if ($param->{'user'}{'password'} =~ /^init/);
    
    &List::send_global_file('sendssopasswd', $email, $robot, $param);
    
    
    $param->{'email'} = $email;
    
    
    return 'validateemail';
}

 ## Remind the password
sub do_remindpasswd {
     &wwslog('info', 'do_remindpasswd(%s)', $in{'email'}); 

     my $url_redirect;
     if($in{'email'}){
	 if($url_redirect = &is_ldap_user($in{'email'})){
	     $param->{'redirect_to'} = $url_redirect
		 if ($url_redirect && ($url_redirect != 1));
	 }elsif (! &tools::valid_email($in{'email'})) {
	     &report::reject_report_web('user','incorrect_email',{'email' => $in{'email'}},$param->{'action'});
	     &wwslog('info','do_remindpasswd: incorrect email \"%s\"', $in{'email'});
	     return undef;
	 }
     }

     $param->{'email'} = $in{'email'};

     # &List::db_log('wwsympa',$in{'email'},'null',$ip,'remindpasswd','',$robot,'','done');

     if ($in{'previous_action'} eq 'referer') {
	 $param->{'referer'} = &tools::escape_chars($in{'previous_list'});
     }
     return 1;
 }

####################################################
# do_sendpasswd                              
####################################################
#  Sends a message to the user containing user password.
# 
# IN : -
#
# OUT : 'remindpasswd' |  1 | 'loginrequest' | undef
#
####################################################
 sub do_sendpasswd {
     &wwslog('info', 'do_sendpasswd(%s)', $in{'email'}); 
     my ($passwd, $user);

     unless ($in{'email'}) {
	 &wwslog('info','do_sendpasswd: no email');
	 return 'remindpasswd';
     }

     unless (&tools::valid_email($in{'email'})) {
	 &report::reject_report_web('user','incorrect_email',{'email' => $in{'email'}},$param->{'action'});
	 &wwslog('info','do_sendpasswd: incorrect email %s', $in{'email'});
	 return 'remindpasswd';
     }

     my $url_redirect;
     if($url_redirect = &is_ldap_user($in{'email'})){
	 ## There might be no authentication_info_url URL defined in auth.conf
	 if ($url_redirect == 1) {
	     &report::reject_report_web('user','ldap_user',{},$param->{'action'});
	     &wwslog('info','do_sendpasswd: LDAP user %s, cannot remind password', $in{'email'});
	     return 'remindpasswd';
	 }else {
	     $param->{'redirect_to'} = $url_redirect
		 if ($url_redirect && ($url_redirect != 1));
	    
	     return 1;
	 }
     }

     if ($param->{'newuser'} =  &List::get_user_db($in{'email'})) {
	 &wwslog('info','do_sendpasswd: new password allocation for %s', $in{'email'});
	 ## Create a password if none
	 unless ($param->{'newuser'}{'password'}) {
	     unless ( &List::update_user_db($in{'email'},
					    {'password' => &tools::tmp_passwd($in{'email'}) 
					     })) {
		 &report::reject_report_web('intern','update_user_db_failed',{'user'=>$in{'email'}},$param->{'action'},'',$in{'email'},$robot);
		 &wwslog('info','send_passwd: update failed');
		 return undef;
	     }
	     $param->{'newuser'}{'password'} = &tools::tmp_passwd($in{'email'});
	 }

	 $param->{'newuser'}{'escaped_email'} =  &tools::escape_chars($param->{'newuser'}{'email'});

     }else {
	 &wwslog('debug','do_sendpasswd: sending existing password for %s', $in{'email'});
	 $param->{'newuser'} = {'email' => $in{'email'},
				'escaped_email' => &tools::escape_chars($in{'email'}),
				'password' => &tools::tmp_passwd($in{'email'}) 
				};

     }

     $param->{'init_passwd'} = 1 
	 if ($param->{'user'}{'password'} =~ /^init/);

     unless (&List::send_global_file('sendpasswd', $in{'email'}, $robot, $param)) {
	 &wwslog('notice',"Unable to send template 'sendpasswd' to $in{'email'}");
     }
     # &List::db_log('wwsympa',$in{'email'},'null',$ip,'sendpasswd','',$robot,'','done');


     $param->{'email'} = $in{'email'};

 #    if ($in{'previous_action'}) {
 #	$in{'list'} = $in{'previous_list'};
 #	return $in{'previous_action'};
 #
 #    }els

     if ($in{action} eq 'sendpasswd') {
	 #&message('password_sent');
	 $param->{'password_sent'} = 1;
	 $param->{'init_email'} = $in{'email'};
	 return 'loginrequest';
     }

     return 'loginrequest';
 }

 ## Which list the user is subscribed to 
 ## TODO (pour listmaster, toutes les listes)
 sub do_which {
     my $which = {};

     &wwslog('info', 'do_which');

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_which: no user');
	 $param->{'previous_action'} = 'which';
	 return 'loginrequest';
     }
     $param->{'get_which'} = undef ;
     $param->{'which'} = undef ;

     foreach my $role ('member','owner','editor') {

	 foreach my $list ( &List::get_which($param->{'user'}{'email'}, $robot, $role) ){ 	    
	     my $l = $list->{'name'};

	     my $result = $list->check_list_authz('visibility', $param->{'auth_method'},
						  {'sender' =>$param->{'user'}{'email'} ,
						   'remote_host' => $param->{'remote_host'},
						   'remote_addr' => $param->{'remote_addr'}});
	     
	     my $r_action;
	     $r_action = $result->{'action'} if (ref($result) eq 'HASH');
	     
	     next unless ($r_action =~ /do_it/);

	     $param->{'which'}{$l}{'subject'} = $list->{'admin'}{'subject'};
	     $param->{'which'}{$l}{'host'} = $list->{'admin'}{'host'};

	     if ($role eq 'member') {
		 push @{$param->{'get_which'}}, $list;
	     }

	     if ($role eq 'owner' || $role eq 'editor') {
		 $param->{'which'}{$l}{'admin'} = 1;
	     }

	     ## For compatibility concerns (3.0)
	     ## To be deleted one of these day
	     $param->{$role}{$l}{'subject'} = $list->{'admin'}{'subject'};
	     $param->{$role}{$l}{'host'} = $list->{'admin'}{'host'};

	 }

     }
     # &List::db_log('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'which','',$robot,'','done');
     return 1;
 }

 ## The list of list
 sub do_lists {
     my @lists;
     &wwslog('info', 'do_lists(%s,%s)', $in{'topic'}, $in{'subtopic'});

     my %topics = &List::load_topics($robot);

     if ($in{'topic'}) {
 	 $param->{'topic'} = $in{'topic'};
	 if ($in{'subtopic'}) {
	     $param->{'subtopic'} = $in{'subtopic'};
	     $param->{'subtitle'} = sprintf "%s / %s", $topics{$in{'topic'}}{'current_title'}, $topics{$in{'topic'}}{'sub'}{$in{'subtopic'}}{'current_title'};
	     $param->{'subtitle'} ||= "$in{'topic'} / $in{'subtopic'}";
	 }else {
	     $param->{'subtitle'} = $topics{$in{'topic'}}{'current_title'} || $in{'topic'};
	 }
     }

     my $all_lists = &List::get_lists($robot);
     foreach my $list ( @$all_lists ) {

	 my $sender = $param->{'user'}{'email'} || 'nobody';

	 my $result = $list->check_list_authz('visibility',$param->{'auth_method'},
					      {'sender' => $sender, 
					       'remote_host' => $param->{'remote_host'},
					       'remote_addr' => $param->{'remote_addr'}});

	 my $r_action;
	 $r_action = $result->{'action'} if (ref($result) eq 'HASH');

	 next unless ($r_action eq 'do_it');

	 my $list_info = {};
	 $list_info->{'subject'} = $list->{'admin'}{'subject'};
	 $list_info->{'host'} = $list->{'admin'}{'host'};
	 $list_info->{'date_epoch'} = $list->{'admin'}{'creation'}{'date_epoch'};
	 $list_info->{'date'} = $list->{'admin'}{'creation'}{'date'};
	 if ($param->{'user'}{'email'} &&
	     ($list->am_i('owner',$param->{'user'}{'email'}) ||
	      $list->am_i('editor',$param->{'user'}{'email'})) ) {
	     $list_info->{'admin'} = 1;
	 }
	 if ($param->{'user'}{'email'} &&
	     $list->is_user($param->{'user'}{'email'})) {
	     $list_info->{'is_subscriber'} = 1;
	 }

	 ## no topic ; List all lists
	 if (! $in{'topic'}) {
	     $param->{'which'}{$list->{'name'}} = $list_info;
	 }elsif ($list->{'admin'}{'topics'}) {
	     foreach my $topic (@{$list->{'admin'}{'topics'}}) {
		 my @tree = split '/', $topic;

		 next if (($in{'topic'}) && ($tree[0] ne $in{'topic'}));
		 next if (($in{'subtopic'}) && ($tree[1] ne $in{'subtopic'}));

		 $param->{'which'}{$list->{'name'}} = $list_info;
	     }
	 }elsif ($in{'topic'} eq 'topicsless') {
	     $param->{'which'}{$list->{'name'}} = $list_info;
	 }
     }
     return 1;
 }

 ## The list of latest created lists
 sub do_latest_lists {
     &wwslog('info', "do_latest_lists($in{'for'}, $in{'count'},$in{'topic'}, $in{'subtopic'})");

     unless ($in{'for'} || $in{'count'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => '"for" or "count"'},$param->{'action'});
	 &wwslog('err','do_latest_lists: missing parameter "count" or "for"');
	 return undef;
     }

     unless (&do_lists()) {
	 &wwslog('err','do_latest_lists: error while calling do_lists');
	 return undef;
     }

     my $today  = time;

     my $oldest_day;
     if (defined $in{'for'}) {
 	 $oldest_day = $today - (3600 * 24 * ($in{'for'}));
	 $param->{'for'} = $in{'for'};
	 unless ($oldest_day >= 0){
	     &report::reject_report_web('user','nb_days_to_much',{'nb_days' => $in{'for'} },$param->{'action'});
	     &wwslog('err','do_latest_lists: parameter "for" is too big"');
	 }
     }

     my $nb_lists = 0;
     my @date_lists;
     foreach my $listname (keys (%{$param->{'which'}})) {
	 if ($param->{'which'}{$listname}{'date_epoch'} < $oldest_day) { 
	     delete $param->{'which'}{$listname};
	     next;
	 }
	 $nb_lists++;
     }

     if (defined $in{'count'}) {
	 $param->{'count'} = $in{'count'};
	
	 unless ($in{'count'}) {
	     $param->{'which'} = undef;
	 }
     }

     my $count_lists = 0;
     foreach my $l ( sort {$param->{'which'}{$b}{'date_epoch'} <=> $param->{'which'}{$a}{'date_epoch'}} (keys (%{$param->{'which'}}))) {

	 $count_lists++;

	 if ($in{'count'}) {
	      if ($count_lists > $in{'count'}){
		  last;
	      }
	  }

	 $param->{'which'}{$l}{'name'} = $l;
	 push @{$param->{'latest_lists'}} , $param->{'which'}{$l};
     }

     $param->{'which'} = undef;
     
     return 1;
 }


 ## The list of the most active lists
 sub do_active_lists {
     &wwslog('info', "do_active_lists($in{'for'}, $in{'count'},$in{'topic'}, $in{'subtopic'})");

     unless ($in{'for'} || $in{'count'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => '"for" or "count"'},$param->{'action'});
	 &wwslog('err','do_active_lists: missing parameter "count" or "for"');
	 return undef;
     }

     unless (&do_lists()) {
	 &wwslog('err','do_active_lists: error while calling do_lists');
	 return undef;
     }
     
     ## oldest interesting day
     my $oldest_day = 0;
     
     if (defined $in{'for'}) {
	 $oldest_day = int(time/86400) - $in{'for'};
	 unless ($oldest_day >= 0){
	     &report::reject_report_web('user','nb_days_to_much',{'nb_days' => $in{'for'} },$param->{'action'});
	     &wwslog('err','do_latest_lists: parameter "for" is too big"');
	     return undef;
	 }
     } 

     ## get msg count for each list
     foreach my $l (keys (%{$param->{'which'}})) {
	 my $list = new List ($l, $robot);
	 my $file = "$list->{'dir'}/msg_count";
   
	 my %count ; 

	 if (open(MSG_COUNT, $file)) {	
	     while (<MSG_COUNT>){
		 if ($_ =~ /^(\d+)\s(\d+)$/) {
		     $count{$1} = $2;	
		 }
	     }
	     close MSG_COUNT ;

	     $param->{'which'}{$l}{'msg_count'}	= &count_total_msg_since($oldest_day,\%count);
	  
	     if ($in{'for'}) {
		 my $average = $param->{'which'}{$l}{'msg_count'} / $in{'for'}; ## nb msg by day  
		 $average = int($average * 10);
		 $param->{'which'}{$l}{'average'} = $average /10; ## one digit
	     }
	 } else {
	     $param->{'which'}{$l}{'msg_count'}	= 0;
	 }
     }
	
     my $nb_lists = 0;

     ## get "count" lists
     foreach my $l ( sort {$param->{'which'}{$b}{'msg_count'} <=> $param->{'which'}{$a}{'msg_count'}} (keys (%{$param->{'which'}}))) {
	 if (defined $in{'count'}) {
	     $nb_lists++;
	     if ($nb_lists > $in{'count'}) {
		 last;
	     }
	 }

	 $param->{'which'}{$l}{'name'} = $l;
	 push @{$param->{'active_lists'}} , $param->{'which'}{$l};

     }
     
     if (defined $in{'count'}) {
	 $param->{'count'} = $in{'count'};
     }
     if (defined $in{'for'}) {
	 $param->{'for'} = $in{'for'};
     }
     
     $param->{'which'} = undef;


     return 1;
 }

 sub count_total_msg_since {
     my $oldest_day = shift;
     my $count = shift;

     my $total = 0;
     foreach my $d (sort {$b <=> $a}  (keys %$count)) {
	 if ($d < $oldest_day) {
	     last;
	 }
	 $total = $total + $count->{$d};
     }
     return $total;
 }

 ## List information page
 sub do_info {
     &wwslog('info', 'do_info');

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_info: no list');
	 return undef;
     }

     ## Access control
     return undef unless (defined &check_authz('do_info', 'info'));

     ## Digest frequency
     if ($list->{'admin'}{'digest'} =~ /^([\d\,]+)\s+([\d\:]+)/m) {
	 my (@days, $d);
	 my $hour = $2;
	 foreach $d (split /\,/, $1) {
 #	    push @days, $week{$param->{'lang'}}[$d];
	     &Language::SetLang($list->{'admin'}{'lang'});
	     push @days, &POSIX::strftime("%A", localtime(0 + ($d +3) * (3600 * 24)));
	 }
	 $param->{'digest'} = sprintf '%s - %s', (join ', ', @days), $hour;
     }

     ## Is_user
     if ($param->{'is_subscriber'}) {
	 my ($s, $m);

	 unless($s = $list->get_subscriber($param->{'user'}{'email'})) {
	     &report::reject_report_web('intern','subscriber_not_found',{'email' => $param->{'user'}{'email'}},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('info', 'do_info: subscriber %s not found', $param->{'user'}{'email'});
	     return undef;
	 }

	 $s->{'reception'} ||= 'mail';
	 $s->{'visibility'} ||= 'noconceal';
	 $s->{'date'} = &POSIX::strftime("%d %b %Y", localtime($s->{'date'}));

	 foreach $m (keys %wwslib::reception_mode) {
	     $param->{'reception'}{$m}{'description'} = sprintf(gettext($wwslib::reception_mode{$m}->{'gettext_id'}));
	     if ($s->{'reception'} eq $m) {
		 $param->{'reception'}{$m}{'selected'} = 'selected="selected"';

	     }else {
		 $param->{'reception'}{$m}{'selected'} = '';
	     }
	 }

	 ## my $sortby = $in{'sortby'} || 'email';
	 $param->{'subscriber'} = $s;
     }

     ## Get List Description
     if (-r $list->{'dir'}.'/homepage') {
	 $param->{'homepage'} = 1;
     }
     &tt2::add_include_path($list->{'dir'});

     return 1;
 }


 ## List subcriber count page
 sub do_subscriber_count {
     &wwslog('info', 'do_subscriber_count');

     unless (&do_info()) {
	 &wwslog('info','do_subscriber_count: error while calling do_info');
	 return undef;
     }

     my $list;
     unless ($list = new List($param->{'list'},$robot)) {
	 &report::reject_report_web('user','unknown_list',{'list' => $param->{'list'}},$param->{'action'});
	 &wwslog('info', 'do_subscriber_coount : impossible to load list %s',$param->{'list'});
	 return undef;
     }

     print "Content-type: text/plain\n\n";
     print $list->get_total()."\n";

     $param->{'bypass'} = 'extreme';

     return 1;
 }


 ## Subscribers' list
 sub do_review {
     &wwslog('info', 'do_review(%d)', $in{'page'});
     my $record;
     my @users;
     my $size = $in{'size'} || $wwsconf->{'review_page_size'};
     my $sortby = $in{'sortby'} || 'email';
     my %sources;

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'})
	 &wwslog('info','do_review: no list');
	 return undef;
     }

     ## Access control
     return undef unless (defined &check_authz('do_review', 'review'));

     unless ($param->{'total'}) {
	 &report::reject_report_web('user','no_subscriber',{},$param->{'action'},$list)
	 &wwslog('info','do_review: no subscriber');
	 # &List::db_log('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'review',$param->{'list'},$robot,'','no subscriber');
	 return 1;
     }

     ## Owner
     $param->{'page'} = $in{'page'} || 1;
     $param->{'total_page'} = int ($param->{'total'} / $size);
     $param->{'total_page'} ++
	 if ($param->{'total'} % $size);

     if ($param->{'page'} > $param->{'total_page'}) {
	 &report::reject_report_web('user','no_page',{'page' => $param->{'page'}},$param->{'action'},$list);
	 ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'review',$param->{'list'},$robot,'','out of pages');
	 &wwslog('info','do_review: no page %d', $param->{'page'});
	 return undef;
     }

     my $offset;
     if ($param->{'page'} > 1) {
	 $offset = (($param->{'page'} - 1) * $size);
     }else {
	 $offset = 0;
     }

     ## We might not use LIMIT clause
     my ($limit_not_used, $count);
     unless (($list->{'admin'}{'user_data_source'} =~ /^database|include2$/) && 
	     ($Conf{'db_type'} =~ /^Pg|mysql$/)) {
	 $limit_not_used = 1;
     }

     ## Additional DB fields
     my @additional_fields = split ',', $Conf{'db_additional_subscriber_fields'};

     ## Members list
     $count = -1;
     for (my $i = $list->get_first_user({'sortby' => $sortby, 
					 'offset' => $offset, 
					 'rows' => $size}); 
	  $i; $i = $list->get_next_user()) {

	 ## some review pages may be empty while viewed by subscribers
	 next if (($i->{'visibility'} eq 'conceal')
		  and (! $param->{'is_priv'}) );

	 if ($limit_not_used) {
	     $count++;
	     next unless (($count >= $offset) && ($count <= $offset+$size));
	 }

	 ## Add user
	 &_prepare_subscriber($i, \@additional_fields, \%sources);

	 push @{$param->{'members'}}, $i;
     }

     if ($param->{'page'} > 1) {
	 $param->{'prev_page'} = $param->{'page'} - 1;
     }

     unless (($offset + $size) >= $param->{'total'}) {
	 $param->{'next_page'} = $param->{'page'} + 1;
     }

     $param->{'size'} = $size;
     $param->{'sortby'} = $sortby;


     ## additional DB fields
     $param->{'additional_fields'} = $Conf{'db_additional_subscriber_fields'};
     ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'review',$param->{'list'},$robot,'','done');

     ## msg_topics
     if ($list->is_there_msg_topic()) {
	 foreach my $top (@{$list->{'admin'}{'msg_topic'}}) {
	     if (defined $top->{'name'}) {
		 push (@{$param->{'available_topics'}},$top);
	     }
	 }
     }


     return 1;
 }

 ## Search in subscribers
 sub do_search {
     &wwslog('info', 'do_search(%s)', $in{'filter'});

     my %sources;

     ## Additional DB fields
     my @additional_fields = split ',', $Conf{'db_additional_subscriber_fields'};

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_search: no list');
	 return undef;
     }

     unless ($in{'filter'}) {
	 &report::reject_report_web('user','no_filter',{},$param->{'action'});
	 &wwslog('info','do_search: no filter');
	 return undef;
     }elsif ($in{'filter'} =~ /[<>\\\*\$]/) {
	 &report::reject_report_web('user','syntax_errors',{'params' => 'filter'},$param->{'action'});
	 &wwslog('err','do_search: syntax error');
	 return undef;
     }

     ## Access control
     return undef unless (defined &check_authz('do_search', 'review'));

     ## Regexp
     $param->{'filter'} = $in{'filter'};
     my $regexp = $param->{'filter'};
     $regexp =~ s/\\/\\\\/g;
     $regexp =~ s/\./\\\./g;
     $regexp =~ s/\*/\.\*/g;
     $regexp =~ s/\+/\\\+/g;
     $regexp =~ s/\?/\\\?/g;

     my $sql_regexp;
     if ($list->{'admin'}{'user_data_source'} eq 'database') {
	 $sql_regexp = $param->{'filter'};
	 $sql_regexp =~ s/\%/\\\%/g;
	 $sql_regexp =~ s/\*/\%/g;
	 $sql_regexp = '%'.$sql_regexp.'%';
     }

     my $record = 0;
     ## Members list
     for (my $i = $list->get_first_user({'sql_regexp' => $sql_regexp, 'sortby' => 'email'})
	  ; $i; $i = $list->get_next_user()) {

	 ## Search filter
	 next if ($i->{'email'} !~ /$regexp/i
		  && $i->{'gecos'} !~ /$regexp/i);

	 next if (($i->{'visibility'} eq 'conceal')
		  and (! $param->{'is_owner'}) );

	 ## Add user
	 &_prepare_subscriber($i, \@additional_fields, \%sources);

	 $record++;
	 push @{$param->{'members'}}, $i;
     }

     ## Maximum size of selection
     my $max_select = 500;

     if ($record > $max_select) {
	 undef $param->{'members'};
	 $param->{'too_many_select'} = 1;
     }

     $param->{'occurrence'} = $record;
     return 1;
 }

 ## Access to user preferences
 sub do_pref {
     &wwslog('info', 'do_pref');

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_pref: no user');
	 $param->{'previous_action'} = 'pref';
	 return 'loginrequest';
     }

     ## Find nearest expiration period
     my $selected = 0;
     foreach my $p (sort {$b <=> $a} keys %wwslib::cookie_period) {
	 my $entry = {'value' => $p};

	 ## Set description from NLS
	 $entry->{'desc'} = sprintf gettext($wwslib::cookie_period{$p}{'gettext_id'});

	 ## Choose nearest delay
	 if ((! $selected) && $param->{'user'}{'cookie_delay'} >= $p) {
	     $entry->{'selected'} = 'selected="selected"';
	     $selected = 1;
	 }

	 unshift @{$param->{'cookie_periods'}}, $entry;
     }

     $param->{'previous_list'} = $in{'previous_list'};
     $param->{'previous_action'} = $in{'previous_action'};

     return 1;
 }

 ## Set the initial password
 sub do_choosepasswd {
     &wwslog('info', 'do_choosepasswd');

     if($param->{'auth'} eq 'ldap'){
	 &report::reject_report_web('auth','',{'login'=> $param->{'need_login'}},$param->{'action'});
	 &wwslog('notice', "do_choosepasswd : user not authorized\n");
      }

     unless ($param->{'user'}{'email'}) {
	 unless ($in{'email'} && $in{'passwd'}) {
	     &report::reject_report_web('user','no_user',{},$param->{'action'});
	     &wwslog('info','do_pref: no user');
	     $param->{'previous_action'} = 'choosepasswd';
	     return 'loginrequest';
	 }

	 $in{'previous_action'} = 'choosepasswd';
	 return 'login';
     }

     $param->{'init_passwd'} = 1 if ($param->{'user'}{'password'} =~ /^INIT/i);

     return 1;
 }

####################################################
# do_set
####################################################
# Changes subscription parameter (reception or visibility)
# 
# IN : -
#
# OUT :'loginrequest'|'info' | undef

 sub do_set {
     &wwslog('info', 'do_set(%s, %s)', $in{'reception'}, $in{'visibility'});

     my ($reception, $visibility) = ($in{'reception'}, $in{'visibility'});
     my $email;

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_set: no list');
	 return undef;
     }

     unless ($reception || $visibility) {
	 &report::reject_report_web('user','missing_arg',{'argument' => '"reception" or "visibility"'},$param->{'action'});
	 &wwslog('info','do_set: no reception');
	 return undef;
     }

     if ($in{'email'}) {
	 unless ($param->{'is_owner'}) {
	     &report::reject_report_web('auth','action_owner',{},$param->{'action'},$list);
	     &wwslog('info','do_set: not owner');
	     return undef;
	 }

	 $email = &tools::unescape_chars($in{'email'});
     }else {
	 unless ($param->{'user'}{'email'}) {
	     &report::reject_report_web('user','no_user',{},$param->{'action'});
	     &wwslog('info','do_set: no user');
	     return 'loginrequest';
	 }
	 $email = $param->{'user'}{'email'};
     } 

     unless ($list->is_user($email)) {
	 &report::reject_report_web('user','not_subscriber',{'list'=> $param->{'list'}},$param->{'action'},$list);
	 &wwslog('info','do_set: %s not subscriber of list %s', $email, $param->{'list'});
	 return undef;
     }

     # Verify that the mode is allowed
     if (! $list->is_available_reception_mode($reception)) {
	 &report::reject_report_web('user','not_available_reception_mode',{'recpetion_mode'=> $reception},$param->{'action'},$list);
	 return undef;
     }

     $reception = '' if $reception eq 'mail';
     $visibility = '' if $visibility eq 'noconceal';

     my $update = {'reception' => $reception,
		   'visibility' => $visibility,
		   'update_date' => time};

     ## Lower-case new email address
     $in{'new_email'} = lc( $in{'new_email'});

     if ($in{'new_email'} && ($in{'email'} ne $in{'new_email'})) {

	 unless ($in{'new_email'} && &tools::valid_email($in{'new_email'})) {
	     &wwslog('notice', "do_set:incorrect email %s",$in{'new_email'});
	     &report::reject_report_web('user','incorrect_email',{'email' => $in{'new_email'}},$param->{'action'});
	     return undef;
	 }

	 ## Check if new email is already subscribed
	 if ($list->is_user($in{'new_email'})) {
	     &report::reject_report_web('user','already_subscriber', {'list' => $list->{'name'}},$param->{'action'},$list);
	     &wwslog('info','do_set: %s already subscriber', $in{'new_email'});
	     return undef;
	 }

	 ## Duplicate entry in user_table
	 unless (&List::is_user_db($in{'new_email'})) {

	     my $user_pref = &List::get_user_db($in{'email'});
	     $user_pref->{'email'} = $in{'new_email'};
	     &List::add_user_db($user_pref);
	 }

	 $update->{'email'} = $in{'new_email'};
     }

     ## message topic subscription
     if (($reception eq '') && $list->is_there_msg_topic()) {
 	my @user_topics;
 	
 	if ($in{'no_topic'}) {
 	    $update->{'topics'} = undef;
 	    
 	} else {
 	    foreach my $msg_topic (@{$list->{'admin'}{'msg_topic'}}) {
 		my $var_name = "topic_"."$msg_topic->{'name'}";
 		if ($in{"$var_name"}) {
 		    push @user_topics, $msg_topic->{'name'};
 		}
 	    }	 
 	    
 	    if ($in{"topic_other"}) {
 		push @user_topics, 'other';
 	    }
 	    
 	    $update->{'topics'} = join(',',@user_topics);
 	}
     }
     
     if ($reception ne '') {
	 $update->{'topics'} = '';
     }     

     ## Get additional DB fields
     foreach my $v (keys %in) {
	 if ($v =~ /^additional_field_(\w+)$/) {
	     $update->{$1} = $in{$v};
	 }
     }

     $update->{'gecos'} = $in{'gecos'} if $in{'gecos'};

     unless ( $list->update_user($email, $update) ) {
	 &report::reject_report_web('intern','update_subscriber_db_failed',{'sub'=>$email},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('info', 'do_set: set failed');
	 return undef;
     }

     $list->save();
     &report::notice_report_web('performed',{},$param->{'action'});

     return $in{'previous_action'} || 'suboptions';
 }

 ## Update of user preferences
 sub do_setpref {
     &wwslog('info', 'do_setpref');
     my $changes = {};

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_pref: no user');
	 return 'loginrequest';
     }

     foreach my $p ('gecos','lang','cookie_delay') {
	 $changes->{$p} = $in{$p} if (defined($in{$p}));
     }

     if (&List::is_user_db($param->{'user'}{'email'})) {

	 unless (&List::update_user_db($param->{'user'}{'email'}, $changes)) {
	     &report::reject_report_web('intern','update_user_db_failed',{'user'=>$param->{'user'}{'email'}},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	     &wwslog('info','do_pref: update failed');
	     return undef;
	 }
     }else {
	 $changes->{'email'} = $param->{'user'}{'email'};
	 unless (&List::add_user_db($changes)) {
	     &report::reject_report_web('intern','add_user_db_failed',{'user'=>$param->{'user'}{'email'}},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	     &wwslog('info','do_pref: add failed');
	     return undef;
	 }
     }

     foreach my $p ('gecos','lang','cookie_delay') {
	 $param->{'user'}{$p} = $in{$p};
     }


     if ($in{'previous_action'}) {
	 $in{'list'} = $in{'previous_list'};
	 return $in{'previous_action'};
     }else {
	 return 'pref';
     }
 }

 ## Prendre en compte les d�fauts
 sub do_viewfile {
     &wwslog('info', 'do_viewfile');

     unless ($in{'file'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'file'},$param->{'action'});
	 &wwslog('info','do_viewfile: no file');
	 return undef;
     }

     unless (defined $wwslib::filenames{$in{'file'}}) {
	 &report::reject_report_web('user','file_not_editable',{'file' => $in{'file'}},$param->{'action'});
	 &wwslog('info','do_viewfile: file %s not editable', $in{'file'});
	 return undef;
     }

    unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_viewfile: no list');
	 return undef;
     }

     $param->{'file'} = $in{'file'};

     $param->{'filepath'} = $list->{'dir'}.'/'.$in{'file'};

     if ((-e $param->{'filepath'}) and (! -r $param->{'filepath'})) {
	 &report::reject_report_web('intern','cannot_read',{'filepath' => $param->{'filepath'}},$param->{'action'},'','',$robot);
	 &wwslog('info','do_viewfile: cannot read %s', $param->{'filepath'});
	 return undef;
     }

     return 1;
 }


####################################################
# do_subscribe
####################################################
# Subscribes a user to the list 
# 
# IN : -
#
# OUT :'subrequest'|'login'|'info'|$in{'previous_action'}
#     | undef
####################################################
 ## TOTO: accepter nouveaux users
 sub do_subscribe {
     &wwslog('info', 'do_subscribe(%s)', $in{'email'});

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_subscribe: no list');
	 return undef;
     }

     ## Not authentified
     unless ($param->{'user'}{'email'}) {
	 ## no email 
	 unless ($in{'email'}) {
	     return 'subrequest';
	 }

	 ## Perform login
	 if ($in{'passwd'}) {
	     $in{'previous_action'} = 'subscribe';
	     $in{'previous_list'} = $param->{'list'};
	     return 'login';
	 }else {
	     return 'subrequest';
	 }

	 if ( &List::is_user_db($in{'email'})) {
	     &report::reject_report_web('user','no_user',{},$param->{'action'});
	     &wwslog('info','do_subscribe: need auth for user %s', $in{'email'});
	     return undef;
	 }

     }

     if ($param->{'is_subscriber'} && 
	      ($param->{'subscriber'}{'subscribed'} == 1)) {
	 &report::reject_report_web('user','already_subscriber', {'list' => $list->{'name'}},$param->{'action'},$list);
	 &wwslog('info','do_subscribe: %s already subscriber', $param->{'user'}{'email'});
	 return undef;
     }

     my $result = $list->check_list_authz('subscribe',$param->{'auth_method'},
					  {'sender' => $param->{'user'}{'email'}, 
					   'remote_host' => $param->{'remote_host'},
					   'remote_addr' => $param->{'remote_addr'}});
     my $sub_is;
     my $reason;
     if (ref($result) eq 'HASH') {
	 $sub_is = $result->{'action'};
	 $reason = $result->{'reason'};
     }
     if ($sub_is =~ /reject/) {
	 &report::reject_report_web('auth',$reason,{},$param->{'action'},$list);
	 &wwslog('info', 'do_subscribe: subscribe closed');
	 return undef;
     }

     $param->{'may_subscribe'} = 1;

     if ($sub_is =~ /owner/) {
	 unless ($list->send_notify_to_owner('subrequest',{'who' => $param->{'user'}{'email'},
							   'keyauth' => $list->compute_auth($param->{'user'}{'email'}, 'add'),
							   'replyto' => &Conf::get_robot_conf($robot, 'sympa'),
							   'gecos' => $param->{'user'}{'gecos'}})) {
	     &wwslog('notice',"Unable to send notify 'subrequest' to $list->{'name'} listowner");
	 }

	 $list->store_subscription_request($param->{'user'}{'email'});
	 &report::notice_report_web('sent_to_owner',{},$param->{'action'});
	 &wwslog('info', 'do_subscribe: subscribe sent to owner');

	 return 'info';
     }elsif ($sub_is =~ /do_it/) {
	 if ($param->{'is_subscriber'}) {
	     unless ($list->update_user($param->{'user'}{'email'}, 
					{'subscribed' => 1,
					 'update_date' => time})) {
		 &report::reject_report_web('intern','update_subscriber_db_failed',{'sub'=>$param->{'user'}{'email'}},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('info', 'do_subscribe: update failed');
		 return undef;
	     }
	 }else {
	     my $defaults = $list->get_default_user_options();
	     my $u;
	     %{$u} = %{$defaults};
	     $u->{'email'} = $param->{'user'}{'email'};
	     $u->{'gecos'} = $param->{'user'}{'gecos'} || $in{'gecos'};
	     $u->{'date'} = $u->{'update_date'} = time;
	     $u->{'password'} = $param->{'user'}{'password'};
	     $u->{'lang'} = $param->{'user'}{'lang'} || $param->{'lang'};

	     unless ($list->add_user($u)) {
		 &report::reject_report_web('intern','add_subscriber_db_failed',{'sub'=>$param->{'user'}{'email'}},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('info', 'do_subscribe: subscribe failed');
		 return undef;
	     }
	     $list->save();
	 }

	 unless ($sub_is =~ /quiet/i ) {
	     unless ($list->send_file('welcome', $param->{'user'}{'email'}, $robot,{})) {
		 &wwslog('notice',"Unable to send template 'welcome' to $param->{'user'}{'email'}");
	     }
	 }

	 if ($sub_is =~ /notify/) {
	     unless ($list->send_notify_to_owner('notice',{'who' => $param->{'user'}{'email'}, 
					  'gecos' => $param->{'user'}{'gecos'}, 
							   'command' => 'subscribe'})) {
		 &wwslog('notice','Unable to send notify "notice" to listmaster');
	     }
	 }
	 ## perform which to update your_subscribtions cookie ;
	 @{$param->{'get_which'}} = &List::get_which($param->{'user'}{'email'},$robot,'member') ; 
	 &report::notice_report_web('performed',{},$param->{'action'});
     }

     if ($in{'previous_action'}) {
	 return $in{'previous_action'};
     }

 #    return 'suboptions';
     return 'info';
 }

 ## Subscription request (user not authentified)
 sub do_suboptions {
     &wwslog('info', 'do_suboptions()');

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_suboptions: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_suboptions: user not logged in');
	 return undef;
     }

     unless($param->{'is_subscriber'} ) {
	 &report::reject_report_web('user','not_subscriber',{'list'=> $list->{'name'}},$param->{'action'},$list);
	 &wwslog('info','do_suboptions: %s not subscribed to %s',$param->{'user'}{'email'}, $param->{'list'} );
	 return undef;
     }

     my ($s, $m);

     unless($s = $list->get_subscriber($param->{'user'}{'email'})) {
	 &report::reject_report_web('intern','subscriber_not_found',{'email' => $param->{'user'}{'email'}},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('info', 'do_sub_options: subscriber %s not found', $param->{'user'}{'email'});
	 return undef;
     }

     $s->{'reception'} ||= 'mail';
     $s->{'visibility'} ||= 'noconceal';
     $s->{'date'} = &POSIX::strftime("%d %b %Y", localtime($s->{'date'}));
     $s->{'update_date'} = &POSIX::strftime("%d %b %Y", localtime($s->{'update_date'}));

     foreach $m (keys %wwslib::reception_mode) {
       if ($list->is_available_reception_mode($m)) {
	 $param->{'reception'}{$m}{'description'} = sprintf(gettext($wwslib::reception_mode{$m}->{'gettext_id'}));
	 if ($s->{'reception'} eq $m) {
	     $param->{'reception'}{$m}{'selected'} = 'selected="selected"';

	     if ($m eq 'mail') {
		 $param->{'possible_topic'} = 1;
	     }
	 }else {
	     $param->{'reception'}{$m}{'selected'} = '';
	 }
       }
     }

     foreach $m (keys %wwslib::visibility_mode) {
	 $param->{'visibility'}{$m}{'description'} = sprintf(gettext($wwslib::visibility_mode{$m}->{'gettext_id'}));
	 if ($s->{'visibility'} eq $m) {
	     $param->{'visibility'}{$m}{'selected'} = 'selected="selected"';
	 }else {
	     $param->{'visibility'}{$m}{'selected'} = '';
	 }
     }

     $param->{'subscriber'} = $s;


     #msg_topic
     $param->{'sub_user_topic'} = 0;
     foreach my $user_topic (split /,/,$s->{'topics'}) {
	 $param->{'topic_checked'}{$user_topic} = 1;
	 $param->{'sub_user_topic'}++;
     }
     
     if ($list->is_there_msg_topic()) {
	 foreach my $top (@{$list->{'admin'}{'msg_topic'}}) {
	     if (defined $top->{'name'}) {
		 push (@{$param->{'available_topics'}},$top);
	     }
	 }
     }
     
     return 1;
 }

## Subscription request (user not authentified)
 sub do_subrequest {
     &wwslog('info', 'do_subrequest(%s)', $in{'email'});

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_subrequest: no list');
	 return undef;
     }

     my $ldap_user;
     $ldap_user = 1
	 if (!&tools::valid_email($in{'email'}) || &is_ldap_user($in{'email'}));

     ## Auth ?
     if ($param->{'user'}{'email'}) {

	 ## Subscriber ?
	 if ($param->{'is_subscriber'}) {
	     &report::reject_report_web('user','already_subscriber', {'list' => $list->{'name'}},$param->{'action'},$list);
	     &wwslog('info','do_subscribe: %s already subscriber', $param->{'user'}{'email'});
	     return undef;
	 }

	 $param->{'status'} = 'auth';
     }else {
	 ## Provided email parameter ?
	 unless ($in{'email'}) {
	     $param->{'status'} = 'notauth_noemail';
	     return 1;
	 }

	 ## Subscriber ?
	 if (!$ldap_user && $list->is_user($in{'email'})) {
	     $param->{'status'} = 'notauth_subscriber';
	     return 1;
	 }

	 my $user;
	 $user = &List::get_user_db($in{'email'})
	     if &List::is_user_db($in{'email'});

	 ## Need to send a password by email
	 if ((!&List::is_user_db($in{'email'}) || 
	      !$user->{'password'} || 
	      ($user->{'password'} =~ /^INIT/i)) &&
	     !$ldap_user) {

	     &do_sendpasswd();
	     $param->{'status'} = 'notauth_passwordsent';
	     return 1;
	 }

	 $param->{'email'} = $in{'email'};
	 $param->{'status'} = 'notauth';
     }

     return 1;
 }
####################################################
# do_signoff
####################################################
# Unsubcribes a user from a list 
# 
# IN : -
#
# OUT : 'sigrequest' | 'login' | 'info'
#
####################################################
 ## Unsubscribe from list
 sub do_signoff {
     &wwslog('info', 'do_signoff');

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_signoff: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 unless ($in{'email'}) {
	     return 'sigrequest';
	 }

	 ## Perform login first
	 if ($in{'passwd'}) {
	     $in{'previous_action'} = 'signoff';
	     $in{'previous_list'} = $param->{'list'};
	     return 'login';
	 }

	 if ( &List::is_user_db($in{'email'}) ) {
	     &report::reject_report_web('user','no_user',{},$param->{'action'});
	     &wwslog('info','do_signoff: need auth for user %s', $in{'email'});
	     return undef;
	 }

	 ## No passwd
	 &init_passwd($in{'email'}, {'lang' => $param->{'lang'} });

	 $param->{'user'}{'email'} = $in{'email'};
     }

     unless ($list->is_user($param->{'user'}{'email'})) {
	 &report::reject_report_web('user','not_subscriber',{'list'=>$list->{'name'}},$param->{'action'},$list);
	 &wwslog('info','do_signoff: %s not subscribed to %s',$param->{'user'}{'email'}, $param->{'list'} );
	 return undef;
     }

     my $result = $list->check_list_authz('unsubscribe',$param->{'auth_method'},
					  {'sender' => $param->{'user'}{'email'},
					   'remote_host' => $param->{'remote_host'},
					   'remote_addr' => $param->{'remote_addr'}});
     my $sig_is;
     my $reason;
     if (ref($result) eq 'HASH') {
	 $sig_is = $result->{'action'};
	 $reason = $result->{'reason'};
     }

     $param->{'may_signoff'} = 1 if ($sig_is =~ /do_it|owner/);

     if ($sig_is =~ /reject/) {
	 &report::reject_report_web('auth',$reason,{},$param->{'action'},$list);
	 &wwslog('info', 'do_signoff: %s may not signoff from %s'
		 , $param->{'user'}{'email'}, $param->{'list'});
	 return undef;
     }elsif ($sig_is =~ /owner/) {
	 unless ($list->send_notify_to_owner('sigrequest',{'who' => $param->{'user'}{'email'},
							   'keyauth' => $list->compute_auth($param->{'user'}{'email'}, 'del')})) {
	     &wwslog('notice',"Unable to send notify 'sigrequest' to $list->{'name'} list owner");
	 }
	 &report::notice_report_web('sent_to_owner',{},$param->{'action'});
	 &wwslog('info', 'do_signoff: signoff sent to owner');
	 return undef;
     }else {
	 if ($param->{'subscriber'}{'included'}) {
	     unless ($list->update_user($param->{'user'}{'email'}, 
					{'subscribed' => 0,
					 'update_date' => time})) {
		 &report::reject_report_web('intern','update_subscriber_db_failed',{'sub'=>$param->{'user'}{'email'}},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('info', 'do_signoff: update failed');
		 return undef;
	     }
	 }else {
	     unless ($list->delete_user($param->{'user'}{'email'})) {
		 &report::reject_report_web('intern','delete_subscriber_db_failed',{'sub'=>$param->{'user'}{'email'}},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('info', 'do_signoff: signoff failed');
		 return undef;
	     }

	     $list->save();
	 }

	 if ($sig_is =~ /notify/) {
	     unless ($list->send_notify_to_owner('notice',{'who' => $param->{'user'}{'email'},
					  'gecos' => '', 
							   'command' => 'signoff'})) {
		 &wwslog('notice',"Unable to send notify 'notice' to $list->{'name'} list owner");
	     }
	 }

	 ## perform which to update your_subscribtions cookie ;
	 @{$param->{'get_which'}} = &List::get_which($param->{'user'}{'email'},$robot,'member') ; 

	 unless ($list->send_file('bye', $param->{'user'}{'email'}, $robot, {})) {
	     &wwslog('notice',"Unable to send template 'bye' to $param->{'user'}{'email'}");
	 }
     }
     &report::notice_report_web('performed',{},$param->{'action'});
     $param->{'is_subscriber'} = 0;
     $param->{'may_signoff'} = 0;

     return 'info';
 }

 ## Unsubscription request (user not authentified)
 sub do_sigrequest {
     &wwslog('info', 'do_sigrequest(%s)', $in{'email'});

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_sigrequest: no list');
	 return undef;
     }

     my $ldap_user;
     $ldap_user = 1
	 if (!&tools::valid_email($in{'email'}) || &is_ldap_user($in{'email'}));

     ## Do it
     if ($param->{'user'}{'email'}) {
	 $param->{'status'} = 'auth';
	 return 1;
 #	return 'signoff';
     }

     ## Not auth & no email
     unless ($in{'email'}) {
	 return 1;
     }

     if ($list->is_user($in{'email'}) || $ldap_user) {
	 my $user;
	 $user = &List::get_user_db($in{'email'})
	     if &List::is_user_db($in{'email'});

	 ## Need to send a password by email
	 if ((!&List::is_user_db($in{'email'}) || 
	     !$user->{'password'} || 
	     ($user->{'password'} =~ /^INIT/i)) &&
	     !$ldap_user) {

	     &do_sendpasswd();
	     $param->{'email'} =$in{'email'};
	     $param->{'init_passwd'} = 1;
	     return 1;
	 }
     }else {
	 $param->{'not_subscriber'} = 1;
     }

     $param->{'email'} = $in{'email'};

     return 1;
 }


 ## Update of password
 sub do_setpasswd {
     &wwslog('info', 'do_setpasswd');
     my $user;

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_setpasswd: no user');
	 return 'loginrequest';
     }

     if ( ! $in{'newpasswd1'} || 
	     $in{'newpasswd1'} =~ /^\s+$/ ) {
	 &report::reject_report_web('user','no_passwd',{},$param->{'action'});
	 &wwslog('info','do_setpasswd: no newpasswd1');
	 return undef;
     }

     unless ($in{'newpasswd2'}) {
	 &report::reject_report_web('user','no_passwd',{},$param->{'action'});
	 &wwslog('info','do_setpasswd: no newpasswd2');
	 return undef;
     }

     unless ($in{'newpasswd1'} eq $in{'newpasswd2'}) {
	 &report::reject_report_web('user','diff_passwd',{},$param->{'action'});
	 &wwslog('info','do_setpasswd: different newpasswds');
	 return undef;
     }

     if (&List::is_user_db($param->{'user'}{'email'})) {
	 unless ( &List::update_user_db($param->{'user'}{'email'}, {'password' => $in{'newpasswd1'}} )) {
	     &report::reject_report_web('intern','update_user_db_failed',{'user'=>$param->{'user'}{'email'}},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	     &wwslog('info','do_setpasswd: update failed');
	     return undef;
	 }
     }else {
	 unless ( &List::add_user_db({'email' => $param->{'user'}{'email'}, 
				      'password' => $in{'newpasswd1'}} )) {
	     &report::reject_report_web('intern','add_user_db_failed',{'user'=>$param->{'user'}{'email'}},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	     &wwslog('info','do_setpasswd: update failed');
	     return undef;
	 }
     }

     $param->{'user'}{'password'} =  $in{'newpasswd1'};

     &report::notice_report_web('performed',{},$param->{'action'});

     if ($in{'previous_action'}) {
	 $in{'list'} = $in{'previous_list'};
	 return $in{'previous_action'};
     }else {
	 return 'pref';
     }
 }

 ## List admin page
 sub do_admin {
     &wwslog('info', 'do_admin');

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_admin: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_admin: no user');
	 $param->{'previous_action'} = 'admin';
	 $param->{'previous_list'} = $in{'list'};
	 return 'loginrequest';
     }

     unless ($param->{'is_owner'} or $param->{'is_editor'}) {
	 &report::reject_report_web('auth','action_owner_or_editor',{},$param->{'action'},$list);
	 &wwslog('info','do_admin: %s not private user', $param->{'user'}{'email'});
	 return undef;
     }

     ## Messages edition
     foreach my $f ('info','homepage','welcome.tt2','bye.tt2','removed.tt2','message.footer','message.header','remind.tt2','invite.tt2','reject.tt2') {
	 next unless ($list->may_edit($f, $param->{'user'}{'email'}) eq 'write');
	 if ($wwslib::filenames{$f}{'gettext_id'}) {
	     $param->{'files'}{$f}{'complete'} = gettext($wwslib::filenames{$f}{'gettext_id'});
	 }else {
	     $param->{'files'}{$f}{'complete'} = $f;
	 }
	 $param->{'files'}{$f}{'selected'} = '';
     }
     $param->{'files'}{'info'}{'selected'} = 'selected="selected"';

 #    my %mode;
 #    $mode{'edit'} = 1;
 #    my %access = &d_access_control(\%mode,$path);

     return 1;
 }

 ## Server admin page
 sub do_serveradmin {
     &wwslog('info', 'do_serveradmin');
     my $f;

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_serveradmin: no user');
	 $param->{'previous_action'} = 'serveradmin';
	 return 'loginrequest';
     }

     unless ($param->{'is_listmaster'}) {
	 &report::reject_report_web('auth','action_listmaster',{},$param->{'action'},$list);
	 &wwslog('info','do_admin: %s not listmaster', $param->{'user'}{'email'});
	 return undef;
     }

 #    $param->{'conf'} = \%Conf;

     ## Lists Default files
     foreach my $f ('welcome.tt2','bye.tt2','removed.tt2','message.footer','message.header','remind.tt2','invite.tt2','reject.tt2','your_infected_msg.tt2') {
	 if ($wwslib::filenames{$f}{'gettext_id'}){
	     $param->{'lists_default_files'}{$f}{'complete'} = gettext($wwslib::filenames{$f}{'gettext_id'});
	 }else {
	     $param->{'lists_default_files'}{$f}{'complete'} = $f;
	 }
	 $param->{'lists_default_files'}{$f}{'selected'} = '';
     }

     ## All Robots are shown to super listmaster
     if (&List::is_listmaster($param->{'user'}{'email'})) {
	 $param->{'main_robot'} = 1;
	 $param->{'robots'} = $Conf{'robots'};
     }

     ## Families
     my @families = &Family::get_available_families($robot);

     if (@families) {
	 $param->{'families'} = \@families;
     }
     
     ## Server files
     foreach my $f ('helpfile.tt2','lists.tt2','global_remind.tt2','summary.tt2','create_list_request.tt2','list_created.tt2','list_aliases.tt2') {
	 $param->{'server_files'}{$f}{'complete'} = gettext($wwslib::filenames{$f}{'gettext_id'});
	 $param->{'server_files'}{$f}{'selected'} = '';
     }
     $param->{'server_files'}{'helpfile.tt2'}{'selected'} = 'selected="selected"';

     return 1;
 }


## list availible templates
sub do_ls_templates  {
    &wwslog('info', 'do_ls_templates');

    unless ($param->{'is_listmaster'}) {
	&report::reject_report_web('auth','action_listmaster',{},$param->{'action'},$list);
	&wwslog('info','do_ls_templates: %s not listmaster', $param->{'user'}{'email'});
	return undef;
    }

    $in{'webormail'} = 'web' unless $in{'webormail'};
    my $type =  $param->{'webormail'} = $in{'webormail'};
    #    $in{'subdir'} = 'default' unless ($in{'subdir'});
    $param->{'subdir'}= $in{'subdir'};
    
    return 1 unless (($type == 'web')||($type == 'mail'));
 
    if ($in{'listname'}) {
	chomp ($in{'listname'});
	$param->{'listname'} = $in{'listname'};
	
	unless ($list = new List ($in{'listname'}, $robot)) {
	    &report::reject_report_web('user','unknown_list',{'list' => $in{'listname'}},$param->{'action'});
	    &wwslog('info','check_param_in: unknown list %s', $in{'listname'});
	    return undef;		
	}
	$param->{'templates'} = &tools::get_templates_list($type,$robot,$in{'subdir'},$list->{'dir'});
    }else{
	$param->{'templates'} = &tools::get_templates_list($type,$robot,$in{'subdir'});
    }
    return 1;
}    

# show a template, used by copy_template and edit_emplate
sub do_remove_template {
    
    &wwslog('info', 'do_remove_template');
    unless ($param->{'is_listmaster'}) {
	&report::reject_report_web('auth','action_listmaster',{},$param->{'action'});
	&wwslog('info','do_remove_template: %s not listmaster', $param->{'user'}{'email'});
	return undef;
    }

    my $type =  $param->{'webormail'} = $in{'webormail'};
    return 1 unless (($type == 'web')||($type == 'mail'));

    my $scope = $in{'scope'} ;
    $param->{'scope'} = $scope;    

    return 1 unless (($scope eq 'distrib')||($scope eq 'robot')||($scope eq 'family')||($scope eq 'list')||($scope eq 'site'));

    my $namedlist ; 

    if ($in{'listname'}) {
	chomp ($in{'listname'});
	$param->{'listname'} = $in{'listname'};
	
	unless ($namedlist = new List ($in{'listname'}, $robot)) {
	    &report::reject_report_web('user','unknown_list',{'list' => $in{'list'}},$param->{'action'},'');
	    &wwslog('info','check_param_in: unknown list %s', $in{'listname'});
	    return undef;		
	}
    }

    my $template_name = $param->{'template_name'} = $in{'template_name'};
    my $template_path ;

    if ($in{'scope'} eq 'list') { 
	$template_path = &tools::get_template_path($type,$robot,'list',$template_name,$in{'listname'});
    }else{
	$template_path = &tools::get_template_path($type,$robot,$in{'scope'},$template_name);
    }
        
    &wwslog('debug',"remove_template: template_path '$template_path'");
    unless ($template_path eq $in{'template_path'}) {
	&report::reject_report_web('user','wrong_input_path',{'tpl' => $template_name},$param->{'action'});
	&wwslog('info',"remove_template: wrong input path $in{'template_path'} differ from $template_path");
	return undef;		
    }
    my $template_old_path = &tools::shift_file($template_path,10);
    unless ($template_old_path) {
	&report::reject_report_web('intern','remove_failed',{'path'=>$template_path},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	&wwslog('info',"remove_template: could not remove $template_path");
	return undef;
    }
    
    &report::notice_report_web('file_renamed',{'orig_file'=>$template_path,'new_file'=>$template_old_path}, $param->{'action'});
    
    return (ls_templates);
}

# show a template, used by copy_template and edit_emplate
sub do_view_template {
    
    &wwslog('info', 'do_view_template');
    unless ($param->{'is_listmaster'}) {
	&report::reject_report_web('auth','action_listmaster',{},$param->{'action'},$list);
	&wwslog('info','do_admin: %s not listmaster', $param->{'user'}{'email'});
	return undef;
    }

    my $type =  $param->{'webormail'} = $in{'webormail'};
    return 1 unless (($type == 'web')||($type == 'mail'));

    my $scope = $in{'scope'} ;
    $param->{'scope'} = $scope;    

    return 1 unless (($scope eq 'distrib')||($scope eq 'robot')||($scope eq 'family')||($scope eq 'list')||($scope eq 'site'));

    my $namedlist ; 

    if ($in{'listname'}) {
	chomp ($in{'listname'});
	$param->{'listname'} = $in{'listname'};
	
	unless ($namedlist = new List ($in{'listname'}, $robot)) {
	    &report::reject_report_web('user','unknown_list',{'list' => $in{'listname'}},$param->{'action'});
	    &wwslog('info','check_param_in: unknown list %s', $in{'listname'});
	    return undef;		
	}
    }

    my $template_name = $param->{'template_name'} = $in{'template_name'};
    my $template_path ;

    &wwslog('info', "do_view_template(type=$type,template-name=$template_name,listname=$in{'listname'},path=$in{'template_path'},scope=$in{'scope'},lang=$in{'subdir'})");

    if ($in{'scope'} eq 'list') { 
	$template_path = &tools::get_template_path($type,$robot,'list',$template_name,$in{'subdir'},$in{'listname'});
    }else{
	$template_path = &tools::get_template_path($type,$robot,$in{'scope'},$template_name,$in{'subdir'});
    }
    
    
    &wwslog('info',"view_template: template_path '$template_path' ");

    unless ($template_path eq $in{'template_path'}) {
	&report::reject_report_web('user','wrong_input_path',{'tpl' => $template_name},$param->{'action'});
	&wwslog('info',"view_template: wrong input path $in{'template_path'} differ from $template_path");
	return undef;		
    }
    unless (open (TPL,"$template_path")) {
	&report::reject_report_web('intern','cannot_open_file',{'path' => $in{'template_path'}},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	&wwslog('err',"view_template: can't open file %s",$template_path);
	return undef;
    }
    $param->{'rows'} = 5; #input area is always contain 5 emptyline; 
    while(<TPL>) {$param->{'template_content'}.= $_; $param->{'rows'}++;}
    $param->{'template_content'} = &tools::escape_html($param->{'template_content'});
    close TPL;
}

##  template copy
sub do_copy_template  {
    &wwslog('info', 'do_copy_template');
    
    my $type =  $param->{'webormail'} = $in{'webormail'};
    my $template_name = $param->{'template_name'} = $in{'template_name'};
    my $listname = $param->{'listname'}= $in{'listname'};
    $param->{'template_path'} = $in{'template_path'};
    $param->{'scope'} = $in{'scope'};
    $in{'subdir'} = 'default' unless $in{'subdir'};
    $param->{'subdir'} = $in{'subdir'};

    &do_view_template;               

    # $in{'scopeout'} = 'list' if ($in{'listnameout'});
    return 1 unless ($in{'scopeout'}) ;

    # one of theses parameters is commint from the form submission
    my $pathout ; 
    my $scopeout = $param->{'scopeout'} = $in{'scopeout'} ;
    if ($in{'scopeout'} eq 'list') { 
	if ($in{'listnameout'}) {
	    $pathout = &tools::get_template_path($type,$robot,$in{'scopeout'},$in{'template_nameout'},$in{'listnameout'});
	}else{
	    &report::reject_report_web('user','listname_needed',{},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	    &wwslog('info',"edit_template : no output lisname while output scope is list");
	    return 1;
	}
    }else{
	$pathout = &tools::get_template_path($type,$robot,$in{'scopeout'},$in{'template_nameout'});
    }
    
    
    $param->{'pathout'} = $pathout ;
    
    &tools::mk_parent_dir($pathout);

    unless (open (TPLOUT,">$pathout")) {
	&report::reject_report_web('intern','cannot_open_file',{'path' => $pathout},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	&wwslog('err',"edit_template: can't open file %s",$pathout);
	return undef;
    }
    print TPLOUT $param->{'template_content'};
    close TPLOUT;
    
    if ($in{'listnameout'}) {$in{'listname'} = $in{'listnameout'} ;}else{$in{'listname'} = undef; }
    $in{'template_name'} = $in{'template_nameout'};
    $in{'scope'} = $in{'scopeout'};
    $in{'template_path'} = $pathout;

    return ('edit_template');    
}

## online template edition
sub do_edit_template  {


    my $type =  $param->{'webormail'} = $in{'webormail'};
    my $template_name = $param->{'template_name'} = $in{'template_name'};
    my $listname = $param->{'listname'}= $in{'listname'};
    $param->{'template_path'} = $in{'template_path'};
    $param->{'scope'} = $in{'scope'};

    $in{'subdir'} = 'default' unless $in{'subdir'};
    $param->{'subdir'} = $in{'subdir'};

    &wwslog('info', "xxx do_edit_template(type=$type,template-name=$template_name,listname=$listname,path=$in{'template_path'},scope=$in{'scope'},lang=$in{'subdir'})");

    &do_view_template; 

    return 1 unless $in{'content'};

    my $pathout ; 
    my $scopeout = $param->{'scopeout'} = $in{'scopeout'} ;
    if ($in{'scopeout'} eq 'list') { 
	if ($listname) {
	    $pathout = &tools::get_template_path($type,$robot,$in{'scopeout'},$template_name,$in{'subdir'},$listname);
	}else{
	    &report::reject_report_web('user','listname_needed',{},$param->{'action'});
	    &wwslog('info',"edit_template : no output lisname while output scope is list");
	    return undef;
	}
    }
    
    $pathout = &tools::get_template_path($type,$robot,$in{'scopeout'},$template_name,$in{'subdir'});
    $param->{'pathout'} = $pathout ;
    
    unless (open (TPLOUT,">$pathout")) {
	&report::reject_report_web('intern','cannot_open_file',{'path' => $pathout},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	&wwslog('err',"edit_template: can't open file %s",$pathout);
	return undef;
    }
    print TPLOUT $in{'content'};
    close TPLOUT;

    $param->{'saved'} = 1;
    $param->{'template_content'} = $in{'content'};
    return 1;
    
}    


   ## Server show colors, and install static css in futur edit colors etc
sub do_skinsedit {
    &wwslog('info', 'do_skinsedit');
    my $f;
    
    unless ($param->{'user'}{'email'}) {
	&report::reject_report_web('user','no_user',{},$param->{'action'});
	&wwslog('info','do_skinsedit: no user');
	$param->{'previous_action'} = 'skinsedit';
	return 'loginrequest';
    }
    
    unless ($param->{'is_listmaster'}) {
	&report::reject_report_web('auth','action_listmaster',{},$param->{'action'},$list);
	&wwslog('info','do_admin: %s not listmaster', $param->{'user'}{'email'});
	return undef;
    }
    
    #    $param->{'conf'} = \%Conf;
    
    my $dir = &Conf::get_robot_conf($robot, 'css_path');
    my $css_url  = &Conf::get_robot_conf($robot, 'css_url');
	
    $param->{'css_warning'} = "parameter css_url seems strange, it must be the url of a directory not a css file" if ($css_url =~ /\.css$/);
    
    if ($in{'installcss'}) {

	my $lang = &Language::Lang2Locale($param->{'lang'});
	my $tt2_include_path = &tools::make_tt2_include_path($robot,'web_tt2',$lang,'');

	my $date= time;
	foreach my $css ('style.css','print.css','fullPage.css','print-preview.css') {
	    $param->{'css'} = $css;
	    
	    ## Keep a copy of the previous CSS
	    if (-f "$dir/$css") {
		unless (rename "$dir/$css", "$dir/$css.$date") {
		    &report::reject_report_web('intern','cannot_rename_file',{'path' => "$dir/$css.$date"},$param->{'action'},'',$param->{'user'}{'email'},$robot);
		    &wwslog('err','skinsedit : can\'t open file %s/%s.%s',$dir,$css,$date);
		    return undef;
		}
	    }
	    
	    unless (-d $dir) {
		unless (mkdir $dir, 0775) {
		    &report::reject_report_web('intern',"mkdir_failed",{'path' => $dir}, $param->{'action'},'',$param->{'user'}{'email'},$robot);
 		    &wwslog('err','skinsedit : failed to create directory %s : %s',$dir, $!);
  		    return undef;
  		}
 		chmod 0775, $dir;
 		&wwslog('notice','skinsedit : created missing directory %s',$dir);
 	    }
	    
	    unless (open (CSS,">$dir/$css")) {
		&report::reject_report_web('intern','cannot_open_file',{'path' => "$dir/$css"},$param->{'action'},'',$param->{'user'}{'email'},$robot);
		&wwslog('err','skinsedit : can\'t open file (write) %s/%s',$dir,$css);
		return undef;
	    }
	    unless (&tt2::parse_tt2($param,'css.tt2' ,\*CSS, $tt2_include_path)) {
		my $error = &tt2::get_error();
		$param->{'tt2_error'} = $error;
		&List::send_notify_to_listmaster('web_tt2_error', $robot,[$error]);
		&wwslog('info', "do_skinsedit : error while installing $dir/$css");
	    }
	    close (CSS) ;
	    
	    ## Make the CSS readable to anyone
	    chmod 0775, "$dir/$css";
	}  
	$param->{'css_result'} = 1 ;
    }
    return 1;
}


 ## Multiple add
 sub do_add_request {
     &wwslog('info', 'do_add_request(%s)', $in{'email'});

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_add_request: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_add_request: no user');
	 $param->{'previous_action'} = 'add_request';
	 $param->{'previous_list'} = $in{'list'};
	 return 'loginrequest';
     }

     ## Access control
     return undef unless (defined &check_authz('do_add_request', 'add'));

     return 1;
 }


####################################################
#  do_add                           
####################################################
#  Adds a user to a list (requested by an other user)
# 
# IN : -
#
# OUT : 'loginrequest' 
#      | ($in{'previous_action'} || 'review')
#      | undef
####################################################
## TODO: v�rifier validit� email
 sub do_add {
     &wwslog('info', 'do_add(%s)', $in{'email'}||$in{'pending_email'});

     my %user;

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_add: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_add: no user');
	 return 'loginrequest';
     }

     if ($in{'dump'}) {
	 foreach (split /\n/, $in{'dump'}) {
	     if (/^($tools::regexp{'email'})(\s+(.*))?\s*$/) {
		 $user{&tools::get_canonical_email($1)} = $5;
	     }
	 }
     }elsif ($in{'email'} =~ /,/) {
	 foreach my $pair (split /\0/, $in{'email'}) {
	     if ($pair =~ /^($tools::regexp{'email'})(,(.*))?\s*$/) {
		 $user{&tools::get_canonical_email($1)} = $5;
	     }
	 }
     }elsif ($in{'email'}) {
	 $user{&tools::get_canonical_email($in{'email'})} = $in{'gecos'};
     }elsif ($in{'pending_email'}) {
	 foreach my $pair (split /\0/, $in{'pending_email'}) {
	     my ($email, $gecos);
	     if ($pair =~ /^($tools::regexp{'email'})(,(.*))?\s*$/) {
		 ($email, $gecos) = ($1,$5);
		 $user{&tools::get_canonical_email($email)} = $gecos;
	     }
	 }
     }else {
	 &report::reject_report_web('user','no_email',{},$param->{'action'});
	 &wwslog('info','do_add: no email');
	 return undef;
     }

     my ($total, @new_users );
     my $comma_emails ;
     foreach my $email (keys %user) {

	 my $result = $list->check_list_authz('add',$param->{'auth_method'},
					      {'sender' => $param->{'user'}{'email'}, 
					       'email' => $in{'email'},
					       'remote_host' => $param->{'remote_host'},
					       'remote_addr' => $param->{'remote_addr'}});
	 my $add_is;
	 my $reason;
	 if (ref($result) eq 'HASH') {
	     $add_is = $result->{'action'};
	     $reason = $result->{'reason'};
	 }
	 
	 unless ($add_is =~ /do_it/) {
	     &report::reject_report_web('auth',$reason,{},$param->{'action'},$list);
	     &wwslog('info','do_add: %s may not add', $param->{'user'}{'email'});
	     ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'add',$param->{'list'},$robot,$in{'email'},'may not');
	     next;
	 }
	 
	 unless (&tools::valid_email($email)) {
	     &report::reject_report_web('user','incorrect_email',{'email' => $email},$param->{'action'},$list);
	     &wwslog('info','do_add: incorrect email %s', $email);
	     ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'add',$param->{'list'},$robot,$email,"incorrect_email");
	     next;
	 }

	 my $user_entry = $list->get_subscriber($email);
	 
	 if ( defined($user_entry) && ($user_entry->{'subscribed'} == 1)) {
	     &report::reject_report_web('user','user_already_subscriber', {'list' => $list->{'name'},'email' => $email},$param->{'action'},$list);
	     &wwslog('info','do_add: %s already subscriber', $email);
	     ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'add',$param->{'list'},$robot,$email,"already subscriber");
	     next;
	 }
	 
	 ## If already included
	 if (defined($user_entry)) {
	     unless ($list->update_user($email, 
					{'subscribed' => 1,
					 'update_date' => time})) {
		 &report::reject_report_web('intern','update_subscriber_db_failed',{'sub'=>$email},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('info', 'do_add: update failed');
		 ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'add',$param->{'list'},$robot,$email,"update failed");
		 return undef;
	     }
	     ('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'add',$param->{'list'},$robot,$email,"updated");
	     
	 }else {
	     my $u2 = &List::get_user_db($email);
	     my $defaults = $list->get_default_user_options();
	     my $u;
	     %{$u} = %{$defaults};
	     $u->{'email'} = $email;
	     $u->{'gecos'} = $user{$email} || $u2->{'gecos'};
	     $u->{'date'} = $u->{'update_date'} = time;
	     $u->{'password'} = $u2->{'password'} || &tools::tmp_passwd($email) ;
	     $u->{'lang'} = $u2->{'lang'} || $list->{'admin'}{'lang'};
	     if ($comma_emails) {
		 $comma_emails = $comma_emails .','. $email;
	     }else{
		 $comma_emails = $email;
	     }

	     ##
	     push @new_users, $u;
	 }

	 ## Delete subscription request if any
	 $list->delete_subscription_request($email);

	 unless ($in{'quiet'} || ($add_is =~ /quiet/i )) {
	     unless ($list->send_file('welcome', $email, $robot,{})) {
		 &wwslog('notice',"Unable to send template 'welcome' to $email");
	     }
	 }
     }

     $total = $list->add_user(@new_users);
     unless( defined $total) {
	 &report::reject_report_web('intern','add_subscriber_db_failed',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('info','do_add: failed adding');
	 # &List::db_log('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'add',$param->{'list'},$robot,$comma_emails,'failed',$total);
	 return undef;
     }

     $list->save();
     &report::notice_report_web('add_performed', {'total' => $total},$param->{'action'});
     # &List::db_log('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'add',$param->{'list'},$robot,$comma_emails,'done',$total) if (@new_users);
     
     $in{'list'} = $in{'previous_list'} if ($in{'previous_list'});
     return $in{'previous_action'} || 'review';
 }



####################################################
#  do_del                           
####################################################
#  Deletes a user from a list (requested by an other user)
# 
# IN : -
#
# OUT : 'loginrequest' 
#      | ($in{'previous_action'} || 'review') | undef
#
####################################################
 ## TODO: v�rifier validit� email
 sub do_del {
     &wwslog('info', 'do_del()');

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_del: no list');
	 return undef;
     }

     unless ($in{'email'}) {
	 &report::reject_report_web('user','no_email',{},$param->{'action'});
	 &wwslog('info','do_del: no email');
	 return undef;
     }

     $in{'email'} = &tools::unescape_chars($in{'email'});

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_del: no user');
	 return 'loginrequest';
     }
     
     my $result = $list->check_list_authz('del',$param->{'auth_method'},
					  {'sender' => $param->{'user'}{'email'},
					   'email' => $in{'email'},
					   'remote_host' => $param->{'remote_host'},
					   'remote_addr' => $param->{'remote_addr'}});
     my $del_is;
     my $reason;
     if (ref($result) eq 'HASH') {
	 $del_is = $result->{'action'};
	 $reason = $result->{'reason'};
     }
     
     unless ( $del_is =~ /do_it/) {
	 &report::reject_report_web('auth',$reason,{},$param->{'action'},$list);
	 # &List::db_log('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'del',$param->{'list'},$robot,$in{'email'},'may not');
	 &wwslog('info','do_del: %s may not del', $param->{'user'}{'email'});
	 return undef;
     }

     my @emails = split /\0/, $in{'email'};

     my ($total, @removed_users);

     foreach my $email (@emails) {

	 my $escaped_email = &tools::escape_chars($email);

	 my $user_entry = $list->get_subscriber($email);

	 unless ( defined($user_entry) && ($user_entry->{'subscribed'} == 1) ) {
	     &report::reject_report_web('user','not_subscriber',{'email' => $email},$param->{'action'},$list);
	     # &List::db_log('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'del',$param->{'list'},$robot,$email,'not subscriber');
	     &wwslog('info','do_del: %s not subscribed', $email);
	     next;
	 }

	 if ($user_entry->{'included'}) {
	     unless ($list->update_user($email, 
					{'subscribed' => 0,
					 'update_date' => time})) {
		 &report::reject_report_web('intern','update_subscriber_db_failed',{'sub'=>$email},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 # &List::db_log('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'del',$param->{'list'},$robot,$email,'failed subscriber included');
		 &wwslog('info', 'do_del: update failed');
		 return undef;
	     }


	 }else {
	     push @removed_users, $email;
	 }
	 
	 my $bounce_dir = $list->get_bounce_dir();

	 if (-f $bounce_dir.'/'.$escaped_email) {
	     unless (unlink $bounce_dir.'/'.$escaped_email) {
		 &wwslog('info','do_resetbounce: failed deleting %s', $bounce_dir.'/'.$escaped_email);
		 next;
	     }
	 }


	 &wwslog('info','do_del: subscriber %s deleted from list %s', $email, $param->{'list'});

	 unless ($in{'quiet'}) {
	     unless ($list->send_file('removed', $email, $robot,{})) {
		 &wwslog('notice',"Unable to send template 'removed' to $email");
	     }
	 }
     }

     $total = $list->delete_user(@removed_users);

     unless( defined $total) {
	 &report::reject_report_web('intern','delete_subscriber_db_failed',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('info','do_del: failed');
	 # &List::db_log('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'del',$param->{'list'},$robot,join('.',@removed_users),'failed');
	 return undef;
     }
     # &List::db_log('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'del',$param->{'list'},$robot,join(',',@removed_users),'done',$total) if (@removed_users) ;
     $list->save();

     &report::notice_report_web('del_performed',{'total' => $total},$param->{'action'});
     $param->{'is_subscriber'} = 1;
     $param->{'may_signoff'} = 1;

     ## Skip search because we don't have the expression anymore
     delete $in{'previous_action'} if ($in{'previous_action'} eq 'search');

     return $in{'previous_action'} || 'review';
 }


####################################################
#  do_modindex
####################################################
#  Web page for an editor to moderate documents and
#  and/or to tag message in message topic context
# 
# IN : -
#
# OUT : 'loginrequest' | 'admin' | '1' | undef
#
####################################################### 
 sub do_modindex {
     &wwslog('info', 'do_modindex');
     my $msg;
     my $doc;

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_modindex: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'},$list);
	 &wwslog('err','do_modindex: no user');
	 $param->{'previous_action'} = 'modindex';
	 $param->{'previous_list'} = $in{'list'};
	 return 'loginrequest';
     }

     unless ($list->am_i('editor', $param->{'user'}{'email'})) {
	 &report::reject_report_web('auth','action_editor',{},$param->{'action'},$list);
	 &wwslog('err','do_modindex: %s not editor', $param->{'user'}{'email'});
	 return 'admin';
     }

     ## Loads message list
     unless (opendir SPOOL, $Conf{'queuemod'}) {
	 &report::reject_report_web('intern','cannot_open_spool',{'spool'=>$Conf{'queuemod'}},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('err','do_modindex: unable to read spool');
	 return 'admin';
     }

     my $list_name = $list->{'name'};
     my $list_id = $list->get_list_id();
     foreach $msg ( sort grep(!/^\./, readdir SPOOL )) {
	 next
	     unless ($msg =~ /^$list_id\_(\w+)$/ ||
		     $msg =~ /^$list_name\_(\w+)$/);

	 my $id = $1;

	 ## Load msg
	 my $mail = new Message("$Conf{'queuemod'}/$msg");
	 
	 unless (defined $mail) {
	     &report::reject_report_web('intern','cannot_get_msg',{'msg'=>"$Conf{'queuemod'}/$msg"},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err','do_modindex: unable to parse msg %s', $msg);
	     closedir SPOOL;
	     return 'admin';
	 }


	 $param->{'spool'}{$id}{'size'} = int( (-s "$Conf{'queuemod'}/$msg") / 1024 + 0.5);
	 $param->{'spool'}{$id}{'subject'} =  &MIME::Words::decode_mimewords($mail->{'msg'}->head->get('Subject'));
	 $param->{'spool'}{$id}{'subject'} ||= 'no_subject';
	 $param->{'spool'}{$id}{'date'} = $mail->{'msg'}->head->get('Date');
	 $param->{'spool'}{$id}{'from'} = &MIME::Words::decode_mimewords($mail->{'msg'}->head->get('From'));
	 foreach my $field ('subject','date','from') {
	     $param->{'spool'}{$id}{$field} =~ s/</&lt;/;
	     $param->{'spool'}{$id}{$field} =~ s/>/&gt;/;
	 }
     }
     closedir SPOOL;

     if ($list->is_there_msg_topic()) {

	 $param->{'request_topic'} = 1;
     
	 foreach my $top (@{$list->{'admin'}{'msg_topic'}}) {
	     if ($top->{'name'}) {
		 push (@{$param->{'available_topics'}},$top);
	     }
	 }
	 $param->{'topic_required'} = $list->is_msg_topic_tagging_required();
     }



     ##  document shared awaiting for moderation
     foreach my $d (@{$param->{'doc_mod_list'}}) {
	 
         $d =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/;
	 
	 my $path = $1; # path without the filename
	 my $fname = $3; # the filename with .moderate
	 my $visible_fname = &make_visible_path($fname); # the filename without .moderate
	 my $visible_path = $path;
	 $visible_path =~ s/^.*\/shared//; #the path for the user, without the filename

	 my %desc_hash;
	 if ($d  && (-e "$path.desc.$fname")){
	     %desc_hash = &get_desc_file("$path.desc.$fname");
	 }

	 my @info = stat $d;

	 my $doc = {};
	 $doc->{'visible_path'} = "$visible_path";
         $doc->{'visible_fname'} = "$visible_fname";
	 $doc->{'fname'} = "$fname";
	 $doc->{'size'} = (-s $d)/1000; 
	 $doc->{'date'} = POSIX::strftime("%d %b %Y", localtime($info[9]));
	 $doc->{'author'} = $desc_hash{'email'};
         $doc->{'path'} = $d;
	
	 push(@{$param->{'info_doc_mod'}},$doc)
     }
    
     unless (($param->{'spool'}) || ($param->{'mod_total_shared'} > 0)) {
	 &report::notice_report_web('no_msg_document', {'list' => $in{'list'}},$param->{'action'});
	 &wwslog('err','do_modindex: no message and no document');
	 return 'admin';
     }

     return 1;
 }

### installation of moderated documents of shared
 sub do_d_install_shared {
     &wwslog('info', 'do_d_install_shared()');

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_d_install_shared: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('err','do_d_install_shared: no user');
	 return 'loginrequest';
     }

     unless ($list->am_i('editor', $param->{'user'}{'email'})) {
	 &report::reject_report_web('auth','action_editor',{},$param->{'action'},$list);
	 &wwslog('err','do_d_install_shared: %s not editor', $param->{'user'}{'email'});
	 return undef;
     }

     unless ($in{'id'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'docid'},$param->{'action'});
	 &wwslog('err','do_d_install_shared: no docid');
	 return undef;
     }

     if ($in{'mode_cancel'}) {
	 return 'modindex';
     }

     my $shareddir =  $list->{'dir'}.'/shared';
     my $file;
     my $slash_path;
     my $fname;
     my $visible_fname;
     # list of file already existing
     my @list_file_exist;
    
     unless($in{'mode_confirm'} || $in{'mode_cancel'}) {

	 # file already exists ?
	 foreach my $id (split /\0/, $in{'id'}) {
	   
	     $file = "$shareddir$id";
	     $id =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
	     $slash_path = $1; 
	     $fname = $3; 
	     $visible_fname = &make_visible_path($fname);
	     
	     if (-e "$file") {
		 if (-e "$shareddir$slash_path$visible_fname") {
		     push(@list_file_exist,"$slash_path$visible_fname");
		 }
	     }   
	 }
	 
	 if (@list_file_exist) {

	     $param->{'list_file'}=\@list_file_exist;
	     my @id = split(/\0/,$in{'id'});
	     $param->{'id'} = \@id;

     return 1;
 }
     }
     
     # install the file(s) selected
     foreach my $id (split /\0/, $in{'id'}) {

	 $file = "$shareddir$id";
         $id =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
	 $slash_path = $1;
	 $fname = $3;
	 $visible_fname = &make_visible_path($fname);
	 
     	 if (-e "$file") {
	     
	     # rename the old file in .old if exists
	     if (-e "$shareddir$slash_path$visible_fname") {
		 unless (rename "$shareddir$slash_path$visible_fname","$shareddir$slash_path$visible_fname.old"){
		     &report::reject_report_web('intern','rename_file',{'old'=>"$shareddir$slash_path$visible_fname", 
									'new'=>"$shareddir$slash_path$visible_fname.old" },
						$param->{'action'},$list,$param->{'user'}{'email'},$robot);
		     &wwslog('err',"do_d_install_shared : Failed to rename $shareddir$slash_path$visible_fname to .old : %s",$!);
		     return undef;
		 }
		 unless (rename "$shareddir$slash_path.desc.$visible_fname","$shareddir$slash_path.desc.$visible_fname.old"){
		     &report::reject_report_web('intern','rename_file',{'old'=>"$shareddir$slash_path.desc.$visible_fname", 
									'new'=>"$shareddir$slash_path.desc.$visible_fname.old"},
						$param->{'action'},$list,$param->{'user'}{'email'},$robot);
		     &wwslog('err',"do_d_install_shared : Failed to rename shareddir$slash_path.desc.$visible_fname to .old : %s",$!);
		     return undef;
		 }
		 
	     }

	     unless (rename ("$shareddir$id","$shareddir$slash_path$visible_fname")){
		 &report::reject_report_web('intern','rename_file',{'old'=>"$shareddir$id", 
								    'new'=>"$shareddir$slash_path$visible_fname"},
					    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('err',"do_d_install_shared : Failed to rename $file to $shareddir$slash_path$visible_fname : $!");
		 return undef; 
	     }
	     unless (rename ("$shareddir$slash_path.desc.$fname","$shareddir$slash_path.desc.$visible_fname")){
		 &report::reject_report_web('intern','rename_file',{'old'=>"$shareddir$slash_path.desc.$fname", 
								    'new'=>"$shareddir$slash_path.desc.$visible_fname"},
					    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('err',"do_d_install_shared : Failed to rename $file to $shareddir$slash_path$visible_fname : $!");
		 return undef; 
	     }
	    
	     # send a message to the author
	     my %context;
	     $context{'installed_by'} = $param->{'user'}{'email'};
	     $context{'filename'} = "$slash_path$visible_fname";
	     
	     my %desc_hash;
	     if ($id  && (-e "$shareddir$slash_path.desc.$visible_fname")){
		 %desc_hash = &get_desc_file("$shareddir$slash_path.desc.$visible_fname");
	     }
	     
	     my $sender = $desc_hash{'email'};
	     unless ($list->send_file('d_install_shared', $sender, $robot, \%context)) {
 		 &wwslog('notice',"Unable to send template 'd_install_shared' to $sender");
 	     }	     
	 } 
     }
      
     &report::notice_report_web('performed',{},$param->{'action'});
     return 'modindex';
 }

### reject moderated documents of shared
 sub do_d_reject_shared {
     &wwslog('info', 'do_d_reject_shared()');
  
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_d_reject_shared: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('err','do_d_reject_shared: no user');
	 return 'loginrequest';
     }

     unless ($list->am_i('editor', $param->{'user'}{'email'})) {
	 &report::reject_report_web('auth','action_editor',{},$param->{'action'},$list);
	 &wwslog('err','do_d_reject_shared: %s not editor', $param->{'user'}{'email'});
	 return undef;
     }

     unless ($in{'id'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'docid'},$param->{'action'});
	 &wwslog('err','do_reject: no docid');
	 return undef;
     }

     my $shareddir =  $list->{'dir'}.'/shared';
     my $file;
     my $slash_path;
     my $fname;
     my $visible_fname;

     foreach my $id (split /\0/, $in{'id'}) {

	 $file = "$shareddir$id";
         $id =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
	 $slash_path = $1;
	 $fname = $3;
	 $visible_fname = &make_visible_path($fname); 

	 unless ($in{'quiet'}) {
	     
	     my %context;
	     my $sender;
	     $context{'rejected_by'} = $param->{'user'}{'email'};
	     $context{'filename'} = "$slash_path$visible_fname";
	     
	     my %desc_hash;
	     if ($id  && (-e "$shareddir$slash_path.desc.$fname")){
		 %desc_hash = &get_desc_file("$shareddir$slash_path.desc.$fname");
	     }
	     $sender = $desc_hash{'email'};
	     
 	     unless ($list->send_file('d_reject_shared', $sender, $robot, \%context)) {
 		 &wwslog('notice',"Unable to send template 'd_reject_shared' to $sender");
 	     }
	 }


	 unless (unlink($file)) {
	     &report::reject_report_web('intern','erase_file',{'file' => $file},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err','do_d_reject_shared: failed to erase %s', $file);
	     return undef;
	 }

	 unless (unlink("$shareddir$slash_path.desc.$fname")) {
	     &report::reject_report_web('intern','erase_file',{'file' => "$shareddir$slash_path.desc.$fname"},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err',"do_d_reject_shared: failed to erase $shareddir$slash_path.desc.$fname");
	     return undef;
	 } 
     }

     &report::notice_report_web('performed',{},$param->{'action'});
     return 'modindex';
 }



####################################################
#  do_reject
####################################################
#  Moderation of messages : rejects messages and notifies 
#  their senders
# 
# IN : -
#
# OUT : 'loginrequest' | 'modindex' | undef
#      
####################################################
 sub do_reject {

     $in{'id'} =~ s/\0/,/g;
     
    &wwslog('info', 'do_reject(%s)', $in{'id'});
     my ($msg, $file);

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_reject: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('err','do_reject: no user');
	 return 'loginrequest';
     }

     unless ($list->am_i('editor', $param->{'user'}{'email'})) {
	 &report::reject_report_web('auth','action_editor',{},$param->{'action'},$list);
	 &wwslog('err','do_reject: %s not editor', $param->{'user'}{'email'});
	 return undef;
     }

     unless ($in{'id'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'msgid'},$param->{'action'});
	 &wwslog('err','do_reject: no msgid');
	 return undef;
     }

     foreach my $id (split /,/, $in{'id'}) {

	 ## For compatibility concerns
	 foreach my $list_id ($list->get_list_id(),$list->{'name'}) {
	     $file = $Conf{'queuemod'}.'/'.$list_id.'_'.$id;
	     last if (-f $file);
	 }

	 ## Open the file
	 unless (open(IN, $file)) {
	     &report::reject_report_web('user','already_moderated',{},$param->{'action'});
	     &wwslog('err','do_reject: Unable to open %s', $file);
	     next;
	 }
	 unless ($in{'quiet'}) {
	     my $msg;
	     my $parser = new MIME::Parser;
	     $parser->output_to_core(1);
	     unless ($msg = $parser->read(\*IN)) {
		 &wwslog('err', 'Unable to parse message %s', $file);
		 next;
	     }
	     
	     my @sender_hdr = Mail::Address->parse($msg->head->get('From'));
	     unless  ($#sender_hdr == -1) {
		 my $rejected_sender = $sender_hdr[0]->address;
		 my %context;
		 $context{'subject'} = &MIME::Words::decode_mimewords($msg->head->get('subject'));
		 $context{'rejected_by'} = $param->{'user'}{'email'};
		 unless ($list->send_file('reject', $rejected_sender, $robot, \%context)) {
		     &wwslog('notice',"Unable to send template 'reject' to $rejected_sender");
		 }
	     }
	 }
	 close(IN);  

	 unless (unlink($file)) {
	     &report::reject_report_web('intern','erase_file',{'file' => $file},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err','do_reject: failed to erase %s', $file);
	     return undef;
	 }

     }

     &report::notice_report_web('performed',{},$param->{'action'});

     return 'modindex';
 }

####################################################
#  do_distribute
####################################################
#  Moderation of messages : distributes moderated 
#  messages and tag it in message moderation context
# 
# IN : -
#
# OUT : 'loginrequest' | 'modindex' | undef
#      
###################################################### 
 sub do_distribute {

     $in{'id'} =~ s/\0/,/g;

     &wwslog('info', 'do_distribute(%s)', $in{'id'});
     my ($msg, $file);

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_distribute: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('err','do_distribute: no user');
	 return 'loginrequest';
     }

     unless ($list->am_i('editor', $param->{'user'}{'email'})) {
	 &report::reject_report_web('auth','action_editor',{},$param->{'action'},$list);
	 &wwslog('err','do_distribute: %s not editor', $param->{'user'}{'email'});
	 return undef;
     }

     unless ($in{'id'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'msgid'},$param->{'action'});
	 &wwslog('err','do_distribute: no msgid');
	 return undef;
     }

     my $time = time;
     my $data = {'headers' => {'Message-ID' => &tools::get_message_id($robot)},
		 'from'=> $param->{'user'}{'email'}};

     ## msg topics
     my @msg_topics;
     foreach my $msg_topic (@{$list->{'admin'}{'msg_topic'}}) {
	 my $var_name = "topic_"."$msg_topic->{'name'}";
	 if ($in{"$var_name"}) {
	     push @msg_topics, $msg_topic->{'name'};
	 }
     }	 
     my $list_topics = join(',',@msg_topics);
    
     if (!$list_topics && $list->is_msg_topic_tagging_required()) {
	 &report::reject_report_web('user','msg_topic_missing',{},$param->{'action'});
	 &wwslog('info','do_distribute: message(s) without topic topic but in a required list');
	 return undef;
     } 


     ## messages
     foreach my $id (split /,/, $in{'id'}) {
	 my $mail_command = sprintf ("QUIET DISTRIBUTE %s %s\n",$list->{'name'},$id);
	 $data->{'body'} .= $mail_command;


	 ## For compatibility concerns
	 foreach my $list_id ($list->get_list_id(),$list->{'name'}) {
	     $file = $Conf{'queuemod'}.'/'.$list_id.'_'.$id;
	     last if (-f $file);
	 }

	 unless (-f $file) {
	     &report::reject_report_web('user','already_moderated',{},$param->{'action'});
	     &wwslog('err','do_distribute: Unable to open %s', $file);
	     next;
	 }

	 ## TAG 
	 if ($list_topics) {

	     my $parser = new MIME::Parser;
	     $parser->output_to_core(1);
	     
	     unless (open FILE, "$file") {
		 &wwslog('notice', 'do_distribute: Cannot open file %s', $file);
		 &report::reject_report_web('intern','cannot_open_file',{'file' => $file},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 return undef;
	     }

	     my $msg = $parser->parse(\*FILE);
	     my $head = $msg->head();
	     my $filetopic = $list->tag_topic(&tools::clean_msg_id($head->get('Message-Id')),$list_topics,'editor');
	 }
	 
	 unless (rename($file,"$file.distribute")) {
	     &report::reject_report_web('intern','rename_file',{'old'=>$file,
								'new'=>"$file.distribute"},
					$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err','do_distribute: failed to rename %s', $file);
	 }
     }

     unless (&mail::mail_file('',&Conf::get_robot_conf($robot, 'sympa'), $data, $robot)) {
	 &report::reject_report_web('intern','cannot_send_distribute',{'from' => $param->{'user'}{'email'},'listname'=>$list->{'name'}},
				    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('err','do_distribute: failed to send message for file %s', $file);
	 return undef;
     }

     &report::notice_report_web('performed_soon',{},$param->{'action'});

     return 'modindex';
 }

####################################################
#  do_viewmod
####################################################
#  Web page for an editor to moderate a mail and/or 
#  to tag it in message topic context
# 
# IN : -
#
# OUT : 'login,request' | '1' | undef
#
####################################################
sub do_viewmod {
     &wwslog('info', 'do_viewmod(%s)', $in{'id'});
     my $msg;

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_viewmod: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('err','do_viewmod: no user');
	 return 'loginrequest';
     }

     unless ($in{'id'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'msgid'},$param->{'action'});
	 &wwslog('err','do_viewmod: no msgid');
	 return undef;
     }

     unless ($list->am_i('editor', $param->{'user'}{'email'})) {
	 &report::reject_report_web('auth','action_editor',{},$param->{'action'},$list);
	 &wwslog('err','do_viewmod: %s not editor', $param->{'user'}{'email'});
	 return undef;
     }

     my $tmp_dir;
     ## For compatibility concerns
     foreach my $list_id ($list->get_list_id(),$list->{'name'}) {
	 $tmp_dir = $Conf{'queuemod'}.'/.'.$list_id.'_'.$in{'id'};
	 if (-d $tmp_dir) {
	     last;
	 }
     }
     
     unless (-d $tmp_dir) {
	 &report::reject_report_web('intern','no_html_message_available',{'dir' => $tmp_dir},$param->{'action'});
	 &wwslog('err','do_viewmod: no HTML version of the message available in %s', $tmp_dir);
	 return undef;
     }

     if ($in{'file'}) {
	 $in{'file'} =~ /\.(\w+)$/;
	 $param->{'file_extension'} = $1;
	 $param->{'file'} = $tmp_dir.'/'.$in{'file'};
	 $param->{'bypass'} = 1;
     }else {
	 &tt2::add_include_path($tmp_dir) ;
     }

     $param->{'base'} = sprintf "%s/viewmod/%s/%s/", &Conf::get_robot_conf($robot, 'wwsympa_url'), $param->{'list'}, $in{'id'};
     $param->{'id'} = $in{'id'};

     if ($list->is_there_msg_topic()) {

	 $param->{'request_topic'} = 1;
     
	 foreach my $top (@{$list->{'admin'}{'msg_topic'}}) {
	     if ($top->{'name'}) {
		 push (@{$param->{'available_topics'}},$top);
	     }
	 }
	 $param->{'topic_required'} = $list->is_msg_topic_tagging_required();
     }

     return 1;
 }


## Edition of list/sympa files
## No list -> sympa files (helpfile,...)
## TODO : upload
## TODO : edit family file ???
 sub do_editfile {
     &wwslog('info', 'do_editfile(%s)', $in{'file'});

     $param->{'subtitle'} = sprintf $param->{'subtitle'}, $in{'file'};

     unless ($in{'file'}) {
	 ## Messages edition
	 foreach my $f ('info','homepage','welcome.tt2','bye.tt2','removed.tt2','message.footer','message.header','remind.tt2','invite.tt2','reject.tt2','your_infected_msg.tt2') {
	     next unless ($list->may_edit($f, $param->{'user'}{'email'}) eq 'write');
	     if ($wwslib::filenames{$f}{'gettext_id'}) {
		 $param->{'files'}{$f}{'complete'} = gettext($wwslib::filenames{$f}{'gettext_id'});
	     }else {
		 $param->{'files'}{$f}{'complete'} = $f;
	     }
	     $param->{'files'}{$f}{'selected'} = '';
	 }
	 return 1;
     }

     unless (defined $wwslib::filenames{$in{'file'}}) {
	 &report::reject_report_web('user','file_not_editable',{'file' => $in{'file'}},$param->{'action'});
	 &wwslog('err','do_editfile: file %s not editable', $in{'file'});
	 return undef;
     }

     $param->{'file'} = $in{'file'};

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('err','do_editfile: no user');
	 return 'loginrequest';
     }
     
     my $subdir = '';
     if ($in{'file'} =~ /\.tt2$/) {
	 $subdir = 'mail_tt2/';
     }

     if ($param->{'list'}) {
	 my ($role,$right) = $list->may_edit($in{'file'}, $param->{'user'}{'email'});

	 unless ($right eq 'write') {
	     &report::reject_report_web('auth','edit_right',{'role'=>$role, 'right' => $right},$param->{'action'},$list);
	     &wwslog('err','do_editfile: not allowed');
	     return undef;
	 }

	 ## Add list lang to tpl filename
	 my $file = $in{'file'};
	 #$file =~ s/\.tpl$/\.$list->{'admin'}{'lang'}\.tpl/;

	 ## Look for the template
	 $param->{'filepath'} = &tools::get_filename('etc',$subdir.$file,$robot, $list);

	 ## Default for 'homepage' is 'info'
	 if (($in{'file'} eq 'homepage') &&
	     ! $param->{'filepath'}) {
	     $param->{'filepath'} = &tools::get_filename('etc',$subdir.'info',$robot, $list);
	 }
     }else {
	 unless (&List::is_listmaster($param->{'user'}{'email'},$robot)) {
	     &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	     &wwslog('err','do_editfile: no list');
	     return undef;
	 }

	 my $file = $in{'file'};

	 ## Look for the template
	 if ($file eq 'list_aliases.tt2') {
	     $param->{'filepath'} = &tools::get_filename('etc',$file,$robot,$list);
	 }else {
	     #my $lang = &Conf::get_robot_conf($robot, 'lang');
	     #$file =~ s/\.tpl$/\.$lang\.tpl/;

	     $param->{'filepath'} = &tools::get_filename('etc',$subdir.$file,$robot,$list);
	 }
     }

     if ($param->{'filepath'} && (! -r $param->{'filepath'})) {
	 &report::reject_report_web('intern','cannot_read',{'filepath' => $param->{'filepath'}},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	 &wwslog('err','do_editfile: cannot read %s', $param->{'filepath'});
	 return undef;
     }

     &tt2::allow_absolute_path();

     return 1;
 }





#####################################################################################

 ## Saving of list files
 sub do_savefile {
     &wwslog('info', 'do_savefile(%s)', $in{'file'});

     $param->{'subtitle'} = sprintf $param->{'subtitle'}, $in{'file'};

     unless ($in{'file'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_savefile: no file');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('err','do_savefile: no user');
	 return 'loginrequest';
     }

     if ($param->{'list'}) {
	 unless ($list->am_i('owner', $param->{'user'}{'email'})) {
	     &report::reject_report_web('auth','action_owner',{},$param->{'action'},$list);
	     &wwslog('err','do_savefile: not allowed');
	     return undef;
	 }

	 if ($in{'file'} =~ /\.tt2$/) {
	     $param->{'filepath'} = $list->{'dir'}.'/mail_tt2/'.$in{'file'};
	 }else {
	     $param->{'filepath'} = $list->{'dir'}.'/'.$in{'file'};
	     
	     if (defined $list->{'admin'}{'family_name'}) {
		 unless ($list->update_config_changes('file',$in{'file'})) {
		     &report::reject_report_web('intern','update_config_changes',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
		     &wwslog('info','do_savefile: cannot write in config_changes for file %s', $param->{'filepath'});
		     return undef;
		 }
	     }

	 }
     }else {
	 unless (&List::is_listmaster($param->{'user'}{'email'}),$robot) {
	     &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	     &wwslog('err','do_savefile: no list');
	     return undef;
	 }

	 if ($robot ne $Conf{'domain'}) {
	     if ($in{'file'} eq 'list_aliases.tt2') {
		 $param->{'filepath'} = "$Conf{'etc'}/$robot/$in{'file'}";
	     }else {
		 $param->{'filepath'} = "$Conf{'etc'}/$robot/mail_tt2/$in{'file'}";
	     }
	 }else {
	      if ($in{'file'} eq 'list_aliases.tt2') {
		  $param->{'filepath'} = "$Conf{'etc'}/$in{'file'}";
	      }else {
		  $param->{'filepath'} = "$Conf{'etc'}/mail_tt2/$in{'file'}";
	      }
	 }
     }

     unless ((! -e $param->{'filepath'}) or (-w $param->{'filepath'})) {
	 &report::reject_report_web('intern','cannot_write',{'filepath' => $param->{'filepath'}},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('err','do_savefile: cannot write %s', $param->{'filepath'});
	 return undef;
     }

     ## Keep the old file
     if (-e $param->{'filepath'}) {
	 rename($param->{'filepath'}, "$param->{'filepath'}.orig");
     }

     ## Not empty
     if ($in{'content'} && ($in{'content'} !~ /^\s*$/)) {			

	 ## Remove DOS linefeeds (^M) that cause problems with Outlook 98, AOL, and EIMS:
	 $in{'content'} =~ s/\015//g;

	 ## Create directory if required
	 my $dir = $param->{'filepath'};
	 $dir =~ s/\/[^\/]+$//;
	 unless (-d $dir) {
	     unless (mkdir $dir, 0777) {
		 &report::reject_report_web('intern','cannot_mkdir',{'dir' => $dir},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('err','do_savefile: failed to create directory %s: %s', $dir,$!);
		 return undef;	 
	     }
	 }
     
	 ## Save new file
	 unless (open FILE, ">$param->{'filepath'}") {
	     &report::reject_report_web('intern','cannot_open_file',{'file' => $param->{'filepath'}},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err','do_savefile: failed to save file %s: %s', $param->{'filepath'},$!);
	     return undef;
	 }
	 print FILE $in{'content'};
	 close FILE;
     }elsif (-f $param->{'filepath'}) {
	 &wwslog('info', 'do_savefile: deleting %s', $param->{'filepath'});
	 unlink $param->{'filepath'};
     }

     &report::notice_report_web('performed',{},$param->{'action'});

 #    undef $in{'file'};
 #    undef $param->{'file'};
     return 'editfile';
 }

 ## Access to web archives
 sub do_arc {
     &wwslog('info', 'do_arc(%s, %s)', $in{'month'}, $in{'arc_file'});

# OpenFoundry
$in{'arc_file'} =~ s#/$##;

     my $latest;
     my $index = $wwsconf->{'archive_default_index'};

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_arc: no list');
	 return undef;
     }

     ## Access control
     unless (defined &check_authz('do_arc', 'web_archive.access')) {
	 $param->{'previous_action'} = 'arc';
	 $param->{'previous_list'} = $list->{'name'};
	 return undef;
     }

     if ($list->{'admin'}{'web_archive_spam_protection'} eq 'cookie'){
	 ## Reject Email Sniffers
	 unless (&cookielib::check_arc_cookie($ENV{'HTTP_COOKIE'})) {
	     if ($param->{'user'}{'email'} or $in{'not_a_sniffer'}) {
		 &cookielib::set_arc_cookie($param->{'cookie_domain'});
	     }else {
		 return 'arc_protect';
	     }
	 }
     }

     my $arc_path = $wwsconf->{'arc_path'}.'/'.$list->get_list_id();
     ## Calendar
     unless (opendir ARC, $arc_path) {
	 &report::reject_report_web('user','empty_archives',{},$param->{'action'},$list);
	 &wwslog('err','do_arc: no directory %s', $arc_path);
	 return undef;
     }
     foreach my $dir (sort grep(!/^\./,readdir ARC)) {
	 if ($dir =~ /^(\d{4})-(\d{2})$/ &&
	     -d $arc_path.'/'.$dir.'/arctxt') {
	     $param->{'calendar'}{$1}{$2} = '???';
	     if (open(IDX, $arc_path.'/'.$dir.'/index')) {
		 my ($msgs) = <IDX>;
		 chomp ($msgs);
		 close IDX;
		 $param->{'calendar'}{$1}{$2} = $msgs if ($msgs);
	     }
	     $latest = $dir;
	 }
     }
     closedir ARC;

     ## Read html file
     $in{'month'} ||= $latest;
     my $arc_month_path = $arc_path.'/'.$in{'month'};

     unless ($in{'arc_file'}) {
	 undef $latest;
	 unless (opendir ARC, $arc_month_path) {
	     &wwslog('err',"unable to readdir $arc_month_path");
	     &report::reject_report_web('user','month_not_found',{'month' => $in{'month'},
								    'dir' => $arc_month_path,
								    'listname' => $param->{'list'}},
					$param->{'action'},
                                        $list,$param->{'user'}{'email'},
                                        $robot);
	 }
	 foreach my $file (grep(/^$index/,readdir ARC)) {
	     if ($file =~ /^$index(\d+)\.html$/) {
		 $latest = $1 if ($latest < $1);
	     }
	 }
	 closedir ARC;

	 $in{'arc_file'} = $index.$latest.".html";
     }

     ## File exist ?
     my $arc_file_path = $arc_month_path.'/'.$in{'arc_file'};
     unless (-r $arc_file_path) {
	 &wwslog('err',"unable to read $arc_file_path");
	 &report::reject_report_web('user','arc_not_found',{'arc_file' => $in{'arc_file'},
							      'path' => $arc_file_path,
							      'listname' => $param->{'list'}},
				    $param->{'action'},
				    $list,$param->{'user'}{'email'},
				    $robot);
	 return undef;
     }

     ## File type
     if ($in{'arc_file'} !~ /^(mail\d+|msg\d+|thrd\d+)\.html$/) {
	 $in{'arc_file'} =~ /\.(\w+)$/;
	 $param->{'file_extension'} = $1;

	 if ($param->{'file_extension'} !~ /^html$/i) {
	     $param->{'bypass'} = 1;
	 }

	  $param->{'file'} = $arc_file_path;
     }else {
	 
	 if ($in{'arc_file'} =~ /^(msg\d+)\.html$/) {
	     # Get subject message thanks to X-Subject field (<!--X-Subject: x -->)
	     open (FILE, $arc_file_path);
	     while (<FILE>) {
		 if (/<!--X-Subject: (.+) -->/) {
		     $param->{'subtitle'} = $1;
		     last;
		 }
	     }
	     close FILE;
	 }
	 
	 &tt2::add_include_path($arc_month_path);
	 $param->{'file'} = $in{'arc_file'};
     }

     my @stat = stat ($arc_file_path);
     $param->{'date'} = $stat[9];

     $param->{'base'} = sprintf "%s%s/arc/%s/%s/", $param->{'base_url'}, $param->{'path_cgi'}, $param->{'list'}, $in{'month'};

     $param->{'archive_name'} = $in{'month'};

     if ($list->{'admin'}{'web_archive_spam_protection'} eq 'cookie'){
	 &cookielib::set_arc_cookie($param->{'cookie_domain'});
     }

     return 1;
 }

 ## Access to latest web archives
 sub do_latest_arc {
     &wwslog('info', 'do_latest_arc(%s,%s,%s)', $in{'list'}, $in{'for'}, $in{'count'});

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_latest_arc: no list');
	 return undef;
     }

     unless ($in{'for'} || $in{'count'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => '"for" or "count"'},$param->{'action'});
	 &wwslog('err','do_latest_arc: missing parameter "count" or "for"');
	 return undef;
     }

     ## Access control
     return undef unless (defined &check_authz('do_latest_arc', 'web_archive.access'));

     ## parameters of the query
     my $today  = time;
     
     my $oldest_day;
     if (defined $in{'for'}) {
 	 $oldest_day = $today - (86400 * ($in{'for'}));
	 $param->{'for'} = $in{'for'};
	 unless ($oldest_day >= 0){
	     &report::reject_report_web('user','nb_days_to_much',{'nb_days' => $in{'for'} },$param->{'action'},$list);
	     &wwslog('err','do_latest_lists: parameter "for" is too big"');
	 }
     }

     my $nb_arc;
     my $NB_ARC_MAX = 100;
     if (defined $in{'count'}) {
	 if ($in{'count'} > $NB_ARC_MAX) {
	     $in{'count'} = $NB_ARC_MAX;
	 }
	 $param->{'count'} = $in{'count'};
         $nb_arc = $in{'count'};
     } else {
	 $nb_arc = $NB_ARC_MAX;
     }       

     my $arc_path = $wwsconf->{'arc_path'}.'/'.$list->get_list_id();
    unless (opendir ARC_DIR, $arc_path) {
	 &report::reject_report_web('user','empty_archives',{},$param->{'action'},$list);
	 &wwslog('err','do_latest_arc: no directory %s', $arc_path);
	 return undef;
     }

     my @months;
     my $latest;
     foreach my $dir (sort grep(!/^\./,readdir ARC_DIR)) {
	 if ($dir =~ /^(\d{4})-(\d{2})$/) {
	     push @months, $dir;
	     $latest = $dir;
	 }
     }
     closedir ARC_DIR;

     @months = reverse @months;
     my $stop_search;
     
     my @archives;

     ## year-month directory 
     foreach my $year_month (@months) {
	 if ($nb_arc <= 0) {
	     last;
	 }
	  
	 last if $stop_search;
	 
	 my $arc_month_path = $arc_path.'/'.$year_month.'/arctxt';
	 unless (opendir MONTH, $arc_month_path) {
	     &report::reject_report_web('intern','inaccessible_archive',{'path' => $arc_month_path,
									 'listname' => $list->{'name'}},
					$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err','do_latest_arc: unable to open directory %s', $arc_month_path);
	     next;
	 }

	 ## mails in the year-month directory
	 foreach my $arc (sort {$b <=> $a} grep(!/^\./,readdir MONTH)) {
	     last if ($nb_arc <= 0);
	    
	     if ($arc =~ /^(\d)+$/) {
		 my %msg_info;

                 use MIME::Parser;
		 my $parser = new MIME::Parser;
		 $parser->output_to_core(1);
		 
		 my $arc_file = $arc_month_path.'/'.$arc;
		 
		 unless (open (FILE, $arc_file)) {
		     &wwslog('err', 'Unable to open file %s', $arc_file);
		 }
		 
		 my $message;
		 unless ($message = $parser->read(\*FILE)) {
		     &wwslog('err', 'Unable to parse message %s', $arc_file);
		     next;
		 }

		 use Mail::Header;
		 my $hdr = $message->head;
		 
		 unless (defined $hdr) {
		     &wwslog('err', 'Unable to parse header of message %s', $arc_file);
		     next;
		 }
		 
 		 foreach my $field ('message-id','subject','from') {
 
 		     my $var = $field; $var =~ s/-/_/g;
 
 		     $msg_info{$var} = $hdr->get($field);
 
 		     if (ref $msg_info{$var} eq 'ARRAY') {
 			 $msg_info{$var} = $msg_info{$var}->[0];
 		     }
 
 		     ## Hide full email address
 		     if ($field eq 'from') {
 			 if ($msg_info{$var} =~ /(.+)\<.+\>/) {
 			     $msg_info{$var} = $1;
			 }else {
			     my @email = split /\@/, $msg_info{$var};
			     $msg_info{$var} = $email[0];
			 }
 		     }
		     
 		     if ($field eq 'message-id') {
 			 $msg_info{$var} = &tools::clean_msg_id($msg_info{'message_id'});
 			 $msg_info{$var} = &tools::escape_chars($msg_info{$var});
 			 
 			 $msg_info{'year_month'} = $year_month;			 
 		     }else {	     
			 $msg_info{$var} =   &MIME::Words::decode_mimewords($msg_info{$var});
 			 $msg_info{$var} = &tools::escape_html($msg_info{$var});
 		     }
 		 }		

		 my $date = $hdr->get('Date'); 
		 
		 unless (defined $date) {
		     &wwslog('err', 'No date found in message %s', $arc_file);
		     next;
		 }

		 my @array_date = &time_utils::parse_date($date);

		 $msg_info{'date_smtp'} = $date;
		 $msg_info{'date_epoch'} = &get_timelocal_from_date(@array_date[1..$#array_date]);

		 $msg_info{'date'} = &POSIX::strftime("%d %b %Y",localtime($msg_info{'date_epoch'}) );
		 if ($msg_info{'date_epoch'} < $oldest_day) {
		     $stop_search = 1;
		     last;
		 }
	
 		 foreach my $key (keys %msg_info) {
 		     chomp($msg_info{$key});
 		 }

		 push @archives,\%msg_info;
		 $nb_arc--;
	     }
	 }
	 closedir MONTH;
	 
	
     }

     @{$param->{'archives'}} = sort ({$b->{'date_epoch'} <=> $a->{'date_epoch'}} @archives);

     if ($list->{'admin'}{'web_archive_spam_protection'} eq 'cookie'){
	 &cookielib::set_arc_cookie($param->{'cookie_domain'});
     }

     return 1;
 }


sub get_timelocal_from_date {
    my($mday, $mon, $yr, $hr, $min, $sec, $zone) = @_;    
    my($time) = 0;

    $yr -= 1900  if $yr >= 1900;  # if given full 4 digit year
    $yr += 100   if $yr <= 37;    # in case of 2 digit years
    if (($yr < 70) || ($yr > 137)) {
	warn "Warning: Bad year (", $yr+1900, ") using current\n";
	$yr = (localtime(time))[5];
    }    

    $time = &timelocal($sec,$min,$hr,$mday,$mon,$yr);
    return $time

}



####################################################
#  do_remove_arc                           
####################################################
#  
#  request by list owner or message sender to remove message from archive
#  Create in the outgoing spool a file containing the message-id of mesage to be removed
# 
# IN : list@host yyyy month and a tab of msgid
#
# OUT :  1 | undef
#
#################################################### 

sub do_remove_arc {
    &wwslog('info', 'do_remove_arc : list %s, yyyy %s, mm %s, #message %s', $in{'list'}, $in{'yyyy'}, $in{'month'});

    my $arcpath = $wwsconf->{'arc_path'}.'/'.$list->get_list_id().'/'.$in{'yyyy'}.'-'.$in{'month'};

    ## Access control

#    $in{'msgid'} = &tools::unescape_chars($in{'msgid'});
    my @msgids = split /\0/, $in{'msgid'};

    if ($#msgids == -1) { 
	 &report::reject_report_web('user','may_not_remove_arc',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('err','remove_arc: no message id found');
	 $param->{'status'} = 'no_msgid';
	 return undef;
     } 

    my $file = $Conf{'queueoutgoing'}.'/.remove.'.$list->get_list_id().'.'.$in{'yyyy'}.'-'.$in{'month'}.'.'.time;
    unless (open REBUILD, ">$file") {
	&report::reject_report_web('intern','cannot_open_file',{'file' => $file},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	&wwslog('info','do_remove: cannot create %s', $file);
	closedir ARC;
	return undef;
    }

    foreach my $msgid (@msgids) {	
	chomp $msgid ;	
	printf REBUILD ('%s||%s',$msgid,$param->{'user'}{'email'}) ; printf  REBUILD "\n";
    }
    close REBUILD;	
    &wwslog('info', 'do_remove_arc %d messages marked to be removed by archived', $#msgids+1);
    $param->{'status'} = 'done';

    return 1;
}
 

####################################################
#  do_send_me                           
####################################################
#  Sends a web archive message to a 
#  requesting user
#  It uses mail::mail_forward() to do it.
# 
# IN : -
#
# OUT : 'arc' | 1 | undef
#
#################################################### 
 sub do_send_me {
     &wwslog('info', 'do_send_me(%s, %s, %s, %s', $in{'list'}, $in{'yyyy'}, $in{'month'}, $in{'msgid'});

     if ($in{'msgid'} =~ /NO-ID-FOUND\.mhonarc\.org/) {
	 &report::reject_report_web('intern','may_not_send_me',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('info','send_me: no message id found');
	 $param->{'status'} = 'no_msgid';
	 return undef;
     } 
     ## 
     my $arcpath = $wwsconf->{'arc_path'}.'/'.$list->get_list_id().'/'.$in{'yyyy'}.'-'.$in{'month'};

     opendir ARC, "$arcpath/arctxt";
     my $msgfile;
     foreach my $file (grep (!/\./,readdir ARC)) {
	 &wwslog('debug','send_me: scanning %s', $file);
	 next unless (open MAIL,"$arcpath/arctxt/$file") ;
	 while (<MAIL>) {
	     last if /^$/ ;
	     if (/^Message-id:\s?<?([^>\s]+)>?\s?/i ) {
		 my $id = $1;
		 if ($id eq $in{'msgid'}) {
		     $msgfile = $file ;
		 }
		 last ;
	     }
	 }
	 close MAIL ;
     }
     if ($msgfile) {
	 unless (open MSG, "$arcpath/arctxt/$msgfile") {
	     $param->{'status'} = 'message_err';
	     &wwslog('info', 'do_send_me : could not read file %s',"$arcpath/arctxt/$msgfile");
	 }
	 my $msg_string;
	 while (<MSG>){
	     $msg_string .= $_ ;
	 }
	 close MSG;

	 unless (&mail::mail_forward($msg_string,&Conf::get_robot_conf($robot, 'sympa'),\$param->{'user'}{'email'},$robot)) {
	     $param->{'status'} = 'message_err';
	     &wwslog('err',"do_send_me : impossible to send archive file to %s",$param->{'user'}{'email'});
	     return undef;
	 }
	 &wwslog('info', 'do_send_me message %s spooled for %s', "$arcpath/arctxt/$msgfile", $param->{'user'}{'email'} );
	 &report::notice_report_web('performed',{},$param->{'action'});
	 $in{'month'} = $in{'yyyy'}."-".$in{'month'};
	 return 'arc';

     }else{
	 &wwslog('info', 'do_send_me : no file match msgid');
	 $param->{'status'} = 'not_found';
	 return undef;
     }

     return 1;
 }

 ## Output an initial form to search in web archives
 sub do_arcsearch_form {
     &wwslog('info', 'do_arcsearch_form(%s)', $param->{'list'});

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_arcsearch_form: no list');
	 return undef;
     }

     ## Access control
     return undef unless (defined &check_authz('do_arcsearch_form', 'web_archive.access'));

     my $search_base = $wwsconf->{'arc_path'}.'/'.$list->get_list_id();
     opendir ARC, "$search_base";
     foreach my $dir (sort {$b cmp $a} grep(!/^\./,readdir ARC)) {
	 if ($dir =~ /^(\d{4})-(\d{2})$/) {
	     push @{$param->{'yyyymm'}}, $dir;
	 }
     }
     closedir ARC;

     $param->{'key_word'} = $in{'key_word'};
     $param->{'archive_name'} = $in{'archive_name'};

     return 1;
 }

 ## Search in web archives
 sub do_arcsearch {
     &wwslog('info', 'do_arcsearch(%s)', $param->{'list'});

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_arcsearch: no list');
	 return undef;
     }

     ## Access control
     return undef unless (defined &check_authz('do_arcsearch', 'web_archive.access'));

     use Marc::Search;

     my $search = new Marc::Search;
     $search->search_base ($wwsconf->{'arc_path'} . '/' . $list->get_list_id());
     $search->base_href (&Conf::get_robot_conf($robot, 'wwsympa_url') . '/arc/' . $param->{'list'});
     $search->archive_name ($in{'archive_name'});

     unless (defined($in{'directories'})) {
	 # by default search in current month and in the previous none empty one
	 my $search_base = $wwsconf->{'arc_path'}.'/'.$list->get_list_id();
	 my $previous_active_dir ;
	 opendir ARC, "$search_base";
	 foreach my $dir (sort {$b cmp $a} grep(!/^\./,readdir ARC)) {
	     if (($dir =~ /^(\d{4})-(\d{2})$/) && ($dir lt $search->archive_name)) {
		 $previous_active_dir = $dir;
		 last;
	     }
	 }
	 closedir ARC;
	 $in{'directories'} = $search->archive_name."\0".$previous_active_dir ;
     }

     if (defined($in{'directories'})) {
	 $search->directories ($in{'directories'});
	 foreach my $dir (split/\0/, $in{'directories'})	{
	     push @{$param->{'directories'}}, $dir;
	 }
     }

     if (defined $in{'previous'}) {
	 $search->body_count ($in{'body_count'});
	 $search->date_count ($in{'date_count'});
	 $search->from_count ($in{'from_count'});
	 $search->subj_count ($in{'subj_count'});
	 $search->previous ($in{'previous'});
     }

     ## User didn't enter any search terms
     if ($in{'key_word'} =~ /^\s*$/) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'key_word'},$param->{'action'});
	 &wwslog('info','do_arcsearch: no search term');
	 return undef;
     }elsif ($in{'key_word'} =~ /[<>\\\*\$]/) {
	 &report::reject_report_web('user','syntax_errors',{'params' => 'key_word'},$param->{'action'});
	 &wwslog('info','do_arcsearch: syntax error');
	 return undef;
     }

     $param->{'key_word'} = $in{'key_word'};
     $in{'key_word'} =~ s/\@/\\\@/g;
     $in{'key_word'} =~ s/\[/\\\[/g;
     $in{'key_word'} =~ s/\]/\\\]/g;
     $in{'key_word'} =~ s/\(/\\\(/g;
     $in{'key_word'} =~ s/\)/\\\)/g;
     $in{'key_word'} =~ s/\$/\\\$/g;
     $in{'key_word'} =~ s/\'/\\\'/g;

     $search->limit ($in{'limit'});

     $search->age (1) 
	 if ($in{'age'} eq 'new');

     $search->match (1) 
	 if (($in{'match'} eq 'partial') or ($in{'match'} eq '1'));

     my @words = split(/\s+/,$in{'key_word'});
     $search->words (\@words);
     $search->clean_words ($in{'key_word'});
     my @clean_words = @words;

     for my $i (0 .. $#words) {
	 $words[$i] =~ s,/,\\/,g;
	 $words[$i] = '\b' . $words[$i] . '\b' if ($in{'match'} eq 'exact');
     }
     $search->key_word (join('|',@words));

     if ($in{'case'} eq 'off') {
	 $search->case(1);
	 $search->key_word ('(?i)' . $search->key_word);
     }
     if ($in{'how'} eq 'any') {
	 $search->function2 ($search->match_any(@words));
	 $search->how ('any');
     }elsif ($in{'how'} eq 'all') {
	 $search->function1 ($search->body_match_all(@clean_words,@words));
	 $search->function2 ($search->match_all(@words));
	 $search->how       ('all');
     }else {
	 $search->function2 ($search->match_this(@words));
	 $search->how       ('phrase');
     }

     $search->subj (defined($in{'subj'}));
     $search->from (defined($in{'from'}));
     $search->date (defined($in{'date'}));
     $search->body (defined($in{'body'}));

     $search->body (1) 
	 if ( not ($search->subj)
	      and not ($search->from)
	      and not ($search->body)
	      and not ($search->date));

     my $searched = $search->search;

     if (defined($search->error)) {
	 &wwslog('info','do_arcsearch_search_error : %s', $search->error);
     }

     $search->searched($searched);

     if ($searched < $search->file_count) {
	 $param->{'continue'} = 1;
     }

     foreach my $field ('list','archive_name','age','body','case','date','from','how','limit','match','subj') {
	 $param->{$field} = $in{$field};
     }

     $param->{'body_count'} = $search->body_count;
     $param->{'clean_words'} = $search->clean_words;
     $param->{'date_count'} = $search->date_count;
     $param->{'from_count'} = $search->from_count;
     $param->{'subj_count'} = $search->subj_count;

     $param->{'num'} = $search->file_count + 1;
     $param->{'searched'} = $search->searched;

     $param->{'res'} = $search->res;

     ## Decode subject header fields
     foreach my $m (@{$param->{'res'}}) {
	 $m->{'subj'} = &MIME::Words::decode_mimewords($m->{'subj'});
     }

     return 1;
 }

 ## Search message-id in web archives
 sub do_arcsearch_id {
     &wwslog('info', 'do_arcsearch_id(%s,%s,%s)', $param->{'list'},$in{'archive_name'},$in{'msgid'});

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_arcsearch_id: no list');
	 return undef;
     }

     ## Access control
     return undef unless (defined &check_authz('do_arcsearch_id', 'web_archive.access'));

     use Marc::Search;

     my $search = new Marc::Search;
     $search->search_base ($wwsconf->{'arc_path'} . '/' . $list->get_list_id());
     $search->base_href (&Conf::get_robot_conf($robot, 'wwsympa_url') . '/arc/' . $param->{'list'});

     $search->archive_name ($in{'archive_name'});

     # search in current month and in the previous none empty one 
     my $search_base = $search->search_base; 
     my $previous_active_dir ; 
     opendir ARC, "$search_base"; 
     foreach my $dir (sort {$b cmp $a} grep(!/^\./,readdir ARC)) { 
	 if (($dir =~ /^(\d{4})-(\d{2})$/) && ($dir lt $search->archive_name)) { 
	     $previous_active_dir = $dir; 
	     last; 
	 } 
     } 
     closedir ARC; 
     $in{'archive_name'} = $search->archive_name."\0".$previous_active_dir ; 

     $search->directories ($in{'archive_name'});
 #    $search->directories ($search->archive_name);

     ## User didn't enter any search terms
     if ($in{'msgid'} =~ /^\s*$/) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'msgid'},$param->{'action'});
	 &wwslog('info','do_arcsearch_id: no search term');
	 return undef;
     }

     $param->{'msgid'} = &tools::unescape_chars($in{'msgid'});
     $in{'msgid'} =~ s/\@/\\\@/g;
     $in{'msgid'} =~ s/\[/\\\[/g;
     $in{'msgid'} =~ s/\]/\\\]/g;
     $in{'msgid'} =~ s/\(/\\\(/g;
     $in{'msgid'} =~ s/\)/\\\)/g;
     $in{'msgid'} =~ s/\$/\\\$/g;
     $in{'msgid'} =~ s/\*/\\\*/g;

     ## Mhonarc escapes '-' characters (&#45;)
     $in{'msgid'} =~ s/\-/\&\#45\;/g;

     $search->limit (1);

     my @words = split(/\s+/,$in{'msgid'});
     $search->words (\@words);
     $search->clean_words ($in{'msgid'});
     my @clean_words = @words;

     $search->key_word (join('|',@words));

     $search->function2 ($search->match_this(@words));

     $search->id (1);

     my $searched = $search->search;

     if (defined($search->error)) {
	 &wwslog('info','do_arcsearch_id_search_error : %s', $search->error);
     }

     $search->searched($searched);

     $param->{'res'} = $search->res;

     unless ($#{$param->{'res'}} >= 0) {
	 &report::reject_report_web('intern','archive_not_found',{'msgid'=> $in{'msgid'}},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('info','No message found in archives matching Message-ID %s', $in{'msgid'});
	 return 'arc';
     }

     $param->{'redirect_to'} = $param->{'res'}[0]{'file'};

     return 1;
 }

 # get pendings lists
 sub do_get_pending_lists {

     &wwslog('info', 'get_pending_lists');

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','get_pending_lists :  no user');
	 $param->{'previous_action'} = 'get_pending_lists';
	 return 'loginrequest';
     }
     unless ( $param->{'is_listmaster'}) {
	 &report::reject_report_web('auth','action_listmaster',{},$param->{'action'},$list);
	 &wwslog('info', 'Incorrect_privilege to get pending');
	 return undef;
     } 

     my $all_lists = &List::get_lists($robot);
     foreach my $list ( @$all_lists ) {
	 if ($list->{'admin'}{'status'} eq 'pending') {
	     $param->{'pending'}{$list->{'name'}}{'subject'} = $list->{'admin'}{'subject'};
	     $param->{'pending'}{$list->{'name'}}{'by'} = $list->{'admin'}{'creation'}{'email'};
	     $param->{'pending'}{$list->{'name'}}{'date'} = &POSIX::strftime("%d %b %y  %H:%M", localtime($list->{'admin'}{'creation'}{'date_epoch'}));
	 }
     }

     return 1;
 }

 # get closed lists
 sub do_get_closed_lists {

     &wwslog('info', 'get_closed_lists');

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','get_closed_lists :  no user');
	 $param->{'previous_action'} = 'get_closed_lists';
	 return 'loginrequest';
     }
     unless ( $param->{'is_listmaster'}) {
	 &report::reject_report_web('auth','action_listmaster',{},$param->{'action'});
	 &wwslog('info', 'Incorrect_privilege');
	 return undef;
     } 

     my $all_lists = &List::get_lists($robot);
     foreach my $list ( @$all_lists ) {
	 if ($list->{'admin'}{'status'} eq 'closed' ||
	     $list->{'admin'}{'status'} eq 'family_closed') {
	     $param->{'closed'}{$list->{'name'}}{'subject'} = $list->{'admin'}{'subject'};
	     $param->{'closed'}{$list->{'name'}}{'by'} = $list->{'admin'}{'creation'}{'email'};
	 }
     }

     return 1;
 }

 # get ordered latest lists
 sub do_get_latest_lists {

     &wwslog('info', 'get_latest_lists');

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','get_latest_lists :  no user');
	 $param->{'previous_action'} = 'get_latest_lists';
	 return 'loginrequest';
     }

     unless ( $param->{'is_listmaster'}) {
	 &report::reject_report_web('auth','action_listmaster',{},$param->{'action'},$list);
	 &wwslog('info', 'Incorrect_privilege');
	 return undef;
     } 

     my @unordered_lists;
     my $all_lists = &List::get_lists($robot);
     foreach my $list ( @$all_lists ) {

	 push @unordered_lists, {'name' => $list->{'name'},
				 'subject' => $list->{'admin'}{'subject'},
				 'creation_date' => $list->{'admin'}{'creation'}{'date_epoch'}};
     }

     foreach my $l (sort {$b->{'creation_date'} <=> $a->{'creation_date'}} @unordered_lists) {
	 push @{$param->{'latest_lists'}}, $l;
	 $l->{'creation_date'} = &POSIX::strftime("%d %b %Y", localtime($l->{'creation_date'}));
     }

     return 1;
 }


# get inactive lists
sub do_get_inactive_lists {

     &wwslog('info', 'get_inactive_lists');

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','get_inactive_lists :  no user');
	 $param->{'previous_action'} = 'get_inactive_lists';
	 return 'loginrequest';
     }

     unless ( $param->{'is_listmaster'}) {
	 &report::reject_report_web('auth','action_listmaster',{},$param->{'action'},$list);
	 &wwslog('info', 'Incorrect_privilege');
	 return undef;
     } 

     my @unordered_lists;
     my $all_lists = &List::get_lists($robot);
     foreach my $list ( @$all_lists ) {

	 ## skip closed lists
	 if ($list->{'admin'}{'status'} eq 'closed') {
	     next;
	 }

	 my $last_message;

	 if (open COUNT, $list->{'dir'}.'/msg_count') {
	     while (<COUNT>) {
		 $last_message = $1 if (/^(\d+)\s/ && ($1 > $last_message));
	     }
	     close COUNT;

	 }else {
	     &wwslog('info', 'Could not open file %s', $list->{'dir'}.'/msg_count');	     
	 }


	 push @unordered_lists, {'name' => $list->{'name'},
				 'subject' => $list->{'admin'}{'subject'},
				 'last_message_epoch' => $last_message,
				 'last_message_date' => &POSIX::strftime("%d %b %Y", localtime($last_message*86400)),
				 'creation_date_epoch' => $list->{'admin'}{'creation'}{'date_epoch'},
				 'creation_date' => &POSIX::strftime("%d %b %Y", localtime($list->{'admin'}{'creation'}{'date_epoch'}))
				 };
     }

     foreach my $l (sort {$a->{'last_message_epoch'} <=> $b->{'last_message_epoch'}} @unordered_lists) {
	 push @{$param->{'inactive_lists'}}, $l;
     }

     return 1;
 }

## show a list parameters
sub do_set_pending_list_request {
     &wwslog('info', 'set_pending_list(%s)',$in{'list'});

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','set_pending_list:  no user');
	 return 'loginrequest';
     }
     unless ( $param->{'is_listmaster'}) {
	 &report::reject_report_web('auth','action_listmaster',{},$param->{'action'},$list);
	 &wwslog('info', 'Incorrect_privilege to open pending list %s from %s', $in{'list'},$param->{'user'}{'email'});
	 return undef;
     } 

     my $list_dir = $list->{'dir'};

     $param->{'list_config'} = $list_dir.'/config';
     $param->{'list_info'} = $list_dir.'/info';
     $param->{'list_subject'} = $list->{'admin'}{'subject'};
     $param->{'list_request_by'} = $list->{'admin'}{'creation'}{'email'};
     $param->{'list_request_date'} = $list->{'admin'}{'creation'}{'date'};
     $param->{'list_serial'} = $list->{'admin'}{'serial'};
     $param->{'list_status'} = $list->{'admin'}{'status'};

     &tt2::add_include_path($list->{'dir'});

     return 1;
 }

 ## show a list parameters
 sub do_install_pending_list {
     &wwslog('info', 'do_install_pending_list(%s,%s,%s)',$in{'list'},$in{'status'},$in{'notify'});

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_install_pending_list:  no user');
	 return 'loginrequest';
     }
     unless ( $param->{'is_listmaster'}) {
	 &report::reject_report_web('auth','action_listmaster',{},$param->{'action'},$list);
	 &wwslog('info', 'Incorrect_privilege to open pending list %s from %s', $in{'list'},$param->{'user'}{'email'});
	 return undef;
     } 

     unless ($in{'status'} && (($in{'status'} eq 'open') || ($in{'status'} eq 'closed'))) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'status'},$param->{'action'});
	 &wwslog('info', 'Missing status parameter',);
	 return undef;
     }
     
     if ($list->{'admin'}{'status'} eq $in{'status'}) {
	 &report::reject_report_web('user','didnt_change_anything',{},$param->{'action'});
	 &wwslog('info','view_pending_list: didn t change really the status, nothing to do');
	 return undef ;
     }    

     $list->{'admin'}{'status'} = $in{'status'};

 #    open TMP, ">/tmp/dump1";
 #    &tools::dump_var ($list->{'admin'}, 0, \*TMP);
 #    close TMP;

     unless ($list->save_config($param->{'user'}{'email'})) {
	 &report::reject_report_web('intern','cannot_save_config',{'listname'=> $list->{'name'}},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('info','_create_list: Cannot save config file');
	 return undef;
     }

 #    open TMP, ">/tmp/dump2";
 #    &tools::dump_var ($list->{'admin'}, 0, \*TMP);
 #    close TMP;

     ## create the aliases
     if ($in{'status'} eq 'open') {
 	 my $aliases = &admin::install_aliases($list,$robot);
 	 if ($aliases == 1) {
 	     $param->{'auto_aliases'} = 1;
 	 }else { 
 	     $param->{'aliases'} = $aliases;
 	     $param->{'auto_aliases'} = 0;
 	 }

     }

     ## Notify listmasters
     if ($in{'status'} eq 'open') {
	 unless ($list->send_file('list_created', &Conf::get_robot_conf($robot, 'listmaster'), $robot,{})) {
	     &wwslog('notice',"Unable to send template 'list_created' to listmaster");
	 }
     }elsif ($in{'status'} eq 'closed') {
	 unless ($list->send_file('list_rejected', &Conf::get_robot_conf($robot, 'listmaster'), $robot,{})) {
	     &wwslog('notice',"Unable to send template 'list_rejected' to listmaster");
	 }
     }

    if ($in{'notify'}) {
	 my $owners = $list->get_owners();
	 foreach my $i (@{$owners}) {
	     ## Notify all listowners, even if reception is nomail
	     next unless ($i->{'email'});
	     if ($in{'status'} eq 'open') {
		 unless ($list->send_file('list_created', $i->{'email'}, $robot,{})) {
		     &wwslog('notice',"Unable to send template 'list_created' to $i->{'email'}");
		 }
	     }elsif ($in{'status'} eq 'closed') {
		 unless ($list->send_file('list_rejected', $i->{'email'}, $robot,{})) {
		     &wwslog('notice',"Unable to send template 'list_rejected' to $i->{'email'}");
		 }
	     }
	 }
     }

     $param->{'status'} = $in{'status'};

     $list = $param->{'list'} = $in{'list'} = undef;
     return 'get_pending_lists';

     return 1;
 }

 ## check if the requested list exists already using smtp 'rcpt to'
 sub list_check_smtp {
     my $list = shift;
     my $conf = '';
     my $smtp;
     my (@suf, @addresses);

     my $smtp_relay = $Conf{'robots'}{$robot}{'list_check_smtp'} || $Conf{'list_check_smtp'};
     my $suffixes = $Conf{'robots'}{$robot}{'list_check_suffixes'} || $Conf{'list_check_suffixes'};
     return 0 
	 unless ($smtp_relay && $suffixes);
     my $domain = &Conf::get_robot_conf($robot, 'host');
     &wwslog('debug2', 'list_check_smtp(%s)',$in{'listname'});
     @suf = split(/,/,$suffixes);
     return 0 if ! @suf;
     for(@suf) {
	 push @addresses, $list."-$_\@".$domain;
     }
     push @addresses,"$list\@" . $domain;

     unless (eval "require Net::SMTP") {
	 wwslog ('err',"Unable to use Net library, Net::SMTP required, install it (CPAN) first");
	 return undef;
     }
     require Net::SMTP;

     if( $smtp = Net::SMTP->new($smtp_relay,
				Hello => $smtp_relay,
				Timeout => 30) ) {
	 $smtp->mail('');
	 for(@addresses) {
		 $conf = $smtp->to($_);
		 last if $conf;
	 }
	 $smtp->quit();
	 return $conf;
    }
    return undef;
 }

## create a liste using a list template. 
 sub do_create_list {

     &wwslog('info', 'do_create_list(%s,%s,%s)',$in{'listname'},$in{'subject'},$in{'template'});

     foreach my $arg ('listname','subject','template','info','topics') {
	 unless ($in{$arg}) {
	     &report::reject_report_web('user','missing_arg',{'argument' => $arg},$param->{'action'});
	     &wwslog('info','do_create_list: missing param %s', $arg);
	     return undef;
	 }
     }
     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_create_list :  no user');
	 return 'loginrequest';
     }

     $param->{'create_action'} = $param->{'create_list'};

     &wwslog('info',"do_create_list, get action : $param->{'create_action'} ");

     if ($param->{'create_action'} =~ /reject/) {
	 &report::reject_report_web('auth',$param->{'reason'},{},$param->{'action'},$list);
	 &wwslog('info','do_create_list: not allowed');
	 return undef;
     }elsif ($param->{'create_action'} =~ /listmaster/i) {
	 $param->{'status'} = 'pending' ;
     }elsif  ($param->{'create_action'} =~ /do_it/i) {
	 $param->{'status'} = 'open' ;
     }else{
	 &report::reject_report_web('intern','internal_scenario_error_create_list',{},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	 &wwslog('info','do_create_list: internal error in scenario create_list');
	 return undef;
     }

     ## 'other' topic means no topic
     $in{'topics'} = undef if ($in{'topics'} eq 'other');
  
     my %owner;
     $owner{'email'} = $param->{'user'}{'email'};
     $owner{'gecos'} = $param->{'user'}{'gecos'};

     my $parameters;
     push @{$parameters->{'owner'}},\%owner;
     $parameters->{'listname'} = $in{'listname'};
     $parameters->{'subject'} = $in{'subject'};
     $parameters->{'creation_email'} = $param->{'user'}{'email'};
     $parameters->{'lang'} = $param->{'lang'};
     $parameters->{'status'} = $param->{'status'};
     $parameters->{'topics'} = $in{'topics'};
     $parameters->{'description'} = $in{'info'};


     ## create liste
     my $resul = &admin::create_list_old($parameters,$in{'template'},$robot);
     unless(defined $resul) {
	 &report::reject_report_web('intern','create_list',{},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	 &wwslog('info','do_create_list: unable to create list %s for %s',$in{'listname'},$param->{'user'}{'email'});
	 return undef
     }
     
     ## Create list object
     $in{'list'} = $in{'listname'};
     &check_param_in();

     if  ($param->{'create_action'} =~ /do_it/i) {
	 if ($resul->{'aliases'} == 1) {
	     $param->{'auto_aliases'}  = 1;
	 }else {
	     $param->{'aliases'} = $resul->{'aliases'};
	     $param->{'auto_aliases'} = 0;
	 }
     }

     ## notify listmaster
     if ($param->{'create_action'} =~ /notify/) {
	 &wwslog('info','notify listmaster');
	 unless (&List::send_notify_to_listmaster('request_list_creation',$robot, 
						  {'listname' => $in{'listname'},
						   'email' => $param->{'user'}{'email'}})) {
	     &wwslog('notice',"Unable to send notify 'request_list_creation' to listmaster");
	 }
     }
     
     $in{'list'} = $resul->{'list'}{'name'};
     &check_param_in();

     $param->{'listname'} = $resul->{'list'}{'name'};
     return 1;
 }

 ## Return the creation form
 sub do_create_list_request {
     &wwslog('info', 'do_create_list_request()');

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_create_list_request:  no user');
	 $param->{'previous_action'} = 'create_list_request';
	 return 'loginrequest';
     }

     my $result = &List::request_action('create_list',$param->{'auth_method'},$robot,
						       {'sender' => $param->{'user'}{'email'},
							'remote_host' => $param->{'remote_host'},
							'remote_addr' => $param->{'remote_addr'}});
 
     my $r_action;
     my $reason;
     if (ref($result) eq 'HASH') {
	 $r_action = $result->{'action'};
	 $reason = $result->{'reason'};
     }

     $param->{'create_action'} = $r_action;
     ## Initialize the form
     ## When returning to the form
     foreach my $p ('listname','template','subject','topics','info') {
	 $param->{'saved'}{$p} = $in{$p};
     }

     if ($param->{'create_action'} =~ /reject/) {
	 &report::reject_report_web('auth',$reason,{},$param->{'action'},$list);
	 &wwslog('info','do_create_list: not allowed');
	 return undef;
     }

     my %topics;
     unless (%topics = &List::load_topics($robot)) {
	 &report::reject_report_web('intern','unable_to_load_list_of_topics',{},$param->{'action'},'',$param->{'user'}{'email'},$robot);
     }
     $param->{'list_of_topics'} = \%topics;

     $param->{'list_of_topics'}{$in{'topics'}}{'selected'} = 1
	 if ($in{'topics'});

     unless ($param->{'list_list_tpl'} = &tools::get_list_list_tpl($robot)) {
	 &report::reject_report_web('intern','unable_to_load_create_list_templates',{},$param->{'action'},'',$param->{'user'}{'email'},$robot);
     }	

     &tt2::allow_absolute_path();

     foreach my $template (keys %{$param->{'list_list_tpl'}}){
	 $param->{'tpl_count'} ++ ;
     }

     $param->{'list_list_tpl'}{$in{'template'}}{'selected'} = 1
	 if ($in{'template'});


     return 1 ;

 }

## WWSympa Home-Page
 sub do_home {
     &wwslog('info', 'do_home');
     # all variables are set in export_topics

     return 1;
 }

 sub do_editsubscriber {
     &wwslog('info', 'do_editsubscriber(%s)', $in{'email'});

     my $user;

     unless ($param->{'is_owner'}) {
	 &report::reject_report_web('auth','action_owner',{},$param->{'action'},$list);
	 &wwslog('info','do_editsubscriber: may not edit');
	 return undef;
     }

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_editsubscriber: no list');
	 return undef;
     }

     unless ($in{'email'}) {
	 &report::reject_report_web('user','no_email',{},$param->{'action'});
	 &wwslog('info','do_editsubscriber: no email');
	 return undef;
     }

     $in{'email'} = &tools::unescape_chars($in{'email'});

     unless($user = $list->get_subscriber($in{'email'})) {
	 &report::reject_report_web('intern','subscriber_not_found',{'email' => $in{'email'}},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('info','do_editsubscriber: subscriber %s not found', $in{'email'});
	 return undef;
     }

     $param->{'current_subscriber'} = $user;
     $param->{'current_subscriber'}{'escaped_email'} = &tools::escape_html($param->{'current_subscriber'}{'email'});
     $param->{'current_subscriber'}{'escaped_bounce_address'} = &tools::escape_html($param->{'current_subscriber'}{'bounce_address'});
     $param->{'current_subscriber'}{'date'} = &POSIX::strftime("%d %b %Y", localtime($user->{'date'}));
     $param->{'current_subscriber'}{'update_date'} = &POSIX::strftime("%d %b %Y", localtime($user->{'update_date'}));

     ## Prefs
     $param->{'current_subscriber'}{'reception'} ||= 'mail';
     $param->{'current_subscriber'}{'visibility'} ||= 'noconceal';
     foreach my $m (keys %wwslib::reception_mode) {		
       if ($list->is_available_reception_mode($m)) {
	 $param->{'reception'}{$m}{'description'} = sprintf(gettext($wwslib::reception_mode{$m}->{'gettext_id'}));
	 if ($param->{'current_subscriber'}{'reception'} eq $m) {
	     $param->{'reception'}{$m}{'selected'} = 'selected="selected"';
	 }else {
	     $param->{'reception'}{$m}{'selected'} = '';
	 }
       }
     }

     ## Bounces
     if ($user->{'bounce'} =~ /^(\d+)\s+(\d+)\s+(\d+)(\s+(.*))?$/) {
	 my @bounce = ($1, $2, $3, $5);
	 $param->{'current_subscriber'}{'first_bounce'} = &POSIX::strftime("%d %b %Y", localtime($bounce[0]));
	 $param->{'current_subscriber'}{'last_bounce'} = &POSIX::strftime("%d %b %Y", localtime($bounce[1]));
	 $param->{'current_subscriber'}{'bounce_count'} = $bounce[2];
	 if ($bounce[3] =~ /^(\d+\.(\d+\.\d+))$/) {
	    $user->{'bounce_code'} = $1;
	    $user->{'bounce_status'} = $wwslib::bounce_status{$2};
	 }	

	 $param->{'previous_action'} = $in{'previous_action'};
     }

     ## Additional DB fields
     if ($Conf{'db_additional_subscriber_fields'}) {
	 my @additional_fields = split ',', $Conf{'db_additional_subscriber_fields'};

	 my %data;

	 foreach my $field (@additional_fields) {

	     ## Is the Database defined
	     unless ($Conf{'db_name'}) {
		 &wwslog('info', 'No db_name defined in configuration file');
		 return undef;
	     }

	     ## Check field type (enum or not) with MySQL
	     $data{$field}{'type'} = &List::get_db_field_type('subscriber_table', $field);
	     if ($data{$field}{'type'} =~ /^enum\((\S+)\)$/) {
		 my @enum = split /,/,$1;
		 foreach my $e (@enum) {
		     $e =~ s/^\'([^\']+)\'$/$1/;
		     $data{$field}{'enum'}{$e} = '';
		 }
		 $data{$field}{'type'} = 'enum';

		 $data{$field}{'enum'}{$user->{$field}} = 'selected="selected"'
		     if (defined $user->{$field});
	     }else {
		 $data{$field}{'type'} = 'string';
		 $data{$field}{'value'} = $user->{$field};
	     } 
	 }
	 $param->{'additional_fields'} = \%data;
     }

     return 1;
 }

 sub do_viewbounce {
     &wwslog('info', 'do_viewbounce(%s)', $in{'email'});

     unless ($param->{'is_owner'}) {
	 &report::reject_report_web('auth','action_owner',{},$param->{'action'},$list);
	 &wwslog('info','do_viewbounce: may not view');
	 return undef;
     }

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_viewbounce: no list');
	 return undef;
     }

     unless ($in{'email'}) {
	 &report::reject_report_web('user','no_email',{},$param->{'action'});
	 &wwslog('info','do_viewbounce: no email');
	 return undef;
     }

     my $escaped_email = &tools::escape_chars($in{'email'});

     $param->{'lastbounce_path'} = $list->get_bounce_dir().'/'.$escaped_email;

     unless (-r $param->{'lastbounce_path'}) {
	 &report::reject_report_web('user','no_bounce_user',{'email'=>$in{'email'}},$param->{'action'},$list);
	 &wwslog('info','do_viewbounce: no bounce %s', $param->{'lastbounce_path'});
	 return undef;
     }

     &tt2::allow_absolute_path();

     return 1;
 }

 ## some help for listmaster and developpers
 sub do_scenario_test {
     &wwslog('info', 'do_scenario_test');

     ## List available scenarii
     unless (opendir SCENARI, "--ETCBINDIR--/scenari/"){
	 &report::reject_report_web('intern','cannot_open_dir',{'dir' => "--ETCBINDIR--/scenari/"},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('info',"do_scenario_test : unable to open --ETCBINDIR--/scenari");
	 return undef;
     }

     foreach my $scfile (readdir SCENARI) {
	 if ($scfile =~ /^(\w+)\.(\w+)/ ) {
	     $param->{'scenario'}{$1}{'defined'}=1 ;
	 }
     }
     closedir SCENARI;
     my $all_lists = &List::get_lists('*');
     foreach my $list ( @$all_lists ) {
	 $param->{'listname'}{$list->{'name'}}{'defined'}=1 ;
     }
     foreach my $a ('smtp','md5','smime') {
	 #$param->{'auth_method'}{$a}{'define'}=1 ;
	 $param->{'authmethod'}{$a}{'defined'}=1 ;
     }

     $param->{'scenario'}{$in{'scenario'}}{'selected'} = 'selected="selected"' if $in{'scenario'};

     $param->{'listname'}{$in{'listname'}}{'selected'} = 'selected="selected"' if $in{'listname'};

     $param->{'authmethod'}{$in{'auth_method'}}{'selected'} = 'selected="selected"' if $in{'auth_method'};

     $param->{'email'} = $in{'email'};

     if ($in{'scenario'}) {
	 my $operation = $in{'scenario'};
	 &wwslog('debug4', 'do_scenario_test: perform scenario_test');

	 my $result = &List::request_action ($operation,$in{'auth_method'},$robot,
					     {'listname' => $in{'listname'},
					      'sender' => $in{'sender'},
					      'email' => $in{'email'},
					      'remote_host' => $in{'remote_host'},
					      'remote_addr' => $in{'remote_addr'}},'debug');
	 if (ref($result) eq 'HASH'){
	    $param->{'scenario_action'} = $result->{'action'};
	    $param->{'scenario_condition'} = $result->{'condition'};
	    $param->{'scenario_auth_method'} = $result->{'auth_method'};
	    $param->{'scenario_reason'} = $result->{'reason'};
	 }	     	
     }
     return 1;
 }

 ## Bouncing addresses review
 sub do_reviewbouncing {
     &wwslog('info', 'do_reviewbouncing(%d)', $in{'page'});
     my $size = $in{'size'} || $wwsconf->{'review_page_size'};

     unless ($in{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_reviewbouncing: no list');
	 return undef;
     }

     unless ($param->{'is_owner'}) {
	 &report::reject_report_web('auth','action_owner',{},$param->{'action'});
	 &wwslog('info','do_reviewbouncing: may not review');
	 return 'admin';
     }

     unless ($param->{'bounce_total'}) {
	 &report::reject_report_web('user','no_bounce_user',{},$param->{'action'});
	 &wwslog('info','do_reviewbouncing: no bouncing subscriber');
	 return 'admin';
     }

     ## Owner
     $param->{'page'} = $in{'page'} || 1;
     $param->{'total_page'} = int ( $param->{'bounce_total'} / $size);
     $param->{'total_page'} ++
	 if ($param->{'bounce_total'} % $size);

     if ($param->{'page'} > $param->{'total_page'}) {
	 &report::reject_report_web('user','no_page',{'page' => $param->{'page'}},$param->{'action'});
	 &wwslog('info','do_reviewbouncing: no page %d', $param->{'page'});
	 return 'admin';
     }

     my @users;
     ## Members list
     for (my $i = $list->get_first_bouncing_user(); $i; $i = $list->get_next_bouncing_user()) {
	 $i->{'bounce'} =~ /^(\d+)\s+(\d+)\s+(\d+)(\s+(.*))?$/;
	 $i->{'first_bounce'} = $1;
	 $i->{'last_bounce'} = $2;
	 $i->{'bounce_count'} = $3;
	 if ($5 =~ /^(\d+)\.\d+\.\d+$/) {
	     $i->{'bounce_class'} = $1;
	 }

	 ## Define color in function of bounce_score
	 if ($i->{'bounce_score'} <= $list->{'admin'}{'bouncers_level1'}{'rate'}) {
	     $i->{'bounce_level'} = 0;
	 }elsif ($i->{'bounce_score'} <= $list->{'admin'}{'bouncers_level2'}{'rate'}){
	     $i->{'bounce_level'} = 1;
	 }else{
	     $i->{'bounce_level'} = 2;
	 }
	 push @users, $i;
     }

     my $record;
     foreach my $i (sort 
		    {($b->{'bounce_score'} <=> $a->{'bounce_score'}) ||
			 ($b->{'last_bounce'} <=> $a->{'last_bounce'}) ||
			 ($b->{'bounce_class'} <=> $a->{'bounce_class'}) }
		    @users) {
	 $record++;

	 if ($record > ( $size * ($param->{'page'} ) ) ) {
	     $param->{'next_page'} = $param->{'page'} + 1;
	     last;
	 }

	 next if ($record <= ( ($param->{'page'} - 1) *  $size));

	 $i->{'first_bounce'} = &POSIX::strftime("%d %b %Y", localtime($i->{'first_bounce'}));
	 $i->{'last_bounce'} = &POSIX::strftime("%d %b %Y", localtime($i->{'last_bounce'}));

	 ## Escape some weird chars
	 $i->{'escaped_email'} = &tools::escape_chars($i->{'email'});

	 push @{$param->{'members'}}, $i;
     }

     if ($param->{'page'} > 1) {
	 $param->{'prev_page'} = $param->{'page'} - 1;
     }

     $param->{'size'} = $in{'size'};

     return 1;
 }

 sub do_resetbounce {
     &wwslog('info', 'do_resetbounce()');

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_resetbounce: no list');
	 return undef;
     }

     unless ($in{'email'}) {
	 &report::reject_report_web('user','no_email',{},$param->{'action'});
	 &wwslog('info','do_resetbounce: no email');
	 return undef;
     }

     $in{'email'} = &tools::unescape_chars($in{'email'});

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_resetbounce: no user');
	 return 'loginrequest';
     }

     ## Require DEL privilege

     my $result = $list->check_list_authz('del',$param->{'auth_method'},
					  {'sender' => $param->{'user'}{'email'},
					   'email' => $in{'email'},
					   'remote_host' => $param->{'remote_host'},
					   'remote_addr' => $param->{'remote_addr'}});
     my $del_is;
     my $reason;
     if (ref($result) eq 'HASH') {
	 $del_is = $result->{'action'};
	 $reason = $result->{'reason'};
     }

     unless ( $del_is =~ /do_it/) {
	 &report::reject_report_web('auth',$reason,{},$param->{'action'});
	 &wwslog('info','do_resetbounce: %s may not reset', $param->{'user'}{'email'});
	 return undef;
     }

     my @emails = split /\0/, $in{'email'};

     foreach my $email (@emails) {

	 my $escaped_email = &tools::escape_chars($email);

	 unless ( $list->is_user($email) ) {
	     &report::reject_report_web('user','not_subscriber',{'email'=> $email},$param->{'action'},$list);
	     &wwslog('info','do_del: %s not subscribed', $email);
	     return undef;
	 }

	 unless( $list->update_user($email, {'bounce' => 'NULL', 'update_date' => time, 'score' => 0})) {
	     &report::reject_report_web('intern','update_subscriber_db_failed',{'sub'=> $email},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('info','do_resetbounce: failed update database for %s', $email);
	     return undef;
	 }

	 my $bounce_dir = $list->get_bounce_dir();

	 unless (unlink $bounce_dir.'/'.$escaped_email) {
	     &wwslog('info','do_resetbounce: failed deleting %s', $bounce_dir.'/'.$escaped_email);
	 }

	 &wwslog('info','do_resetbounce: bounces for %s reset ', $email);

     }

     return $in{'previous_action'} || 'review';
 }

 ## Rebuild an archive using arctxt/
 sub do_rebuildarc {
     &wwslog('info', 'do_rebuildarc(%s, %s)', $param->{'list'}, $in{'month'});

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_rebuildarc: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_rebuildarc: no user');
	 return 'loginrequest';
     }

     unless ($param->{'is_listmaster'}) {
	 &report::reject_report_web('auth','action_listmaster',{},$param->{'action'},$list);
	 &wwslog('info','do_rebuildarc: not listmaster');
	 return undef;
     }

     my $file = $Conf{'queueoutgoing'}.'/.rebuild.'.$list->get_list_id();

     unless (open REBUILD, ">$file") {
	 &report::reject_report_web('intern','cannot_open_file',{'file' => $file},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('info','do_rebuildarc: cannot create %s', $file);
	 return undef;
     }

     &wwslog('info', 'File: %s', $file);

     print REBUILD ' ';
     close REBUILD;

     &report::notice_report_web('performed',{},$param->{'action'});

     return 'admin';
 }

 ## Rebuild all archives using arctxt/
 sub do_rebuildallarc {
     &wwslog('info', 'do_rebuildallarc');

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_rebuildallarc: no user');
	 return 'loginrequest';
     }

     unless ($param->{'is_listmaster'}) {
	 &report::reject_report_web('auth','action_listmaster',{},$param->{'action'});
	 &wwslog('info','do_rebuildallarc: not listmaster');
	 return undef;
     }

     my $all_lists = &List::get_lists($robot);
     foreach my $list ( @$all_lists ) {
	 next unless (defined $list->{'admin'}{'web_archive'});
	 my $file = $Conf{'queueoutgoing'}.'/.rebuild.'.$list->get_list_id();

	 unless (open REBUILD, ">$file") {
	     &report::reject_report_web('intern','cannot_open_file',{'file' => $file},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	     &wwslog('info','do_rebuildarc: cannot create %s', $file);
	     return undef;
	 }

	 &wwslog('info', 'File: %s', $file);

	 print REBUILD ' ';
	 close REBUILD;

     }
     &report::notice_report_web('performed',{},$param->{'action'});

     return 'serveradmin';
 }

 ## Search among lists
 sub do_search_list {
     &wwslog('info', 'do_search_list(%s)', $in{'filter'});

     unless ($in{'filter'}) {
	 &report::reject_report_web('user','no_filter',{},$param->{'action'});
	 &wwslog('info','do_search_list: no filter');
	 return undef;
     }elsif ($in{'filter'} =~ /[<>\\\*\$]/) {
	 &report::reject_report_web('user','syntax_errors',{'params' => 'filter'},$param->{'action'});
	 &wwslog('err','do_search_list: syntax error');
	 return undef;
     }

     ## Regexp
     $param->{'filter'} = $in{'filter'};
     $param->{'regexp'} = $param->{'filter'};
     $param->{'regexp'} =~ s/\\/\\\\/g;
     $param->{'regexp'} =~ s/\./\\\./g;
     $param->{'regexp'} =~ s/\*/\.\*/g;
     $param->{'regexp'} =~ s/\+/\\\+/g;
     $param->{'regexp'} =~ s/\?/\\\?/g;
     $param->{'regexp'} =~ s/\[/\\\[/g;
     $param->{'regexp'} =~ s/\]/\\\]/g;
     $param->{'regexp'} =~ s/\(/\\\)/g;
     $param->{'regexp'} =~ s/\)/\\\)/g;

     ## Members list
     my $record = 0;
     my $all_lists = &List::get_lists($robot);
     foreach my $list ( @$all_lists ) {
	 my $is_admin;
	 ## Search filter
	 my $regtest = eval { (($list->{'name'} !~ /$param->{'regexp'}/i)
			       && ($list->{'admin'}{'subject'} !~ /$param->{'regexp'}/i)) };
	 unless (defined($regtest)) {
	     &report::reject_report_web('user','syntax_errors',{'params' => 'filter'},$param->{'action'});
 	     &wwslog('err','do_search_list: syntax error');
	     return undef;
	  }
	 next if $regtest;
	 	 
	 my $result = $list->check_list_authz('visibility',$param->{'auth_method'},
					      {'sender' => $param->{'user'}{'email'}, 
					       'remote_host' => $param->{'remote_host'},
					       'remote_addr' => $param->{'remote_addr'}});
	 my $r_action;
	 $r_action = $result->{'action'} if (ref($result) eq 'HASH');
	 next unless ($r_action eq 'do_it');

	 if ($param->{'user'}{'email'} &&
	     ($list->am_i('owner',$param->{'user'}{'email'}) ||
	      $list->am_i('editor',$param->{'user'}{'email'})) ) {
	     $is_admin = 1;
	 }

	 $record++;
	 $param->{'which'}{$list->{'name'}} = {'host' => $list->{'admin'}{'host'},
					       'subject' => $list->{'admin'}{'subject'},
					       'admin' => $is_admin,
					       'export' => 'no'};
     }
     $param->{'occurrence'} = $record;

     ##Lists stored in ldap directories
     my %lists;
     if($in{'extended'}){
	 foreach my $directory (keys %{$Conf{'ldap_export'}}){
	     next unless(%lists = &Ldap::get_exported_lists($param->{'regexp'},$directory));
	     
	     foreach my $list_name (keys %lists) {
		 $param->{'occurrence'}++ unless($param->{'which'}{$list_name});
		 next if($param->{'which'}{$list_name});
		 $param->{'which'}{$list_name} = {'host' => "$lists{$list_name}{'host'}",
						  'subject' => "$lists{$list_name}{'subject'}",
						  'urlinfo' => "$lists{$list_name}{'urlinfo'}",
						  'list_address' => "$lists{$list_name}{'list_address'}",
						  'export' => 'yes',
					      };
	     }  
	 }
     } 
     
     return 1;
 }

sub do_edit_list {
    &wwslog('info', 'do_edit_list()');
    
    unless ($param->{'user'}{'email'}) {
	&report::reject_report_web('user','no_user',{},$param->{'action'});
	&wwslog('info','do_edit_list:  no user');
	return 'loginrequest';
    }
    
    unless ($param->{'is_owner'}) {
	&report::reject_report_web('auth','action_owner',{},$param->{'action'},$list);
	&wwslog('info','do_edit_list: not allowed');
	return undef;
    }
    
    my $family;
    if (defined $list->{'admin'}{'family_name'}) {
	unless ($family = $list->get_family()) {
	    &report::reject_report_web('intern','unable_get_family',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	    &wwslog('info','do_edit_list : impossible to get list %s\'s family',$list->{'name'});
	    return undef;
	}          
    }
    
    my $new_admin = {};
    
    ## List the parameters editable sent in the format
    my $edited_param = {};
    
    foreach my $key (sort keys %in) {
	next unless ($key =~ /^(single_param|multiple_param)\.(\S+)$/);
	
	$key =~ /^(single_param|multiple_param)\.(\S+)$/;
	my ($type, $name) = ($1, $2);
	
	## Tag parameter as present in the form
	if ($name =~ /^([^\.]+)(\.)/ ||
	    $name =~ /^([^\.]+)$/) {
	    $edited_param->{$1} = 1;
	}
	
	## Parameter value
	my $value = $in{$key};
	next if ($value =~ /^\s*$/);
	
	if ($type eq 'multiple_param') {
	    my @values = split /\0/, $value;
	    $value = \@values;
	}
	
	my @token = split /\./, $name;
	
	## make it an entry in $new_admin
	my $var = &_shift_var(0, $new_admin, @token);
	$$var = $value;
    } 

    #    print "Content-type: text/plain\n\n";
    #    &tools::dump_var($new_admin,0);
    
    ## Did the config changed ?
    unless ($list->{'admin'}{'serial'} == $in{'serial'}) {
	&report::reject_report_web('user','config_changed',{'email' => $list->{'admin'}{'update'}{'email'}},$param->{'action'},$list);
	&wwslog('info','do_edit_list: Config file has been modified(%d => %d) by %s. Cannot apply changes', $in{'single_param.serial'}, $list->{'admin'}{'serial'}, $list->{'admin'}{'update'}{'email'});
	return undef;
    }
    
    ## Check changes & check syntax
    my (%changed, %delete);
    my @syntax_error;
    
    ## Check family constraint
    my %check_family;
    
    
    ## getting changes about owners or editors
    my $owner_update = 0;
    my $editor_update = 0;	
    
    foreach my $pname (sort List::by_order keys %{$edited_param}) {
	
	my ($p, $new_p);
	## Check privileges first
	next unless ($list->may_edit($pname,$param->{'user'}{'email'}) eq 'write');
	
	## family_constraint : edit control
	if (ref($family) eq 'Family') {
	    
	    if ((ref($::pinfo{$pname}{'format'}) ne 'HASH') && (!ref($pname))) { # simple parameter
		my $constraint = $family->get_param_constraint($pname);
		
		if (ref($constraint) eq 'HASH') { # controlled parameter        
		    $check_family{$pname} = $constraint;
		    
		} elsif ($constraint ne '0') {    # fixed parameter (free : no control)
		    next;
		}
	    }
	}
	
	#next unless (defined $new_admin->{$pname});
	next if $pinfo->{$pname}{'obsolete'};
	
	my $to_index;
	
	## Single vs multiple parameter
	if ($pinfo->{$pname}{'occurrence'} =~ /n$/) {
	    
	    my $last_index = $#{$new_admin->{$pname}};
	    
	    if ($#{$list->{'admin'}{$pname}} < $last_index) {
		$to_index = $last_index;
	    }else {
		$to_index = $#{$list->{'admin'}{$pname}};
	    }
	    
	    if ($#{$list->{'admin'}{$pname}} != $last_index) {
		$changed{$pname} = 1; 
		#next;
	    }
	    $p = $list->{'admin'}{$pname};
	    $new_p = $new_admin->{$pname};
#	     &wwslog('notice',"MULTIPLE param 5 6 7 8: $pname...........................");
	}else {
	    $p = [$list->{'admin'}{$pname}];
	    $new_p = [$new_admin->{$pname}];
#	     &wwslog('notice',"UNIQUE param 1 2 3 4 : $pname.........................");
	}

	 ## Check changed parameters
	 ## Also check syntax
	foreach my $i (0..$to_index) {
	    
	    ## Scenario
	    ## Eg: 'subscribe'
	    if ($pinfo->{$pname}{'scenario'} || 
		$pinfo->{$pname}{'task'} ) {
		if ($p->[$i]{'name'} ne $new_p->[$i]{'name'}) {
		    $changed{$pname} = 1; next;
		}
		# &wwslog('notice',"..scenario task, SIMPLE UNIVALUE, param 1-5 : $pname($new_p->[$i]{'name'})");
		## Hash
		## Ex: 'owner'
	    }elsif (ref ($pinfo->{$pname}{'format'}) eq 'HASH') {
#		 &wwslog('notice',"..COMPOSE param 2 4 6 8 : $pname");
		## Foreach Keys
		## Ex: 'owner->email'
		foreach my $key (keys %{$pinfo->{$pname}{'format'}}) {
		    
		    next unless ($list->may_edit("$pname.$key",$param->{'user'}{'email'}) eq 'write');
		    
		    ## family_constraint : edit_control
		    if (ref($family) eq 'Family') {
			if ((ref($::pinfo{$pname}{'format'}) eq 'HASH') && !ref($pname) && !ref($key)) {
			    my $constraint = $family->get_param_constraint("$pname.$key");
			    
			    if (ref($constraint) eq 'HASH') { # controlled parameter        
				$check_family{$pname}{$key} = $constraint;
			    } elsif ($constraint ne '0') {    # fixed parameter
				next;
			    }
			}
		    }		     
		    
		    ## Ex: 'shared_doc->d_read'
		    if ($pinfo->{$pname}{'format'}{$key}{'scenario'} || 
			$pinfo->{$pname}{'format'}{$key}{'task'} ) {
			#			 &wwslog('notice',"....scenario task UNIVALUE param 2 6 : $pname.$key($new_p->[$i]{$key}{'name'})");
			if ($p->[$i]{$key}{'name'} ne $new_p->[$i]{$key}{'name'}) {
			    $changed{$pname} = 1; next;
			}
		    }else{
			## Multiple param
			#&wwslog('notice',"....non task non scenario param 2 4 6 8");
			if ($pinfo->{$pname}{'format'}{$key}{'occurrence'} =~ /n$/) {
			    #&wwslog('notice',"......MULTIVALUE param 4 8 : $pname.$key(@{$new_p->[$i]{$key}})");
			    if ($#{$p->[$i]{$key}} != $#{$new_p->[$i]{$key}}) {
				$changed{$pname} = 1; next;
			    }
			    
			    ## Multiple param, foreach entry
			    ## Ex: 'digest->days'
			    foreach my $index (0..$#{$p->[$i]{$key}}) {
#				 &wwslog('notice',"........($new_p->[$i]{$key}[$index])");
				my $format = $pinfo->{$pname}{'format'}{$key}{'format'};
				if (ref ($format)) {
				    $format = $pinfo->{$pname}{'format'}{$key}{'file_format'};
				}
				
				if ($p->[$i]{$key}[$index] ne $new_p->[$i]{$key}[$index]) {
				    
				    if ($new_p->[$i]{$key}[$index] !~ /^$format$/i) {
					push @syntax_error, $pname;
				    }
				    $changed{$pname} = 1; next;
				}
			    }
			    
			    ## Single Param
			    ## Ex: 'owner->email'
			}else {
#			     &wwslog('notice',"......UNIVALUE param 2 6: $pname.$key($new_p->[$i]{$key})");
			    if (! $new_p->[$i]{$key}) {
				## If empty and is primary key => delete entry
				if ($pinfo->{$pname}{'format'}{$key}{'occurrence'} =~ /^1/) {
				    $new_p->[$i] = undef;
				    
				    ## Skip the rest of the paragraph
				    $changed{$pname} = 1; last;
				    
				    ## If optionnal parameter
				}else {
				    $changed{$pname} = 1; next;
				}
			    }
			    if ($p->[$i]{$key} ne $new_p->[$i]{$key}) {
				
				my $format = $pinfo->{$pname}{'format'}{$key}{'format'};
				if (ref ($format)) {
				    $format = $pinfo->{$pname}{'format'}{$key}{'file_format'};
				}
				
				if ($new_p->[$i]{$key} !~ /^$format$/i) {
				    push @syntax_error, $pname;
				}
				
				$changed{$pname} = 1; next;
			    }
			}
		    }
		}
		## Scalar
		## Ex: 'max_size'
	    }else {
#		 &wwslog('notice',"..SIMPLE non SCENARIO non TASK param 1-3-5-7 : $pname($new_p->[$i])");
		if (! defined($new_p->[$i])) {
		    push @{$delete{$pname}}, $i;
		    $changed{$pname} = 1;
		}elsif ($p->[$i] ne $new_p->[$i]) {
		    unless ($new_p->[$i] =~ /^$pinfo->{$pname}{'file_format'}$/) {
			push @syntax_error, $pname;
		    }
		    $changed{$pname} = 1; 
		}
	    }	    
	}
    }

     ## Syntax errors
     if ($#syntax_error > -1) {
	 &report::reject_report_web('user','syntax_errors',{'params' => 'filter'},$param->{'action'},$list);
	 foreach my $pname (@syntax_error) {
	     &wwslog('info','do_edit_list: Syntax errors, param %s=\'%s\'', $pname, $new_admin->{$pname});
	 }
	 return undef;
     }

    ## Checking no topic named "other"
    foreach my $msg_topic (@{$new_admin->{'msg_topic'}}) {
	if ($msg_topic->{'name'} =~  /^other$/i) {
	    $msg_topic->{'name'} = undef;
	    $msg_topic->{'title'} = undef;
	    &report::reject_report_web('user','topic_other',{},$param->{'action'},$list);
	    &wwslog('notice',"do_edit_list: topic other is a reserved word");
	    return undef;
	}
    }

    ## For changed msg_topic.name
    if (defined $new_admin->{'msg_topic'} && $list->modifying_msg_topic_for_subscribers($new_admin->{'msg_topic'})) {
	&report::notice_report_web('subscribers_noticed_deleted_topics',{},$param->{'action'});
    }

    ## Delete selected params
    foreach my $p (keys %delete) {
	
	if (($p eq 'owner') || ($p eq 'owner_include')) {
	    $owner_update = 1;
	}
	
	if (($p eq 'editor') || ($p eq 'editor_include')) {
	    $editor_update = 1;
	}
	
	## Delete ALL entries
	unless (ref ($delete{$p})) {
	    #	    if (defined $check_family{$p}) { # $p is family controlled
	    #		&error_message('failed');
	    #		&wwslog('info','do_edit_list : parameter %s must have values (family context)',$p);
	    #		return undef;	
	    #	    }
	    undef $new_admin->{$p};
	    next;
	}
	
	## Delete selected entries
	foreach my $k (reverse @{$delete{$p}}) {
	    splice @{$new_admin->{$p}}, $k, 1;
	}
	
	if (defined $check_family{$p}) { # $p is family controlled
	    if ($#{$new_admin->{$p}} < 0) {
		&report::reject_report_web('user','p_family_controlled',{'param' => $p},$param->{'action'},$list);
		&wwslog('info','do_edit_list : parameter %s must have values (family context)',$p);
		return undef;	
	    }    
	}
    }
      
    # updating config_changes for deleted parameters
    if (ref($family)) {
	my @array_delete = keys %delete;
	unless ($list->update_config_changes('param',\@array_delete)) {
	    &report::reject_report_web('intern','update_config_changes',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	    &wwslog('info','do_edit_list: cannot write in config_changes for deleted parameters from list %s', $list->{'name'});
	    return undef;
	}
    }
    
    ## Update config in memory
    my $data_source_updated;
    foreach my $parameter (keys %changed) {
	
	my $pname;
	if ($parameter =~ /^([\w-]+)\.([\w-]+)$/) {
	    $pname = $1;
	} else{
	    $pname = $parameter;
	}
	
	my @users;
	
	if (defined $check_family{$pname}) { # $pname is CONTROLLED
	    &_check_new_values(\%check_family,$pname,$new_admin);
	}	  
	
	## If datasource config changed
	if ($pname =~ /^(include_.*|user_data_source|ttl)$/) {
	    $data_source_updated = 1;
	}
	
	## User Data Source
	if ($pname eq 'user_data_source') {
	    ## Migrating to database
	    if (($list->{'admin'}{'user_data_source'} eq 'file') && ($new_admin->{'user_data_source'} eq 'database' || $new_admin->{'user_data_source'} eq 'include2')) {
		unless (-f "$list->{'dir'}/subscribers") {
		    &wwslog('notice', 'No subscribers to load in database');
		}
		@users = &List::_load_users_file("$list->{'dir'}/subscribers");
	    }elsif (($list->{'admin'}{'user_data_source'} ne 'include2') &&
		    ($new_admin->{'user_data_source'} eq 'include2')) {
		$list->update_user('*', {'subscribed' => 1});
		&report::notice_report_web('subscribers_updated_soon',{},$param->{'action'});
	    }elsif (($list->{'admin'}{'user_data_source'} eq 'include2') &&
		    ($new_admin->{'user_data_source'} eq 'database')) {
		$list->sync_include('purge');
	    }
	    
	    ## Update total of subscribers
	    $list->{'total'} = $list->_load_total_db();
	    $list->savestats();
	}
	
	#If no directory, delete the entry
	if($pname eq 'export'){
	    foreach my $old_directory (@{$list->{'admin'}{'export'}}){
		my $var = 0;
		foreach my $new_directory (@{$new_admin->{'export'}}){
		    next unless($new_directory eq $old_directory);
		    $var = 1;
		}
		
		if(!$var || $new_admin->{'status'} ne 'open'){
		    &Ldap::delete_list($old_directory,$list);
		}
	    }
	}
	
	$list->{'admin'}{$pname} = $new_admin->{$pname};
	if (defined $new_admin->{$pname} || $pinfo->{$pname}{'internal'}) {
	    delete $list->{'admin'}{'defaults'}{$pname};
	}else {
	    $list->{'admin'}{'defaults'}{$pname} = 1;
	}
	
	if (($pname eq 'user_data_source') &&
	    ($#users >= 0)) {
	    
	    $list->{'total'} = 0;
	    
	    ## Insert users in database
	    foreach my $user (@users) {
		$list->add_user($user);
	    }
	    
	    $list->get_total();
	    $list->{'mtime'}[1] = 0;
	    
	    if (($pname eq 'owner') || ($pname eq 'owner_include')){
		$owner_update = 1;
	    }
	    
	    if (($pname eq 'editor') || ($pname eq 'editor_include')){
		$editor_update = 1;
	    }
	}
	# updating config_changes for changed parameters
	
	if (ref($family)) {
	    my @array_changed = keys %changed;
	    unless ($list->update_config_changes('param',\@array_changed)) {
		&report::reject_report_web('intern','update_config_changes',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
		&wwslog('info','do_edit_file: cannot write in config_changes for changed parameters from list %s', $list->{'name'});
		return undef;
	    }
	}
    }

     ## Save config file
     unless ($list->save_config($param->{'user'}{'email'})) {
	 &report::reject_report_web('intern','cannot_save_config',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('info','do_edit_list: Cannot save config file');
	 return undef;
     }


     ## Reload config to clean some empty entries in $list->{'admin'}
     $list = new List $list->{'name'}, $robot, {'reload_config' => 1};

      unless (defined $list) {
 	  &report::reject_report_web('intern','list_reload',{},$param->{'action'},'',$param->{'user'}{'email'},$robot);
 	  &wwslog('info','do_edit_list: error in list reloading');
 	  return undef;
      }

     ## remove existing sync_include task
     ## to start a new one
     if ($data_source_updated && ($list->{'admin'}{'user_data_source'} eq 'include2')) {
	 $list->remove_task('sync_include');
	 if ($list->sync_include()) {
	     &report::notice_report_web('subscribers_updated',{},$param->{'action'});
	 }else {
	     &report::reject_report_web('intern','sync_include_failed',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 }
     }

     ## call sync_include_admin if there are changes about owners or editors and we're in mode include2
     if ( ($list->{'admin'}{'user_data_source'} eq 'include2')) {
	 unless ($list->sync_include_admin()) {
	     &report::reject_report_web('intern','sync_include_admin_failed',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('info','do_edit_list: sync_include_admin() failed');
	     return undef;
	 }
     }
#($owner_update || $editor_update) &&
     ## checking there is some owner(s)	in case of sync_include_admin not called
     if (($owner_update || $data_source_updated) && ($list->{'admin'}{'user_data_source'} ne 'include2')) {

	 unless ( $list->get_nb_owners()) {
	     &report::reject_report_web('intern','no_owner_defined',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('info','do_edit_list: no owner defined for list %s',$list->{'name'});
	     return undef;
	 }
     }


     ##Exportation to an Ldap directory
     if(($list->{'admin'}{'status'} eq 'open')){
	 if($list->{'admin'}{'export'}){
	     foreach my $directory (@{$list->{'admin'}{'export'}}){
		 if($directory){
		     unless(&Ldap::export_list($directory,$list)){
			 &report::reject_report_web('intern','exportation_failed',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
			 &wwslog('info','do_edit_list: The exportation failed');
		     }
		 }
	     }
	 }
     }

     ## Tag changed parameters
     foreach my $pname (keys %changed) {
	 $::changed_params{$pname} = 1;
     }

     ## Save stats
     $list->savestats();

#      print "Content-type: text/plain\n\n";
 #    &tools::dump_var($list->{'admin'}{'msg_topic'},0);
 #    &tools::dump_var($param->{'param'},0);


     &report::notice_report_web('list_config_updated',{},$param->{'action'});

     return 'edit_list_request';
 }

 ## Shift tokens to get a reference to the desired 
 ## entry in $var (recursive)
 sub _shift_var {
     my ($i, $var, @tokens) = @_;
 #    &wwslog('debug2','shift_var(%s,%s,%s)',$i, $var, join('.',@tokens));
     my $newvar;

     my $token = shift @tokens;

     if ($token =~ /^\d+$/) {
	 return \$var->[$token]
	     if ($#tokens == -1);

	 if ($tokens[0] =~ /^\d+$/) {
	     unless (ref $var->[$token]) {
		 $var->[$token] = [];
	     }
	     $newvar = $var->[$token];
	 }else {
	     unless (ref $var->[$token]) {
		 $var->[$token] = {};
	     }
	     $newvar = $var->[$token];
	 }
     }else {
	 return \$var->{$token}
	     if ($#tokens == -1);

	 if ($tokens[0] =~ /^\d+$/) {
	     unless (ref $var->{$token}) {
		 $var->{$token} = [];
	     }
	     $newvar = $var->{$token};
	 }else {
	     unless (ref $var->{$token}) {
		 $var->{$token} = {};
	     }
	     $newvar = $var->{$token};
	 }

     }

     if ($#tokens > -1) {
	 $i++;
	 return &_shift_var($i, $newvar, @tokens);
     }
     return $newvar;
 }

 ## Send back the list config edition form
 sub do_edit_list_request {
     &wwslog('info', 'do_edit_list_request(%s)', $in{'group'});

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_edit_list_request:  no user');
	 $param->{'previous_action'} = 'edit_list_request';
	 $param->{'previous_list'} = $in{'list'};
	 return 'loginrequest';
     }

     unless ($param->{'is_owner'}) {
	 &report::reject_report_web('auth','action_owner',{},$param->{'action'},$list);
	 &wwslog('info','do_edit_list: not allowed');
	 return undef;
     }

     if ($in{'group'}) {
	 $param->{'group'} = $in{'group'};
	 &_prepare_edit_form ($list);
     }

 #    print "Content-type: text/plain\n\n";
 #    &tools::dump_var(\%pinfo,0);
 #    &tools::dump_var($list->{'admin'},0);
 #    &tools::dump_var($param->{'param'},0);

     $param->{'serial'} = $list->{'admin'}{'serial'};
     
     return 1;
 }

sub _check_new_values {
    my $check_family = shift;
    my $pname = shift;
    my $new_admin = shift;
    &wwslog('debug3', '_check_new_values(%s)',$pname);
    
    my $uncompellable_param = &Family::get_uncompellable_param();

    if (ref($::pinfo{$pname}{'format'}) eq 'HASH') { #composed parameter

	foreach my $key (keys %{$check_family->{$pname}}) {
		    
	    my $constraint = $check_family->{$pname}{$key};
	    my $values = &List::_get_param_value_anywhere($new_admin,"$pname.$key");
	    my $nb_for = 0;
	    
	    # exception for uncompellable param
	    foreach my $p (keys %{$uncompellable_param}) {
		if (($pname eq $p) && !($uncompellable_param->{$p})) { 
		    return 1;
		}
		
		if (($pname eq $p) && ($key eq $uncompellable_param->{$p})) { 
		    return 1;
		}
	    }
	    foreach my $p_val (@{$values}) { #each element value
		$nb_for++;
		if (ref($p_val) eq 'ARRAY') { # multiple values
		    foreach my $p (@{$p_val}) {
			if (!($constraint->{$p}) && (($nb_for == 1) || ($p ne ''))) {
			    &report::reject_report_web('user','p_family_wrong',{'param' => $pname,'val'=> $p},$param->{'action'});
			    &wwslog('info','do_edit_list : parameter %s has got wrong value : %s (family context), %s, %d',$pname,$p);
			    return undef;
			}
		    }
		} else { # single value
		    if (!($constraint->{$p_val}) && (($nb_for == 1) || ($p_val ne ''))) {
			&report::reject_report_web('user','p_family_wrong',{'param' => $pname,'val'=> $p_val},$param->{'action'});
			&wwslog('info','do_edit_list : parameter %s has got wrong value : %s (family context), %s, %d',$pname,$p_val);
			return undef;
		    }
		}
	    }
	}
    } else { #simple parameter

	    # exception for uncompellable param
	    foreach my $p (keys %{$uncompellable_param}) {
		if ($pname eq $p) {
		    return 1;
		}
	    }


	my $constraint = $check_family->{$pname};
	my $values = &List::_get_param_value_anywhere($new_admin,$pname);
	my $nb_for = 0;


	foreach my $p_val (@{$values}) { #each element value
	    $nb_for++;
	    if (ref($p_val) eq 'ARRAY') { # multiple values
		foreach my $p (@{$p_val}) {
		    if (!($constraint->{$p}) && (($nb_for == 1) || ($p ne ''))) {
			&report::reject_report_web('user','p_family_wrong',{'param' => $pname,'val'=> $p},$param->{'action'});
			&wwslog('info','do_edit_list : parameter %s has got wrong value : %s (family context), %s, %d',$pname,$p);
			return undef;
		    }
		}
	    } else { # single value
		if (!($constraint->{$p_val}) && (($nb_for == 1) || ($p_val ne ''))) {
		    &report::reject_report_web('user','p_family_wrong',{'param' => $pname,'val'=> $p_val},$param->{'action'});
		    &wwslog('info','do_edit_list : parameter %s has got wrong value : %s (family context), %s, %d',$pname,$p_val);
		    return undef;
		}
	    }
	}
    }
}

## Prepare config data to be send in the
## edition form
sub _prepare_edit_form {
    my $list = shift;
    my $list_config = &tools::dup_var($list->{'admin'});
    my $family;

    if (defined $list_config->{'family_name'}) {
	unless ($family = $list->get_family()) {
	    &report::reject_report_web('intern','unable_get_family',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	    &wwslog('info','_prepare_edit_form : impossible to get list %s\'s family',$list->{'name'});
	    return undef;
	}          
    }

    foreach my $pname (sort List::by_order keys %{$pinfo}) {
	 next if ($pname =~ /^comment|defaults$/);
	 next if ($in{'group'} && ($pinfo->{$pname}{'group'} ne $in{'group'}));
	 
	 ## Skip obsolete parameters
	 next if $pinfo->{$pname}{'obsolete'};

	 my $may_edit = $list->may_edit($pname,$param->{'user'}{'email'});
	 my $p = &_prepare_data($pname, $pinfo->{$pname}, $list_config->{$pname},$may_edit,$family);

	 $p->{'default'} = $list_config->{'defaults'}{$pname};
	 $p->{'changed'} = $::changed_params{$pname};

	 ## Exceptions...too many
         if ($pname eq 'topics') {
	     $p->{'type'} = 'enum';

	     my @topics;
	     foreach my $topic(@{$p->{'value'}}) {
		 push @topics, $topic->{'value'};
	     }
	     undef $p->{'value'};
	     my %list_of_topics = &List::load_topics($robot);
	     
	     if (defined $p->{'constraint'}) {
		 &_restrict_values(\%list_of_topics,$p->{'constraint'});
	     }

	     foreach my $topic (keys %list_of_topics) {
		 $p->{'value'}{$topic}{'selected'} = 0;
		 $p->{'value'}{$topic}{'title'} = $list_of_topics{$topic}{'current_title'};
		 
		 if ($list_of_topics{$topic}{'sub'}) {
		     foreach my $subtopic (keys %{$list_of_topics{$topic}{'sub'}}) {
			 $p->{'value'}{"$topic/$subtopic"}{'selected'} = 0;
			 $p->{'value'}{"$topic/$subtopic"}{'title'} = "$list_of_topics{$topic}{'current_title'}/$list_of_topics{$topic}{'sub'}{$subtopic}{'current_title'}";
		     }
		 }
	     }
	     foreach my $selected_topic (@topics) {
		 next unless (defined $selected_topic);
		 $p->{'value'}{$selected_topic}{'selected'} = 1;
		 $p->{'value'}{$selected_topic}{'title'} = "Unknown ($selected_topic)"
		     unless (defined $p->{'value'}{$selected_topic}{'title'});
	     }
	 }elsif ($pname eq 'digest') {
	     foreach my $v (@{$p->{'value'}}) {
		 next unless ($v->{'name'} eq 'days');

		 foreach my $day (keys %{$v->{'value'}}) {
		     $v->{'value'}{$day}{'title'} = &POSIX::strftime("%A", localtime(0 + ($day +3) * (3600 * 24)));
		 }
	     }
	 }elsif ($pname eq 'lang') {
	     my $saved_lang = &Language::GetLang();
	     
	     foreach my $lang (keys %{$p->{'value'}}) {
		 #&wwslog('notice','LANG: %s', $lang);
		 &Language::SetLang($lang);
		 $p->{'value'}{$lang}{'title'} = gettext('_language_');
	     }
	     &Language::SetLang($saved_lang);
	 }

	 push @{$param->{'param'}}, $p;	
     }
     return 1; 
 }

sub _prepare_data {
    my ($name, $struct,$data,$may_edit,$family,$main_p) = @_;
    #    &wwslog('debug2', '_prepare_data(%s, %s)', $name, $data);
    # $family and $main_p (recursive call) are optionnal
    # if $main_p is needed, $family also
    next if ($struct->{'obsolete'});

     ## Prepare data structure for the parser
     my $p_glob = {'name' => $name,
		   'comment' => $struct->{'comment'}{$param->{'lang'}}
	       };

    ## family_constraint
    my $restrict = 0;
    my $constraint;
    if ((ref($family) eq 'Family') && ($may_edit eq 'write')) {
	
 	if ($main_p && defined $::pinfo{$main_p}) { 
 	    if (ref($::pinfo{$main_p}{'format'}) eq 'HASH') { # composed parameter
 		$constraint = $family->get_param_constraint("$main_p.$p_glob->{'name'}");
 	    }	
 	} else {       # simple parameter
 	    if (ref($::pinfo{$p_glob->{'name'}}{'format'}) ne 'HASH') { # simple parameter
 		$constraint = $family->get_param_constraint($p_glob->{'name'});
 	    }
 	}
 	if ($constraint eq '0') {              # free parameter
 	    $p_glob->{'may_edit'} = 'write';        
	    
 	} elsif (ref($constraint) eq 'HASH') { # controlled parameter        
 	    $p_glob->{'may_edit'} = 'write';
 	    $restrict = 1;
	    
 	} else {                               # fixed parameter
 	    $p_glob->{'may_edit'} = 'read';
 	}
	
    } else {
 	$p_glob->{'may_edit'} = $may_edit;
    }        
    
    if ($struct->{'gettext_id'}) {
	$p_glob->{'title'} = gettext($struct->{'gettext_id'});
    }else {
	$p_glob->{'title'} = $name;
    }

     ## Occurrences
     my $data2;
     if ($struct->{'occurrence'} =~ /n$/) {
	 $p_glob->{'occurrence'} = 'multiple';
	 if (defined($data)) {
	     $data2 = $data;

	     if ($may_edit eq 'write') {
		 ## Add an empty entry
		 unless (($name eq 'days') || ($name eq 'reception') || ($name eq 'rfc2369_header_fields') || ($name eq 'topics')) {
		     push @{$data2}, undef;
		     ## &wwslog('debug2', 'Add 1 %s', $name);
		 }
	     }
	 }else {
	     if ($may_edit eq 'write') {
		 $data2 = [undef];
	     }
	 }
     }else {
	 $data2 = [$data];
     }

     my @all_p;

     ## Foreach occurrence of param
     foreach my $d (@{$data2}) {
	 my $p = {};

	 ## Type of data
	 if ($struct->{'scenario'}) {
	     $p_glob->{'type'} = 'scenario';
	     my $list_of_scenario = $list->load_scenario_list($struct->{'scenario'},$robot);

	     $list_of_scenario->{$d->{'name'}}{'selected'} = 1;
	     
	     $p->{'value'} = $list_of_scenario;

	     if ($restrict) {
		 &_restrict_values($p->{'value'},$constraint);
	     }

	 }elsif ($struct->{'task'}) {
	     $p_glob->{'type'} = 'task';
	     my $list_of_task = $list->load_task_list($struct->{'task'}, $robot);

	     $list_of_task->{$d->{'name'}}{'selected'} = 1;

	     $p->{'value'} = $list_of_task;

	     if ($restrict) {
		 &_restrict_values($p->{'value'},$constraint);
	     }

	 }elsif ($struct->{'datasource'}) {
	     $p_glob->{'type'} = 'datasource';
	     my $list_of_data_sources = $list->load_data_sources_list($robot);

	     $list_of_data_sources->{$d}{'selected'} = 1;

	     $p->{'value'} = $list_of_data_sources;

	     if ($restrict) {
		 &_restrict_values($p->{'value'},$constraint);
	     }

	 }elsif (ref ($struct->{'format'}) eq 'HASH') {
	     $p_glob->{'type'} = 'paragraph';
	     unless (ref($d) eq 'HASH') {
		 $d = {};
	     }

	     foreach my $k (sort {$struct->{'format'}{$a}{'order'} <=> $struct->{'format'}{$b}{'order'}} 
			    keys %{$struct->{'format'}}) {
		 ## Prepare data recursively
		 my $m_e = $list->may_edit("$name.$k",$param->{'user'}{'email'});
		 my $v = &_prepare_data($k, $struct->{'format'}{$k}, $d->{$k},$m_e,$family,$name);

		 push @{$p->{'value'}}, $v;
	     }

	 }elsif ((ref ($struct->{'format'}) eq 'ARRAY') || ($restrict && ($main_p eq 'msg_topic' && $name eq 'keywords'))) {
	     $p_glob->{'type'} = 'enum';

	     unless (defined $p_glob->{'value'}) {
		 ## Initialize
		 foreach my $elt (@{$struct->{'format'}}) {
		     $p_glob->{'value'}{$elt}{'selected'} = 0;
		 }
	     }
	     if (ref ($d)) {
		 next unless (ref ($d) eq 'ARRAY');
		 foreach my $v (@{$d}) {
		     $p_glob->{'value'}{$v}{'selected'} = 1;
		 }
	     }else {
		 $p_glob->{'value'}{$d}{'selected'} = 1 if (defined $d);
	     }
	     
	     if ($restrict) {
		 &_restrict_values($p_glob->{'value'},$constraint);
	     }
	     
	 }else {
	     if ($restrict && ($name ne 'topics')) {
		 $p_glob->{'type'} = 'enum';
		 
		 foreach my $elt (keys %{$constraint}) {
		     $p->{'value'}{&tools::escape_html($elt)}{'selected'} = 0;
		 } 
		 
		 $p->{'value'}{&tools::escape_html($d)}{'selected'} = 1;
		 $p->{'length'} = $struct->{'length'};
		 $p->{'unit'} = $struct->{'unit'};
		 
	     } else {
		 
		 $p_glob->{'type'} = 'scalar';
		 $p->{'value'} = &tools::escape_html($d);
		 $p->{'length'} = $struct->{'length'};
		 $p->{'field_type'} = $struct->{'field_type'};
		 my $l = length($p->{'value'});
		 $p->{'hidden_field'} = '*' x $l;
		 $p->{'unit'} = $struct->{'unit'};
		 if ($restrict) { # for topics
		     $p_glob->{'constraint'} = $constraint;
		 }
	     }
	 }

	 push @all_p, $p;
     }

     if (($p_glob->{'occurrence'} eq 'multiple')
	 && ($p_glob->{'type'} ne 'enum')) {
	 $p_glob->{'value'} = \@all_p;
     }else {
	 foreach my $k (keys %{$all_p[0]}) {
	     $p_glob->{$k} = $all_p[0]->{$k};
	 }
     }

     return $p_glob;
 }

## Restrict allowed values in the hash
sub _restrict_values {
    my $values = shift;    #ref on hash of values
    my $allowed = shift;   #ref on hash of allowed values
    &wwslog('debug3', '_restrict_values()');

    foreach my $v (keys %{$values}) {
	unless (defined $allowed->{$v}) {
	    delete $values->{$v};
	}
    }
}

 ## NOT USED anymore (expect chinese)
 sub do_close_list_request {
     &wwslog('info', 'do_close_list_request()');

     unless($param->{'is_owner'} || $param->{'is_listmaster'}) {
	 &report::reject_report_web('auth','action_listmaster_or_owner',{},$param->{'action'},$list);
	 &wwslog('info','do_close_list_request: not listmaster or list owner');
	 return undef;
     }

     if ($list->{'admin'}{'status'} eq 'closed') {
	 &report::reject_report_web('user','already_closed',{},$param->{'action'},$list);
	 &wwslog('info','do_close_list_request: already closed');
	 return undef;
     }      

     return 1;
 }


 # in order to rename a list you must be list owner and you must be allowed to create new list
 sub do_rename_list_request {
     &wwslog('info', 'do_rename_list_request()');

     unless (($param->{'is_privileged_owner'}) || ($param->{'is_listmaster'})) {
	 &report::reject_report_web('auth','action_listmaster_or_privileged_owner',{},$param->{'action'},$list);
	 &wwslog('info','do_rename_list_request: not owner');
	 return undef;
     }  
     my $result = &List::request_action ('create_list',$param->{'auth_method'},$robot,
					 {'sender' => $param->{'user'}{'email'},
					  'remote_host' => $param->{'remote_host'},
					  'remote_addr' => $param->{'remote_addr'}});
     my $r_action;
     my $reason;
     if (ref($result) eq 'HASH') {
	 $r_action = $result->{'action'};
	 $reason = $result->{'reason'};
     }
 
     unless ($param->{'user'}{'email'} &&  ($r_action =~ /do_it|listmaster/)) {
	 &report::reject_report_web('auth',$reason,{},$param->{'action'},$list);
	 &wwslog('info','do_rename_list_request: not owner');
	 return undef;
     }

     ## Super listmaster can move a list to another robot
     if (&List::is_listmaster($param->{'user'}{'email'})) {
	 foreach (keys %{$Conf{'robots'}}) {
	     if ($_ eq $robot) {
		 $param->{'robots'}{$_} = 'selected="selected"';
	     }else {
		 $param->{'robots'}{$_} = '';
	     }	  
	 }
     }

     return '1';
 }

 # in order to rename a list you must be list owner and you must be allowed to create new list
 sub do_rename_list {
     &wwslog('info', 'do_rename_list(%s,%s)', $in{'new_listname'}, $in{'new_robot'});

     unless (($param->{'is_privileged_owner'}) || ($param->{'is_listmaster'})) {
	 &report::reject_report_web('auth','action_listmaster_or_privileged_owner',{},$param->{'action'},$list);
	 &wwslog('info','do_rename_list: not owner');
	 return undef;
     }  

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_rename_list: parameter list missing');
	 return undef;
     }  

     # check new listname syntax
     $in{'new_listname'} = lc ($in{'new_listname'});
     unless ($in{'new_listname'} =~ /^$tools::regexp{'listname'}$/i) {
	 &report::reject_report_web('user','incorrect_listname', {'bad_listname' => $in{'new_listname'}},$param->{'action'},$list);
	 &wwslog('info','do_rename_list: incorrect listname %s', $in{'new_listname'});
	 return 'rename_list_request';
     }

     # check new listname syntax
     unless ($in{'new_robot'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'robot'},$param->{'action'});
	 &wwslog('info','do_rename_list: missing new_robot parameter');
	 return 'rename_list_request';
     }
     my $result = &List::request_action ('create_list',$param->{'auth_method'},$in{'new_robot'},
					{'sender' => $param->{'user'}{'email'},
					 'remote_host' => $param->{'remote_host'},
					 'remote_addr' => $param->{'remote_addr'}});

     my $r_action;
     my $reason;
     if (ref($result) eq 'HASH') {
	 $r_action = $result->{'action'};
	 $reason = $result->{'reason'};
     }
 
     unless ($param->{'user'}{'email'} &&  ($r_action =~ /do_it|listmaster/)) {
	 &report::reject_report_web('auth',$reason,{},$param->{'action'},$list);
	 &wwslog('info','do_rename_list: not owner');
	 return undef;
     }

     ## Check listname on SMTP server
     my $res = list_check_smtp($in{'new_listname'}, $robot);
     unless ( defined($res) ) {
	 &report::reject_report_web('intern','unable_to_check_list_smtp',{'new_listname' => $in{'new_listname'},
									  'check_smtp' => $Conf{'list_check_smtp'}},
				    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('info', "can't check list %.128s on %.128s",
		 $in{'new_listname'},
		 $Conf{'list_check_smtp'});
	 return undef;
     }
     if( $res || 
	 ($list->{'name'} ne $in{'new_listname'}) && ## Do not test if listname did not change
	 (new List ($in{'new_listname'}, $in{'new_robot'}, {'just_try' => 1}))) {
	 &report::reject_report_web('user','list_already_exists',{'new_listname' => $in{'new_listname'}},$param->{'action'},$list);
	 &wwslog('info', 'Could not rename list %s for %s: new list %s already existing list', 
		 $in{'listname'},$param->{'user'}{'email'},$in{'new_listname'});
	 return undef;
     }

     my $regx = Conf::get_robot_conf($in{'new_robot'},'list_check_regexp');
     if( $regx ) {
	 if ($in{'new_listname'} =~ /^(\S+)-($regx)$/) {
	     &report::reject_report_web('user','listname_matches_aliases',{'new_listname' => $in{'new_listname'}},$param->{'action'},$list);
	     &wwslog('info','do_create_list: incorrect listname %s matches one of service aliases', $in{'new_listname'});
	     return 'rename_list_request';
	 }
     }
     
     $list->savestats();

     ## Dump subscribers
     $list->_save_users_file("$list->{'dir'}/subscribers.closed.dump");

     my $aliases = &admin::remove_aliases($list,$robot);
     if ($aliases == 1) {
 	 $param->{'auto_aliases'} = 1;
     }else { 
 	 $param->{'aliases'} = $aliases;
 	 $param->{'auto_aliases'} = 0;
     }     

     ## Rename this list itself
     my $new_dir;
     ## Default robot
     if (-d "$Conf{'home'}/$in{'new_robot'}") {
	 $new_dir = $Conf{'home'}.'/'.$in{'new_robot'}.'/'.$in{'new_listname'};
     }elsif ($in{'new_robot'} eq $Conf{'host'}) {
	 $new_dir = $Conf{'home'}.'/'.$in{'new_listname'};
     }else {
	 &wwslog('info',"do_rename_list : unknown robot $in{'new_robot'}");
	 &report::reject_report_web('user','unknown_robot',{'new_robot' =>  $in{'new_robot'}},$param->{'action'},$list);
	 return undef;
     }
     # set list status topending if creation list is moderated
     $list->{'admin'}{'status'} = 'pending' if ($r_action =~ /listmaster/) ;

     ## Save config file for the new() later to reload it
     $list->save_config($param->{'user'}{'email'});

     unless (rename ($list->{'dir'}, $new_dir )){
	 &wwslog('info',"do_rename_list : unable to rename $list->{'dir'} to $new_dir : $!");
	 &report::reject_report_web('intern','rename_dir',{'old'=>$list->{'dir'}, 
							   'new'=>$new_dir },
				    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 return undef;
     }
     ## Rename archive
     my $arc_dir = $wwsconf->{'arc_path'}.'/'.$list->get_list_id();
     my $new_arc_dir = $wwsconf->{'arc_path'}.'/'.$in{'new_listname'}.'@'.$in{'new_robot'};
     if (-d $arc_dir) {
	 unless (rename ($arc_dir,$new_arc_dir)) {
	     &wwslog('info',"do_rename_list : unable to rename archive $arc_dir");
	     &report::reject_report_web('intern','rename_dir',{'old'=>$arc_dir, 
							       'new'=>$new_arc_dir},
					$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     # continue even if there is some troubles with archives
	     # return undef;
	 }
     }
     ## Rename bounces
     my $bounce_dir = $list->get_bounce_dir();
     my $new_bounce_dir = &Conf::get_robot_conf($in{'new_robot'}, 'bounce_path').'/'.$in{'new_listname'}.'@'.$in{'new_robot'};
     if (-d $bounce_dir &&
	 ($list->{'name'} ne $in{'new_listname'})
	 ) {
	 unless (rename ($bounce_dir,$new_bounce_dir)) {
	     &report::reject_report_web('intern','rename_dir',{'old'=> $bounce_dir,
									  'new'=>$new_bounce_dir},
					$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('info',"do_rename_list unable to rename bounces from $bounce_dir to $new_bounce_dir");
	 }
     }


     # if subscribtion are stored in database rewrite the database
     if ($list->{'admin'}{'user_data_source'} =~ /^database|include2$/) {
	 &List::rename_list_db ($list,$in{'new_listname'},$in{'new_robot'});
	 &wwslog('debug',"do_rename_list :List::rename_list_db ($in{'list'},$in{'new_listname'} ");
     }

     ## Install new aliases
     $in{'listname'} = $in{'new_listname'};
     
     unless ($list = new List ($in{'new_listname'}, $in{'new_robot'},{'reload_config' => 1})) {
	 &wwslog('info',"do_rename_list : unable to load $in{'new_listname'} while renamming");
	 &report::reject_report_web('intern','list_reload',{'new_listname' => $in{'new_listname'}},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 return undef;
     }

     if ($list->{'admin'}{'status'} eq 'open') {
      	 my $aliases = &admin::install_aliases($list,$robot);
 	 if ($aliases == 1) {
 	     $param->{'auto_aliases'} = 1;
 	 }else { 
 	     $param->{'aliases'} = $aliases;
 	     $param->{'auto_aliases'} = 0;
 	 }
     } 

     ## Rename files in spools
     ## Auth & Mod  spools
     foreach my $spool ('queueauth','queuemod','queuetask','queuebounce',
			'queue','queueoutgoing','queuesubscribe') {
	 unless (opendir(DIR, $Conf{$spool})) {
	     &wwslog('info', "Unable to open '%s' spool : %s", $Conf{$spool}, $!);
	 }
	 
	 foreach my $file (sort grep (!/^\.+$/,readdir(DIR))) {
	     next unless ($file =~ /^$param->{'list'}\_/ ||
			  $file =~ /^$param->{'list'}\./ ||
			  $file =~ /^$param->{'list'}\@$robot\./ ||
			  $file =~ /^$param->{'list'}\@$robot\_/ ||
			  $file =~ /\.$param->{'list'}$/);
	     
	     my $newfile = $file;
	     if ($file =~ /^$param->{'list'}\_/) {
		 $newfile =~ s/^$param->{'list'}\_/$in{'new_listname'}\_/;
	     }elsif ($file =~ /^$param->{'list'}\./) {
		 $newfile =~ s/^$param->{'list'}\./$in{'new_listname'}\./;
	     }elsif ($file =~ /^$param->{'list'}\@$robot\./) {
		 $newfile =~ s/^$param->{'list'}\@$robot\./$in{'new_listname'}\@$in{'new_robot'}\./;
	     }elsif ($file =~ /^$param->{'list'}\@$robot\_/) {
		 $newfile =~ s/^$param->{'list'}\@$robot\_/$in{'new_listname'}\@$in{'new_robot'}\_/;
	     }elsif ($file =~ /\.$param->{'list'}$/) {
		 $newfile =~ s/\.$param->{'list'}$/\.$in{'new_listname'}/;
	     }
 
	     ## Rename file
	     unless (rename "$Conf{$spool}/$file", "$Conf{$spool}/$newfile") {
		 &wwslog('err', "Unable to rename %s to %s : %s", "$Conf{$spool}/$newfile", "$Conf{$spool}/$newfile", $!);
		 next;
	     }
	     
	     ## Change X-Sympa-To
	     &tools::change_x_sympa_to("$Conf{$spool}/$newfile", "$in{'new_listname'}\@$in{'new_robot'}");
	 }
	 
	 close DIR;
     }

     ## Digest spool
     if (-f "$Conf{'queuedigest'}/$param->{'list'}") {
	 unless (rename "$Conf{'queuedigest'}/$param->{'list'}", "$Conf{'queuedigest'}/$in{'new_listname'}") {
	     &wwslog('err', "Unable to rename %s to %s : %s", "$Conf{'queuedigest'}/$param->{'list'}", "$Conf{'queuedigest'}/$in{'new_listname'}", $!);
	     next;
	 }
     }elsif (-f "$Conf{'queuedigest'}/$param->{'list'}\@$robot") {
	 unless (rename "$Conf{'queuedigest'}/$param->{'list'}\@$robot", "$Conf{'queuedigest'}/$in{'new_listname'}\@$in{'new_robot'}") {
	     &wwslog('err', "Unable to rename %s to %s : %s", "$Conf{'queuedigest'}/$param->{'list'}\@$robot", "$Conf{'queuedigest'}/$in{'new_listname'}\@$in{'new_robot'}", $!);
	     next;
	 }
}     


     if ($in{'new_robot'} eq '$robot') {
	 $param->{'redirect_to'} = "$param->{'base_url'}$param->{'path_cgi'}/admin/$in{'new_listname'}";
     }else {
	 $param->{'redirect_to'} = &Conf::get_robot_conf($in{'new_robot'}, 'wwsympa_url')."/admin/$in{'new_listname'}";
     }

     $param->{'list'} = $in{'new_listname'};

     return 1;

 }


 sub do_purge_list {
     &wwslog('info', 'do_purge_list()');

     unless (($param->{'is_listmaster'}) || ($param->{'is_privileged_owner'})) {
	 &report::reject_report_web('auth','action_listmaster_or_privileged_owner',{},$param->{'action'},$list);
	 &wwslog('info','do_purge_list: not privileged_owner');
	 return undef;
     }  

     unless ($in{'selected_lists'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'selected_lists'},$param->{'action'});
	 &wwslog('info','do_purge_list: no list');
	 return undef;
     }

     my @lists = split /\0/, $in{'selected_lists'};

     foreach my $l (@lists) {
	 my $list = new List ($l, $robot);
	 next unless (defined $list);
	 $list->purge($param->{'user'}{'email'});
     }    

      &report::notice_report_web('performed',{},$param->{'action'});

     return 'serveradmin';
 }

 sub do_close_list {
     &wwslog('info', "do_close_list($list->{'name'})");

     unless ($param->{'is_privileged_owner'}) {
	 &report::reject_report_web('auth','action_privileged_owner',{},$param->{'action'},$list);
	 &wwslog('info','do_close_list: not privileged owner');
	 return undef;
     }  

     if ($list->{'admin'}{'status'} eq 'closed') {
	 &report::reject_report_web('user','already_closed',{},$param->{'action'},$list);
	 &wwslog('info','do_close_list: already closed');
	 return undef;
     }elsif($list->{'admin'}{'status'} eq 'pending') {
	 &wwslog('info','do_close_list: closing a pending list makes it purged');
	 $list->purge($param->{'user'}{'email'});
	 &report::notice_report_web('list_purged',{},$param->{'action'});
	 return 'home';	
     }else{
	 $list->close($param->{'user'}{'email'});
	 &report::notice_report_web('list_closed',{},$param->{'action'});
         return 'admin';
     }

 }

 sub do_restore_list {
     &wwslog('info', 'do_restore_list()');

     unless ($param->{'is_listmaster'}) {
	 &report::reject_report_web('auth','action_listmaster',{},$param->{'action'},$list);
	 &wwslog('info','do_restore_list: not listmaster');
	 return undef;
     }

     unless ($list->{'admin'}{'status'} eq 'closed') {
	 &report::reject_report_web('user','not_closed',{},$param->{'action'},$list);
	 &wwslog('info','do_restore_list: list not closed');
	 return undef;
     }      

     ## Change status & save config
     $list->{'admin'}{'status'} = 'open';
     $list->save_config($param->{'user'}{'email'});

     if ($list->{'admin'}{'user_data_source'} eq 'file') {
	 $list->{'users'} = &List::_load_users_file("$list->{'dir'}/subscribers.closed.dump");
	 $list->save();
     }elsif ($list->{'admin'}{'user_data_source'} =~ /^database|include2$/) {
	 unless (-f "$list->{'dir'}/subscribers.closed.dump") {
	     &wwslog('notice', 'No subscribers to restore');
	 }
	 my @users = &List::_load_users_file("$list->{'dir'}/subscribers.closed.dump");

	 ## Insert users in database
	 foreach my $user (@users) {
	     $list->add_user($user);
	 }
     }

     $list->savestats(); 

     my $aliases = &admin::install_aliases($list,$robot);
     if ($aliases == 1) {
 	 $param->{'auto_aliases'} = 1;
     }else { 
	 $param->{'aliases'} = $aliases;
 	 $param->{'auto_aliases'} = 0;
     }
     
     &report::notice_report_web('list_restored',{},$param->{'action'});

     return 'admin';
 }


 sub get_desc_file {
     my $file = shift;
     my $ligne;
     my %hash;

     open DESC_FILE,"$file";

     while ($ligne = <DESC_FILE>) {
	 if ($ligne =~ /^title\s*$/) {
	     #case title of the document
	     while (($ligne = <DESC_FILE>) and ($ligne!~/^\s*$/)) {
		 $ligne =~ /^\s*(\S.*\S)\s*/;
		 $hash{'title'} = $hash{'title'}.$1." ";
	     }
	 }



	 if ($ligne =~ /^creation\s*$/) {
	     #case creation of the document
	     while (($ligne = <DESC_FILE>) and ($ligne!~/^\s*$/)) {
		 if ($ligne =~ /^\s*email\s*(\S*)\s*/) {
		     $hash{'email'} = $1;
		 } 
		 if ($ligne =~ /^\s*date_epoch\s*(\d*)\s*/) {
		     $hash{'date'} = $1;
		 }

	     }
	 }   

	 if ($ligne =~ /^access\s*$/) {
	     #case access scenari for the document
	     while (($ligne = <DESC_FILE>) and ($ligne!~/^\s*$/)) {
		 if ($ligne =~ /^\s*read\s*(\S*)\s*/) {
		     $hash{'read'} = $1;
		 }
		 if ($ligne =~ /^\s*edit\s*(\S*)\s*/) {
		     $hash{'edit'} = $1;
		 }

	     }
	 }

     }


     close DESC_FILE;

     return %hash;

 }


 sub show_cert {
     return 1;
 }

 ## Function synchronize
 ## Return true if the file in parameter can be overwrited
 ## false if it has changes since the parameter date_epoch
 sub synchronize {
     # args : 'path' , 'date_epoch'
     my $path = shift;
     my $date_epoch = shift;

     my @info = stat $path;

     return ($date_epoch == $info[9]);
 }


 #*******************************************
 # Function : d_access_control
 # Description : return a hash with privileges
 #               in read, edit, control
 #               if first parameter require
 #               it 
 #******************************************

 ## Regulars
 #  read(/) = default (config list)
 #  edit(/) = default (config list)
 #  control(/) = not defined
#  read(A/B)= (read(A) && read(B)) ||
 #             (author(A) || author(B))
 #  edit = idem read
 #  control (A/B) : author(A) || author(B)
 #  + (set owner A/B) if (empty directory &&   
 #                        control A)


 sub d_access_control {
     # Arguments:
     # (\%mode,$path)
     # if mode->{'read'} control access only for read
     # if mode->{'edit'} control access only for edit
     # if mode->{'control'} control access only for control

     # return the hash (
     # $result{'may'}{'read'} == $result{'may'}{'edit'} == $result{'may'}{'control'}  if is_author else :
     # $result{'may'}{'read'} = 0 or 1 (right or not)
     # $result{'may'}{'edit'} = 0(not may edit) or 0.5(may edit with moderation) or 1(may edit ) : it is not a boolean anymore
     # $result{'may'}{'control'} = 0 or 1 (right or not)
     # $result{'reason'}{'read'} = string for authorization_reject.tt2 when may_read == 0
     # $result{'reason'}{'edit'} = string for authorization_reject.tt2 when may_edit == 0
     # $result{'scenario'}{'read'} = scenario name for the document
     # $result{'scenario'}{'edit'} = scenario name for the document

     
     # Result
     my %result;
     $result{'reason'} = {};

     # Control 

     # Arguments
     my $mode = shift;
     my $path = shift;
     
     &wwslog('debug', "d_access_control(%s, %s)", join('/',%$mode), $path);
     
     my $mode_read = $mode->{'read'};
     my $mode_edit = $mode->{'edit'};
     my $mode_control = $mode->{'control'};
     
     # Useful parameters
     my $list_name = $list->{'name'};
     my $shareddir =  $list->{'dir'}.'/shared';
     

     # document to read
     my $doc;
     if ($path) {
	 # the path must have no slash a its end
	 $path =~ /^(.*[^\/])?(\/*)$/;
	 $path = $1;
	 $doc = $shareddir.'/'.$path;
     } else {
	 $doc = $shareddir;
     }

     # Control for editing
     my $may_read = 1;
     my $why_not_read = ''; 
     my $may_edit = 1;
     my $why_not_edit = ''; 
     my $is_author = 0; # <=> $may_control

     ## First check privileges on the root shared directory
     $result{'scenario'}{'read'} = $list->{'admin'}{'shared_doc'}{'d_read'}{'name'};
     $result{'scenario'}{'edit'} = $list->{'admin'}{'shared_doc'}{'d_edit'}{'name'};

     ## Privileged owner has all privileges
     if ($param->{'is_privileged_owner'}) {
	 $result{'may'}{'read'} = 1;
	 $result{'may'}{'edit'} = 1;
	 $result{'may'}{'control'} = 1; 
	 return %result;
     }

     # if not privileged owner
     if ($mode_read) {
	 my $result = $list->check_list_authz('shared_doc.d_read',$param->{'auth_method'},
					      {'sender' => $param->{'user'}{'email'},
					       'remote_host' => $param->{'remote_host'},
					       'remote_addr' => $param->{'remote_addr'}});    
	 my $action;
	 if (ref($result) eq 'HASH') {
	     $action = $result->{'action'};   
	     $why_not_read = $result->{'reason'}; 
	 }	     
	 
	 $may_read = ($action =~ /do_it/i);
     }
      
     if ($mode_edit) {
	 my $result = $list->check_list_authz('shared_doc.d_edit',$param->{'auth_method'},
					      {'sender' => $param->{'user'}{'email'},
					       'remote_host' => $param->{'remote_host'},
					       'remote_addr' => $param->{'remote_addr'}});
	 my $action;
	 if (ref($result) eq 'HASH') {
	     $action = $result->{'action'};   
	     $why_not_edit = $result->{'reason'}; 
	 }	 
	 
	 #edit = 0, 0.5 or 1
	 $may_edit = &find_edit_mode($action);	 
	 $why_not_edit = '' if ($may_edit);
     }
     
     ## Only authenticated users can edit files
     unless ($param->{'user'}{'email'}) {
	 $may_edit = 0;
	 $why_not_edit = 'not_authenticated';
     }
     
#     if ($mode_control) {
#	 $result{'may'}{'control'} = 0;
#     }
     
     my $current_path = $path;
     my $current_document;
     my %desc_hash;
     my $user = $param->{'user'}{'email'} || 'nobody';
      
     while ($current_path ne "") {
	 # no description file found yet
	 my $def_desc_file = 0;
	 my $desc_file;
	 
	 $current_path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
	 $current_document = $3;
	 my $next_path = $1;
	 
	 # opening of the description file appropriated
	 if (-d $shareddir.'/'.$current_path) {
	     # case directory
	     
	     #		unless ($slash) {
	     $current_path = $current_path.'/';
	     #		}
	      
	     if (-e "$shareddir/$current_path.desc"){
		 $desc_file = $shareddir.'/'.$current_path.".desc";
		 $def_desc_file = 1;
	     }
	     
	 }else {
	     # case file
	     if (-e "$shareddir/$next_path.desc.$3"){
		 $desc_file = $shareddir.'/'.$next_path.".desc.".$3;
		 $def_desc_file = 1;
	     } 
	 }
	 
	 if ($def_desc_file) {
	     # a description file was found
	     # loading of acces information
	     
	     %desc_hash = &get_desc_file($desc_file);
	     
	     if ($mode_read) {
		 
		 my $result = $list->check_list_authz('shared_doc.d_read',$param->{'auth_method'},
						      {'sender' => $param->{'user'}{'email'},
						       'remote_host' => $param->{'remote_host'},
						       'remote_addr' => $param->{'remote_addr'},
						       'scenario'=> $desc_hash{'read'}});
		 my $action;
		 if (ref($result) eq 'HASH') {
		     $action = $result->{'action'};   
		     $why_not_read = $result->{'reason'}; 
		 }	     
		 
		 $may_read = $may_read && ( $action=~ /do_it/i);
		 $why_not_read = '' if ($may_read);
	     }
	     
	     if ($mode_edit) {
		 my $result = $list->check_list_authz('shared_doc.d_edit',$param->{'auth_method'},
						      {'sender' => $param->{'user'}{'email'},
						       'remote_host' => $param->{'remote_host'},
						       'remote_addr' => $param->{'remote_addr'},
						       'scenario'=> $desc_hash{'edit'}});
		 my $action_edit;
		 if (ref($result) eq 'HASH') {
		     $action_edit = $result->{'action'};   
		     $why_not_edit = $result->{'reason'}; 
		 }
		 
		 
		 # $may_edit = 0, 0.5 or 1
		 my $may_action_edit = &find_edit_mode($action_edit);
		 $may_edit = &merge_edit($may_edit,$may_action_edit); 
		 $why_not_edit = '' if ($may_edit);
		 
		 
	     }
	     
	     ## Only authenticated users can edit files
	     unless ($param->{'user'}{'email'}) {
		 $may_edit = 0;
		 $why_not_edit = 'not_authenticated';
	     }
	     
	     $is_author = $is_author || ($user eq $desc_hash{'email'});
	     
	     unless (defined $result{'scenario'}{'read'}) {
		 $result{'scenario'}{'read'} = $desc_hash{'read'};
		 $result{'scenario'}{'edit'} = $desc_hash{'edit'};
	     }
	     
	     ## Author has all privileges
	     if ($is_author) {
		 $result{'may'}{'read'} = 1;
		 $result{'may'}{'edit'} = 1;
		 $result{'may'}{'control'} = 1;
		 return %result;
	     } 
	      
	  }
	  
	  # truncate the path for the while   
	  $current_path = $next_path; 
      }
      
      if ($mode_read) {
	  $result{'may'}{'read'} = $may_read;
	  $result{'reason'}{'read'} = $why_not_read;
      }
      
      if ($mode_edit) {
	  $result{'may'}{'edit'} = $may_edit;
	  $result{'reason'}{'edit'} = $why_not_edit;
      }
      
#     if ($mode_control) {
#	 $result{'may'}{'control'} = 0;
#     }
      


      return %result;
  }

## return the mode of editing included in $action : 0, 0.5 or 1
sub find_edit_mode{
    my $action=shift;

    my $result;
    if ($action =~ /editor/i){
	$result = 0.5;
    } elsif ($action =~ /do_it/i){
	$result = 1;
    } else {
	$result = 0;
    }	 
    return $result;
}

## return the mode of editing : 0, 0.5 or 1 :
#  do the merging between 2 args of right access edit  : "0" > "0.5" > "1"
#  instead of a "and" between two booleans : the most restrictive right is
#  imposed 
sub merge_edit{
    my $arg1=shift;
    my $arg2=shift;
    my $result;

    if ($arg1 == 0 || $arg2 == 0){
	$result = 0; 
    }elsif ($arg1 == 0.5 || $arg2 == 0.5){
	$result = 0.5;
    }else {
	$result = 1;
 }
    return $result;
}




 # create the root shared document
 sub do_d_admin {
     &wwslog('info', 'do_d_admin(%s,%s)', $in{'list'}, $in{'d_admin'});

     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode,$in{'path'});


     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_d_admin : no list');
	 return undef;
     }

     my $dir = $list->{'dir'};

     unless ($access{'may'}{'edit'}) {
	 &wwslog('info',"do_d_admin : permission denied for $param->{'user'}{'email'} ");
	 &report::reject_report_web('auth',$access{'reason'}{'edit'},{},$param->{'action'},$list);
	 return undef;
     }

     if ($in{'d_admin'} eq 'create') {

	 unless ($list->create_shared()) {
	     &wwslog('info',"do_d_admin : could not create the shared");
	     &report::reject_report_web('intern','create_shared',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     return undef;	 
	 }
	 
	 return 'd_read';
 
     }elsif($in{'d_admin'} eq 'restore') {
	 unless (-e "$dir/pending.shared") {
	     &wwslog('info',"do_d_admin : restore; $dir/pending.shared not found");
	     &report::reject_report_web('intern','restore_shared',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     return undef;
	 }
	 if (-e "$dir/shared") {
	     &wwslog('info',"do_d_admin : restore; $dir/shared already exist");
	     &report::reject_report_web('intern','restore_shared',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     return undef;
	 }
	 unless (rename ("$dir/pending.shared", "$dir/shared")){
	     &wwslog('info',"do_d_admin : restore; unable to rename $dir/pending.shared");
	     &report::reject_report_web('intern','restore_shared',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     return undef;
	 }

	 return 'd_read';
     }elsif($in{'d_admin'} eq 'delete') {
	 unless (-e "$dir/shared") {
	     &wwslog('info',"do_d_admin : restore; $dir/shared not found");
	     &report::reject_report_web('intern','delete_shared',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     return undef;
	 }
	 if (-e "$dir/pending.shared") {
	     &wwslog('info',"do_d_admin : delete ; $dir/pending.shared already exist");
	     &report::reject_report_web('intern','delete_shared',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     return undef;
	 }
	 unless (rename ("$dir/shared", "$dir/pending.shared")){
	     &wwslog('info',"do_d_admin : restore; unable to rename $dir/shared");
	     &report::reject_report_web('intern','delete_shared',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     return undef;
	     }
     }

     return 'admin';
 }

 #*******************************************
# Function : do_d_read
 # Description : reads a file or a directory
 #******************************************

 # Function which sorts a hash of documents
 # Sort by various parameters
 sub by_order {
     my $order = shift;
     my $hash = shift;
     # $order = 'order_by_size'/'order_by_doc'/'order_by_author'/'order_by_date'

     if ($order eq 'order_by_doc')  {
	 $hash->{$a}{'doc'} cmp $hash->{$b}{'doc'}
	 or $hash->{$b}{'date_epoch'} <=> $hash->{$a}{'date_epoch'};
     } 
     elsif ($order eq 'order_by_author') {
	 $hash->{$a}{'author'} cmp $hash->{$b}{'author'}
	 or $hash->{$b}{'date_epoch'} <=> $hash->{$a}{'date_epoch'};
     } 
     elsif ($order eq 'order_by_size') {
	 $hash->{$a}{'size'} <=> $hash->{$b}{'size'} 
	 or $hash->{$b}{'date_epoch'} <=> $hash->{$a}{'date_epoch'};
     }
     elsif ($order eq 'order_by_date') {
	 $hash->{$b}{'date_epoch'} <=> $hash->{$a}{'date_epoch'} or $a cmp $b;
     }

     else {
	 $a cmp $b;
     }
 }


##
## Function do_d_read
sub do_d_read {
     &wwslog('info', 'do_d_read(%s)', $in{'path'});

     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_d_read: no list');
	 return undef;
     }

     ### Useful variables

     # current list / current shared directory
     my $list_name = $list->{'name'};

     # relative path / directory shared of the document 
    my $path = &no_slash_end($in{'path'});
    
     # moderation
    my $visible_path = &make_visible_path($path);

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';

     # document to read
     my $doc;
     if ($path) {
	 $doc = $shareddir.'/'.$path;
     } else {
	 $doc = $shareddir;
     }

     ### Document exist ? 
     unless (-r "$doc") {
	 &wwslog('err',"do_d_read : unable to read $shareddir/$path : no such file or directory");
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
	 return undef;
     }

     ### Document has non-size zero?
     unless (-s "$doc") {
	 &wwslog('err',"do_d_read : unable to read $shareddir/$path : empty document");
	 &report::reject_report_web('user','empty_document',{'path'=> $visible_path},$param->{'action'},$list);
	 return undef;
     }

     ### Document isn't a description file
     unless ($path !~ /\.desc/) {
	 &wwslog('err',"do_d_read : $shareddir/$path : description file");
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
	 return undef;
     }

     ### Access control    
     my %mode;
     $mode{'read'} = 1;
     $mode{'edit'} = 1;
     $mode{'control'} = 1;
     my %access = &d_access_control(\%mode,$path);
     my $may_read = $access{'may'}{'read'};
     unless ($may_read) {
	 &report::reject_report_web('auth',$access{'reason'}{'read'},{},$param->{'action'},$list);
	 &wwslog('err','d_read : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     my $may_edit = $access{'may'}{'edit'};
     my $may_control = $access{'may'}{'control'};


     ### File or directory ?

     if (!(-d $doc)) {
	 my @tokens = split /\//,$doc;
	 my $filename = $tokens[$#tokens];

	 ## Jump to the URL
	 if ($filename =~ /^\..*\.(\w+)\.moderate$/) {
	     $param->{'file_extension'} = $1;
	 }elsif ($filename =~ /^.*\.(\w+)$/) {
	     $param->{'file_extension'} = $1;
	 }

	 if ($param->{'file_extension'} eq 'url') {
	     open DOC, $doc;
	     my $url = <DOC>;
	     close DOC;
	     chomp $url;
	     $param->{'redirect_to'} = $url;
	     return 1;
	 }else {
	     # parameters for the template file
	     # view a file 
	     $param->{'file'} = $doc;
	     $param->{'bypass'} = 1;
	     return 1;	 
	 }
    }else { # directory
	 # verification of the URL (the path must have a slash at its end)
 #	if ($ENV{'PATH_INFO'} !~ /\/$/) { 
 #	    $param->{'redirect_to'} = "$param->{'base_url'}$param->{'path_cgi'}/d_read/$list_name/";
 #	    return 1;
 #	}

	 ## parameters of the current directory
	 if ($path && (-e "$doc/.desc")) {
	     my %desc_hash = &get_desc_file("$doc/.desc");
	     $param->{'doc_owner'} = $desc_hash{'email'};
	     $param->{'doc_title'} = $desc_hash{'title'};
	 }
	 my @info = stat $doc;
	 $param->{'doc_date'} =  &POSIX::strftime("%d %b %Y", localtime($info[9]));


	 # listing of all the shared documents of the directory
         unless (opendir DIR, "$doc") {
             &report::reject_report_web('intern','cannot_open_dir',{'dir' => $doc },$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err',"d_read : cannot open $doc : $!");
	     return undef;
	 }

	 # array of entry of the directory DIR 
	 my @tmpdir = readdir DIR;
	 closedir DIR;

	my $dir = &get_directory_content(\@tmpdir,$param->{'user'}{'email'},$list,$doc);

	 # empty directory?
	$param->{'empty'} = ($#{$dir} == -1);

	# subdirectories hash
	my %subdirs;
	# file hash
	my %files;

	 ## for the exception of index.html
	 # name of the file "index.html" if exists in the directory read
	 my $indexhtml;
	
	 # boolean : one of the subdirectories or files inside
	 # can be edited -> normal mode of read -> d_read.tt2;
	 my $normal_mode;


	 my $path_doc;
	 my %desc_hash;
	 my $may, my $def_desc;
	 my $user = $param->{'user'}{'email'} || 'nobody';

	foreach my $d (@{$dir}) {

	     # current document
	     my $path_doc = "$doc/$d";

	     #case subdirectory
	     if (-d $path_doc) {

		 # last update
		 my @info = stat $path_doc;

		 if (-e "$path_doc/.desc") {

		     # check access permission for reading
		     %desc_hash = &get_desc_file("$path_doc/.desc");
		     
		     my $result = $list->check_list_authz('shared_doc.d_read',$param->{'auth_method'},
							  {'sender' => $param->{'user'}{'email'},
							   'remote_host' => $param->{'remote_host'},
							   'remote_addr' => $param->{'remote_addr'},
							   'scenario' => $desc_hash{'read'}});
		     my $action;
		     $action = $result->{'action'} if (ref($result) eq 'HASH');  

		     if  (($user eq $desc_hash{'email'}) || ($may_control) ||
			  ($action =~ /do_it/i)) {
			 
			 $subdirs{$d}{'date_epoch'} = $info[9];
			 $subdirs{$d}{'date'} = &POSIX::strftime("%d %b %Y", localtime($info[9]));
			 
			 # Case read authorized : fill the hash 
			 $subdirs{$d}{'icon'} = $icon_table{'folder'};
			 
			 $subdirs{$d}{'doc'} = $d;
			 $subdirs{$d}{'escaped_doc'} =  &tools::escape_chars($d);
			 
			 # size of the doc
			 $subdirs{$d}{'size'} = (-s $path_doc)/1000;
			 
			 # description
			 $subdirs{$d}{'title'} = $desc_hash{'title'};
			 $subdirs{$d}{'escaped_title'}=&tools::escape_html($desc_hash{'title'});

			 # Author
			 if ($desc_hash{'email'}) {
			     $subdirs{$d}{'author'} = $desc_hash{'email'};
			     $subdirs{$d}{'author_mailto'} = &mailto($list,$desc_hash{'email'});
			     $subdirs{$d}{'author_known'} = 1;
			 }

			 # if the file can be read, check for edit access & edit description files access
			 ## only authentified users can edit a file

			 if ($param->{'user'}{'email'}) {
                             my $result = $list->check_list_authz('shared_doc.d_edit',$param->{'auth_method'},
								  {'sender' => $param->{'user'}{'email'},
								   'remote_host' => $param->{'remote_host'},
								   'remote_addr' => $param->{'remote_addr'},
								   'scenario' => $desc_hash{'edit'}});
			     my $action_edit;
			     $action_edit = $result->{'action'} if (ref($result) eq 'HASH');  
                             #may_action_edit = 0, 0.5 or 1
                             my $may_action_edit=&find_edit_mode($action_edit);
                             $may_action_edit=&merge_edit($may_action_edit,$may_edit);	
                            
                             if ($may_control || ($user eq $desc_hash{'email'})){

				     $subdirs{$d}{'edit'} = 1;# or = $may_action_edit ?
               			     # if index.html, must know if something can be edit in the dir
		         	     $normal_mode = 1;                         
			     } elsif ($may_action_edit != 0) {
                                 # $may_action_edit = 0.5 or 1 
				 $subdirs{$d}{'edit'} = $may_action_edit;
			     # if index.html, must know if something can be edit in the dir
			     $normal_mode = 1;
			 }
			 }
			   
			 if  ($may_control || ($user eq $desc_hash{'email'})) {
			     $subdirs{$d}{'control'} = 1;
			 }

		     }
		 } else {
		     # no description file = no need to check access for read
		     # access for edit and control

                     if ($may_control) {
			$subdirs{$d}{'edit'} = 1; # or = $may_action_edit ?
			 $normal_mode = 1;
		     } elsif ($may_edit !=0) {
                              # $may_action_edit = 1 or 0.5
                              $subdirs{$d}{'edit'} = $may_edit;
			 $normal_mode = 1;
		     }

		     if ($may_control) {$subdirs{$d}{'control'} = 1;}
		 }

	     }else {
		 # case file
		 $may = 1;
		 $def_desc = 0;

		 if (-e "$doc/.desc.$d") {
		     # a desc file was found
		     $def_desc = 1;

		     # check access permission		
		     %desc_hash = &get_desc_file("$doc/.desc.$d");


		     my $result = $list->check_list_authz('shared_doc.d_read',$param->{'auth_method'},
							 {'sender' => $param->{'user'}{'email'},
							  'remote_host' => $param->{'remote_host'},
							  'remote_addr' => $param->{'remote_addr'},
							  'scenario' => $desc_hash{'read'}});
		     my $action;
		     $action = $result->{'action'} if (ref($result) eq 'HASH');  
		     unless (($user eq $desc_hash{'email'}) || ($may_control) ||
			     ($action =~ /do_it/i)) {
			 $may = 0;
		     } 
		 } 

		 # if permission or no description file
		 if ($may) {
		     $path_doc =~ /^([^\/]*\/)*([^\/]+)\.([^\/]+)$/; 

		     ## Bookmark
		    if (($path_doc =~ /\.url$/) || ($path_doc =~ /\.url\.moderate$/)) {
			 open DOC, $path_doc;
			 my $url = <DOC>;
			 close DOC;
			 chomp $url;
			 $files{$d}{'url'} = $url;
			 $files{$d}{'anchor'} = $d;
			$files{$d}{'anchor'} =~ s/\.moderate$//;
			$files{$d}{'anchor'} =~ s/^\.//;
			 $files{$d}{'anchor'} =~ s/\.url$//;
			 $files{$d}{'icon'} = $icon_table{'url'};			

		     ## MIME - TYPES : icons for template
		     }elsif (my $type = $mime_types->{$3}) {
			 # type of the file and apache icon
			 $type =~ /^([\w\-]+)\/([\w\-]+)$/;
			 my $mimet = $1;
			 my $subt = $2;
			 if ($subt) {
			     if ($subt =~  /^octet-stream$/) {
				 $mimet = 'octet-stream';
				 $subt = 'binary';
			     }
			     $files{$d}{'type'} = "$subt file";
			 }
			 $files{$d}{'icon'} = $icon_table{$mimet} || $icon_table{'unknown'};
		     } else {
			 # unknown file type
			 $files{$d}{'icon'} = $icon_table{'unknown'};
		     }

		     ## case html
		     if ($3 =~ /^html?$/i) { 
			 $files{$d}{'html'} = 1;
			 $files{$d}{'type'} = 'html file';
			 $files{$d}{'icon'} = $icon_table{'text'};
		     }
		     ## exception of index.html
		     if ($d =~ /^(index\.html?)$/i) {
			 $indexhtml = $1;
		     }

		     ## Access control for edit and control
		     if ($def_desc) {
			 # check access for edit and control the file
			 ## Only authenticated users can edit files

                         if ($param->{'user'}{'email'}) {
                             my $result= $list->check_list_authz('shared_doc.d_edit',$param->{'auth_method'},
								 {'sender' => $param->{'user'}{'email'},
								  'remote_host' => $param->{'remote_host'},
								  'remote_addr' => $param->{'remote_addr'},
								  'scenario' => $desc_hash{'edit'}});
			     my $action_edit;
			     $action_edit = $result->{'action'} if (ref($result) eq 'HASH');  
                             #may_action_edit = 0, 0.5 or 1
                             my $may_action_edit=&find_edit_mode($action_edit);
                             $may_action_edit=&merge_edit($may_action_edit,$may_edit);

                             if ($may_control || ($user eq $desc_hash{'email'})){
			     $normal_mode = 1;
			         $files{$d}{'edit'} = 1;  # or = $may_action_edit ? 
                             } elsif ($may_action_edit != 0){
                                 # $may_action_edit = 1 or 0.5
                                 $normal_mode = 1;
			         $files{$d}{'edit'} = $may_action_edit;   
			 }

			 if (($user eq $desc_hash{'email'}) || $may_control) { 
			     $files{$d}{'control'} = 1;    
			 }

			 # fill the file hash
			   # description of the file
			 $files{$d}{'title'} = $desc_hash{'title'};
			 $files{$d}{'escaped_title'}=&tools::escape_html($desc_hash{'title'});
			   # author
			 if ($desc_hash{'email'}) {
			     $files{$d}{'author'} = $desc_hash{'email'};
			     $files{$d}{'author_known'} = 1;
			     $files{$d}{'author_mailto'} = &mailto($list,$desc_hash{'email'});
			 }
		     } else {
			     if ($may_edit!=0) {
				 $files{$d}{'edit'} = $may_edit ;
			     $normal_mode = 1;
			 }    
			 if ($may_control) {$files{$d}{'control'} = 1;} 
		     }

		       # name of the file
			 if ($d =~ /^(\.).*(.moderate)$/) {
			         # file not yet moderated can be seen by its author 
			     	 my $visible_d = $d;
				 $visible_d =~ s/^(\.)/ /;
				 $visible_d =~ s/\.moderate/ /;
				 $files{$d}{'doc'} = $visible_d;
				 $files{$d}{'moderate'} = 1;
			 } else {
		     $files{$d}{'doc'} = $d;
			 }
		     $files{$d}{'escaped_doc'} =  &tools::escape_chars($d);

		       # last update
		     my @info = stat $path_doc;
		     $files{$d}{'date_epoch'} = $info[9];
		     $files{$d}{'date'} = POSIX::strftime("%d %b %Y", localtime($info[9]));
		       # size
		     $files{$d}{'size'} = (-s $path_doc)/1000; 
		 }
	     }
	 }

	 }

	 ### Exception : index.html
	 if ($indexhtml) {
	     unless ($normal_mode) {
		 $param->{'file_extension'} = 'html';
		 $param->{'bypass'} = 1;
		 $param->{'file'} = "$doc/$indexhtml";
		 return 1;
	     }
	 }

	 ## to sort subdirs
	 my @sort_subdirs;
	 my $order = $in{'order'} || 'order_by_doc';
	 $param->{'order_by'} = $order;
	 foreach my $k (sort {by_order($order,\%subdirs)} keys %subdirs) {
	     push @sort_subdirs, $subdirs{$k};
	 }

	 ## to sort files
	 my @sort_files;
	 foreach my $k (sort {by_order($order,\%files)} keys %files) {
	     push @sort_files, $files{$k};
	 }

	 # parameters for the template file
	 $param->{'list'} = $list_name;

	 $param->{'may_edit'} = $may_edit;	
	 $param->{'may_control'} = $may_control;

	 if ($path) {
	     # building of the parent directory path
	     if ($path =~ /^(([^\/]*\/)*)([^\/]+)$/) {
		 $param->{'father'} = $1;
	     }else {
		 $param->{'father'} = '';
	     }
	     $param->{'escaped_father'} = &tools::escape_chars($param->{'father'}, '/');


	     # Parameters for the description
	     if (-e "$doc/.desc") {
		 my @info = stat "$doc/.desc";
		 $param->{'serial_desc'} = $info[9];
		 my %desc_hash = &get_desc_file("$doc/.desc");
		 $param->{'description'} = $desc_hash{'title'};
	     }

	    $param->{'path'} = $path;
	    $param->{'visible_path'} = $visible_path;
	     $param->{'escaped_path'} = &tools::escape_chars($param->{'path'}, '/');
	 }
	 if (scalar keys %subdirs) {
	     $param->{'sort_subdirs'} = \@sort_subdirs;
	 }
	 if (scalar keys %files) {
	     $param->{'sort_files'} = \@sort_files;
	 }
     }
     $param->{'father_icon'} = $icon_table{'father'};
     $param->{'sort_icon'} = $icon_table{'sort'};


    ## Show expert commands / user page
    
    # for the curent directory
    if ($may_edit == 0 && $may_control == 0) {
	$param->{'has_dir_rights'} = 0;
    } else {
	$param->{'has_dir_rights'} = 1;
	if ($may_edit == 1) { # (is_author || ! moderated)
	    $param->{'total_edit'} = 1;
	}
    }

    # set the page mode
    if ($in{'show_expert_page'} && $param->{'has_dir_rights'}) {
	$param->{'expert_page'} = 1;
	&cookielib::set_expertpage_cookie(1,$param->{'cookie_domain'});
 
    } elsif ($in{'show_user_page'}) {
	$param->{'expert_page'} = 0;
	&cookielib::set_expertpage_cookie(0,$param->{'cookie_domain'});
    } else {
	if (&cookielib::check_expertpage_cookie($ENV{'HTTP_COOKIE'}) && $param->{'has_dir_rights'}) {
	    $param->{'expert_page'} = 1; 
	} else {
	    $param->{'expert_page'} = 0;
	}
    }
    
     #open TMP, ">/tmp/dump1";
     #&tools::dump_var($param, 0,\*TMP);
     #close TMP;


     return 1;
}

## return a ref on an array of file (or subdirecties) to show to user
sub get_directory_content {
    my $tmpdir = shift; 
    my $user = shift;
    my $list = shift;
    my $doc = shift;

    # array of file not hidden
    my @dir = grep !/^\./, @$tmpdir;
	
    # array with documents not yet moderated
    my @moderate_dir = grep (/(\.moderate)$/, @$tmpdir);
    @moderate_dir = grep (!/^\.desc\./, @moderate_dir);
	
    # the editor can see file not yet moderated
    # a user can see file not yet moderated if he is th owner of these files
    if ($list->am_i('editor',$user)) {
	push(@dir,@moderate_dir);
    }else {
	my @privatedir = &select_my_files($user,$doc,\@moderate_dir);
	push(@dir,@privatedir);
 }

    return \@dir;
}


## return an array that contains only file from @$refdir that belongs to $user
sub select_my_files {
    my ($user,$path,$refdir)=@_;
    my @new_dir;
   
    foreach my $d (@$refdir) {
	if (-e "$path/.desc.$d") {
	    my %desc_hash = &get_desc_file("$path/.desc.$d");
	    if  ($user eq $desc_hash{'email'}){
		$new_dir[$#new_dir+1]=$d;
	    }
	}
    }
    return @new_dir;
}

 ## Useful function to get off the slash at the end of the path
 ## at its end
 sub no_slash_end {
     my $path = shift;

     ## supress ending '/'
     $path =~ s/\/+$//;

     return $path;
 } 

## return a visible path from a moderated file or not
sub make_visible_path {
    my $path=shift;
    if ($path =~ /\.moderate/){
	$path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
	my $name = $3;
	$name =~ s/^\.//;
	$name =~ s/\.moderate//;
	return "$2"."$name";
    }
    else {
	return $path;
    }
}


 ## Access to latest shared documents
sub do_latest_d_read {
     &wwslog('info', 'do_latest_d_read(%s,%s,%s)', $in{'list'}, $in{'for'}, $in{'count'});

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_latest_d_read: no list');
	 return undef;
     }

     unless ($in{'for'} || $in{'count'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => '"for" or "count"'},$param->{'action'});
	 &wwslog('err','do_latest_d_read: missing parameter "count" or "for"');
	 return undef;
     }

     ### shared exist ? 
     my $shareddir =  $list->{'dir'}.'/shared';
     unless (-r "$shareddir") {
	 &wwslog('err',"do_latest_d_read : unable to read $shareddir : no such file or directory");
	 &report::reject_report_web('user','no_shared',{},$param->{'action'},$list);
	 return undef;
     }
     
     ### Document has non-size zero?
     unless (-s "$shareddir") {
	 &wwslog('err',"do_latest_d_read : unable to read $shareddir : empty document");
	 &report::reject_report_web('user','shared_empty',{},$param->{'action'},$list);
	 return undef;
     }

     ### Access control    
     my %mode;
     $mode{'read'} = 1;
     $mode{'control'} = 1;

     my %access = &d_access_control(\%mode,$shareddir);
     unless ($access{'may'}{'read'}) {
	 &report::reject_report_web('auth',$access{'reason'}{'read'},{},$param->{'action'},$list);
	 &wwslog('err','latest_d_read : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     ## parameters of the query
     my $today  = time;
     
     my $oldest_day;
     if (defined $in{'for'}) {
 	 $oldest_day = $today - (86400 * ($in{'for'}));
	 $param->{'for'} = $in{'for'};
	 unless ($oldest_day >= 0){
	     &report::reject_report_web('user','nb_days_to_much',{'nb_days' => $in{'for'} },$param->{'action'},$list);
	     &wwslog('err','do_latest_d_read: parameter "for" is too big"');
	 }
     }

     my $nb_doc;
     my $NB_DOC_MAX = 100;
     if (defined $in{'count'}) {
	 if ($in{'count'} > $NB_DOC_MAX) {
	     $in{'count'} = $NB_DOC_MAX;
	 }
	 $param->{'count'} = $in{'count'};
         $nb_doc = $in{'count'};
     } else {
	 $nb_doc = $NB_DOC_MAX;
     }       

     my $documents;
     unless ($documents = &directory_browsing('',$oldest_day,$access{'may'}{'control'})) {
         &wwslog('err',"do_d_latest_d_read($list) : impossible to browse shared");
	 &report::reject_report_web('intern','browse_shared',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 return undef;
     }

     @$documents = sort ({$b->{'date_epoch'} <=> $a->{'date_epoch'}} @$documents);
     
     @{$param->{'documents'}} = splice(@$documents,0,$nb_doc);

     return 1;
 }

##  browse a directory recursively and return documents younger than $oldest_day
 sub directory_browsing {
     my ($dir,$oldest_day,$may_control) = @_;
     &wwslog('debug2',"directory_browsing($dir,$oldest_day)");
     
     my @result;
     my $shareddir =  $list->{'dir'}.'/shared';
     my $path_dir = "$shareddir/$dir";

     ## listing of all the shared documents of the directory
     unless (opendir DIR, "$path_dir") {
	 &wwslog('err',"directory_browsing($dir) : cannot open the directory : $!");
	 return undef;
     }

     my @tmpdir = readdir DIR;
     closedir DIR;
     
     # array of file not hidden
     my @directory = grep !/^\./, @tmpdir;
     
     my $user = $param->{'user'}{'email'} || 'nobody';

     ## browsing
     foreach my $d (@directory) {
	 my $path_d = "$path_dir/$d";
	 
	 #case subdirectory
	 if (-d $path_d) {
	     if (-e "$path_d/.desc") {
		 # check access permission for reading
		 my %desc_hash = &get_desc_file("$path_d/.desc");

		 my $result = $list->check_list_authz('shared_doc.d_read',$param->{'auth_method'},
						      {'sender' => $param->{'user'}{'email'},
						       'remote_host' => $param->{'remote_host'},
						       'remote_addr' => $param->{'remote_addr'},
						       'scenario' => $desc_hash{'read'}});
		 my $action;
		 $action = $result->{'action'} if (ref($result) eq 'HASH');  
		 if  (($user eq $desc_hash{'email'}) || ($may_control) ||
		      ($action =~ /do_it/i)) {
		     my $content_d;
		     unless($content_d = &directory_browsing("$dir/$d",$oldest_day)) {
			 &wwslog('err',"directory_browsing($dir) : impossible to browse subdirectory $d");
			 next;
 		     }	
		     if (ref($content_d) eq "ARRAY") {
			 push @result,@$content_d;
		     }
		 }	     
	     }	     
	     
	 #case file    
	 } else {
	     
	     my %file_info;
	     
             ## last update
	     my @info = stat $path_d;
	     $file_info{'date_epoch'} = $info[9];

	     if ($file_info{'date_epoch'} < $oldest_day) {
		 next;
	     }

	     $file_info{'last_update'} = POSIX::strftime("%d %b %Y", localtime($info[9]));
	     
             ## exception of index.html
	     if ($d =~ /^(index\.html?)$/i) {
		 next;
	     }
	     
	     my $may = 1;
	     my $def_desc = 0;
	     my %desc_hash;
	     
	     if (-e "$path_dir/.desc.$d") {
		 # a desc file was found
		 $def_desc = 1;
		 
		 # check access permission		
		 %desc_hash = &get_desc_file("$path_dir/.desc.$d");
		 
		 my $result = $list->check_list_authz('shared_doc.d_read',$param->{'auth_method'},
						      {'sender' => $param->{'user'}{'email'},
						       'remote_host' => $param->{'remote_host'},
						       'remote_addr' => $param->{'remote_addr'},
						       'scenario' => $desc_hash{'read'}});
		 my $action;
		 $action = $result->{'action'} if (ref($result) eq 'HASH');  
		 unless (($user eq $desc_hash{'email'}) || ($may_control) ||
			 ($action =~ /do_it/i)) {
		     $may = 0;
		 } 
	     } 
	     
	     # if permission or no description file
	     if ($may) {
		 $path_d =~ /^([^\/]*\/)*([^\/]+)\.([^\/]+)$/; 

		 ## Bookmark
		 if ($path_d =~ /\.url$/) {
		     open DOC, $path_d;
		     my $url = <DOC>;
		     close DOC;
		     chomp $url;
		     $file_info{'url'} = $url;
		     $file_info{'anchor'} = $d;
		     $file_info{'anchor'} =~ s/\.url$//;
		     $file_info{'icon'} = $icon_table{'url'};			
		     
		 ## MIME - TYPES : icons for template
		 }elsif (my $type = $mime_types->{$3}) {
		     # type of the file and apache icon
		     $type =~ /^([\w\-]+)\/([\w\-]+)$/;
		     my $mimet = $1;
		     my $subt = $2;
		     if ($subt) {
			 if ($subt =~  /^octet-stream$/) {
			     $mimet = 'octet-stream';
			     $subt = 'binary';
			 }
		     }
		     $file_info{'icon'} = $icon_table{$mimet} || $icon_table{'unknown'};

		 ## UNKNOWN FILE TYPE
		 } else {
		     $file_info{'icon'} = $icon_table{'unknown'}; 
		 }

		 ## case html
		 if ($3 =~ /^html?$/i) { 
		     $file_info{'html'} = 1;
		     $file_info{'icon'} = $icon_table{'text'};
		 }
	
		 ## name of the file
		 $file_info{'name'} = $d;
		 $file_info{'escaped_name'} =  &tools::escape_chars($d);
		 
		 ## content_directory
		 if ($dir) {
		     $file_info{'content_dir'} = $dir;
		 } else {
		     $file_info{'content_dir'} = "/"; 
		 }
		 $file_info{'escaped_content_dir'} = &tools::escape_chars($dir,'/');
		 
		 if ($def_desc) {
		     ## description
		     $file_info{'title'} = $desc_hash{'title'};
		     $file_info{'escaped_title'}=&tools::escape_html($desc_hash{'title'});
		  
		     ## author
		     if ($desc_hash{'email'}) {
			 $file_info{'author'} = $desc_hash{'email'};
		     }
		 }

	     push @result,\%file_info;
	     }
	 } # else (file)
	     
     } # foreach

     return \@result;

 }

 #*******************************************
 # Function : do_d_editfile
 # Description : prepares the parameters to
 #               edit a file
 #*******************************************

 sub do_d_editfile {
     &wwslog('info', 'do_d_editfile(%s)', $in{'path'});

     # Variables
     my $path = &no_slash_end($in{'path'});

     my $list_name = $list->{'name'};
     my $shareddir =  $list->{'dir'}.'/shared';
     my $visible_path = &make_visible_path($path);

     $param->{'directory'} = -d "$shareddir/$path";

     # Control

     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_d_editfile: no list');
	 return undef;
     }

     unless ($path) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'file name'},$param->{'action'});
	 &wwslog('err','do_d_editfile: no file name');
	 return undef;
     }   

     # Existing document? File?
     unless (-w "$shareddir/$path") {
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
         &wwslog('err',"d_editfile : Cannot edit $shareddir/$path : not an existing file");
	 return undef;
     }

     ### Document isn't a description file?
     unless ($path !~ /\.desc/) {
	 &wwslog('err',"do_editfile : $shareddir/$path : description file");
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
	 return undef;
     }

     if (($path =~ /\.url$/) ||($path =~ /^\..+\.url.moderate$/)) {
	 ## Get URL of bookmark
	 open URL, "$shareddir/$path";
	 my $url = <URL>;
	 close URL;
	 chomp $url;

	 $param->{'url'} = $url;
	 $visible_path =~ s/\.url$//;
     }

     # Access control
     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode,$path);
     my $may_edit = $access{'may'}{'edit'};

     unless ($may_edit > 0) {
	 &report::reject_report_web('auth',$access{'reason'}{'edit'},{},$param->{'action'},$list);
	 &wwslog('err','d_editfile : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     ## End of controls

     $param->{'list'} = $list_name;
     $param->{'path'} = $path;
     $param->{'visible_path'} = $visible_path;

     # test if it's a text file
     if (-T "$shareddir/$path") {
	 $param->{'textfile'} = 1;
	 $param->{'filepath'} = "$shareddir/$path";
     } else {
	 $param->{'textfile'} = 0;
     }
     $param->{'use_htmlarea'} = '1' if (($wwsconf->{'htmlarea_url'}) and ($param->{'textfile'}) and ($path =~ /\.html?/));



     #Current directory
     if ($path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/) {
	 $param->{'father'} = $1;
     }else {
	 $param->{'father'} = '';
     }
     $param->{'escaped_father'} = &tools::escape_chars($param->{'father'}, '/');

     # Description of the file
     my $descfile;
     if (-d "$shareddir/$path") {
	 $descfile = "$shareddir/$1$3/.desc";
     }else {
	 $descfile = "$shareddir/$1.desc.$3";
     }

     if (-e $descfile) {
	 my %desc_hash = &get_desc_file($descfile);
	 $param->{'desc'} = $desc_hash{'title'};
	 $param->{'doc_owner'} = $desc_hash{'email'};   
	 ## Synchronization
	 my @info = stat $descfile;
	 $param->{'serial_desc'} = $info[9];
     }

     ## Synchronization
     my @info = stat "$shareddir/$path";
     $param->{'serial_file'} = $info[9];
     ## parameters of the current directory
     $param->{'doc_date'} =  &POSIX::strftime("%d %b %y  %H:%M", localtime($info[9]));

     &tt2::allow_absolute_path();

     $param->{'father_icon'} = $icon_table{'father'};
     return 1;
 }

  #*******************************************
 # Function : do_d_properties
 # Description : prepares the parameters to
 #               change a file properties 
 #*******************************************

 sub do_d_properties {
     &wwslog('info', 'do_d_properties(%s)', $in{'path'});

     # Variables
     my $path = &no_slash_end($in{'path'});

     my $list_name = $list->{'name'};
     my $shareddir =  $list->{'dir'}.'/shared';
     my $visible_path = &make_visible_path($path);

     $param->{'directory'} = -d "$shareddir/$path";

     # Control

     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_d_properties : no list');
	 return undef;
     }

     unless ($path) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'filename'},$param->{'action'});
	 &wwslog('err','do_d_properties: no file name');
	 return undef;
     }   

     # Existing document? File?
     unless (-w "$shareddir/$path") {
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
         &wwslog('err',"do_d_properties : Cannot edit $shareddir/$path : not an existing file");
	 return undef;
     }

     ### Document isn't a description file?
     unless ($path !~ /\.desc/) {
	 &wwslog('err',"do_d_properties : $shareddir/$path : description file");
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
         return undef;
     }

     if ($path =~ /\.url$/) {
	 ## Get URL of bookmark
	 open URL, "$shareddir/$path";
	 my $url = <URL>;
	 close URL;
	 chomp $url;

	 $param->{'url'} = $url;
     }

     # Access control
     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode,$path);
     my $may_edit = $access{'may'}{'edit'};

     unless ($may_edit > 0) {
	 &report::reject_report_web('auth',$access{'reason'}{'edit'},{},$param->{'action'},$list);
	 &wwslog('err','do_d_properties : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     ## End of controls

     $param->{'list'} = $list_name;
     $param->{'path'} = $path;
     $param->{'visible_path'} = $visible_path;

     # test if it's a text file
     if (-T "$shareddir/$path") {
	 $param->{'textfile'} = 1;
	 $param->{'filepath'} = "$shareddir/$path";
     } else {
	 $param->{'textfile'} = 0;
     }
     $param->{'use_htmlarea'} = '1' if (($wwsconf->{'htmlarea_url'}) and ($param->{'textfile'}) and ($path =~ /\.html?/));



     #Current directory
     if ($path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/) {
	 $param->{'father'} = $1;
     }else {
	 $param->{'father'} = '';
     }
     $param->{'escaped_father'} = &tools::escape_chars($param->{'father'}, '/');

     $param->{'fname'} = $3;
     # Description of the file
     my $descfile;
     if (-d "$shareddir/$path") {
	 $descfile = "$shareddir/$1$3/.desc";
     }else {
	 $descfile = "$shareddir/$1.desc.$3";
     }

     if (-e $descfile) {
	 my %desc_hash = &get_desc_file($descfile);
	 $param->{'desc'} = $desc_hash{'title'};
	 $param->{'doc_owner'} = $desc_hash{'email'};   
	 ## Synchronization
	 my @info = stat $descfile;
	 $param->{'serial_desc'} = $info[9];
     } 

     ## Synchronization
     my @info = stat "$shareddir/$path";
     $param->{'serial_file'} = $info[9];
     ## parameters of the current directory
     $param->{'doc_date'} =  &POSIX::strftime("%d %b %y  %H:%M", localtime($info[9]));

     &tt2::allow_absolute_path();

     $param->{'father_icon'} = $icon_table{'father'};
     return 1;
 }

 #*******************************************
 # Function : do_d_describe
 # Description : Saves the description of 
 #               the file
 #******************************************

 sub do_d_describe {
     &wwslog('info', 'do_d_describe(%s)', $in{'path'});

     # Variables
     my $path = &no_slash_end($in{'path'});
     my $visible_path=&make_visible_path($path);
     my $list_name = $list->{'name'};
     my $shareddir =  $list->{'dir'}.'/shared';

 ####  Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_d_describe: no list');
	 return undef;
     }

     ### Document isn't a description file?
     unless ($path !~ /\.desc/) {
	 &wwslog('info',"do_d_describe : $shareddir/$path : description file");
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
	 return undef;
     }

     ## the path must not be empty (the description file of the shared directory
     #  doesn't exist)
     unless ($path) {
	 &report::reject_report_web('intern','cannot_describe_shared_directory',{'path' => $path },$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('info',"d_describe : Cannot describe $shareddir : root directory");
	 return undef;
     }

     ## must be existing a content to replace the description
     unless ($in{'content'}) {
	 &report::reject_report_web('user','no_description',{'path'=> $visible_path},$param->{'action'},$list);
	 &wwslog('info',"do_d_describe : cannot describe $shareddir/$path : no content");
	 return undef;
     }

     # the file to describe must already exist
     unless (-e "$shareddir/$path") {
	 &report::reject_report_web('user','no_doc_to_describe',{'path'=> $visible_path},$param->{'action'},$list);
	 &wwslog('info',"d_describe : Unable to describe $shareddir/$path : not an existing document");
	 return undef;in{'shortname'}
     }

     # Access control
	 # Access control
     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode,ath);

     unless ($access{'may'}{'edit'} > 0) {
	 &report::reject_report_web('auth',$access{'reason'}{'edit'},{},$param->{'action'},$list);
	 &wwslog('info','d_describe : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }


     ## End of controls

     if ($in{'content'} !~ /^\s*$/) {

	 # Description file
	 $path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
	 my $dir = $1;
	 my $file = $3;

	 my $desc_file;
	 if (-d "$shareddir/$path") {
	     $desc_file = "$shareddir/$dir$file/.desc";
	 } else {
	     $desc_file = "$shareddir/$dir.desc.$file";
	 }

	 if (-r "$desc_file"){
	     # if description file already exists : open it and modify it
	     my %desc_hash = &get_desc_file ("$desc_file");

	     # Synchronization
	     unless (&synchronize($desc_file,$in{'serial'})){
		 &report::reject_report_web('user','synchro_failed',{},$param->{'action'},$list);
		 &wwslog('info',"d_describe : Synchronization failed for $desc_file");
		 return undef;
	     }

	     # fill the description file
	     unless (open DESC,">$desc_file") {
		 &wwslog('info',"do_d_describe : cannot open $desc_file : $!");
		 &report::reject_report_web('intern','cannot_open_file',{'file' => $desc_file},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 return undef;
	     }

	     # information modified
	     print DESC "title\n  $in{'content'}\n\n"; 
	     # information not modified
	     print DESC "access\n  read $desc_hash{'read'}\n  edit $desc_hash{'edit'}\n\n";
	     print DESC "creation\n";
	     # time
	     print DESC "  date_epoch $desc_hash{'date'}\n";
	     # author
	     print DESC "  email $desc_hash{'email'}\n\n";

	     close DESC;

	 } else {
	     # Creation of a description file 
	     unless (open (DESC,">$desc_file")) {
		 &report::reject_report_web('intern','cannot_open_file',{'file' => $desc_file},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('info',"d_describe : Cannot create description file $desc_file : $!");
		 return undef;
	     }
	     # fill
	     # description
	     print DESC "title\n  $in{'content'}\n\n";
	     # date and author
	     my @info = stat "$shareddir/$path";
	     print DESC "creation\n  date_epoch ".$info[10]."\n  email\n\n"; 
	     # access rights
	     print DESC "access\n";
	     print DESC "  read $access{'scenario'}{'read'}\n";
	     print DESC "  edit $access{'scenario'}{'edit'}\n\n";  

	     close DESC;

	 }

	 $in{'path'} = &no_slash_end($dir);
     }

     return 'd_read';

 }

 #*******************************************
 # Function : do_d_savefile
 # Description : Saves a file edited in a 
 #               text area
 #******************************************

sub do_d_savefile {
     &wwslog('info', 'do_d_savefile(%s)', $in{'path'});

     # Variables
     my $path = &no_slash_end($in{'path'});

     if ($in{'url'} && 
	 $in{'previous_action'} eq 'd_read') {
	 $path .= '/'.$in{'name_doc'} . '.url';
     }


     my $visible_path = &make_visible_path($path);

     my $moderated;
     if ($visible_path ne $path) {
	 $moderated = 1;
     }

     if ($in{'name_doc'} =~ /[\[\]\/]/) {
	 &report::reject_report_web('user','incorrect_name',{'name' => $in{'name_doc'}},$param->{'action'},$list);
	 &wwslog('err',"do_d_savefile : Unable to create file $path : incorrect name");
	 return undef;
     }

     #my $list_name = $in{'list'};
     my $list_name = $list->{'name'};

     my $shareddir =  $list->{'dir'}.'/shared';

 ####  Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_d_savefile : no list');
	 return undef;
     }

     ## must be existing a content to replace the file
     unless ($in{'content'} || $in{'url'}) {
	 &report::reject_report_web('user','no_content',{},$param->{'action'},$list);
	 &wwslog('err',"do_d_savefile : Cannot save file $shareddir/$path : no content");
	 return undef;
     }

     my $creation = 1 unless (-f "$shareddir/$path");

     ### Document isn't a description file
     unless ($path !~ /\.desc/) {
	 &wwslog('err',"do_d_savefile : $shareddir/$path : description file");
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
	 return undef;
     }

     # Access control
     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode,$path);

     unless ($access{'may'}{'edit'} > 0) {
	 &report::reject_report_web('auth',$access{'reason'}{'edit'},{},$param->{'action'},$list);
	 &wwslog('err','do_d_savefile : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }
 #### End of controls

     if (($in{'content'} =~ /^\s*$/) && ($in{'url'} =~ /^\s*$/)) {
	 &report::reject_report_web('user','no_content',{},$param->{'action'},$list);
	 &wwslog('err',"do_d_savefile : Cannot save file $shareddir/$path : no content");
	 return undef;
     }

     # Synchronization
     unless ($in{'url'}) { # only for files
     unless (&synchronize("$shareddir/$path",$in{'serial'})){
	 &report::reject_report_web('user','synchro_failed',{},$param->{'action'},$list);
	 &wwslog('err',"do_d_savefile : Synchronization failed for $shareddir/$path");
	 return undef;
     }
     }

     # Renaming of the old file 
############""" pas les url ?
     rename ("$shareddir/$path","$shareddir/$path.old")
	 unless ($creation);

     my $dir;
     my $file;
     if ($path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/){ 
	 $dir = $1;
	 $file = $3;
     }

     if ($in{'url'}) {
##############
#	 if ($access{'may'}{'edit'} == 0.5) {
#	     open URL, ">$shareddir/$dir.$file.moderate";
#	 }else {		 
	     open URL, ">$shareddir/$path";
#	 }
	 print URL "$in{'url'}\n";
	 close URL;
     }else {
	 # Creation of the shared file
	 unless (open FILE, ">$shareddir/$path") {
	     rename("$shareddir/$path.old","$shareddir/$path");
	     &report::reject_report_web('user','cannot_overwrite', {'reason' => $1,
								    'path' => $visible_path }
					,$param->{'action'},$list);
	     &wwslog('err',"do_d_savefile : Cannot open for replace $shareddir/$path : $!");
	     return undef;
	 }
	 print FILE $in{'content'};
	 close FILE;
     }

     unlink "$shareddir/$path.old";

     # Description file
     if (-e "$shareddir/$dir.desc.$file"){

	 # if description file already exists : open it and modify it
	 my %desc_hash = &get_desc_file ("$shareddir/$dir.desc.$file");

	 open DESC,">$shareddir/$dir.desc.$file"; 

	 # information not modified
	 print DESC "title\n  $desc_hash{'title'}\n\n"; 
	 print DESC "access\n  read $desc_hash{'read'}\n  edit $desc_hash{'edit'}\n\n";
	 print DESC "creation\n";
	 # date
	 print DESC '  date_epoch '.$desc_hash{'date'}."\n";

	 # information modified
	 # author
	 print DESC "  email $param->{'user'}{'email'}\n\n";

	 close DESC;

     } else {
	 # Creation of a description file if author is known

	 unless (open (DESC,">$shareddir/$dir.desc.$file")) {
	     &wwslog('info',"do_d_savefile: cannot create description file $shareddir/$dir.desc.$file");
	 }
	 # description
	 print DESC "title\n \n\n";
	 # date of creation and author
	 my @info = stat "$shareddir/$path";
	 print DESC "creation\n  date_epoch ".$info[10]."\n  email $param->{'user'}{'email'}\n\n"; 
	 # Access
	 print DESC "access\n";
	 print DESC "  read $access{'scenario'}{'read'}\n";
	 print DESC "  edit $access{'scenario'}{'edit'}\n\n";  

	 close DESC;
     }

     # shared_moderated
#######################
     if (($access{'may'}{'edit'} == 0.5) && ($creation)) {

	 unless (rename "$shareddir/$path","$shareddir/$dir.$file.moderate"){
	     &report::reject_report_web('intern','rename_file',{'old'=>"$shareddir/$path",
								'new'=>"$shareddir/$dir.$file.moderate"},
					$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err',"do_d_savefile : Failed to rename  $path to $dir.$file.moderate : $!");
	 }
	 unless (rename "$shareddir/$dir.desc.$file","$shareddir/$dir.desc..$file.moderate"){
	      &report::reject_report_web('intern','rename_file',{'old'=>"$shareddir/$dir.desc.$file",
								 'new'=>"$shareddir/$dir.desc..$file.moderate"},
					$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err',"do_d_savefile : Failed to rename $dir.desc.$file to $dir.desc..$file.moderate : $!");
	 }
	 
	 if (!$in{'url'}){
	     $in{'path'}=$path;
	     $param->{'path'}=$path;
	 }else {
	     $visible_path = $file;
	     $visible_path =~ s/\.url$//
	 }

 	 unless ($list->send_notify_to_editor('shared_moderated',{'filename' => $visible_path,
								  'who' => $param->{'user'}{'email'}})) {
 	     &wwslog('notice',"Unable to send notify 'shared_moderated' to $list->{'name'} list editor");
 	 }

	 &report::notice_report_web('to_moderate', {'path' => $visible_path},$param->{'action'});
     }

     &report::notice_report_web('save_success', {'path' => $visible_path},$param->{'action'});
      if ($in{'previous_action'}) {
	  return $in{'previous_action'};
      }else {
	  $in{'path'} =~ s/([^\/]+)$//;
	  $param->{'path'} =~ s/([^\/]+)$//;
	  return 'd_read';
      }
 }

 #*******************************************
 # Function : do_d_overwrite
 # Description : Overwrites a file with a
 #               uploaded file
 #******************************************

 sub do_d_overwrite {
     &wwslog('info', 'do_d_overwrite(%s)', $in{'path'});

     # Variables
     my $path = &no_slash_end($in{'path'});

     my $visible_path = &make_visible_path($path);

     #my $list_name = $in{'list'};
     my $list_name = $list->{'name'};

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';

     # Parameters of the uploaded file
     my $fh = $query->upload('uploaded_file');
     my $fn = $query->param('uploaded_file');
     
     # name of the file
     my $fname;
     if ($fn =~ /([^\/\\]+)$/) {
	 $fname = $1;
     }
     
     ### uploaded file must have a name
     unless ($fname) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'file name'},$param->{'action'});
	 &wwslog('info',"do_d_overwrite : No file specified to overwrite");
	 return undef;
     } 

 ####### Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_d_overwrite : no list');
	 return undef;
     }

     ### Document isn't a description file?
     unless ($path !~ /\.desc/) {
	 &wwslog('err',"do_d_overwrite : $shareddir/$path : description file");
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
	 return undef;
     }

     # the path to replace must already exist
     unless (-e "$shareddir/$path") {
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
     	 &wwslog('err',"do_d_overwrite : Unable to overwrite $shareddir/$path : not an existing file");
	 return undef;
     }

     # the path must represent a file
     if (-d "$shareddir/$path") {
	 &report::reject_report_web('user','doc_already_a_dir',{'path'=> $visible_path},$param->{'action'},$list);
	 &wwslog('err',"do_d_overwrite : Unable to create $shareddir/$path : a directory named $path already exists");
	 return undef;
     }


       # Access control
     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode,$path);

     unless ($access{'may'}{'edit'} > 0) {
	 &report::reject_report_web('auth',$access{'reason'}{'edit'},{},$param->{'action'},$list);
	 &wwslog('err','do_d_overwrite :  access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }
 #### End of controls

     # Synchronization
     unless (&synchronize("$shareddir/$path",$in{'serial'})){
	 &report::reject_report_web('user','synchro_failed',{},$param->{'action'},$list);
	 &wwslog('err',"do_d_overwrite : Synchronization failed for $shareddir/$path");
	 return undef;
     }

     # Renaming of the old file 
     rename ("$shareddir/$path","$shareddir/$path.old");

     # Creation of the shared file
     unless (open FILE, ">$shareddir/$path") {
	 &report::reject_report_web('user','cannot_overwrite', {'reason' => $!,
								'path' => $visible_path }
				    ,$param->{'action'},$list);
	 &wwslog('err',"d_overwrite : Cannot open for replace $shareddir/$path : $!");
	 return undef;
     }
     while (<$fh>) {
	 print FILE;
     }
     close FILE;

     # Description file
     my ($dir, $file);
     if ($path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/) { 
	 $dir = $1;
	 $file = $3;
     }

     if (-e "$shareddir/$dir.desc.$file"){
	 # if description file already exists : open it and modify it
	 my %desc_hash = &get_desc_file ("$shareddir/$dir.desc.$file");

	 open DESC,">$shareddir/$dir.desc.$file"; 

	 # information not modified
	 print DESC "title\n  $desc_hash{'title'}\n\n"; 
	 print DESC "access\n  read $desc_hash{'read'}\n  edit $desc_hash{'edit'}\n\n";
	 print DESC "creation\n";
	 # time
	 print DESC "  date_epoch $desc_hash{'date'}\n";
	 # information modified
	 # author
	 print DESC "  email $param->{'user'}{'email'}\n\n";

	 close DESC;
     } else {
	 # Creation of a description file
	 unless (open (DESC,">$shareddir/$dir.desc.$file")) {
	     &wwslog('info',"do_d_overwrite : Cannot create description file $shareddir/$dir.desc.$file");
	     return undef;
	 }
	 # description
	 print DESC "title\n  \n\n";
	 # date of creation and author
	 my @info = stat "$shareddir/$path";
	 print DESC "creation\n  date_epoch ".$info[10]."\n  email $param->{'user'}{'email'}\n\n"; 
	 # access rights
	 print DESC "access\n";
	 print DESC "  read $access{'scenario'}{'read'}\n";
	 print DESC "  edit $access{'scenario'}{'edit'}\n\n";  

	 close DESC;

     }

     # shared_moderated
     if (($access{'may'}{'edit'} == 0.5) && ($path eq $visible_path)) {
	 unless (rename "$shareddir/$path","$shareddir/$dir.$file.moderate"){
	     &report::reject_report_web('intern','rename_file',{'old'=>"$shareddir/$path",
								'new'=>"$shareddir/$dir.$file.moderate"},
					$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err',"do_d_overwrite : Failed to rename  $path to $dir.$file.moderate : $!");
	     return undef;
	 }
	 unless (rename "$shareddir/$dir.desc.$file","$shareddir/$dir.desc..$file.moderate"){
	     &report::reject_report_web('intern','rename_file',{'old'=>"$shareddir/$dir.desc.$file",
								'new'=>"$shareddir/$dir.desc..$file.moderate"},
					$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err',"do_d_overwrite : Failed to rename $dir.desc.$file to $dir.desc..$file.moderate : $!");
	 }
	 unless ($list->send_notify_to_editor('shared_moderated',{'filename' => $visible_path,
								  'who' => $param->{'user'}{'email'}})) {
	     &wwslog('notice',"Unable to send notify 'shared_moderated' to $list->{'name'} list editor");
	 }
	 $in{'path'}="$dir.$file.moderate";
	 &report::notice_report_web('to_moderate',{'path' => $visible_path},$param->{'action'});
     }

     # Removing of the old file
     unlink "$shareddir/$path.old";

     $in{'list'} = $list_name;
     #$in{'path'} = $dir;

     # message of success
     &report::notice_report_web('upload_success', {'path' => $visible_path});
     return 'd_editfile';
 }

 #*******************************************
 # Function : do_d_upload
 # Description : Creates a new file with a 
 #               uploaded file
#******************************************

 sub do_d_upload {
     # Parameters of the uploaded file (from d_read.tt2)
     my $fn = $query->param('uploaded_file');

     # name of the file, without path
     my $fname;
     if ($fn =~ /([^\/\\]+)$/) {
	 $fname = $1; 
     }
     
     # param from d_upload.tt2
     if ($in{'shortname'}){
	 $fname = $in{'shortname'};
     }

     &wwslog('info', 'do_d_upload(%s/%s)', $in{'path'},$fname);

     # Variables 
     my $path = &no_slash_end($in{'path'});
     
     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';
     
     # name of the file 
     my $longname = "$shareddir/$path/$fname";
     $longname =~ s/\/+/\//g;
     
#     ## $path must have a slash at its end
#     $path = &format_path('with_slash',$path);

     #my $list_name = $in{'list'};
     my $list_name = $list->{'name'};


  ## Controls
     # action relative to a list ?
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_d_upload : no list');
	 return undef;
     }


     # uploaded file must have a name 
     unless ($fname) {
	 &report::reject_report_web('user','no_name',{},$param->{'action'},$list);
	 &wwslog('err',"do_d_upload : No file specified to upload");
	 return undef;
     }

     ## Check quota
     if ($list->{'admin'}{'shared_doc'}{'quota'}) {
	 if ($list->get_shared_size() >= $list->{'admin'}{'shared_doc'}{'quota'} * 1024){
	     &report::reject_report_web('user','shared_full',{},$param->{'action'},$list);
	     &wwslog('err',"do_d_upload : Shared Quota exceeded for list $list->{'name'}");
	     return undef;
	 }
     }

     # The name of the file must be correct and musn't not be a description file
     if ($fname =~ /^\./
	 || $fname =~ /\.desc/ 
	 || $fname =~ /[~\#\[\]]$/) {

 #    unless ($fname =~ /^\w/ and 
 #	    $fname =~ /\w$/ and 
 #	    $fname =~ /^[\w\-\.]+$/ and
 #	    $fname !~ /\.desc/) {
	 &report::reject_report_web('user','incorrect_name',{'name' => $fname},$param->{'action'},$list);
	 &wwslog('err',"do_d_upload : Unable to create file $fname : incorrect name");
	 return undef;
     }

     my $visible_path = &make_visible_path($path); 
     # the file must be uploaded in a directory existing
     unless (-d "$shareddir/$path") {
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
	 &wwslog('err',"do_d_upload : $shareddir/$path : not a directory");
	 return undef;
     }

     # Access control for the directory where there is the uploading
     my %mode;
     $mode{'edit'} = 1;
     $mode{'control'} = 1; # for the exception index.html
     my %access_dir = &d_access_control(\%mode,$path);

     if ($access_dir{'may'}{'edit'} == 0) {
	 &report::reject_report_web('auth',$access_dir{'reason'}{'edit'},{},$param->{'action'},$list);
	 &wwslog('err','do_d_upload : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     # Lowercase for file name
     # $fname = $fname;

     ## when the file already exists :

     # the temporary name of the uploaded file : with .duplicate
     my $tmpname="."."$fname".".duplicate";
     my $longtmpname="$shareddir/$path/$tmpname";
     $longtmpname =~ s/\/+/\//g;

     # the temporary desc of the uploaded file : with .duplicate
     my $tmpdesc=".desc."."$tmpname";
     my $longtmpdesc="$shareddir/$path/$tmpdesc";
     $longtmpdesc =~ s/\/+/\//g;
		   
     # if we aren't in mode_delete nor in mode_rename nor in mode_cancel and the file already exists 
     # then we create of a temporary file
     if ((-e "$longname") && 
	 ($in{'mode_delete'} eq undef) && 
	 ($in{'mode_rename'} eq undef) &&
	 ($in{'mode_cancel'} eq undef)) {
	 
	 #access control for the file already existing
	 my %mode;
	 $mode{'edit'} = 1;
	 my %access_file = &d_access_control(\%mode,"$path/$fname");

	 unless ($access_file{'may'}{'edit'} > 0) {
	     &report::reject_report_web('auth',$access_file{'reason'}{'edit'},{},$param->{'action'},$list);
	     return undef;
	 }

	 if (-e "$longtmpname"){
	     # if exists a temp file younger than 5 minutes that belongs to another user : upload refused
	     my @info = stat $longtmpname;
	     my $timeold = time - $info[10];
	     
	     if ($timeold<=300){
		 my %desc_hash = &get_desc_file("$longtmpdesc");
		 
		 unless($desc_hash{'email'} eq $param->{'user'}{'email'}){
		     &report::reject_report_web('user','cannot_upload',{'path' => "$path/$fname",
									'reason' => "file being uploaded by $desc_hash{'email'} at this time" },
						$param->{'action'},$list);
		     &wwslog('err',"do_d_upload : Unable to upload $longtmpname : file being uploaded at this time ");
		     return undef;
		 }
	     }
	 }
	 
	 &creation_shared_file($shareddir,$path,$tmpname);
	 &creation_desc_file($shareddir,$path,$tmpname,%access_file);
	 
	 my @info = stat "$longname";
	 $param->{'serial_file'} = $info[9];
	 $param->{'path'} = $path;
	 $param->{'shortname'} = $fname;
	 
	 return 1;
     }
     
     
     # for the moderation
     my $longmodname = "$shareddir/$path/"."."."$fname".".moderate";
     $longmodname =~ s/\/+/\//g;

     my $longmoddesc="$shareddir/$path/".".desc.."."$fname".".moderate";
     $longmoddesc =~ s/\/+/\//g;
    
     # when a file is already waiting for moderation
     my $file_moderated; 
      
     if (-e "$longmodname"){
	
	 my %desc_hash = &get_desc_file("$longmoddesc");
	 $file_moderated = 1;

	 unless($desc_hash{'email'} eq $param->{'user'}{'email'}){
	     &report::reject_report_web('user','cannot_upload',{'path' => "$path/$fname",
								'reason' => "file already exists but not yet moderated"},
					$param->{'action'},$list); 
	     &wwslog('err',"do_d_upload : Unable to create $longname : file already exists but not yet moderated");
	     return undef;
	 }
     }
     

     ## Exception index.html
     unless ($fname !~ /^index.html?$/i) {
	 unless ($access_dir{'may'}{'control'}) {
	     &report::reject_report_web('user','index_html',{'dir' => $path,
							     'reason' => "d_access_control"},
					$param->{'action'},$list); 
	     &wwslog('err',"do_d_upload : $param->{'user'}{'email'} not authorized to upload a INDEX.HTML file in $path");
	     return undef;
	 }
     }
     
     # if we're in mode_delete or mode_rename or mode_cancel, the temp file and his desc file must exist
     if ($in{'mode_delete'} ||
	 $in{'mode_rename'} ||
	 $in{'mode_cancel'})   {
	 	
	 unless(-e $longtmpname){
	     &report::reject_report_web('user','no_uploaded_file',{},$param->{'action'},$list); 
	     &wwslog('err',"do_d_upload : there isn't any temp file for the uploaded file $fname");
	     return undef;
	 }
	 
	 unless(-e $longtmpdesc){
	     &report::reject_report_web('user','no_uploaded_file',{},$param->{'action'},$list); 
	     &wwslog('err',"do_d_upload : there isn't any desc temp file for the uploaded file $fname");
	     return undef;
     }

     }
 ## End of controls


     # in mode_delete the file is going to be overwritten
     if ($in{'mode_delete'}) {
	 
	 # Synchronization
	 unless (&synchronize("$longname",$in{'serial'})){
	     &report::reject_report_web('user','synchro_failed',{},$param->{'action'},$list);
	     &wwslog('err',"do_d_upload : Synchronization failed for $longname");
	     return undef;
	 }
	 
	 # Renaming the tmp file and the desc file
	
	 if ($access_dir{'may'}{'edit'} == 1 ){
	 
	     # Renaming of the old file 
	     my $longgoodname="$shareddir/$path/$fname";
	     $longgoodname =~ s/\/+/\//g;
	     unless (rename "$longgoodname","$longgoodname.old"){
		 &report::reject_report_web('intern','rename_file',{'old'=>"$longgoodname",
								    'new'=>"$longgoodname.old"},
					    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('err',"do_d_upload : Failed to rename %s to .old : %s",$longgoodname, $!);
		 return undef;
	     }
	     
	     # Renaming of the old desc
	     my $longgooddesc="$shareddir/$path/".".desc."."$fname";
	     $longgooddesc =~ s/\/+/\//g;
	     unless (rename "$longgooddesc","$longgooddesc.old"){
		 &report::reject_report_web('intern','rename_file',{'old'=>"$longgooddesc",
								    'new'=>"$longgooddesc.old"},
					    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('err',"do_d_upload : Failed to rename %s to .old : %s", $longgooddesc, $!);
	     }

	     # the tmp file
	     unless (rename "$longtmpname","$longgoodname"){
		  &report::reject_report_web('intern','rename_file',{'old'=>"$longtmpname",
								     'new'=>"$longgoodname"},
					    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('err',"do_d_upload : Failed to rename %s to %s : %s", $longtmpname, $longgoodname, $!);
	     }
	     
	     # the tmp desc file
	     unless (rename "$longtmpdesc","$longgooddesc"){
		 &report::reject_report_web('intern','rename_file',{'old'=>"$longtmpdesc",
								    'new'=>"$longgooddesc"},
					    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('err',"do_d_upload : Failed to rename %s to %s : %s", $longtmpdesc, $longgooddesc, $!);
	     }

	 }elsif ($access_dir{'may'}{'edit'} == 0.5 ){	 
	     
	     unless (rename "$longtmpname","$longmodname"){
		 &report::reject_report_web('intern','rename_file',{'old'=>"$longtmpname",
								    'new'=>"$longmodname"},
					    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('err',"do_d_upload : Failed to rename %s to %s : %s", $longtmpname, $longmodname, $!);
	     }
	     
	     unless (rename "$longtmpdesc","$longmoddesc"){
		 &report::reject_report_web('intern','rename_file',{'old'=>"$longtmpdesc",
								    'new'=>"$longmoddesc"},
					    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('err',"do_d_upload : Failed to rename %s to %s : %s", $longtmpdesc, $longmoddesc, $!);
	     }
	       
 	     unless ($list->send_notify_to_editor('shared_moderated',{'filename' => "$path/$fname",
 								      'who' => $param->{'user'}{'email'}})) {
 		 &wwslog('notice',"Unable to send notify 'shared_moderated' to $list->{'name'} list editor");
 	     }

	 }else {
	     &report::reject_report_web('auth',$access_dir{'reason'}{'edit'},{},$param->{'action'},$list);
	     &wwslog('err','do_d_upload : access denied for %s', $param->{'user'}{'email'});
	     return undef;
	 }

#	 $in{'list'} = $list_name;
	 
	 # message of success
	 &report::notice_report_web('upload_success', {'path' => $fname},$param->{'action'});
     	 return 'd_read';
     }
     
     # in mode_rename the file is going to be renamed
     if ($in{'mode_rename'}) {
	 
	 my $longnewname="$shareddir/$path/$in{'new_name'}";
	 $longnewname =~ s/\/+/\//g;
	 
         # Control new document name
	 unless ($in{'new_name'}) {
	     &report::reject_report_web('user','missing_arg',{'argument' => 'new name'},$param->{'action'});
	     &wwslog('err',"do_d_upload : new name missing to rename the uploaded file");
	     return undef;
	 }
	 if ($in{'new_name'} =~ /^\./
	     || $in{'new_name'} =~ /\.desc/ 
	     || $in{'new_name'} =~ /[~\#\[\]\/]$/) {
	     &report::reject_report_web('user','incorrect_name',{'name' => $in{'new_name'}},$param->{'action'},$list);
	     &wwslog('err',"do_d_upload : Unable to create file $in{'new_name'} : incorrect name");
	     return undef;
	 }
	 
	 if (($fname =~ /\.url$/) && ($in{'new_name'} !~ /\.url$/)) {
	     &report::reject_report_web('user','incorrect_name',{'name' => $in{'new_name'}},$param->{'action'},$list);
	     &wwslog('err',"do_d_upload : New file name $in{'new_name'} does not match URL filenames");
	     return undef;
	 }
	 
	 if (-e $longnewname){
	     &report::reject_report_web('user','doc_already_exist',{'name' => $in{'new_name'}},$param->{'action'},$list);
	     &wwslog('err',"do_d_upload : $in{'new_name'} is an existing name");
	     return undef;
	 }

	 # when a file is already waiting for moderation
	 if (-e "$shareddir/$path/.$in{'new_name'}.moderate"){
	     &report::reject_report_web('user','doc_already_exist',{'name' => $in{'new_name'}},$param->{'action'},$list);
	     &wwslog('err',"do_d_upload : $in{'new_name'} is an existing name for a not yet moderated file" );
	     return undef;
	 }
	 # when a file is being uploaded
	 if (-e "$shareddir/$path/.$in{'new_name'}.duplicate"){
	     &report::reject_report_web('user','doc_already_exist',{'name' => $in{'new_name'}},$param->{'action'},$list);
	     &wwslog('err',"do_d_upload : $in{'new_name'} is an existing name for a file being uploaded ");
	 }

	 # Renaming the tmp file and the desc file

	 if ($access_dir{'may'}{'edit'} == 1 ){
	     unless (rename "$longtmpname","$longnewname"){
		 &report::reject_report_web('intern','rename_file',{'old'=>"$longtmpname",
								    'new'=>"$longnewname"},
					    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('err',"do_d_upload : Failed to rename %s to %s : %s", $longtmpname, $longnewname, $!);
	     }
	     
	     my $longnewdesc="$shareddir/$path/.desc.$in{'new_name'}";
	     $longnewdesc =~ s/\/+/\//g;
	     
	     unless (rename "$longtmpdesc","$longnewdesc"){
		 &report::reject_report_web('intern','rename_file',{'old'=>"$longtmpdesc",
								    'new'=>"$longnewdesc"},
					    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('err',"do_d_upload : Failed to rename %s to %s : %s", $longtmpdesc, $longnewdesc, $!);
	     }
	 
	 }elsif ($access_dir{'may'}{'edit'} == 0.5 ){	 
	     
	     unless (rename "$longtmpname","$shareddir/$path/.$in{'new_name'}.moderate"){
		 &report::reject_report_web('intern','rename_file',{'old'=>"$longtmpname",
								    'new'=>"$shareddir/$path/.$in{'new_name'}.moderate"},
					    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('err',"do_d_upload : Failed to rename $longtmpname to $shareddir/$path/.$in{'new_name'}.moderate : $!");
	     }
	     
	     unless (rename "$longtmpdesc","$shareddir/$path/.desc..$in{'new_name'}.moderate"){
		 &report::reject_report_web('intern','rename_file',{'old'=>"$longtmpdesc",
								    'new'=>"$shareddir/$path/.desc..$in{'new_name'}.moderate"},
					    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('err',"do_d_upload : Failed to rename $longtmpdesc to $shareddir/$path/.desc..$in{'new_name'}.moderate: $!");
	     }

 	     unless ($list->send_notify_to_editor('shared_moderated',{'filename' => "$path/$in{'new_name'}",
 								      'who' => $param->{'user'}{'email'}})) {
 		 &wwslog('notice',"Unable to send notify 'shared_moderated' to $list->{'name'} list editor");
 	     }
	       
	 }else {
	     &report::reject_report_web('auth',$access_dir{'reason'}{'edit'},{},$param->{'action'},$list);
	     &wwslog('err','do_d_upload : access denied for %s', $param->{'user'}{'email'});
	     return undef;
	 }
	 
#	 $in{'list'} = $list_name;

	 # message of success
	 &report::notice_report_web('upload_success', {'path' => $fname},$param->{'action'});
     	 return 'd_read';
     }

     # in mode_cancel, we delete the temp file and his desc
     if ($in{'mode_cancel'}) {
	 
         # removing of the temp file
	 unless (unlink($longtmpname)) {
	     &report::reject_report_web('intern','erase_file',{'file' => $longtmpname},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err','do_d_upload: failed to erase the temp file %s', $longtmpname);
	     return undef;
	 }
	 
	 # removing of the description temp file 
	 unless (unlink($longtmpdesc)) {
	     &report::reject_report_web('intern','erase_file',{'file' => $longtmpdesc},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err','do_d_upload: failed to erase the desc temp file %s', $longtmpdesc);
	     return undef;
	 }
	 
	 return 'd_read';
     }
     
     ## usual case

     # shared_moderated
     if ($access_dir{'may'}{'edit'} == 0.5 ) {
	 my $modname="."."$fname".".moderate";
	
	 &creation_shared_file($shareddir,$path,$modname);
	 &creation_desc_file($shareddir,$path,$modname,%access_dir);

	 unless ($file_moderated){
 	     unless ($list->send_notify_to_editor('shared_moderated',{'filename' => "$path/$fname",
 								      'who' => $param->{'user'}{'email'}})) {
 		 &wwslog('notice',"Unable to send notify 'shared_moderated' to $list->{'name'} list editor");
 	     }
	 }
       
	 &report::notice_report_web('to_moderate', {'path' => $fname},$param->{'action'});
	
     } else {
	 &creation_shared_file($shareddir,$path,$fname);
	 &creation_desc_file($shareddir,$path,$fname,%access_dir);
     }
    
     $in{'list'} = $list_name;
  
     &report::notice_report_web('upload_success', {'path' => $fname},$param->{'action'});
     return 'd_read';
 }


## Creation of a shared file
sub creation_shared_file {
    my($shareddir,$path,$fname)=@_;

     my $fh = $query->upload('uploaded_file');
     unless (open FILE, ">$shareddir/$path/$fname") {
	 &report::reject_report_web('intern','cannot_upload',{'path' => "$path/$fname"},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('err',"creation_shared_file : Cannot open file $shareddir/$path/$fname : $!");
	 return undef;
     }
     while (<$fh>) {
	 print FILE;
     }
     close FILE;
}

## Creation of the description file
sub creation_desc_file {
    my($shareddir,$path,$fname,%access)=@_;

     unless (open (DESC,">$shareddir/$path/.desc.$fname")) {
	&wwslog('err',"creation_desc_file: cannot create description file $shareddir/.desc.$path/$fname");
     }

     print DESC "title\n \n\n"; 
     print DESC "creation\n  date_epoch ".time."\n  email $param->{'user'}{'email'}\n\n"; 

     print DESC "access\n";
     print DESC "  read $access{'scenario'}{'read'}\n";
     print DESC "  edit $access{'scenario'}{'edit'}\n";  

     close DESC;
}

 #*******************************************
 # Function : do_d_unzip
 # Description : unzip a file or a tree structure 
 #               from an uploaded zip file
 #******************************************

 sub do_d_unzip {
     # Parameters of the uploaded file (from d_read.tt2)
     my $fn = $query->param('unzipped_file');

     # name of the file, without path
     my $fname;
     if ($fn =~ /([^\/\\]+)$/) {
	 $fname = $1; 
     }
     
     &wwslog('info', 'do_d_unzip(%s/%s)', $in{'path'},$fname);

     # Variables 
     my $path = &no_slash_end($in{'path'});

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';
     
     # name of the file 
     my $longname = "$shareddir/$path/$fname";
     $longname =~ s/\/+/\//g;

  ## Controls
     # action relative to a list ?
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_d_unzip(%s/%s) : no list',$path,$fname);
	 return undef;
     }
     
     my $listname = $list->{'name'};

     # uploaded file must have a name 
     unless ($fname) {
	 &report::reject_report_web('user','no_name',{},$param->{'action'},$list);
	 &wwslog('err',"do_d_unzip(%s/%s) : No file specified to upload",$path,$fname);
	 return undef;
     }

     # must have .zip extension
     unless ($fname =~ /^.+\.zip$/) {
	 &report::reject_report_web('user','incorrect_name',{'name' => "$fname",
							     'reason' => "must have the '.zip' extension"},$param->{'action'},$list);
	 &wwslog('err',"do_d_unzip(%s/%s) : the file must have '.zip' extension",$path,$fname);
	 return undef;
     }

     ## Check quota
     if ($list->{'admin'}{'shared_doc'}{'quota'}) {
	 if ($list->get_shared_size() >= $list->{'admin'}{'shared_doc'}{'quota'} * 1024){
	     &report::reject_report_web('user','shared_full',{},$param->{'action'},$list);
	     &wwslog('err',"do_d_unzip(%s/%s) : Shared Quota exceeded for list $list->{'name'}",$path,$fname);
	     return undef;
	 }
     }

     # The name of the file must be correct and must not be a description file
     if ($fname =~ /^\./
	 || $fname =~ /\.desc/ 
	 || $fname =~ /[~\#\[\]]$/) {
	 &report::reject_report_web('user','incorrect_name',{'name' => "$fname"},$param->{'action'},$list);
	 &wwslog('err',"do_d_unzip(%s/%s) : incorrect name",$path,$fname);
	 return undef;
     }

     # the file must be uploaded in a directory existing
     unless (-d "$shareddir/$path") {
	 &report::reject_report_web('user','no_such_document',{'path'=> $path},$param->{'action'},$list);
	 &wwslog('err',"do_d_unzip(%s/%s) : $shareddir/$path : not a directory",$path,$fname);
	 return undef;
     }

     # Access control for the directory where there is the uploading
     # only for (is_author || !moderated)
     my %mode;
     $mode{'edit'} = 1;
     my %access_dir = &d_access_control(\%mode,$path);

     if ($access_dir{'may'}{'edit'} == 0) {
	 &report::reject_report_web('auth',$access_dir{'reason'}{'edit'},{},$param->{'action'},$list);
	 &wwslog('err','do_d_unzip(%s/%s) : access denied for %s',$path,$fname, $param->{'user'}{'email'});
	 return undef;
     }

     if ($access_dir{'may'}{'edit'} == 0.5) {
	 &report::reject_report_web('auth','edit_moderated',{},$param->{'action'},$list);
	 &wwslog('err','do_d_unzip(%s/%s) : access denied for %s',$path,$fname, $param->{'user'}{'email'});
	 return undef;
     }
    
  ## End of control

     # directory for the uploaded file
     my $date = time;
     my $zip_dir_name = $listname.$date.$$;
     my $zip_abs_dir = $Conf{'tmpdir'}.'/'.$zip_dir_name;

     unless (mkdir ("$zip_abs_dir",0777)) {
	 &report::reject_report_web('intern','cannot_mkdir',{'dir' => $zip_abs_dir},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('err',"do_d_unzip($path/$fname) : Unable to create $zip_abs_dir : $!");
	 return undef;
     }
     
 ### directory for unzipped files
     unless (mkdir ("$zip_abs_dir"."/zip",0777)) {
	 &report::reject_report_web('intern','cannot_mkdir',{'dir' => "$zip_abs_dir"."/zip"},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('err',"do_d_unzip($path/$fname) : Unable to create $zip_abs_dir/zip : $!");
	 return undef;
     }
     
 ### uploaded of the file.zip
     my $fh = $query->upload('unzipped_file');
     unless (open FILE, ">$zip_abs_dir/$fname") {
	 &report::reject_report_web('intern','cannot_upload',{'path' => "$path/$fname"},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('err',"do_d_unzip($path/$fname) : Cannot open file $zip_abs_dir/$fname : $!");
	 return undef;
     }
     while (<$fh>) {
	 print FILE;
     }
     close FILE;
     
 ### unzip the file
     my $status = &d_unzip_shared_file($zip_abs_dir,$fname,$path);

     unless (defined($status)) {
	 &report::reject_report_web('intern','cannot_unzip',{'path' => "$zip_abs_dir/$fname", 'name' => $fname},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('err',"do_d_unzip($path/$fname) : Unable to unzip the file $zip_abs_dir/$fname");
	 return undef;
     }

     unless ($status) {
	 &report::reject_report_web('intern','cannot_unzip',{'name' => "$fname"},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
     }	 

 ### install the file hierarchy

     unless (&d_install_file_hierarchy("$zip_abs_dir/zip",$shareddir,$path,\%access_dir)) {
	 &wwslog('err',"do_d_unzip($path/$fname) : unable to install file hierarchy");
	 return undef;
     }

     ## remove tmp directories and files
#     &tools::remove_dir($zip_abs_dir);
     
     $in{'list'} = $listname;
  
     &report::notice_report_web('unzip_success', {'path' => $fname},$param->{'action'});
     return 'd_read'
 }

## unzip a shared file in the tmp directory
sub d_unzip_shared_file {
    my ($zip_abs_dir,$fname) = @_;
    &wwslog('info', 'd_unzip_shared_file(%s/%s)', $zip_abs_dir,$fname);

    my $status = 1;

    my $zip = Archive::Zip->new();

    my $az = $zip->read( "$zip_abs_dir/$fname" );
 
    unless ($az == AZ_OK){
	&wwslog('err',"unzip_shared_file : Unable to read the zip file $zip_abs_dir/$fname : $az");
	return undef;
    }
 
    my @memberNames = $zip->memberNames();
 
    foreach my $name (@memberNames) {
	my $az = $zip->extractMember($name,"$zip_abs_dir/zip/$name");
	unless ($az == AZ_OK) {
	    &wwslog('err',"unzip_shared_file : Unable to extract member $name of the zip file $zip_abs_dir/$fname : $az");
	    $status = 0;
	}
    }		 
    return $status;
}

## Install file hierarchy from $tmp_dir directory to $shareddir/$path directory
sub d_install_file_hierarchy {
    my ($tmp_dir,$shareddir,$path,$access_dir)=@_;
    &wwslog('debug2', 'd_install_file_hierarchy(%s,%s)',$tmp_dir,$path);

    $tmp_dir = &no_slash_end($tmp_dir);
    $shareddir = &no_slash_end($shareddir);
    $path = &no_slash_end($path);

    my $fatal_error = 0;

    unless (opendir DIR,"$tmp_dir") {
	&report::reject_report_web('intern','cannot_open_dir',{'dir' => $tmp_dir},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	&wwslog('err','d_install_file_hierarchy(%s) : impossible to open %s directory',$path,$tmp_dir);
	return undef;
    }
    my @from_dir = readdir DIR;
    closedir DIR;

    foreach my $doc (@from_dir) {
	next 
	    if($doc eq '.' || $doc eq '..');
	if (-d "$tmp_dir/$doc") {
	    if ($fatal_error) {
		&report::reject_report_web('user','directory_no_copied',{'name'=> "$path/$doc",
									 'reason' => "quota exceeded"},
					   $param->{'action'},$list,$param->{'user'}{'email'},$robot);
	    }else {
		unless (&d_copy_rec_dir("$tmp_dir","$path","$shareddir/$path",$doc)){
		    $fatal_error = 1;
		    &report::reject_report_web('user','directory_no_copied',{'name'=> "$path/$doc",
									     'reason' => "quota exceeded"},
					       $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		    #		    return undef;
		}
	    }
	} else {
	    if ($fatal_error) {
		&report::reject_report_web('user','file_no_copied',{'name'=> "$path/$doc",
								    'reason' => "quota exceeded"},
					   $param->{'action'},$list,$param->{'user'}{'email'},$robot);
	    }else {
		unless (&d_copy_file("$tmp_dir","$path","$shareddir/$path",$doc,$access_dir)) {
		    &wwslog('err',"d_install_hierarchy($path) : fatal error from d_copy_file($doc)");
		    
		    $fatal_error = 1;
		    &report::reject_report_web('user','file_no_copied',{'name'=> "$path/$doc",
									'reason' => "quota exceeded"},
					   $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		}
		#		return undef;
	    }
	}
    }

    if ($fatal_error) {
	return undef;
    }else {
	return 1;
    }
}

## copy $dname from $from to $list->{shared}/$path if rights are ok
sub d_copy_rec_dir {
    my ($from,$path,$dest_dir,$dname) = @_;
    &wwslog('debug3', 'd_copy_rec_dir(%s,%s,%s)',$from,$dest_dir,$dname);

    $from = &no_slash_end($from);
    $path = &no_slash_end($path);
    $dest_dir = &no_slash_end($dest_dir);
     
    my $fatal_error = 0;

    # Access control on the directory $path where there is the copy
    # Copy allowed only for (is_author || !moderate)
    my %mode;
    $mode{'edit'} = 1;
    $mode{'control'} = 1;
    my %access_dir = &d_access_control(\%mode,$path);
    
    unless ($access_dir{'may'}{'edit'} == 1) {
	&report::reject_report_web('user','directory_no_copied',{'name'=> $dname,
								 'reason' => "no edition right on father directory"},
				   $param->{'action'},$list,$param->{'user'}{'email'},$robot);
	&wwslog('err','d_copy_rec_dir(%s): access denied for %s',$path,$param->{'user'}{'email'});
	return 1;
    }
    
    my $may;
    unless ($may = &d_test_existing_and_rights($path,$dname,$dest_dir)) {
	&report::reject_report_web('user','directory_no_copied',{'name'=> $dname },
				   $param->{'action'},$list,$param->{'user'}{'email'},$robot);
	&wwslog('err','d_copy_rec_dir(%s) : error while calling "test_existing_and_rights(%s/%s)"',$dname,$dest_dir,$dname);
	return 1;
    }

    unless ($may->{'exists'}) {
	
	# The name of the directory must be correct and musn't not be a description file
	if ($dname =~ /^\./
	    || $dname =~ /\.desc/ 
	    || $dname =~ /[~\#\[\]]$/) {
	    &report::reject_report_web('user','incorrect_name',{'name' => "$dname"},$param->{'action'},$list);
	    &wwslog('err',"d_copy_rec_dir : $dname : incorrect name");
	    return 1;
	}

	## Exception index.html
	unless ($dname !~ /^index.html?$/i) {
	    &report::reject_report_web('user','index_html',{'dir' => $path},$param->{'action'},$list); 
	    &wwslog('err',"d_copy_rec_dir : the directory cannot be called INDEX.HTML ");
	    return 1;
	}

	## directory creation
	unless (mkdir ("$dest_dir/$dname",0777)) {
	    &report::reject_report_web('user','directory_no_copied',{'name'=> "$dname"},$param->{'action'},$list);
	    &wwslog('err',"d_copy_rec_dir : Unable to create directory $dest_dir/$dname : $!");
	    return 1;
	}

	## desc directory creation
	unless (open (DESC,">$dest_dir/$dname/.desc")) {
	    &wwslog('err',"d_copy_rec_dir: cannot create description file $dest_dir/$dname/.desc");
	}
	
	print DESC "title\n \n\n"; 
	print DESC "creation\n  date_epoch ".time."\n  email $param->{'user'}{'email'}\n\n"; 
	
	print DESC "access\n";
	print DESC "  read $access_dir{'scenario'}{'read'}\n";
	print DESC "  edit $access_dir{'scenario'}{'edit'}\n";  
	
	close DESC;
    }

    if ($may->{'rights'} || !($may->{'exists'})) {

	unless (opendir DIR,"$from/$dname") {
	    &report::reject_report_web('user','directory_no_copied',{'name'=> "$dname"},
				       $param->{'action'},$list,$param->{'user'}{'email'},$robot);
	    &wwslog('err','d_copy_rec_dir(%s) : impossible to open %s directory',$dname,$from);
	    return 1;
	}

	my @from_dir = readdir DIR;
	closedir DIR;


	foreach my $doc (@from_dir) {
	    
	    if ($doc eq '.' || $doc eq '..') {
		next;
	    }
	    if (-d "$from/$dname/$doc") {
		if ($fatal_error) {
		    &report::reject_report_web('user','directory_no_copied',{'name'=> "$dname/$doc",
									     'reason' => "quota exceeded"},
					       $param->{'action'},$list,$param->{'user'}{'email'},$robot);

		}else {

		    unless (&d_copy_rec_dir("$from/$dname","$path/$dname","$dest_dir/$dname",$doc)){
			$fatal_error = 1;
			&report::reject_report_web('user','directory_no_copied',{'name'=> "$dname/$doc",
										 'reason' => "quota exceeded"},
						   $param->{'action'},$list,$param->{'user'}{'email'},$robot);
#		    return undef;
		    }	
		}

	    }else {
		if ($fatal_error) {
		    &report::reject_report_web('user','file_no_copied',{'name'=> "$dname/$doc",
									'reason' => "quota exceeded"},
					      $param->{'action'},$list,$param->{'user'}{'email'},$robot);

		}else {
		    unless (&d_copy_file("$from/$dname","$path/$dname","$dest_dir/$dname",$doc,\%access_dir)){
			&wwslog('err',"d_copy_rec_dir($path/$dname) : fatal error from d_copy_file($doc)");
			$fatal_error = 1;
			&report::reject_report_web('user','file_no_copied',{'name'=> "$dname/$doc",
									    'reason' => "quota exceeded"},
						   $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		    }
#		    return undef;
		}
	    }
	}
	
    }else{
	&report::reject_report_web('user','directory_no_copied',{'name'=> $dname,
								 'reason' => "no edition right on the father directory"},
				   $param->{'action'},$list,$param->{'user'}{'email'},$robot);

	&wwslog('err',"d_copy_rec_file : impossible to copy content directory $dname, the user doesn't have edit rights on directory $path");
    }
    
    if ($fatal_error) {
	return undef;
    } else {
	return 1;
    }
}

## copy $from/$fname to $list->{shared}/$path if rights are ok
sub d_copy_file {
    my ($from,$path,$dest_dir,$fname,$access_dir) = @_;
    &wwslog('debug3', 'd_copy_file(%s,%s,%s',$from,$dest_dir,$fname);

    $from = &no_slash_end($from);
    $path = &no_slash_end($path);
    $dest_dir = &no_slash_end($dest_dir);

    my $may;
    unless ($may = &d_test_existing_and_rights($path,$fname,$dest_dir)) {
	&report::reject_report_web('user','file_no_copied',{'name'=> "$fname",
							    'reason' => "quota exceeded"},
				   $param->{'action'},$list,$param->{'user'}{'email'},$robot);
	&wwslog('err','d_copy_file(%s) : error while calling "test_existing_and_rights(%s/%s)"',$fname,$dest_dir,$fname);
	return 1;
    }

    if ($may->{'rights'} || !($may->{'exists'})) {

	# The name of the file must be correct and musn't not be a description file
	if ($fname =~ /^\./
	    || $fname =~ /\.desc/ 
	    || $fname =~ /[~\#\[\]]$/) {
	    &report::reject_report_web('user','incorrect_name',{'name' => "$fname"},$param->{'action'},$list);
	    &wwslog('err',"d_copy_file : $fname : incorrect name");
	    return 1;
	}

	## Exception index.html
	unless ($fname !~ /^index.html?$/i) {
	    unless ($access_dir->{'may'}{'control'}) {
		&report::reject_report_web('user','index_html',{'dir' => $path},$param->{'action'},$list); 
		&wwslog('err',"d_copy_file : the user is not authorized to upload a INDEX.HTML file in $dest_dir");
		return 1;
	    }
	}

	## Check quota
	if ($list->{'admin'}{'shared_doc'}{'quota'}) {

	    if ($list->get_shared_size() >= $list->{'admin'}{'shared_doc'}{'quota'} * 1024){
		 &report::reject_report_web('user','shared_full',{},$param->{'action'},$list);
		&wwslog('err',"d_copy_file : Shared Quota exceeded for list $list->{'name'} on file $path/$fname");
		return undef;
	    }
	}
	
	## if already existing :delete it
	unlink ("$dest_dir/$fname") 
	    if (-e "$dest_dir/$fname");
	unlink ("$dest_dir/.desc.$fname") 
	    if (-e "$dest_dir/.desc.$fname");

	##  # if exists a temp file younger than 5 minutes that belongs to another user : file copy refused
	if (-e "$dest_dir/.$fname.duplicate") {
	    my @info = stat "$dest_dir/.$fname.duplicate";
	    my $timeold = time - $info[10];
	    if ($timeold <= 300){
		my %desc_hash = &get_desc_file("$dest_dir/.desc..$fname.duplicate");
		unless($desc_hash{'email'} eq $param->{'user'}{'email'}){
		    &report::reject_report_web('user','file_no_copied',{'name'=> "$path/$fname",
									'reason' => "file being uploading by $desc_hash{'email'} at this time"},
					       $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		    &wwslog('err',"d_copy_file : unable to copy $path/$fname : file being uploaded at this time ");
		    return 1;
		}
	    }		
	   
	    unlink ("$dest_dir/.$fname.duplicate");
	    unlink ("$dest_dir/.desc..$fname.duplicate") 
		if (-e "$dest_dir/.desc..$fname.duplicate");
	}

	if (-e "$dest_dir/.$fname.moderate") {
	    my %desc_hash = &get_desc_file("$dest_dir/.$fname.moderate");

	    unless($desc_hash{'email'} eq $param->{'user'}{'email'}){
		&report::reject_report_web('user','file_no_copied',{'name'=> "$path/$fname",
								    'reason' => "file awaiting for moderation, uploaded by $desc_hash{'email'}"},
					   $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		&wwslog('err',"d_copy_file : unable to copy $path/$fname : file awaiting for moderation");
		return 1;
	    }
	    unlink ("$dest_dir/.$fname.moderate");
	    
	    unlink ("$dest_dir/.desc..$fname.moderate")
		if (-e "$dest_dir/.desc..$fname.moderate");
	}
	    
	## file copy
	unless (open FROM_FILE,"$from/$fname") {
	    &report::reject_report_web('user','file_no_copied',{'name'=> "$path/$fname"},
								$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	    &wwslog('err',"d_copy_file : impossible to open $from/$fname");
	    return 1;
	}

	my $visible_fname = &make_visible_path($fname);

 	unless (open DEST_FILE, ">$dest_dir/$fname") {
	    &report::reject_report_web('user','file_no_copied',{'name'=> "$path/$visible_fname"},
				       $param->{'action'},$list,$param->{'user'}{'email'},$robot);
	    &wwslog('err',"d_copy_file : Cannot create file $dest_dir/$fname : $!");
	    return 1;
	}

	while (<FROM_FILE>) {
	    print DEST_FILE;
	}
	close FROM_FILE;
	close DEST_FILE;


	## desc file creation
	unless (open (DESC,">$dest_dir/.desc.$fname")) {
	    &wwslog('err',"d_copy_file: cannot create description file $dest_dir/.desc.$fname");
	}
	
	print DESC "title\n \n\n"; 
	print DESC "creation\n  date_epoch ".time."\n  email $param->{'user'}{'email'}\n\n"; 
	
	print DESC "access\n";
	print DESC "  read $access_dir->{'scenario'}{'read'}\n";
	print DESC "  edit $access_dir->{'scenario'}{'edit'}\n";  
	
	close DESC;
   
	## information

	&report::notice_report_web('file_erased',{'path'=> "$path/$visible_fname"},$param->{'action'}) 
	    if ($may->{'exists'});
    }else{
	&report::reject_report_web('user','file_no_copied',{'name'=> "$path/$fname",
							    'reason' => "you do not have total edit right on the file"},
				   $param->{'action'},$list,$param->{'user'}{'email'},$robot);
	&wwslog('err',"d_copy_file : impossible to copy file $fname, the user doesn't have total edit rights on the file");
    }
    
    return 1;
}

## return information on file or dir : existing and edit rights for the user in $param
sub d_test_existing_and_rights {
    my ($path,$name,$dest_dir) = @_;
    
    $path = &no_slash_end($path);
    $name = &no_slash_end($name);
    $dest_dir = &no_slash_end($dest_dir);

    my $return;
    
    $return->{'exists'} = 0;
    $return->{'rights'} = 0;
 
    if ((-e "$dest_dir/$name") ||
	(-e "$dest_dir/.$name.duplicate") ||
	(-e "$dest_dir/.$name.moderate")) {
	
	$return->{'exists'} = 1;

	my %mode;
	$mode{'edit'} = 1;
	my %access = &d_access_control(\%mode,"$path/$name");
	$return->{'rights'} = 1 
	    if $access{'may'}{'edit'} == 1;
    }

    return $return;
}


 #*******************************************
 # Function : do_d_delete
 # Description : Delete an existing document
 #               (file or directory)
 #******************************************

 sub do_d_delete {
     &wwslog('info', 'do_d_delete(%s)', $in{'path'});

     #useful variables
     my $path = &no_slash_end($in{'path'});

     my $visible_path = &make_visible_path($path);

     #Current directory and document to delete
     $path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
     my $current_directory = &no_slash_end($1);
     my $document = $3;

      # path of the shared directory
     #my $list_name = $in{'list'};
     my $list_name = $list->{'name'};
     my $shareddir =  $list->{'dir'}.'/shared';

 #### Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_d_delete : no list');
	 return undef;
     }

     ## must be something to delete
     unless ($document) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'doccument'},$param->{'action'});
	 &wwslog('err',"do_d_delete : no document to delete has been specified");
	 return undef;
     }

     ### Document isn't a description file?
     unless ($document !~ /^\.desc/) {
	 &wwslog('err',"do_d_delete : $shareddir/$path : description file");
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
	 return undef;
     }

     ### Document exists?
     unless (-e "$shareddir/$path") {
	 &wwslog('err',"do_d_delete : $shareddir/$path : no such file or directory");
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
	 return undef;
     }

     # removing of the document
     my $doc = "$shareddir/$path";

     # Access control
     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode,$path);

     unless ($access{'may'}{'edit'} > 0) {
	 &report::reject_report_web('auth',$access{'reason'}{'edit'},{},$param->{'action'},$list);
	 &wwslog('err','do_d_delete : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     ## Directory
     if (-d "$shareddir/$path") {

	 # test of emptiness
	 opendir DIR, "$doc";
	 my @readdir = readdir DIR;
	 close DIR;

	 # test for "ordinary" files
	 my @test_normal = grep !/^\./, @readdir;
	 my @test_hidden = grep !(/^\.desc$/ | /^\.(\.)?$/ | /^[^\.]/), @readdir;
	 if (($#test_normal != -1) || ($#test_hidden != -1)) {
	     &report::reject_report_web('user','full_directory',{'directory'=> $path},$param->{'action'},$list);
	     &wwslog('err',"do_d_delete : Failed to erase $doc : directory not empty");
	     return undef;
	 }

	 # removing of the description file if exists
	 if (-e "$doc/\.desc") {
	     unless (unlink("$doc/.desc")) {
		 &report::reject_report_web('intern','erase_file',{'file' => "$doc/.desc"},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('err',"do_d_delete : Failed to erase $doc/.desc : $!");
		 return undef;
	     }
	 }   
	 # removing of the directory
	 rmdir $doc;

	 ## File
     }else {

	 # removing of the document
	 unless (unlink($doc)) {
	     &report::reject_report_web('intern','erase_file',{'file' => "$doc"},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err','do_d_delete: failed to erase %s', $doc);
	     return undef;
	 }
	 # removing of the description file if exists
	 if (-e "$shareddir/$current_directory/.desc.$document") {
	     unless (unlink("$shareddir/$current_directory/.desc.$document")) {
		 &wwslog('err',"do_d_delete: failed to erase $shareddir/$current_directory/.desc.$document");
	     }
	 }   
     }

     $in{'list'} = $list_name;
     $in{'path'} = $current_directory;
     return 'd_read';
 }

 #*******************************************
 # Function : do_d_rename
 # Description : Rename a document
 #               (file or directory)
 #******************************************

 sub do_d_rename {
     &wwslog('info', 'do_d_rename(%s)', $in{'path'});

     #useful variables
     my $path = &no_slash_end($in{'path'});

     #moderation
     my $visible_path = &make_visible_path($path);     
     my $moderate;
     if ($visible_path ne $path) {
	 $moderate=1;
     }

     #Current directory and document to delete
     my $current_directory;
     if ($path =~ /^(.*)\/([^\/]+)$/) {
	 $current_directory = &no_slash_end($1);
     }else {
	 $current_directory = '.';
     }
     $path =~ /(^|\/)([^\/]+)$/; 
     my $document = $2;

     # path of the shared directory
     my $list_name = $list->{'name'};
     my $shareddir =  $list->{'dir'}.'/shared';

 #### Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_d_rename : no list');
	 return undef;
     }

     ## must be something to delete
     unless ($document) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'document'},$param->{'action'});
	 &wwslog('err',"do_d_rename : no document to rename has been specified");
	 return undef;
     }

     ### Document isn't a description file?
     unless ($document !~ /^\.desc/) {
	 &wwslog('err',"do_d_rename : $shareddir/$path : description file");
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
	 return undef;
     }

     ### Document exists?
     unless (-e "$shareddir/$path") {
	 &wwslog('err',"do_d_rename : $shareddir/$path : no such file or directory");
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
	 return undef;
     }

     ## New document name
     unless ($in{'new_name'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'new name'},$param->{'action'});
	 &wwslog('err',"do_d_rename : new name missing");
	 return undef;
     }

     if ($in{'new_name'} =~ /^\./
	 || $in{'new_name'} =~ /\.desc/ 
	 || $in{'new_name'} =~ /[~\#\[\]\/]$/) {
	 &report::reject_report_web('user','incorrect_name',{'name' => $in{'new_name'}},$param->{'action'},$list);
	 &wwslog('err',"do_d_rename : Unable to create file $in{'new_name'} : incorrect name");
	 return undef;
     }

     if (($document =~ /\.url$/) && ($in{'new_name'} !~ /\.url$/)) {
	 &report::reject_report_web('user','incorrect_name',{'name' => $in{'new_name'}},$param->{'action'},$list);
	 &wwslog('err',"do_d_rename : New file name $in{'new_name'} does not match URL filenames");
	 return undef;
     }

     my $doc = "$shareddir/$path";

     # Access control
     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode,$path);

     unless ($access{'may'}{'edit'} > 0) {
	 &report::reject_report_web('auth',$access{'reason'}{'edit'},{},$param->{'action'},$list);
	 &wwslog('err','do_d_rename : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }
     if ($moderate){
	 unless (rename $doc, "$shareddir/$current_directory/.$in{'new_name'}.moderate") {
	     &report::reject_report_web('intern','rename_file',{'old'=>$doc,
								'new'=>"$shareddir/$current_directory/.$in{'new_name'}.moderate"},
					$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err',"do_d_rename : Failed to rename %s to %s : %s", $doc, "$shareddir/$current_directory/$in{'new_name'}", $!);
	     return undef;
	 }
     }else {
     unless (rename $doc, "$shareddir/$current_directory/$in{'new_name'}") {
	 &report::reject_report_web('intern','rename_file',{'old'=>$doc,
							    'new'=>"$shareddir/$current_directory/$in{'new_name'}"},
				    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('err',"do_d_rename : Failed to rename %s to %s : %s", $doc, "$shareddir/$current_directory/$in{'new_name'}", $!);
	 return undef;
     }
     }
     ## Rename description file
     my $desc_file = "$shareddir/$current_directory/.desc.$document";
	 my $new_desc_file = $desc_file;

     if (-f $desc_file) {
	 if ($moderate){
	     $new_desc_file =~ s/$document/\.$in{'new_name'}\.moderate/;
	 }else {
	     $new_desc_file =~ s/$document/$in{'new_name'}/;   
	 }
	 unless (rename $desc_file, $new_desc_file) {
	     &report::reject_report_web('intern','rename_file',{'old'=>$desc_file,
								'new'=> $new_desc_file},
					$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err',"do_d_rename : Failed to rename $desc_file : $!");
	     return undef;
	 }
     }

     $in{'list'} = $list_name;
     if ($current_directory eq '.') {
	 $in{'path'} = '';
     } else {
	 $in{'path'} = $current_directory.'';
     }
     return 'd_read';
 }

 #*******************************************
 # Function : do_d_create_dir
 # Description : Creates a new file / directory
 #******************************************
 sub do_d_create_dir {
     &wwslog('info', 'do_d_create_dir(%s)', $in{'name_doc'});

     #useful variables
     my $path =  &no_slash_end($in{'path'});

     #my $list_name = $in{'list'};
     my $list_name = $list->{'name'};
     my $name_doc = $in{'name_doc'};

     $param->{'list'} = $list_name;
     $param->{'path'} = $path;

     my $type = $in{'type'} || 'directory';
     my $desc_file;

 ### Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_d_create_dir : no list');
	 return undef;
     }

      # Must be a directory to create (directory name not empty)
     unless ($name_doc) {
	 &report::reject_report_web('user','no_name',{},$param->{'action'},$list);
	 &wwslog('err',"do_d_create_dir : Unable to create : no name specified!");
	 return undef;
     }

     # The name of the directory must be correct
     if ($name_doc =~ /^\./
	 || $name_doc =~ /\.desc/ 
	 || $name_doc =~ /[~\#\[\]\/]$/) {
	 &report::reject_report_web('user','incorrect_name',{'name' => $name_doc},$param->{'action'},$list);
	 &wwslog('err',"do_d_create_dir : Unable to create directory $name_doc : incorrect name");
	 return undef;
     }


     # Access control
     my %mode;
     $mode{'edit'} = 1;
     my %access = &d_access_control(\%mode, $path);

     if ($type eq 'directory') { ## only when (is_author || !moderated) 
	 if ($access{'may'}{'edit'} == 0) {
	     &report::reject_report_web('auth',$access{'reason'}{'edit'},{},$param->{'action'},$list);
	     &wwslog('err','do_d_create_dir :  access denied for %s', $param->{'user'}{'email'});
	     return undef;
	 }    
	 if ($access{'may'}{'edit'} == 0.5) {
	     &report::reject_report_web('auth','dir_edit_moderated',{},$param->{'action'},$list);
	     &wwslog('err','do_d_create_dir :  access denied for %s', $param->{'user'}{'email'});
	     return undef;
	 }  
     } else {
	 if ($access{'may'}{'edit'} == 0) {
	     &report::reject_report_web('auth',$access{'reason'}{'edit'},{},$param->{'action'},$list);
	     &wwslog('err','do_d_create_dir :  access denied for %s', $param->{'user'}{'email'});
	     return undef;
	 }    
     }

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';

     my $document = "$shareddir/$path/$name_doc";

     $param->{'document'} = $document;

     # the file musn't already exists
     if (-e $document){
	 &report::reject_report_web('user','doc_already_exist',{'name' => "$path/$name_doc"},$param->{'action'},$list);
	 &wwslog('err',"do_d_create_dir : cannot create $path/$name_doc : file already exists");
	 return undef;
     }

     # if the file .moderate exists, only its author can erase it 
     
     my $doc_moderate = "$shareddir/$path/"."."."$name_doc".".moderate";
     my $file_moderated;
       
     if (-e "$doc_moderate"){

	 $file_moderated = 1;
	 my $desc="$shareddir/$path/".".desc.."."$name_doc".".moderate";
	 $desc =~ s/\/+/\//g;
	 my %desc_hash = &get_desc_file("$desc");
	 
	 unless($desc_hash{'email'} eq $param->{'user'}{'email'}){
	     &report::reject_report_web('user','cannot_upload',{'path' => "$path/$name_doc",
									'reason' => "file already exists but not yet moderated"},$param->{'action'},$list);
	     &wwslog('err',"do_d_create_dir : Unable to create $doc_moderate : file already exists but not yet moderated");
	     return undef;
	 }
     }

     ### End of controls

     if ($type eq 'directory') {
	 # Creation of the new directory
	 unless (mkdir ("$document",0777)) {
	     &report::reject_report_web('intern','cannot_mkdir',{'dir' => $document},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err',"do_d_create_dir : Unable to create $document : $!");
	     return undef;
	 }

	 $desc_file = "$document/.desc";

     }else {
	 # Creation of the new file
	 unless (open FILE, ">$document") {
	     &report::reject_report_web('intern','cannot_open_file',{'file' => "$path/$name_doc"},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err',"do_d_create_dir : Unable to create $document : $!");
	     return undef;
	 }
	 close FILE;

	 $desc_file = "$shareddir/$path/.desc.$name_doc";
     }

     # Creation of a default description file 
     unless (open (DESC,">$desc_file")) {
	 &report::reject_report_web('intern','cannot_open_file',{'file' => "$desc_file"},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
     }

     print DESC "title\n \n\n"; 
     print DESC "creation\n  date_epoch ".time."\n  email $param->{'user'}{'email'}\n\n"; 

     print DESC "access\n";
     print DESC "  read $access{'scenario'}{'read'}\n";
     print DESC "  edit $access{'scenario'}{'edit'}\n\n";  

     close DESC;

     # moderation
     if ($access{'may'}{'edit'} == 0.5 && ($type ne 'directory')) { 
	 unless (rename "$shareddir/$path/$name_doc","$shareddir/$path/.$name_doc.moderate"){
	     &report::reject_report_web('intern','rename_file',{'old'=>"$shareddir/$path/$name_doc",
								'new'=>"$shareddir/$path/.$name_doc.moderate"},
					$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err',"do_d_create_dir : Failed to rename $path/$name_doc to $path/.$name_doc.moderate : $!");
	 }
	 
	 unless (rename "$desc_file","$shareddir/$path/.desc..$name_doc.moderate"){
	     &report::reject_report_web('intern','rename_file',{'old'=>$desc_file,
								'new'=>"$shareddir/$path/.desc..$name_doc.moderate"},
					$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('err',"do_d_create_dir : Failed to rename $desc_file to $path/.desc..$name_doc.moderate : $!");
	 }

	 unless ($file_moderated){
 	     unless ($list->send_notify_to_editor('shared_moderated',{'filename' => "$path/$name_doc",
 								      'who' => $param->{'user'}{'email'}})) {
 		 &wwslog('notice',"Unable to send notify 'shared_moderated' to $list->{'name'} list editor");
 	     }	     
	 }
     }

     if ($type eq 'directory') {
	 return 'd_read';
     }

     if ($access{'may'}{'edit'} == 0.5) {
	 $in{'path'} = "$path/.$name_doc.moderate";
     }else {
	 $in{'path'} = "$path/$name_doc";
     }

     return 'd_editfile';
 }

 ############## Control


 #*******************************************
 # Function : do_d_control
 # Description : prepares the parameters
 #               to edit access for a doc
 #*******************************************

 sub do_d_control {
     &wwslog('info', "do_d_control $in{'path'}");

     # Variables
     my $path = &no_slash_end($in{'path'});
     #my $list_name = $in{'list'};
     my $list_name = $list->{'name'};

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';

     #moderation
     my $visible_path = &make_visible_path($path);


     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_d_control: no list');
	 return undef;
     }

     unless ($path) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'document'},$param->{'action'});
	 &wwslog('info','do_d_control: no document name');
	 return undef;
     }   

     # Existing document? 
     unless (-e "$shareddir/$path") {
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
	 &wwslog('info',"do_d_control : Cannot control $shareddir/$path : not an existing document");
	 return undef;
     }

     ### Document isn't a description file?
     unless ($path !~ /\.desc/) {
	 &wwslog('info',"do_d_control : $shareddir/$path : description file");
	 &report::reject_report_web('user','no_such_document',{'path'=> $visible_path},$param->{'action'},$list);
	 return undef;
     }

     # Access control
     my %mode;
     $mode{'control'} = 1;
     my %access = &d_access_control(\%mode,$path);
     unless ($access{'may'}{'control'}) {
	 &report::reject_report_web('auth',$access{'reason'}{'edit'},{},$param->{'action'},$list);
	 &wwslog('info','d_control : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }


  ## End of controls


     #Current directory
     if ($path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/) {
	 $param->{'father'} = &no_slash_end($1);    
     }else {
	 $param->{'father'} = '';
     }
     $param->{'escaped_father'} = &tools::escape_chars($param->{'father'}, '/');

     my $desc_file;
     # path of the description file
     if (-d "$shareddir/$path") {
	 $desc_file = "$shareddir/$1$3/.desc";
     } else {
	 $desc_file = "$shareddir/$1.desc.$3";
     }

     # Description of the file
     my $read;
     my $edit;

     if (-e $desc_file) {

	 ## Synchronization
	 my @info = stat "$desc_file";
	 $param->{'serial_desc'} = $info[9];
	 my %desc_hash = &get_desc_file("$desc_file");
	 # rights for read and edit
	 $read = $desc_hash{'read'};
	 $edit = $desc_hash{'edit'};
	 # owner of the document
	 $param->{'owner'} = $desc_hash{'email'};
	 $param->{'doc_title'} = $desc_hash{'title'};
     }else {
	 $read = $access{'scenario'}{'read'};
	 $edit = $access{'scenario'}{'edit'};
     }

     ## other info
     my @info = stat "$shareddir/$path";
     $param->{'doc_date'} =  &POSIX::strftime("%d %b %y  %H:%M", localtime($info[9]));

     # template parameters
     $param->{'list'} = $list_name;
     $param->{'path'} = $path;
     $param->{'visible_path'} = $visible_path;

     my $lang = $param->{'lang'};

     ## Scenario list for READ

     $param->{'scenari_read'} = $list->load_scenario_list('d_read', $robot);
     $param->{'scenari_read'}{$read}{'selected'} = 'selected="selected"';

#     my $read_scenario_list = $list->load_scenario_list('d_read', $robot);
#     $param->{'read'}{'scenario_name'} = $read;
#     $param->{'read'}{'label'} = $read_scenario_list->{$read}{'title'}{$lang};
#
#     foreach my $key (keys %{$read_scenario_list}) {
#	 $param->{'scenari_read'}{$key}{'scenario_name'} = $read_scenario_list->{$key}{'name'};
#	 $param->{'scenari_read'}{$key}{'scenario_label'} = $read_scenario_list->{$key}{'title'}{$lang};
#	 if ($key eq $read) {
#	     $param->{'scenari_read'}{$key}{'selected'} = 'selected="selected"';
#	 }
#     }

     ## Scenario list for EDIT
     $param->{'scenari_edit'} = $list->load_scenario_list('d_edit', $robot);
     $param->{'scenari_edit'}{$edit}{'selected'} = 'selected="selected"';


#     my $edit_scenario_list = $list->load_scenario_list('d_edit', $robot);
#     $param->{'edit'}{'scenario_name'} = $edit;
#     $param->{'edit'}{'label'} = $edit_scenario_list->{$edit}{'title'}{$lang};
#
#     foreach my $key (keys %{$edit_scenario_list}) {
#	 $param->{'scenari_edit'}{$key}{'scenario_name'} = $edit_scenario_list->{$key}{'name'};
#	 $param->{'scenari_edit'}{$key}{'scenario_label'} = $edit_scenario_list->{$key}{'title'}{$lang};
#	 if ($key eq $edit) {
#	     $param->{'scenari_edit'}{$key}{'selected'} = 'selected="selected"';
#	 }
#     }

     ## father directory
     if ($path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/) {
	 $param->{'father'} = &no_slash_end($1);    
     }else {
	 $param->{'father'} = '';
     }
     $param->{'escaped_father'} = &tools::escape_chars($param->{'father'}, '/');

     $param->{'set_owner'} = 1;

     $param->{'father_icon'} = $icon_table{'father'};
     return 1;
 }


 #*******************************************
 # Function : do_d_change_access
 # Description : Saves the description of 
 #               the file
 #******************************************

 sub do_d_change_access {
     &wwslog('info', 'do_d_change_access(%s)', $in{'path'});

     # Variables
     my $path = &no_slash_end($in{'path'});

     my $list_name = $list->{'name'};

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';

 ####  Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_d_change_access: no list');
	 return undef;
     }

     ## the path must not be empty (the description file of the shared directory
     #  doesn't exist)
     unless ($path) {
	 &report::reject_report_web('intern','cannot_describe_shared_directory',{'path' => $path },$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('info',"do_d_change_access : Cannot change access $shareddir : root directory");
	 return undef;
     }

     # the document to describe must already exist 
     unless (-e "$shareddir/$path") {
	 &report::reject_report_web('user','no_doc_to_describe',{'path'=> $path},$param->{'action'},$list);
	 &wwslog('info',"d_change_access : Unable to change access $shareddir/$path : no such document");
	 return undef;
     }


     # Access control
     my %mode;
     $mode{'control'} = 1;
     my %access = &d_access_control(\%mode,$path);

     unless ($access{'may'}{'control'}) {
	 &report::reject_report_web('auth','action_listmaster_or_privileged_owner_or_author',{},$param->{'action'},$list);
	 &wwslog('info','d_change_access : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     ## End of controls

     # Description file
     $path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
     my $dir = $1;
     my $file = $3;

     my $desc_file;
     if (-d "$shareddir/$path") {
	 $desc_file = "$shareddir/$1$3/.desc";
     } else {
	 $desc_file = "$shareddir/$1.desc.$3";
     }

     if (-e "$desc_file"){
	 # if description file already exists : open it and modify it
	 my %desc_hash = &get_desc_file ("$desc_file");

	 # Synchronization
	 unless (&synchronize($desc_file,$in{'serial'})){
	     &report::reject_report_web('user','synchro_failed',{},$param->{'action'},$list);
	     &wwslog('info',"d_change_access : Synchronization failed for $desc_file");
	     return undef;
	 }

	 unless (open DESC,">$desc_file") {
	     &wwslog('info',"d_change_access : cannot open $desc_file : $!");
	     &report::reject_report_web('intern','cannot_open_file',{'file' => $desc_file},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     return undef;
	 }

	 # information not modified
	 print DESC "title\n  $desc_hash{'title'}\n\n"; 

	 # access rights
	 print DESC "access\n  read $in{'read_access'}\n";
	 print DESC "  edit $in{'edit_access'}\n\n";

	 print DESC "creation\n";
	 # time
	 print DESC "  date_epoch $desc_hash{'date'}\n";
	 # author
	 print DESC "  email $desc_hash{'email'}\n\n";

	 close DESC;

     } else {
	 # Creation of a description file 
	 unless (open (DESC,">$desc_file")) {
	     &report::reject_report_web('intern','cannot_open_file',{'file' => $desc_file},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('info',"d_change_access : Cannot create description file $desc_file : $!");
	     return undef;
	 }
	 print DESC "title\n \n\n";

	 my @info = stat "$shareddir/$path";
	 print DESC "creation\n  date_epoch ".$info[10]."\n  email\n\n"; 
	 print DESC "access\n  read $in{'read_access'}\n";
	 print DESC "  edit $in{'edit_access'}\n\n";

	 close DESC;

     }

     return 'd_control';


 }	

 sub do_d_set_owner {
     &wwslog('info', 'do_d_set_owner(%s)', $in{'path'});

     # Variables
     my $desc_file;

     my $path = &no_slash_end($in{'path'});

     #moderation
     my $visible_path = &make_visible_path($path);

     #my $list_name = $in{'list'};
     my $list_name = $list->{'name'};

     # path of the shared directory
     my $shareddir =  $list->{'dir'}.'/shared';

 ####  Controls
     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_d_set_owner: no list');
	 return undef;
     }


     ## the path must not be empty (the description file of the shared directory
     #  doesn't exist)
     unless ($path) {
	 &report::reject_report_web('intern','cannot_describe_shared_directory',{'path' => $path },$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('info',"do_d_set_owner : Cannot change access $shareddir : root directory");
	 return undef;
     }

     # the email must look like an email "somebody@somewhere"
     unless (&tools::valid_email($in{'content'})) {
	 &report::reject_report_web('user','incorrect_email',{'email' => $in{'content'}},$param->{'action'},$list);
	 &wwslog('info',"d_set_owner : $in{'content'} : incorrect email");
	 return undef;
     }

     # Access control
     ## father directory
     $path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
     my $dir = $1; 
     my $file = $3;
     if (-d "$shareddir/$path") {
	 $desc_file = "$shareddir/$dir$file/.desc"; 
     }else {
	 $desc_file = "$shareddir/$dir.desc.$file";
     }       
     
     my %mode;
     $mode{'control'} = 1;
       ## must be authorized to control father directory
     #my %access = &d_access_control(\%mode,$1);
     my %access = &d_access_control(\%mode,$path);

     unless ($access{'may'}{'control'}) {
	 &report::reject_report_web('auth','action_listmaster_or_privileged_owner_or_author',{},$param->{'action'},$list);
	 &wwslog('info','d_set_owner : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     my $may_set = 1;

     unless ($may_set) {
	 &report::reject_report_web('user','full_directory',{'directory'=> $visible_path},$param->{'action'},$list);
	 &wwslog('info',"d_set_owner : cannot set owner of a full directory");
	 return undef;
     }

 ## End of controls

     my %desc_hash;

     if (-e "$desc_file"){
	 # if description file already exists : open it and modify it
	 %desc_hash = &get_desc_file ("$desc_file");
     
	 # Synchronization
	 unless (&synchronize($desc_file,$in{'serial'})) {
	 
	     &report::reject_report_web('user','synchro_failed',{},$param->{'action'},$list);
	     &wwslog('info',"d_set_owner : Synchronization failed for $desc_file");
	     return undef;
	 }

	 unless (open DESC,">$desc_file") {
	     &wwslog('info',"d_set_owner : cannot open $desc_file : $!");
	     &report::reject_report_web('intern','cannot_open_file',{'file' => $desc_file},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     return undef;
	 }

	 # information not modified
	 print DESC "title\n  $desc_hash{'title'}\n\n"; 

	 print DESC "access\n  read $desc_hash{'read'}\n";
	 print DESC "  edit $desc_hash{'edit'}\n\n";
	 print DESC "creation\n";
	 # time
	 print DESC "  date_epoch $desc_hash{'date'}\n";

	 #information modified
	 # author
	 print DESC "  email $in{'content'}\n\n";

	 close DESC;

     } else {
	 # Creation of a description file 
	 unless (open (DESC,">$desc_file")) {
	     &report::reject_report_web('intern','cannot_open_file',{'file' => $desc_file},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('info',"d_set_owner : Cannot create description file $desc_file : $!");
	     return undef;
	 }
	 print DESC "title\n  $desc_hash{'title'}\n\n";
	 my @info = stat "$shareddir/$path";
	 print DESC "creation\n  date_epoch ".$info[10]."\n  email $in{'content'}\n\n"; 

	 print DESC "access\n  read $access{'scenario'}{'read'}\n";
	 print DESC "  edit $access{'scenario'}{'edit'}\n\n";  

	 close DESC;

     }

     ## ONLY IF SET_OWNER can be performed even if not control of the father directory
     $mode{'control'} = 1;
     my %access = &d_access_control(\%mode,$path);
     unless ($access{'may'}{'control'}) {
	 ## father directory
	 $path =~ /^(([^\/]*\/)*)([^\/]+)(\/?)$/; 
	 $in{'path'} = &no_slash_end($1);
	 return 'd_read';
     }

     ## ELSE
     return 'd_control';
 }

 ## Protecting archives from Email Sniffers
 sub do_arc_protect {
     &wwslog('info', 'do_arc_protect()');

     return 1;
 } 

####################################################
#  do_remind                          
####################################################
#  Sends a remind command to sympa.pl.
# 
# IN : -
#
# OUT : 'loginrequest' | 'admin' | undef
#
#####################################################
 sub do_remind {
     &wwslog('info', 'do_remind()');

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_remind: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_remind: no user');
	 return 'loginrequest';
     }

     ## Access control
     return undef unless (defined &check_authz('do_remind', 'remind'));

     my $extention = time.".".int(rand 9999) ;
     my $mail_command;

     ## Sympa will require a confirmation
     my $result = $list->check_list_authz('remind','smtp',
					  {'sender' => $param->{'user'}{'email'},
					   'remote_host' => $param->{'remote_host'},
					   'remote_addr' => $param->{'remote_addr'}});
     my $r_action;
     my $reason;
     if (ref($result) eq 'HASH') {
	 $r_action = $result->{'action'};
	 $reason = $result->{'reason'};
     }

     if ($r_action =~ /reject/i) {
	 &report::reject_report_web('auth',$reason,{},$param->{'action'},$list);
	 &wwslog('info','remind : access denied for %s', $param->{'user'}{'email'});
	 return undef;

     }else {
	 $mail_command = sprintf "REMIND %s", $param->{'list'};
     }

     my $time = time;
     my $data = {'headers' => {'Message-ID' => '<'.$time.'@wwsympa>'},
		 'from'=> $param->{'user'}{'email'},
		 'body' => $mail_command};

     unless (&mail::mail_file('',&Conf::get_robot_conf($robot, 'sympa'),$data,$robot)) {
	 &report::reject_report_web('intern','cannot_send_remind',{'from' => $param->{'user'}{'email'},'listname'=>$list->{'name'}},
				    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('err','do_remind: failed to send message for command REMIND');
	 return undef;
     }

     &report::notice_report_web('performed_soon',{},$param->{'action'});

     return 'admin';
 }

 ## Load list certificat
 sub do_load_cert {
     &wwslog('info','do_load_cert(%s)', $param->{'list'});

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_load_cert: no list');
	 return undef;
     }
     my @cert = $list->get_cert('der');
     unless (@cert) {
	 &report::reject_report_web('user','missing_cert',{},$param->{'action'},$list);
	 &wwslog('info','do_load_cert: no cert for this list');
	 return undef;
     }

     # don't you just HATE it when every single browser seems to want a
     # different content-type for certificates? order is important, as
     # everybody calls themselves "mozilla", and opera identifies as
     # IE if told so (but Opera doesn't do S/MIME anyways, it seems)
     my ($ua, $ct) = ($ENV{HTTP_USER_AGENT}, 'application/x-x509-email-cert');
     if ($ua =~ /MSIE/) {
	 $ct = 'application/pkix-cert';
     }
     $param->{'bypass'} = 'extreme';
     printf "Content-type: $ct\n\n";
     foreach my $l (@cert) {
	 printf "$l";
     }
     return 1;
 }

####################################################
#  do_change_email                          
####################################################
#  Changes a user's email address in Sympa environment
# 
# IN : -
#
# OUT : '1' | 'pref' | undef
#      
####################################################
 ## Change a user's email address in Sympa environment
 sub do_change_email {
     &wwslog('info','do_change_email(%s)', $in{'email'});

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_change_password: user not logged in');
	 return undef;
     }

     unless ($in{'email'}) {
	 &report::reject_report_web('user','no_email',{},$param->{'action'});
	 &wwslog('info','do_change_email: no email');
	 return undef;
     }

     my ($password, $newuser);

     if ($newuser =  &List::get_user_db($in{'email'})) {

	 $password = $newuser->{'password'};
     }

     $password ||= &tools::tmp_passwd($in{'email'});

     ## Step 2 : checking password
     if ($in{'password'}) {
	 unless ($in{'password'} eq $password) {
	     &report::reject_report_web('user','incorrect_passwd',{},$param->{'action'});
	     &wwslog('info','do_change_email: incorrect password for user %s', $in{'email'});
	     return undef;
	 }

	 ## Change email
	 foreach my $list ( &List::get_which($param->{'user'}{'email'},$robot, 'member') ) {
	     my $l = $list->{'name'};
	     
	     my $result_sub = $list->check_list_authz('subscribe',$param->{'auth_method'}
						      {'sender' => $in{'email'}, 
						       'previous_email' => $param->{'user'}{'email'},
						       'remote_host' => $param->{'remote_host'},
						       'remote_addr' => $param->{'remote_addr'}});

	     my $sub_is;
	     my $reason_sub;
	     if (ref($result_sub) eq 'HASH') {
		 $sub_is = $result_sub->{'action'};
		 $reason_sub = $result_sub->{'reason'};
	     }

	     my $result_unsub = $list->check_list_authz('unsubscribe',$param->{'auth_method'},
						      {'sender' => $param->{'user'}{'email'}, 
						       'remote_host' => $param->{'remote_host'},
						       'remote_addr' => $param->{'remote_addr'}});

	     my $unsub_is;
	     my $reason_unsub;
	     if (ref($result_unsub) eq 'HASH') {
		 $unsub_is = $result_unsub->{'action'};
		 $reason_unsub = $result_unsub->{'reason'};
	     }

	     if ($sub_is !~ /do_it/) {	
		 &report::reject_report_web('auth',$reason_sub,{'change_email_failed'=> 1},$param->{'action'},$list);
		 &wwslog('info', "do_change_email: could not change email for list %s because subscribe not allowed");
		 next;
	     }elsif($unsub_is !~ /do_it/) {	
		 &report::reject_report_web('auth',$reason_unsub,{'change_email_failed'=> 1},$param->{'action'},$list);
		 &wwslog('info', "do_change_email : could not change email for list %s because unsubscribe not allowed");
		 next;
	     }
	     #elsif(($sub_is =~ /owner/) || ($unsub_is =~ /owner/)) {
	     #    next;
	     #}
	     unless ($list->update_user($param->{'user'}{'email'}, {'email' => $in{'email'}, 'update_date' => time}) ) {
		 &report::reject_report_web('intern','update_subscriber_db_failed',{'sub'=>$in{'email'},
										    'old_email' => $param->{'user'}{'email'}},
					    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
		 &wwslog('info', 'do_change_email: could not change email for list %s', $l);
	     }
	 }

	 &report::notice_report_web('performed',{},$param->{'action'});

	 ## Update User_table
	 &List::delete_user_db($in{'email'});

	 unless ( &List::update_user_db($param->{'user'}{'email'},
					{'email' => $in{'email'},
					 'lang' => $param->{'user'}{'lang'},
					 'cookie_delay' => $param->{'user'}{'cookie_delay'},
					 'gecos' => $param->{'user'}{'gecos'}
					    })) {
	     &report::reject_report_web('intern','update_user_db_failed',{'user'=>$in{'email'},
									  'old_email' => $param->{'user'}{'email'}},
					$param->{'action'},'',$param->{'user'}{'email'},$robot);
	     &wwslog('info','change_email: update failed');
	     return undef;
	 }

	 ## Change login
	 $param->{'user'} = &List::get_user_db($in{'email'});

	 return 'pref';

	 ## Step 1 : sending password
     }else {
	 $param->{'newuser'} = {'email' => $in{'email'},
				'password' => $password };

	 unless (&List::send_global_file('sendpasswd', $in{'email'}, $robot, $param)) {
	     &wwslog('notice',"Unable to send template 'sendpasswd' to $in{'email'}");
	 }

	 $param->{'email'} = $in{'email'};

	 return '1';
     }

     $param->{'email'} = $in{'email'};

     if ($in{'previous_action'}) {
	 $in{'list'} = $in{'previous_list'};
	 return $in{'previous_action'};
     }else {
	 return 'pref';
     }

 }

 sub do_compose_mail {
     &wwslog('info', 'do_compose_mail');

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_compose_mail: no user');
	 $param->{'previous_action'} = 'compose_mail';
	 return 'loginrequest';
     }

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_compose_mail: no list');
	 return undef;
     }

     unless ($param->{'may_post'}) {
	 &report::reject_report_web('auth',$param->{'may_post_reason'},{},$param->{'action'},$list);
	 &wwslog('info','do_compose_mail: may not send message');
	 return undef;
     }
     if ($in{'to'}) {
	 # In archive we hidde email replacing @ by ' '. Here we must do ther reverse transformation
	 $in{'to'} =~ s/ /\@/;
	 $param->{'to'} = $in{'to'};
     }else{
	 $param->{'to'} = $list->get_list_address();
     }
     ($param->{'local_to'},$param->{'domain_to'}) = split ('@',$param->{'to'});

     $param->{'mailto'}= &mailto($list,$param->{'to'});
     $param->{'subject'}= &MIME::Words::encode_mimewords($in{'subject'});
     $param->{'in_reply_to'}= $in{'in_reply_to'};
     $param->{'message_id'} = &tools::get_message_id($robot);

     if  ($list->is_there_msg_topic()) {

	 $param->{'request_topic'} = 1;

	 foreach my $top (@{$list->{'admin'}{'msg_topic'}}) {
	     if ($top->{'name'}) {
		 push (@{$param->{'available_topics'}},$top);
	     }
	 }
	 $param->{'topic_required'} = $list->is_msg_topic_tagging_required();
     }

     return 1;
 }

####################################################
#  do_send_mail                           
####################################################
#  Sends a message to a list by the Web interface.
#  It uses mail::mail_file() to do it.
# 
# IN : -
#
# OUT : 'loginrequest' 
#      | 'info' | undef
#
####################################################
 sub do_send_mail {
     &wwslog('info', 'do_send_mail');

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_send_mail: no user');
	 $param->{'previous_action'} = 'send_mail';
	 return 'loginrequest';
     }

     # In archive we hidde email replacing @ by ' '. Here we must do ther reverse transformation
     $in{'to'} =~ s/ /\@/;
     my $to = $in{'to'};
     unless ($in{'to'}) {
	 unless ($param->{'list'}) {
	     &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	     &wwslog('info','do_send_mail: no list');
	     return undef;		
	 }
	 unless ($param->{'may_post'}) {
	     &report::reject_report_web('auth',$param->{'may_post_reason'},{},$param->{'action'},$list);
	     &wwslog('info','do_send_mail: may not send message');
	     return undef;
	 }
	 $to = $list->get_list_address();
     }

     $Text::Wrap::columns = 80;
     $in{'body'} = &Text::Wrap::wrap ('','',$in{'body'});


     my @body = split /\0/, $in{'body'};

     my $from = $param->{'user'}{'email'};
     if ($param->{'user'}{'gecos'}) {
	 $from = $param->{'user'}{'gecos'}.'<'.$from.'>';
     }

     ## TOPICS
     my $list_topics;
     if ($list->is_there_msg_topic()) {
	 my @msg_topics;

	 foreach my $msg_topic (@{$list->{'admin'}{'msg_topic'}}) {
	     my $var_name = "topic_"."$msg_topic->{'name'}";
	     if ($in{"$var_name"}) {
		 push @msg_topics, $msg_topic->{'name'};
	     }
	 }	 
	 
	 $list_topics = join(',',@msg_topics);
     }

     if (!$list_topics && $list->is_msg_topic_tagging_required()) {
	 &report::reject_report_web('user','msg_topic_missing',{},$param->{'action'});
	 &wwslog('info','do_send_mail: message(s) without topic topic but in a required list');
	 return undef;
     }

     if ($list_topics) {
	 my $filetopic = $list->tag_topic($in{'message_id'},$list_topics,'sender');
     }

     my $data = {'headers' => {'In-Reply-To' => $in{'in_reply_to'},
			       'Message-ID' => $in{'message_id'}}, 
	         'subject' => $in{'subject'},
		 'return_path' => &Conf::get_robot_conf($robot, 'sympa'),
		 'from'=> $from,
		 'to' => $to,
		 'body' => $in{'body'}};

     unless (&mail::mail_file('',$to,$data,$robot)) {
	 &report::reject_report_web('intern','cannot_send_mail',{'from' => $param->{'user'}{'email'},'listname'=>$list->{'name'}},
				    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('err','do_send_mail: failed to send message for $to list');
	 return undef;
     }

     &report::notice_report_web('performed',{},$param->{'action'});
     return 'info';
 }

####################################################
#  do_request_topic
####################################################
#  Web page for a sender to tag his mail in message 
#  topic context.
# 
# IN : -
#
# OUT : '1' | 'loginrequest' | undef
#
####################################################
 sub do_request_topic {
     &wwslog('info', 'do_request_topic(%s)', $in{'authkey'});

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_request_topic: no user');
	 return 'loginrequest';
     }

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_request_topic: no list');
	 return undef;
     }

     unless ($list->is_there_msg_topic()) {
	 &report::reject_report_web('user','no_topic',{},$param->{'action'},$list);
	 &wwslog('info','do_request_topic: list without topic message');
	 return undef;
     }

     unless ($in{'authkey'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'authkey'},$param->{'action'});
	 &wwslog('info','do_request_topic: no authkey');
	 return undef;
     }

     foreach my $top (@{$list->{'admin'}{'msg_topic'}}) {
	 if ($top->{'name'}) {
	     push (@{$param->{'available_topics'}},$top);
	 }
     }

     $param->{'to'} = $list->get_list_address();
     $param->{'mailto'}= &mailto($list,$param->{'to'});
     $param->{'authkey'} = $in{'authkey'};

     my $listname = $list->{'name'};
     my $authqueue = &Conf::get_robot_conf($robot,'queueauth');
     my $filename = "$authqueue\/$listname\_$in{'authkey'}";

     ## For compatibility concerns
     foreach my $list_id ($list->get_list_id(),$list->{'name'}) {
	 $filename = $authqueue.'/'.$list_id.'_'.$in{'authkey'};
	 last if (-f $filename);
     }

     my $parser = new MIME::Parser;
     $parser->output_to_core(1);

     unless (open FILE, "$filename") {
	 &report::reject_report_web('intern','cannot_open_file',{'file' => $filename},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('notice', 'Cannot open file %s', $filename);
	 return undef;
     }
     my $msg = $parser->parse(\*FILE);
     my $head = $msg->head();
     $param->{'subject'}= &MIME::Words::encode_mimewords($head->get('subject'));
     $param->{'message_id'} = &tools::clean_msg_id($head->get('Message-Id'));

     my $body = $msg->bodyhandle();
     $param->{'body'} = $body->as_string();

     $param->{'topic_required'} = $list->is_msg_topic_tagging_required();

     return 1;
 }

####################################################
#  do_tag_topic_by_sender
####################################################
#  Tag a mail by its sender : tag the mail and 
#  send a command CONFIRM for it
# 
# IN : -
#
# OUT : 'loginrequest' | 'info' | undef
#
####################################################
 sub do_tag_topic_by_sender {
     &wwslog('info', 'do_tag_topic_by_sender');

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_tag_topic_by_sender: no user');
	 $param->{'previous_action'} = 'request_topic';
	 return 'loginrequest';
     }

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_tag_topic_by_sender: no list');
	 return undef;
     }

     unless ($list->is_there_msg_topic()) {
	 &report::reject_report_web('user','no_topic',{},$param->{'action'},$list);
	 &wwslog('info','do_tag_topic_by_sender: list without topic message');
	 return undef;
     }

     my @msg_topics;
     foreach my $msg_topic (@{$list->{'admin'}{'msg_topic'}}) {
	 my $var_name = "topic_"."$msg_topic->{'name'}";
	 if ($in{"$var_name"}) {
	     push @msg_topics, $msg_topic->{'name'};
	 }
     }	 
     my $list_topics = join(',',@msg_topics);

     if (!$list_topics && $list->is_msg_topic_tagging_required()) {
	 &report::reject_report_web('user','msg_topic_missing',{},$param->{'action'},$list);
	 &wwslog('info','do_tag_topic_by_sender: message without topic but in a required list');
	 return undef;
     }

     ## TAG 
     my $filetopic = $list->tag_topic($in{'message_id'},$list_topics,'sender');

     ## CONFIRM
     my $time = time;
     my $data = {'headers' => {'Message-ID' => '<'.$time.'@wwsympa>'},
		 'from'=> $param->{'user'}{'email'}};

     $data->{'body'} = sprintf ("QUIET CONFIRM %s\n",$in{'authkey'});

     my $queueauth = &Conf::get_robot_conf($robot, 'queueauth');
     my $filemsg = "$queueauth/$list->{'name'}_$in{'authkey'}";

     ## For compatibility concerns
     foreach my $list_id ($list->get_list_id(),$list->{'name'}) {
	 $filemsg = $queueauth.'/'.$list_id.'_'.$in{'authkey'};
	 last if (-f $filemsg);
     }

     unless ($filemsg && (-r $filemsg)) {
	 &report::reject_report_web('intern','update_subscriber_db_failed',{'key' => $in{'authkey'}},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('err', 'do_tag_topic_by_sender: Unable to find message %s from %s, auth failed', $in{'authkey'},$param->{'user'}{'email'});
	 return undef;
     }

     unless (&mail::mail_file('',&Conf::get_robot_conf($robot, 'sympa'),$data,$robot)) {
	 &report::reject_report_web('intern','cannot_send_mail',{'from' => $param->{'user'}{'email'},'listname'=>$list->{'name'}},
				    $param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('err','do_tag_topic_by_sender: failed to send message for file %s', $filemsg);
	 return undef;
     }

     &report::notice_report_web('performed_soon',{},$param->{'action'});
     return 'info';
 }



 sub do_search_user {
     &wwslog('info', 'do_search_user');

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_search_user: no user');
	 return 'serveradmin';
     }

     unless ($param->{'is_listmaster'}) {
	 &report::reject_report_web('auth','action_listmaster',{},$param->{'action'},$list);
	 &wwslog('info','do_search_user: requires listmaster privilege');
	 return undef;
     }

     unless ($in{'email'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'email'},$param->{'action'});
	 &wwslog('info','do_search_user: no email');
	 return undef;
     }elsif ($in{'email'} =~ /[<>\\\*\$]/) {
	 &report::reject_report_web('user','syntax_errors',{'params' => 'email'},$param->{'action'});
	 &wwslog('err','do_search_user: syntax error');
	 return undef;
     }

     foreach my $role ('member','owner','editor') {
	 foreach my $list ( &List::get_which($in{'email'},$robot, $role) ) {
	     my $l = $list->{'name'};

	     next unless (defined $list);
	     $param->{'which'}{$l}{'subject'} = $list->{'admin'}{'subject'};
	     $param->{'which'}{$l}{'host'} = $list->{'admin'}{'host'};

	     # show the requestor role not the requested one
	     if ( ($list->am_i('owner',$param->{'user'}{'email'}) || $list->am_i('editor',$param->{'user'}{'email'})) ) {
		 $param->{'which'}{$l}{'admin'} = 1;
	     }

	     if ($role eq 'member') {
		 $param->{'which'}{$l}{'is_member'} = 1;
		 $param->{'which'}{$l}{'reception'} = $list->{'user'}{'reception'};
		 $param->{'which'}{$l}{'include_source'} = $list->{'user'}{'include_source'};
		 $param->{'which'}{$l}{'bounce'} = $list->{'user'}{'bounce'} ;
		 $param->{'which'}{$l}{'topic'} = $list->{'user'}{'topic'} ; 
		 $param->{'which'}{$l}{'included'} =  $list->{'user'}{'included'} if ($list->{'user'}{'included'} == 1)  ;
		 $param->{'which'}{$l}{'subscribed'} = $list->{'user'}{'subscribed'} if ($list->{'user'}{'subscribed'} == 1);
		 my $un = $list->{'user'}{'subscribed'};
#		 $param->{'which'}{$l}{'subscribed'} = 1;

	     }elsif  ($role eq 'owner') {
		 $param->{'which'}{$l}{'is_owner'} = 1;
	     }elsif  ($role eq 'editor') {
		 $param->{'which'}{$l}{'is_editor'} = 1;
	     }
	 }
     }
     
     $param->{'email'} = $in{'email'};

     unless (defined $param->{'which'}) {
	 &report::reject_report_web('user','no_entry',{'email' => $in{'email'}},$param->{'action'});
	 &wwslog('info','do_search_user: no entry for %s', $in{'email'});
	 return 'serveradmin';
     }

     return 1;
 }

 ## Set language
 sub do_set_lang {
     &wwslog('info', 'do_set_lang(%s)', $in{'lang'});

     $param->{'lang'} = $param->{'cookie_lang'} = $in{'lang'};
     &cookielib::set_lang_cookie($in{'lang'},$param->{'cookie_domain'});

     if ($param->{'user'}{'email'}) {
	 if (&List::is_user_db($param->{'user'}{'email'})) {
	     unless (&List::update_user_db($param->{'user'}{'email'}, {'lang' => $in{'lang'}})) {
		  &report::reject_report_web('intern','update_user_db_failed',{'user'=>$param->{'user'}{'email'}},$param->{'action'},'',$param->{'user'}{'email'},$robot);
		 &wwslog('info','do_set_lang: update failed');
		 return undef;
	     }
	 }else {
	     unless (&List::add_user_db({'email' => $param->{'user'}{'email'}, 'lang' => $in{'lang'}})) {
		 &report::reject_report_web('intern','add_user_db_failed',{'user'=>$param->{'user'}{'email'}},$param->{'action'},'',$param->{'user'}{'email'},$robot);
		 &wwslog('info','do_set_lang: update failed');
		 return undef;
	     }
	 }
     }

     if ($in{'previous_action'}) {
	 $in{'list'} = $in{'previous_list'};
	 return $in{'previous_action'};
     }

     return 'home';
 }
 ## Function do_attach
 sub do_attach {
     &wwslog('info', 'do_attach(%s,%s)', $in{'dir'},$in{'file'});


     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','attach: no list');
	 return undef;
     }

     ### Useful variables

     # current list / current shared directory
     my $list_name = $list->{'name'};

     # path of the urlized directory
     my $urlizeddir =  $list->{'dir'}.'/urlized';

     # document to read
     my $doc = $urlizeddir.'/'.$in{'dir'}.'/'.$in{'file'};

     ### Document exist ? 
     unless (-e "$doc") {
	 &wwslog('info',"do_attach : unable to read $doc : no such file or directory");
	 &report::reject_report_web('user','no_such_document',{'path' => $in{'dir'}.'/'.$in{'file'}},$param->{'action'},$list);
	 return undef;
     }

     ### Document has non-size zero?
     unless (-s "$doc") {
	 &wwslog('info',"do_attach : unable to read $doc : empty document");
	 &report::reject_report_web('user','empty_document',{'path' => $in{'dir'}.'/'.$in{'file'}},$param->{'action'},$list);
	 return undef;
     }

     ## Access control
     return undef unless (defined &check_authz('do_attach', 'web_archive.access'));

     # parameters for the template file
     # view a file 
     $param->{'file'} = $doc;
     $param->{'bypass'} = 'asis';

     ## File type
     if ($in{'file'} =~ /\.(\w+)$/) {
	 $param->{'file_extension'} = $1;
     }

     return 1;
 }

 sub do_subindex {
     &wwslog('info', 'do_subindex');

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_subindex: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'},$list);
	 &wwslog('info','do_subindex: no user');
	 $param->{'previous_action'} = 'modindex';
	 $param->{'previous_list'} = $in{'list'};
	 return 'loginrequest';
     }

     unless ($list->am_i('owner', $param->{'user'}{'email'})) {
	 &report::reject_report_web('auth','action_owner',{},$param->{'action'},$list);
	 &wwslog('info','do_subindex: %s not owner', $param->{'user'}{'email'});
	 return 'admin';
     }


     my $subscriptions = $list->get_subscription_requests();
     foreach my $sub (keys %{$subscriptions}) {
	 $subscriptions->{$sub}{'date'} = &POSIX::strftime("%d %b %Y", localtime($subscriptions->{$sub}{'date'}));
     }

     $param->{'subscriptions'} = $subscriptions;

     return 1;
 }

 sub do_ignoresub {
     &wwslog('info', 'do_ignoresub');

     my @users;

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_ignoresub: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'},$list);
	 &wwslog('info','do_ignoresub: no user');
	 $param->{'previous_action'} = 'modindex';
	 $param->{'previous_list'} = $in{'list'};
	 return 'loginrequest';
     }

     unless ($list->am_i('owner', $param->{'user'}{'email'})) {
	 &report::reject_report_web('auth','action_owner',{},$param->{'action'},$list);
	 &wwslog('info','do_ignoresub: %s not owner', $param->{'user'}{'email'});
	 return 'admin';
     }

     foreach my $pair (split /\0/, $in{'pending_email'}) {
	 if ($pair =~ /,/) {
	     push @users, $`;
	 }
     }

     foreach my $u (@users) {
	 unless ($list->delete_subscription_request($u)) {
	     &report::reject_report_web('intern','del_sub_request',{'sub'=>$u},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	     &wwslog('info','do_ignoresub: delete_subscription_request(%s) failed', $u);
	     return 'subindex';
	 }
     }

     return 'subindex';
 }

 sub do_change_identity {
     &wwslog('info', 'do_change_identity(%s)', $in{'email'});

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'});
	 &wwslog('info','do_change_identity: no user');
	 return $in{'previous_action'};
     }

     unless ($in{'email'}) {
	 &report::reject_report_web('user','no_email',{},$param->{'action'});
	 &wwslog('info','do_change_identity: no email');
	 return $in{'previous_action'};
     }

     unless (&tools::valid_email($in{'email'})) {
	 &report::reject_report_web('user','incorrect_email',{'email' => $in{'email'}},$param->{'action'},$list);
	 &wwslog('info','do_change_identity: incorrect email %s', $in{'email'});
	 return $in{'previous_action'};
     }

     unless ($param->{'alt_emails'}{$in{'email'}}) {
	 &report::reject_report_web('auth','',{},$param->{'action'},$list);
	 &wwslog('info','do_change_identity: may not change email address');
	 return $in{'previous_action'};
     }

     $param->{'user'}{'email'} = $in{'email'};
     $param->{'auth'} = $param->{'alt_emails'}{$in{'email'}};

     return $in{'previous_action'};
 }

 sub do_stats {
     &wwslog('info', 'do_stats');

     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_stats: no list');
	 return undef;
     }

     unless ($param->{'user'}{'email'}) {
	 &report::reject_report_web('user','no_user',{},$param->{'action'},$list);
	 &wwslog('info','do_stats: no user');
	 $param->{'previous_action'} = 'stats';
	 $param->{'previous_list'} = $in{'list'};
	 return 'loginrequest';
     }

     unless ($list->am_i('owner', $param->{'user'}{'email'})) {
	 &report::reject_report_web('auth','action_owner',{},$param->{'action'},$list);
	 &wwslog('info','do_stats: %s not owner', $param->{'user'}{'email'});
	 return 'admin';
     }

     $param->{'shared_size'} = int (($list->get_shared_size + 512)/1024);
     $param->{'arc_size'} = int (($list->get_arc_size($wwsconf->{'arc_path'}) + 512)/1024);

     return 1;
 }


 ## setting the topics list for templates
 sub export_topics {

     my $robot = shift; 
     wwslog ('debug2',"export_topics($robot)");
     my %topics = &List::load_topics($robot);

     unless (defined %topics) {
	 &wwslog('err','No topics defined');
	 return undef;
     }

     ## Remove existing topics
     $param->{'topics'} = undef;

     my $total = 0;
     foreach my $t (sort {$topics{$a}{'order'} <=> $topics{$b}{'order'}} keys %topics) {
	 my $result = &List::request_action ('topics_visibility', $param->{'auth_method'},$robot,
					     {'topicname' => $t, 
					      'sender' => $param->{'user'}{'email'},
					      'remote_host' => $param->{'remote_host'},
					      'remote_addr' => $param->{'remote_addr'}});
	 my $action;
	 $action = $result->{'action'} if (ref($result) eq 'HASH');  
	 next unless ($action =~ /do_it/);

	 my $current = $topics{$t};
	 $current->{'id'} = $t;

	 ## For compatibility reasons
	 $current->{'mod'} = $total % 3;
	 $current->{'mod2'} = $total % 2;

	 push @{$param->{'topics'}}, $current;

	 $total++;
     }

     push @{$param->{'topics'}}, {'id' => 'topicsless',
				  'mod' => $total,
				  'sub' => {}
			      };

     $param->{'topics'}[int($total / 2)]{'next'} = 1;
 }


# output in text/plain format a scenario
sub do_dump_scenario {
     &wwslog('info', "do_dump_scenario($param->{'list'}), $in{'pname'}");
     unless ($param->{'list'}){
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_dump_scenario: no list');
	 return undef;
     }
     unless ($in{'pname'}){
	 &report::reject_report_web('user','missing_arg',{'argument' => 'pname'},$param->{'action'});
	 &wwslog('info','do_dump_scenario: missing scenario name');
	 return undef;
     }
     unless (&List::is_listmaster($param->{'user'}{'email'})) {
	 &report::reject_report_web('auth','action_listmaster',{},$param->{'action'},$list);
	 &wwslog('info','do_dump_scenario: reject because not listmaster');
	 return undef;
     }

     ($param->{'dumped_scenario'}, $param->{'scenario_path'}) =  &List::_load_scenario_file($in{'pname'},$robot,$list->{'admin'}{$in{'pname'}}{'name'},$list->{'dir'},'flush');
     $param->{'pname'} = $in{'pname'};
     $param->{'scenario_name'} = $list->{'admin'}{$in{'pname'}}{'name'};
     
     if ($in{'new_scenario_name'}) {
	 # in this case it's a submit.
	 my $scenario_dir = $list->{'dir'}.'/scenari/';
	 my $scenario_file = $scenario_dir.$in{'pname'}.'.'.$in{'new_scenario_name'} ;
	 if ($param->{'dumped_scenario'} eq $in{'new_scenario_content'}){
	     &wwslog('info','do_dump_scenario: scenario unchanged');
	     $param->{'result'} = 'unchanged';
	     return 1;
	 }
	 unless (-d $scenario_dir) {
	     unless (mkdir ($scenario_dir, 0777)) {
		 &do_log('err',"do_dump_scenario: cannot_create_dir %s : %s ", $scenario_dir, $!);
		 &report::reject_report_web('intern','cannot_create_dir',{'file' => $scenario_dir,$param->{'action'},'',$param->{'user'}{'email'}},$robot);
		 return undef;
	     }
	 }
	 unless (open SCENARIO , ">$scenario_file") {
	     &wwslog('info','do_dump_scenario: cannot_open_file %s', $scenario_file);
	     &report::reject_report_web('intern','cannot_open_file',{'file' => $scenario_file,$param->{'action'},'',$param->{'user'}{'email'}},$robot);
	     return undef;
	 }
	 print SCENARIO $in{'new_scenario_content'};
	 close   SCENARIO;  
	 # load the new scenario in the list config.
         if ($in{'new_scenario_name'} eq $in{'scenario_name'}) { 
	     $param->{'result'} = 'success';
	 }else{
	      $param->{'result'} = 'success_new_name';
	 }
     }
     return 1 ;
}

 ## Subscribers' list
 sub do_dump {
     &wwslog('info', "do_dump($param->{'list'})");

     ## Whatever the action return, it must never send a complex html page
     $param->{'bypass'} = 1;
     $param->{'content_type'} = "text/plain";
     $param->{'file'} = undef ; 

     unless ($param->{'list'}) {
	 # any error message must start with 'err_' in order to allow remote Sympa to catch it
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('info','do_dump: no list');
	 return undef;
     }

     ## Access control
     return undef unless (defined &check_authz('do_dump', 'review'));

     $list->dump();
     $param->{'file'} = $list->{'dir'}.'/subscribers.db.dump';

     if ($in{'format'} eq 'light') {
	 unless (open (DUMP,$param->{'file'} )) {
	     &report::reject_report_web('intern','cannot_open_file',{'file' => $param->{'file'}},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	     &wwslog ('info', 'unable to open file %s\n',$param->{'file'} );
	     return undef;
	 }
	 unless (open (LIGHTDUMP,">$param->{'file'}.light")) {
	     &report::reject_report_web('intern','cannot_open_file',{'file' => "$param->{'file'}.light"},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	     &wwslog('err','unable to create file %s.light\n',$param->{'file'} );
	     return undef;
	 }
	 while (<DUMP>){
	     next unless ($_ =~ /^email\s(.*)/);
	     print LIGHTDUMP "$1\n";
	 }
	 close LIGHTDUMP;
	 close DUMP;
	 $param->{'file'} = "$list->{'dir'}/subscribers.db.dump.light";

     }	else {
	 $param->{'file'} = "$list->{'dir'}/select.dump";
	 &wwslog('info','opening %s',$param->{'file'});

	 unless (open (DUMP,">$param->{'file'}")) {
	     &report::reject_report_web('intern','file_update_failed',{},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	     &wwslog('err','unable to create file %s\n',$param->{'file'} );
	     return undef;
	 }

	 if ($in{'format'} eq 'bounce') {
	     do_reviewbouncing();
	     print DUMP "# Exported bouncing subscribers\n";
	     print DUMP "# Email\t\tName\tBounce score\tFirst bounce\tLast bounce\n";
	     foreach my $user (@{$param->{'members'}}){
		 print DUMP "$user->{'email'}\t$user->{'gecos'}\t$user->{'bounce_score'}\t$user->{'first_bounce'}\t$user->{'last_bounce'}\n";
	     }
	 }
	 else {
	     $in{'filter'} = $in{'format'};
	     do_search();
	     print DUMP "# Exported subscribers with search filter \"$in{'format'}\"\n";
	     foreach my $user (@{$param->{'members'}}){
		 print DUMP "$user->{'email'}\t$user->{'gecos'}\n";
	     }
	 }
	 close DUMP;
     }
     return 1;
 }


 ## returns a mailto according to list spam protection parameter
 sub mailto {

     my $list = shift;
     my $email = shift;
     my $gecos = shift;

     my $local; 
     my $domain;

     ($local,$domain) = split ('@',$email);

     $gecos = $email unless ($gecos);

     if ($list->{'admin'}{'spam_protection'} eq 'none') {
	 return("<A HREF=\"mailto:$email\">$gecos</A>");
     }elsif($list->{'admin'}{'spam_protection'} eq 'javascript') {

	 if ($gecos =~ /\@/) {
	     $gecos = "$`\" + \"@\" + \"$'";
	 }

	 my $return = "<script type=\"text/javascript\">
 <!--
 document.write(\"<A HREF=\" + \"mail\" + \"to:\" + \"$local\" + \"@\" + \"$domain\" + \">$gecos<\" + \"/A>\")
 // --></script>";
	 return ($return);
     }elsif($list->{'admin'}{'spam_protection'} eq 'at') {
	 return ("$local AT $domain");
     }
 }

## Returns a spam-protected form of email address
sub get_protected_email_address {
    my ($local_part, $domain_part) = @_;
    
    if($list->{'admin'}{'spam_protection'} eq 'javascript') {

	 my $return = "<script type=\"text/javascript\">
 <!--
 document.write(\"$local_part\" + \"@\" + \"$domain_part\")
 // --></script>";
	 return ($return);
     }elsif($list->{'admin'}{'spam_protection'} eq 'at') {
	 return ("$local_part AT $domain_part");
     }else {
	 return($local_part.'@'.$domain_part);
     }
    
}

 ## view logs stored in RDBMS
 ## this function as been writen in order to allow list owner and listmater to views logs
 ## of there robot or there is real problems with privacy policy and law in such services.
 ## 
 sub do_viewlogs {
     &wwslog('info', 'do_viewlogs()');

     my $list = new List ($param->{'list'}, $robot);

     unless ($param->{'is_listmaster'}) {
	 &report::reject_report_web('auth','action_listmaster',{},$param->{'action'});
	 &wwslog('info','do_viewlogs may_not from %s in list %s', $param->{'user'}{'email'}, $param->{'list'});
	 # &List::db_log('wwsympa',$param->{'user'}{'email'},$param->{'auth_method'},$ip,'viewlogs',$param->{'list'},$robot,'','may not');
	 return undef;
     }
     my @lines;
     my $select = ('list'=> $param->{'list'},'robot'=> $param->{'robot'});

     for (my $line = &List::get_first_db_log($select); $line; $line = &List::get_next_db_log()) {
	 # $line->{'date'} = &POSIX::strftime("%d %b %Y %H:%M:%S", $line->{'date'} );

	 push @lines, sprintf ('%s %8s %15s@%20s %20s %25s %5s %s %s %s',$line->{'date'},$line->{'process'},$line->{'list'},$line->{'robot'},$line->{'ip'},$line->{'email'},$line->{'auth'},$line->{'operation'}, $line->{'operation_arg'}, $line->{'status'}); 
     }
     $param->{'log_entries'} = \@lines;

     return 1;
 }

sub do_arc_manage {
    &wwslog('info', "do_arc_manage ($in{'list'})");

    my $search_base = $wwsconf->{'arc_path'}.'/'.$list->get_list_id();
    opendir ARC, "$search_base";
    foreach my $dir (sort {$b cmp $a} grep(!/^\./,readdir ARC)) {
	if ($dir =~ /^(\d{4})-(\d{2})$/) {
	    push @{$param->{'yyyymm'}}, $dir;
	}
    }
    closedir ARC;
    
    return 1;
}

## create a zip file with archives from (list,month)
sub do_arc_download {
    
    &wwslog('info', "do_arc_download ($in{'list'})");
    
    ##check access rights
    unless($param->{'is_owner'} || $param->{'is_listmaster'}) {
	&report::reject_report_web('auth','action_listmaster_or_owner',{},$param->{'action'},$list);
	&wwslog('info','do_arc_download : not listmaster or list owner');
	return undef;
    }
    
    ##zip file name:listname_archives.zip  
    my $zip_file_name = $in{'list'}.'_archives.zip';
    my $zip_abs_file = $Conf{'tmpdir'}.'/'.$zip_file_name;
    my $zip = Archive::Zip->new();
    
    #Search for months to put in zip
    unless (defined($in{'directories'})) {
	&report::reject_report_web('user','select_month',{},$param->{'action'});
	&wwslog('info','do_arc_download : no archives specified');
	return 'arc_manage';
    }
    
    #for each selected month
    foreach my $dir (split/\0/, $in{'directories'}) {
	## Tainted vars problem
	if  ($dir =~ /^(\d+\-\d+)$/) {
	    $dir = $1;
	}

	my $abs_dir = $wwsconf->{'arc_path'}.'/'.$list->get_list_id().'/'.$dir.'/arctxt';
	##check arc directory
	unless (-d $abs_dir) {
	    &report::reject_report_web('intern','arc_not_found',{'arc_file' => $dir,
								 'listname' => $in{'list'},
							         'path' => $abs_dir},
				       $param->{'action'},'',$param->{'user'}{'email'},$robot);
	    &wwslog('info','archive %s not found',$dir);
	    next;
	}
	
	$zip->addDirectory($abs_dir, $in{'list'}.'_'.$dir);

	unless (opendir SPOOL, $abs_dir) {
	    &report::reject_report_web('intern','cannot_open_dir',{'dir' =>$abs_dir },$param->{'action'},'',$param->{'user'}{'email'},$robot);
	    &wwslog('info','do_arc_download: unable to open %s', $abs_dir);
	    return undef;
	}
	
	foreach my $msg (sort grep(!/^\./, readdir SPOOL)) { 
	    unless ($zip->addFile ($abs_dir.'/'.$msg, $in{'list'}.'_'.$dir.'/'.$msg)) {
		&report::reject_report_web('intern','add_file_zip',{'file' => "$abs_dir/$msg"},$param->{'action'},'',$param->{'user'}{'email'},$robot);
		&wwslog('info','do_arc_download: failed to add %s file to archive', $abs_dir.'/'.$msg);
		return undef;
	    }	   
	}

	closedir SPOOL;

	## create and fill a new folder in zip
	#$zip->addTree ($abs_dir, $in{'list'}.'_'.$dir);                           
    }
    
    ## check if zip isn't empty
    if ($zip->numberOfMembers()== 0) {                      
	&report::reject_report_web('intern','inaccessible_archive',{'listname' => $in{'list'}},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	&wwslog('info','Error : empty directories');
	return undef;
    }   
    ##writing zip file
    unless ($zip->writeToFileNamed($zip_abs_file) == AZ_OK){
	&report::reject_report_web('intern','write_file_zip',{'zipfile'=>$zip_abs_file},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	&wwslog ('info', 'Error while writing Zip File %s\n',$zip_file_name);
	return undef;
    }

    ##Sending Zip to browser
    $param->{'bypass'} ='extreme';
    printf("Content-Type: application/zip;\nContent-disposition: filename=\"%s\";\n\n",$zip_file_name);
    ##MIME Header
    unless (open (ZIP,$zip_abs_file)) {
	&report::reject_report_web('intern','cannot_open_file',{'file' => $zip_abs_file},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	&wwslog ('info', 'Error while reading Zip File %s\n',$zip_abs_file);
	return undef;
    }
    print <ZIP>;
    close ZIP ;
    
    ## remove zip file from server disk
    unless (unlink ($zip_abs_file)){     
	&report::reject_report_web('intern','erase_file',{'file' => $zip_abs_file},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	&wwslog ('info', 'Error while unlinking File %s\n',$zip_abs_file);
    }
    
    return 1;
}

sub do_arc_delete {
  
    my @abs_dirs;
    
    &wwslog('info', "do_arc_delete ($in{'list'})");
    
    unless (defined  $in{'directories'}){
      	&report::reject_report_web('user','select_month',{},$param->{'action'});
	&wwslog('info','No Archives months selected');
	return 'arc_manage';
    }
    
    ## if user want to download archives before delete
    &wwslog('notice', "ZIP: $in{'zip'}");
    if ($in{'zip'} == 1) {
	&do_arc_download();
    }
  
    
    foreach my $dir (split/\0/, $in{'directories'}) {
	push(@abs_dirs ,$wwsconf->{'arc_path'}.'/'.$list->get_list_id().'/'.$dir);
    }

    unless (tools::remove_dir(@abs_dirs)) {
	&wwslog('info','Error while Calling tools::remove_dir');
    }
    
    &report::notice_report_web('performed',{},$param->{'action'});
    return 'arc_manage';
}

sub do_css {
    &wwslog('debug', "do_css ($in{'file'})");		
    $param->{'bypass'} = 'extreme';
    printf "Content-type: text/css\n\n";
    $param->{'css'} = $in{'file'}; 

    my $lang = &Language::Lang2Locale($param->{'lang'});
    my $tt2_include_path = &tools::make_tt2_include_path($robot,'web_tt2',$lang,'');

    unless (&tt2::parse_tt2($param,'css.tt2' ,\*STDOUT, $tt2_include_path)) {
	my $error = &tt2::get_error();
	$param->{'tt2_error'} = $error;
	&List::send_notify_to_listmaster('web_tt2_error', $robot, [$error]);
	&wwslog('info', "do_css/$in{'file'} : error");
    }
    
    return;
}

sub do_rss_request {
	&wwslog('info', "do_rss_request");

	my $args ;

	$in{'count'} ||= 20; 
	$in{'for'} ||= 10;

        $args  = 'count='.$in{'count'}.'&' if ($in{'count'}) ;
        $args .= 'for='.$in{'for'} if ($in{'for'});
	if ($list ) {
   		$param->{'latest_arc_url'} = &Conf::get_robot_conf($robot, 'wwsympa_url')."/rss/latest_arc/".$list->{'name'}."?".$args;
		$param->{'latest_d_read_url'} = &Conf::get_robot_conf($robot, 'wwsympa_url')."/rss/latest_d_read/".$list->{'name'}."?".$args;
	}
	$param->{'active_lists_url'} = &Conf::get_robot_conf($robot, 'wwsympa_url')."/rss/active_lists?".$args;
	$param->{'latest_lists_url'} = &Conf::get_robot_conf($robot, 'wwsympa_url')."/rss/latest_lists?".$args;	

	$param->{'output'} = 1;
	return 1;
}

sub do_wsdl {
  
    &wwslog('info', "do_wsdl ()");
    my $sympawsdl = '--ETCBINDIR--/sympa.wsdl';

    unless (-r $sympawsdl){
      	&report::reject_report_web('intern','err_404',{},$param->{'action'});
	&wwslog('err','could not find $sympawsdl');
	return undef;
    }

    my $soap_url= &Conf::get_robot_conf($robot,'soap_url');
    unless (defined $soap_url) {
	&report::reject_report_web('user','no_soap_service',{},$param->{'action'});
	&wwslog('err','No SOAP service was defined in sympa.conf (soap_url parameter)');
	return undef;
    }

    $param->{'bypass'} = 'extreme';
    printf "Content-type: text/xml\n\n";
    
   $param->{'conf'}{'soap_url'}  = $soap_url;

    &tt2::parse_tt2($param, 'sympa.wsdl' , \*STDOUT, ['--ETCBINDIR--']);
    
#    unless (open (WSDL,$sympawsdl)) {
# 	&error_message('404');
# 	&wwslog('info','could not open $sympawsdl');
# 	return undef;	
#     }
#    print <WSDL>;
#     close WSDL;
    return 1;
}
		
## Synchronize list members with data sources
sub do_sync_include {
    &wwslog('info', "do_sync_include($in{'list'})");
 
    unless (defined $list) {
	&report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	&wwslog('err','do_sync_include: no list');
	return undef;
    }

    unless ($param->{'is_owner'}) {
	&report::reject_report_web('auth','action_owner',{},$param->{'action'},$list);
	&wwslog('info','do_sync_include: not owner');
	return undef;
    }
    
    unless ($list->sync_include()) {
	&report::reject_report_web('intern','sync_include_failed',{},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	return undef;
    }
    &report::notice_report_web('subscribers_updated',{},$param->{'action'});
    return 'review';
}

## Review lists from a family
sub do_review_family {
    &wwslog('info', 'do_review_family');

    unless ($param->{'user'}{'email'}) {
	&report::reject_report_web('user','no_user',{},$param->{'action'});
	&wwslog('info','do_review_family: no user');
	$param->{'previous_action'} = 'serveradmin';
	return 'loginrequest';
     }
    
    unless ($param->{'is_listmaster'}) {
	&report::reject_report_web('auth','action_listmaster_or_owner',{},$param->{'action'},$list);
	&wwslog('err','do_review_family: %s not listmaster', $param->{'user'}{'email'});
	return undef;
    }

    unless ($in{'family_name'}) {
	&report::reject_report_web('user','missing_arg',{'argument' => 'family name'},$param->{'action'});
	&wwslog('err','do_review_family: no family');
	return undef;
    }

    my $family = new Family ($in{'family_name'}, $robot);
    unless (defined $family) {
	&report::reject_report_web('user','unknown_family',{'family'=>$in{'family_name'}},$param->{'action'},'',$param->{'user'}{'email'},$robot);
	&wwslog('err', 'do_review_family: incorrect family %s', $in{'family_name'});
	return undef;	
    }

    my $all_lists = $family->get_family_lists();
    foreach my $flist (@{$all_lists}) {
	my $l = $list->{'name'};
	
	unless (defined $flist) {
	    &wwslog('err', 'do_review_family: incorrect list %s', $l);
	    next;	    
	}
	push @{$param->{'family_lists'}}, {'name' => $flist->{'name'},
					   'status' => $flist->{'admin'}{'status'},
					   'instantiation_date' => $flist->{'admin'}{'latest_instantiation'}{'date'},
					   'subject' => $flist->{'admin'}{'subject'},
				       };
    }

    return 1;
}

## Prepare subscriber data to be prompted on the web interface
## Used by review, search,...
sub _prepare_subscriber {
    my $user = shift;
    my $additional_fields = shift;
    my $sources = shift;

    ## Add user
    $user->{'date'} = &POSIX::strftime("%d %b %Y", localtime($user->{'date'}));
    $user->{'update_date'} = &POSIX::strftime("%d %b %Y", localtime($user->{'update_date'}));
    
    ## Reception mode and topics
    $user->{'reception'} ||= 'mail';
    if (($user->{'reception'} eq 'mail') &&  $user->{'topics'}) {
	$user->{'reception'} = "topic ($user->{'topics'})";
    }
    
    $user->{'email'} =~ /\@(.+)$/;
    $user->{'domain'} = $1;
    
    ## Escape some weird chars
    $user->{'escaped_email'} = &tools::escape_chars($user->{'email'});
    
    ## Check data sources
    if ($user->{'id'}) {
	my @s;
	     my @ids = split /,/,$user->{'id'};
	foreach my $id (@ids) {
	    unless (defined ($sources->{$id})) {
		$sources->{$id} = $list->search_datasource($id);
	    }
	    push @s, $sources->{$id};
	}
	$user->{'sources'} = join ', ', @s;
    }
    
    if (@{$additional_fields}) {
	my @fields;
	foreach my $f (@{$additional_fields}) {
	    push @fields, $user->{$f};
	}
	$user->{'additional'} = join ',', @fields;
    }
    
    return 1;
}

## New d_read function using SharedDocument module
## The following features should be tested : 
##      * inheritance on privileges
##      X moderation
##      * escaping special chars
sub new_d_read {
     &wwslog('info', 'new_d_read(%s)', $in{'path'});

     ### action relative to a list ?
     unless ($param->{'list'}) {
	 &report::reject_report_web('user','missing_arg',{'argument' => 'list'},$param->{'action'});
	 &wwslog('err','do_d_read: no list');
	 return undef;
     }

     # current list / current shared directory
     my $list_name = $list->{'name'};

     my $document = new SharedDocument ($list, $in{'path'}, $param);

     unless (defined $document) {
	 &report::reject_report_web('intern','new_document_failed',{'path'=>$in{'path'}},$param->{'action'},$list,$param->{'user'}{'email'},$robot);
	 &wwslog('err',"d_read : cannot open $document->{'absolute_path'} : $!");
	 return undef;	 
     }

     my $path = $document->{'path'};
     my $visible_path = $document->{'visible_path'};
     my $shareddir = $document->{'shared_dir'};
     my $doc = $document->{'absolute_path'};
     my $ref_access = $document->{'access'}; my %access = %{$ref_access};
     $param->{'doc_owner'} = $document->{'owner'};
     $param->{'doc_title'} = $document->{'title'};
     $param->{'doc_date'} = $document->{'date'};

     ### Access control    
     unless ($access{'may'}{'read'}) {
	 &report::reject_report_web('auth',$access{'reason'}{'read'},{},$param->{'action'},$list);
	 &wwslog('err','d_read : access denied for %s', $param->{'user'}{'email'});
	 return undef;
     }

     my $may_edit = $access{'may'}{'edit'};
     my $may_control = $access{'may'}{'control'};
     $param->{'may_edit'} = $may_edit;	
     $param->{'may_control'} = $may_control;

     ### File or directory ?
     if ($document->{'type'} eq 'url') { 
	 $param->{'file_extension'} = $document->{'file_extension'};
	 $param->{'redirect_to'} = $document->{'url'};
	 return 1;

     }elsif ($document->{'type'} eq 'file') {
	 $param->{'file'} = $document->{'absolute_path'};
	 $param->{'bypass'} = 1;
	 return 1;	 

     }else { # directory
     
	 $param->{'empty'} = $#{$document->{'subdir'}} == -1;
     
	 # subdirectories hash
	 my %subdirs;
	 # file hash
	 my %files;
	 
	 ## for the exception of index.html
	 # name of the file "index.html" if exists in the directory read
	 my $indexhtml;
	 
	 # boolean : one of the subdirectories or files inside
	 # can be edited -> normal mode of read -> d_read.tt2;
	 my $normal_mode;	 
	 
	 my $path_doc;
	 my %desc_hash;
	 my $may, my $def_desc;
	 
	 foreach my $subdocument (@{$document->{'subdir'}}) {
	     
	     my $d = $subdocument->{'filename'};	     
	     my $path_doc = $subdocument->{'path'};
	     
	     ## Subdir
	     if ($subdocument->{'type'} eq 'directory') {
		 
		 if ($subdocument->{'access'}{'may'}{'read'}) {
		     
		     $subdirs{$d} = $subdocument->dup();
		     $subdirs{$d}{'doc'} = $subdocument->{'visible_filename'};
		     $subdirs{$d}{'escaped_doc'} =  $subdocument->{'escaped_filename'};
		     
		     if ($param->{'user'}{'email'}) {
			 if ($subdocument->{'access'}{'may'}{'control'} == 1) {
			     
			     $subdirs{$d}{'edit'} = 1;  # or = $may_action_edit ?
			     # if index.html, must know if something can be edit in the dir
			     $normal_mode = 1;                         
			 }elsif ($subdocument->{'access'}{'may'}{'edit'} != 0) {
			     # $may_action_edit = 0.5 or 1 
			     $subdirs{$d}{'edit'} = $subdocument->{'access'}{'may'}{'edit'};
			     # if index.html, must know if something can be edit in the dir
			     $normal_mode = 1;
			 }
			 
			 if  ($subdocument->{'access'}{'may'}{'control'}) {
			     $subdirs{$d}{'control'} = 1;
			 }
		     }
		 }
	     }else {
		 # case file
		 
		 if ($subdocument->{'access'}{'may'}{'read'}) {
		     
		     $files{$d} = $subdocument->dup();

		     $files{$d}{'doc'} = $subdocument->{'visible_filename'};
		     $files{$d}{'escaped_doc'} =  $subdocument->{'escaped_filename'};

		     ## exception of index.html
		     if ($d =~ /^(index\.html?)$/i) {
			 $indexhtml = $1;
		     }
		     
		     if ($param->{'user'}{'email'}) {
			 if ($subdocument->{'access'}{'may'}{'edit'} == 1) {
			     $normal_mode = 1;
			     $files{$d}{'edit'} = 1;  # or = $may_action_edit ? 
			 } elsif ($subdocument->{'access'}{'may'}{'edit'}  != 0){
			     # $may_action_edit = 1 or 0.5
			     $normal_mode = 1;
			     $files{$d}{'edit'} = $subdocument->{'access'}{'may'}{'edit'};
			 }
			 
			 if ($subdocument->{'access'}{'may'}{'control'}) { 
			     $files{$d}{'control'} = 1;    
			 }
		     }
		 }
	     }
	 }

	 ### Exception : index.html
	 if ($indexhtml) {
	     unless ($normal_mode) {
		 $param->{'file_extension'} = 'html';
		 $param->{'bypass'} = 1;
		 $param->{'file'} = $document->{'absolute_path'};
		 return 1;
	     }
	 }

	 ## to sort subdirs
	 my @sort_subdirs;
	 my $order = $in{'order'} || 'order_by_doc';
	 $param->{'order_by'} = $order;
	 foreach my $k (sort {by_order($order,\%subdirs)} keys %subdirs) {
	     push @sort_subdirs, $subdirs{$k};
	 }

	 ## to sort files
	 my @sort_files;
	 foreach my $k (sort {by_order($order,\%files)} keys %files) {
	     push @sort_files, $files{$k};
	 }

	 # parameters for the template file
	 $param->{'list'} = $list_name;

	 $param->{'father'} = $document->{'father_path'};
	 $param->{'escaped_father'} = $document->{'escaped_father_path'} ;
	 $param->{'description'} = $document->{'title'};
	 $param->{'serial_desc'} = $document->{'serial_desc'};	 
	 $param->{'path'} = $document->{'path'};
	 $param->{'visible_path'} = $document->{'visible_path'};
	 $param->{'escaped_path'} = $document->{'escaped_path'};

	 if (scalar keys %subdirs) {
	     $param->{'sort_subdirs'} = \@sort_subdirs;
	 }
	 if (scalar keys %files) {
	     $param->{'sort_files'} = \@sort_files;
	 }
     }
     $param->{'father_icon'} = $icon_table{'father'};
     $param->{'sort_icon'} = $icon_table{'sort'};


    ## Show expert commands / user page
    
    # for the curent directory
    if ($may_edit == 0 && $may_control == 0) {
	$param->{'has_dir_rights'} = 0;
    } else {
	$param->{'has_dir_rights'} = 1;
	if ($may_edit == 1) { # (is_author || ! moderated)
	    $param->{'total_edit'} = 1;
	}
    }

    # set the page mode
    if ($in{'show_expert_page'} && $param->{'has_dir_rights'}) {
	$param->{'expert_page'} = 1;
	&cookielib::set_expertpage_cookie(1,$param->{'cookie_domain'});
 
    } elsif ($in{'show_user_page'}) {
	$param->{'expert_page'} = 0;
	&cookielib::set_expertpage_cookie(0,$param->{'cookie_domain'});
    } else {
	if (&cookielib::check_expertpage_cookie($ENV{'HTTP_COOKIE'}) && $param->{'has_dir_rights'}) {
	    $param->{'expert_page'} = 1; 
	} else {
	    $param->{'expert_page'} = 0;
	}
    }
    
     open TMP, ">/tmp/dump";
     $document->dump(\*TMP);
     close TMP;

     open TMP, ">/tmp/dump2";
     &tools::dump_var ($param, 0, \*TMP);
     close TMP;

     return 1;
}


## Check authorizations to the current action
## used in common cases where actions fails unless result is 'do_it'
## It does not apply to actions that can be moderated
sub check_authz {
    my ($subname, $action) = @_;
    
    my $sender = $param->{'user'}{'email'} || 'nobody';
    my $result = $list->check_list_authz($action,$param->{'auth_method'},
					 {'sender' => $param->{'user'}{'email'},
					  'remote_host' => $param->{'remote_host'},
					  'remote_addr' => $param->{'remote_addr'}});
    my $r_action;
    my $reason;
    if (ref($result) eq 'HASH') {
	$r_action = $result->{'action'};
	$reason = $result->{'reason'};
    }
    
    unless ($r_action =~ /do_it/i) {
	&report::reject_report_web('auth',$reason,{'login'=> $param->{'need_login'}},$param->{'action'});
	&wwslog('info','check_authz: access denied in %s for %s', $subname, $param->{'user'}{'email'});
	return undef;
    }
    
    return 1;
}

sub get_icon {
    my $type = shift;

    return $icon_table{$type};
}

sub get_mime_type {
    my $type = shift;

    return $mime_types->{$type};
}

sub do_maintenance {
    &wwslog('notice', 'do_maintenance()');
    
    return 1;
}


######################################################################
# OpenFoundry
######################################################################


# modified from "do_lists"
 sub do_lists_by_project {
     my @lists;
     &wwslog('info', 'do_lists(%s,%s)', $in{'topic'}, $in{'subtopic'});

     my %topics = &List::load_topics($robot);

     if ($in{'topic'}) {
        $param->{'topic'} = $in{'topic'};
        if ($in{'subtopic'}) {
            $param->{'subtopic'} = $in{'subtopic'};
            $param->{'subtitle'} = sprintf "%s / %s", $topics{$in{'topic'}}{'current_title'}, $topics{$in{'topic'}}{'sub'}{$in{'subtopic'}}{'current_title'};

            $param->{'subtitle'} ||= "$in{'topic'} / $in{'subtopic'}";
        }else {
            $param->{'subtitle'} = $topics{$in{'topic'}}{'current_title'} || $in{'topic'};
        }
     }

# OpenFoundry
my $project = $in{'projectUnixName'} || '';
$param->{'projectUnixName'} = $project;
$param->{'FOUNDRY_ROLE'} = $in{'FOUNDRY_ROLE'};
my $all_lists = &List::get_lists_by_prefix($robot, undef, [ $project ]);
     foreach my $list ( @$all_lists ) {

        my $sender = $param->{'user'}{'email'} || 'nobody';

        my $result = $list->check_list_authz('visibility',$param->{'auth_method'},
                                             {'sender' => $sender,
                                              'remote_host' => $param->{'remote_host'},
                                              'remote_addr' => $param->{'remote_addr'}});

        my $r_action;
        $r_action = $result->{'action'} if (ref($result) eq 'HASH');

        next unless ($r_action eq 'do_it');

        my $list_info = {};
        $list_info->{'subject'} = $list->{'admin'}{'subject'};
        $list_info->{'host'} = $list->{'admin'}{'host'};
        $list_info->{'date_epoch'} = $list->{'admin'}{'creation'}{'date_epoch'};
        $list_info->{'date'} = $list->{'admin'}{'creation'}{'date'};
        if ($param->{'user'}{'email'} &&
            ($list->am_i('owner',$param->{'user'}{'email'}) ||
             $list->am_i('editor',$param->{'user'}{'email'})) ) {
            $list_info->{'admin'} = 1;
        }
        if ($param->{'user'}{'email'} &&
            $list->is_user($param->{'user'}{'email'})) {
            $list_info->{'is_subscriber'} = 1;
        }

        ## no topic ; List all lists
        if (! $in{'topic'}) {
            $param->{'which'}{$list->{'name'}} = $list_info;
        }elsif ($list->{'admin'}{'topics'}) {
            foreach my $topic (@{$list->{'admin'}{'topics'}}) {
                my @tree = split '/', $topic;

                next if (($in{'topic'}) && ($tree[0] ne $in{'topic'}));
                next if (($in{'subtopic'}) && ($tree[1] ne $in{'subtopic'}));

                $param->{'which'}{$list->{'name'}} = $list_info;
            }
        }elsif ($in{'topic'} eq 'topicsless') {
            $param->{'which'}{$list->{'name'}} = $list_info;
        }
     }
     return 1;
 }



# modified from do_create_list_request
 sub do_create_project_list_request {
     &wwslog('info', 'do_create_project_list_request()');

     unless ($param->{'user'}{'email'}) {
        &report::reject_report_web('user','no_user',{},$param->{'action'});
        &wwslog('info','do_create_project_list_request:  no user');
        $param->{'previous_action'} = 'create_list_request';
        return 'loginrequest';
     }

     my $result = &List::request_action('create_list',$param->{'auth_method'},$robot,
                                                      {'sender' => $param->{'user'}{'email'},
                                                       'remote_host' => $param->{'remote_host'},
                                                       'remote_addr' => $param->{'remote_addr'}});

     my $r_action;
     my $reason;
     if (ref($result) eq 'HASH') {
        $r_action = $result->{'action'};
        $reason = $result->{'reason'};
     }

     $param->{'create_action'} = $r_action;
# OpenFoundry
$param->{'prefix'} = $in{'projectUnixName'};
     ## Initialize the form
     ## When returning to the form
     foreach my $p ('listname','template','subject','topics','info') {
        $param->{'saved'}{$p} = $in{$p};
     }

     if ($param->{'create_action'} =~ /reject/) {
        &report::reject_report_web('auth',$reason,{},$param->{'action'},$list);
        &wwslog('info','do_create_list: not allowed');
        return undef;
     }

     my %topics;
     unless (%topics = &List::load_topics($robot)) {
        &report::reject_report_web('intern','unable_to_load_list_of_topics',{},$param->{'action'},'',$param->{'user'}{'email'},$robot);
     }
     $param->{'list_of_topics'} = \%topics;

     $param->{'list_of_topics'}{$in{'topics'}}{'selected'} = 1
        if ($in{'topics'});

     unless ($param->{'list_list_tpl'} = &tools::get_list_list_tpl($robot)) {
        &report::reject_report_web('intern','unable_to_load_create_list_templates',{},$param->{'action'},'',$param->{'user'}{'email'},$robot);
     }

     &tt2::allow_absolute_path();

     foreach my $template (keys %{$param->{'list_list_tpl'}}){
        $param->{'tpl_count'} ++ ;
     }

     $param->{'list_list_tpl'}{$in{'template'}}{'selected'} = 1
        if ($in{'template'});


     return 1 ;

 }



# modified from "do_create_list"
 sub do_create_project_list {

     &wwslog('info', 'do_create_project_list(%s,%s,%s,%s)',$in{'listname'},$in{'subject'},$in{'template'},$in{'projectUnixName'});

     foreach my $arg ('listname','subject','template','info','topics','projectUnixName') {
        unless ($in{$arg}) {
            &report::reject_report_web('user','missing_arg',{'argument' => $arg},$param->{'action'});
            &wwslog('info','do_create_list: missing param %s', $arg);
            return undef;
        }
     }


# OpenFoundry
# print STDERR "role is ...................................... ###$in{'FOUNDRY_ROLE'}###\n";
unless ($in{'FOUNDRY_ROLE'} eq 'Admin') {
    &report::reject_report_web('auth', "action_project_administrator",{},$param->{'action'},$list);
    &wwslog('info','do_create_list: not allowed');
    return undef;
}


     unless ($param->{'user'}{'email'}) {
        &report::reject_report_web('user','no_user',{},$param->{'action'});
        &wwslog('info','do_create_list :  no user');
        return 'loginrequest';
     }

     $param->{'create_action'} = $param->{'create_list'};

     &wwslog('info',"do_create_list, get action : $param->{'create_action'} ");

     if ($param->{'create_action'} =~ /reject/) {
        &report::reject_report_web('auth',$param->{'reason'},{},$param->{'action'},$list);
        &wwslog('info','do_create_list: not allowed');
        return undef;
     }elsif ($param->{'create_action'} =~ /listmaster/i) {
        $param->{'status'} = 'pending' ;
     }elsif  ($param->{'create_action'} =~ /do_it/i) {
        $param->{'status'} = 'open' ;
     }else{
        &report::reject_report_web('intern','internal_scenario_error_create_list',{},$param->{'action'},'',$param->{'user'}{'email'},$robot);
        &wwslog('info','do_create_list: internal error in scenario create_list');
        return undef;
     }

     ## 'other' topic means no topic
     $in{'topics'} = undef if ($in{'topics'} eq 'other');

     my %owner;
     $owner{'email'} = $param->{'user'}{'email'};
     $owner{'gecos'} = $param->{'user'}{'gecos'};

     my $parameters;
     push @{$parameters->{'owner'}},\%owner;

# OpenFoundry
$in{'listname'} = $in{'projectUnixName'} . "-" . $in{'listname'};

     $parameters->{'listname'} = $in{'listname'};
     $parameters->{'subject'} = $in{'subject'};
     $parameters->{'creation_email'} = $param->{'user'}{'email'};
     $parameters->{'lang'} = $param->{'lang'};
     $parameters->{'status'} = $param->{'status'};
     $parameters->{'topics'} = $in{'topics'};
     $parameters->{'description'} = $in{'info'};

     ## create liste
     my $resul = &admin::create_list_old($parameters,$in{'template'},$robot);
     unless(defined $resul) {
        &report::reject_report_web('intern','create_list',{},$param->{'action'},'',$param->{'user'}{'email'},$robot);
        &wwslog('info','do_create_list: unable to create list %s for %s',$in{'listname'},$param->{'user'}{'email'});
        return undef
     }
     ## Create list object
     $in{'list'} = $in{'listname'};
     &check_param_in();

     if  ($param->{'create_action'} =~ /do_it/i) {
        if ($resul->{'aliases'} == 1) {
            $param->{'auto_aliases'}  = 1;
        }else {
            $param->{'aliases'} = $resul->{'aliases'};
            $param->{'auto_aliases'} = 0;
        }
     }

     ## notify listmaster
     if ($param->{'create_action'} =~ /notify/) {
        &wwslog('info','notify listmaster');
        unless (&List::send_notify_to_listmaster('request_list_creation',$robot,
                                                 {'listname' => $in{'listname'},
                                                  'email' => $param->{'user'}{'email'}})) {
            &wwslog('notice',"Unable to send notify 'request_list_creation' to listmaster");
        }
     }

     $in{'list'} = $resul->{'list'}{'name'};
     &check_param_in();

     $param->{'listname'} = $resul->{'list'}{'name'};
     return 1;
 }


sub foundry_auth
{
       my ($httpCookie, $projectUnixName) = @_;


       #OpenFoundry::_log("original HTTP_COOKIE: $ENV{HTTP_COOKIE}");
       my %cookies = CGI::Cookie->parse($httpCookie);
       OpenFoundry::_log("Dumper of cookies: ", Dumper(\%cookies));

       my $FOUNDRY_COOKIE_KEY = 'RT_SID_OSSF.80_';

       my $sid = $cookies{$FOUNDRY_COOKIE_KEY} ? $cookies{$FOUNDRY_COOKIE_KEY}->value() : undef;
       my ($userName, $role, $email) = OpenFoundry::getSessionInfo($sid, $projectUnixName);
       if ($userName and ($userName ne 'guest')) # valid foundry user
       {
               #my $email = $of->getUserByName($userName)->{'Email'};
               #$email = 'root@lists.openfoundry.org';
               OpenFoundry::_log("email: $email\n");


               my $secret = $Conf{'cookie'};
               my $mac = cookielib::get_mac($email, $secret);
               OpenFoundry::_log("email: $email secret: $secret mac: $mac");
               $cookies{'sympauser'} ||= new CGI::Cookie(-name=>'sympauser', -value=>'');
               $cookies{'sympauser'}->value("$email:$mac");
       }
       else
       {
               delete $cookies{'sympauser'};
       }


       my @newHeaders = ();
       foreach my $cookie (values %cookies)
       {
               OpenFoundry::_log("name: " . $cookie->name() . " value: " . $cookie->value());
               push @newHeaders, CGI::Util::escape($cookie->name()) . '=' . CGI::Util::escape($cookie->value());
       }
       my $newHttpCookie = join("; ", @newHeaders);
       OpenFoundry::_log("new HTTP_COOKIE: $newHttpCookie");

       return ($newHttpCookie, $role);
}

