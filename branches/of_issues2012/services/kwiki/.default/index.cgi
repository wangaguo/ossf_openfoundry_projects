#!/usr/local/bin/perl -w
use lib 'lib';
use Kwiki;
use JSON;
# perl -MJSON -MData::Dumper -e 'print Dumper(jsonToObj(q|{"aa": "bb"}|))'


use LWP::Simple qw(get);
use CGI::Cookie ();


my $SESSION_COOKIE_NAME = '_of_new_key_';
my $OF_HOST = 'www.openfoundry.org';
my $OF_PORT = '80';

my $OF_SESSION_URL = "http://$OF_HOST:$OF_PORT/of/openfoundry/authentication_authorization_II?SID=%s&projectname=%s";

my $SID_COOKIE = (CGI::Cookie->fetch || {})->{$SESSION_COOKIE_NAME};
my $SID = $SID_COOKIE ? $SID_COOKIE->value() : '';

# 'SCRIPT_FILENAME' => '/tmp/mykwiki3/index.cgi',
my ($projectName) = ($ENV{SCRIPT_FILENAME} =~ m|/([a-z][0-9a-z]{2,14})/index.cgi$|);
#print STDERR "name: $projectName\n";

my $url = sprintf($OF_SESSION_URL, $SID, $projectName);
my $tmp = get($url);
#print STDERR "url: $url tmp: $tmp\n";

# {"name":"luors","email":"luors@iis.xxx.tw","function_names":["kwiki_manage","ftp_access" ...]}
#
my $data = jsonToObj($tmp) || {}; # old json 1.07
#use Data::Dumper;
#print STDERR Dumper($data);

$ENV{REMOTE_USER} = $data->{"name"} || 'guest';

# global !
our $HAS_KWIKI_MANAGE = grep { $_ eq "kwiki_manage" } @{$data->{"function_names"}};
#print STDERR "HAS_KWIKI_MANAGE: $HAS_KWIKI_MANAGE\n";


Kwiki->new->debug->process('config*.*', -plugins => 'plugins');

__END__
if ($ENV{QUERY_STRING} =~ /debug=1/)
{
use IO::All;
use Data::Dumper;
Dumper(\%ENV) > io('/tmp/env.txt');
}
elsif ($ENV{MYDEBUG})
{
%ENV = %{ do '/tmp/env.txt' };
}
