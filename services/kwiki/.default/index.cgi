#!/usr/local/bin/perl -w
use lib 'lib';
use Kwiki;


use LWP::Simple qw(get);
use CGI::Cookie ();

my $SID_COOKIE = (CGI::Cookie->fetch || {})->{'RT_SID_OSSF.80_'};
my $SID = $SID_COOKIE ? $SID_COOKIE->value() : '';

# 'SCRIPT_FILENAME' => '/tmp/mykwiki3/index.cgi',
my ($projectUnixName) = ($ENV{SCRIPT_FILENAME} =~ m|/([^/]*)/index.cgi$|);
#print STDERR "name: $projectUnixName\n";

my $tmp = get("http://rt.openfoundry.org/NoAuth/Session.html?SID=$SID&projectUnixName=$projectUnixName");
my ($userName, $role) = split / /, $tmp;
#print STDERR "userName: ##$userName## role: ##$role##\n";

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
