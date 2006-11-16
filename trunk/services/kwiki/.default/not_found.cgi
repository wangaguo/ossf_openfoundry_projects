#!/usr/bin/perl
use LWP::Simple qw(get);
use CGI qw(redirect);
use Data::Dumper;

#print "Content-type: text/plain\r\n\r\n";

my $projectKwikiBaseDir = "/tmp/new_kwiki";

# 'REDIRECT_URL' => '/fdfasdfasdfads',
my ($projectUnixName) = ($ENV{REDIRECT_URL} =~ m|/([^/]*)|);

my $isProjectUnixName = get("http://rt.openfoundry.org/NoAuth/IsProjectUnixName.html?projectUnixName=$projectUnixName");
chomp $isProjectUnixName;
if ($isProjectUnixName)
{
	my $dest = "$projectKwikiBaseDir/$projectUnixName"; 
	if (not -d $dest)
	{
		`cp -p -R $projectKwikiBaseDir/.sample $projectKwikiBaseDir/$projectUnixName`;
		print redirect("/$projectUnixName/index.cgi");
		
	}
}
