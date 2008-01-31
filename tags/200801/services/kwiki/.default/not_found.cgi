#!/usr/bin/perl
use strict;
use LWP::Simple qw(get);
use CGI qw(redirect);
use Data::Dumper;

#print "Content-type: text/plain\r\n\r\n";
#print "done\n";
#print Dumper(\%ENV), "\n";

my $projectKwikiBaseDir = "/usr/local/kwiki";

my $urlPrefix = "/Kwiki";
# See: http://rt.openfoundry.org/Edit/Queues/CustomField/index.html?Queue=4&Begin=0&CF=9
my $projectIdPattern = '[a-z][0-9a-z]{2,14}';

# 'REDIRECT_URL' => '/Kwiki/openfoundry';
my ($projectUnixName) = ($ENV{REDIRECT_URL} =~ m|^$urlPrefix/($projectIdPattern)\b|);


# http://kwiki.rt.openfoundry.org:8080/Kwiki/aaaaaaaaaaaaaaaaaaaa
# http://kwiki.rt.openfoundry.org:8080/Kwiki/afafa
# http://kwiki.rt.openfoundry.org:8080/Kwiki/openfoundry


if ($projectUnixName && foundryIsProjectUnixName($projectUnixName) && (not -d "$projectKwikiBaseDir/$projectUnixName"))
{
	`cp -p -R $projectKwikiBaseDir/.sample $projectKwikiBaseDir/$projectUnixName`;
	print redirect("$urlPrefix/$projectUnixName/index.cgi");
}
else
{
	print redirect("http://rt.openfoundry.org");
}

sub foundryIsProjectUnixName
{
	my $isProjectUnixName = get("http://rt.openfoundry.org/NoAuth/IsProjectUnixName.html?projectUnixName=$_[0]");
	chomp $isProjectUnixName;
	return $isProjectUnixName;
}

