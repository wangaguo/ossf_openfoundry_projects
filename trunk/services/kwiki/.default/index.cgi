#!/usr/local/bin/perl -w
use lib 'lib';
use Kwiki;


use LWP::Simple qw(get);
use CGI::Cookie ();


my $SESSION_COOKIE_NAME = '_of_session_id';
my $OF_HOST = '192.168.0.20';
my $OF_PORT = '3000';

my $OF_SESSION_URL = "http://$OF_HOST:$OF_PORT/openfoundry/authentication_authorization?SID=%s&projectname=%s";

my $SID_COOKIE = (CGI::Cookie->fetch || {})->{$SESSION_COOKIE_NAME};
my $SID = $SID_COOKIE ? $SID_COOKIE->value() : '';

# 'SCRIPT_FILENAME' => '/tmp/mykwiki3/index.cgi',
my ($projectName) = ($ENV{SCRIPT_FILENAME} =~ m|/([^/]*)/index.cgi$|);
#print STDERR "name: $projectName\n";

print STDERR sprintf($OF_SESSION_URL, $SID, $projectName), "\n";
my $tmp = get(sprintf($OF_SESSION_URL, $SID, $projectName));
my ($userName, $role) = split / /, $tmp; # discard email address
print STDERR "userName: ##$userName## role: ##$role##\n";

$ENV{REMOTE_USER} = $userName || 'guest';
$ENV{FOUNDRY_ROLE} = $role || 'Other';


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
