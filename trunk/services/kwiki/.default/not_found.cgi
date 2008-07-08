#!/usr/bin/perl
use strict;
use LWP::Simple qw(get);
use CGI qw(redirect);
use Data::Dumper;

#print "Content-type: text/plain\r\n\r\n";
#print "done\n";
#print Dumper(\%ENV), "\n";

#print STDERR "This is 404 handler: ", __FILE__, "\n";

my $projectKwikiBaseDir = "/usr/local/kwiki";

my $urlPrefix = "/kwiki";
# See: http://rt.openfoundry.org/Edit/Queues/CustomField/index.html?Queue=4&Begin=0&CF=9
my $projectIdPattern = '[a-z][0-9a-z]{2,14}';

# 'REDIRECT_URL' => '/Kwiki/openfoundry';
my ($projectUnixName) = ($ENV{REDIRECT_URL} =~ m|^$urlPrefix/($projectIdPattern)\b|);
#print STDERR "projectUnixName: ##$projectUnixName##\n";


# http://kwiki.rt.openfoundry.org:8080/Kwiki/aaaaaaaaaaaaaaaaaaaa
# http://kwiki.rt.openfoundry.org:8080/Kwiki/afafa
# http://kwiki.rt.openfoundry.org:8080/Kwiki/openfoundry


if ($projectUnixName && foundryIsProjectUnixName($projectUnixName) && (not -d "$projectKwikiBaseDir/$projectUnixName"))
{
	# this should be safe ..
	my $cmd = "cp -p -R $projectKwikiBaseDir/.sample $projectKwikiBaseDir/$projectUnixName";
	print STDERR "creating kwiki for '$projectUnixName': $cmd\n";
	system($cmd) == 0 or print STDERR "'system' failed!: $?: $!";
	print redirect("$urlPrefix/$projectUnixName/index.cgi");
}
else
{
	print redirect("http://of.openfoundry.org");
}

# http://of.openfoundry.org/openfoundry/is_project_name?projectname=closefoundry
sub foundryIsProjectUnixName
{
	# TODO: config ..
	my $url = "http://192.168.0.20:3000/openfoundry/is_project_name?projectname=%s";
	my $isProjectUnixName = get(sprintf($url, $_[0]));
	chomp $isProjectUnixName;
	return $isProjectUnixName eq '1';
}

