#!/usr/bin/perl
use OpenFoundry;
use strict;
use Data::Dumper;

my $of = OpenFoundry->init("RT");
my %conf = %{$of->getConf()};
my $from = "/tmp/svndump";

my $projects = $of->getProjects();
foreach my $p (@{ $of->getProjects() })
{
	if ($p->{VCS} eq 'svn')
	{
		#print $p->{UnixName}, " ";
		my $unixName = $p->{UnixName};
		my $dump = "$from/${unixName}.dump";
		print STDERR "$dump doesn't exist !!\n" if not -f $dump;

		my $to = "$conf{SVN_PARENT_PATH}/$unixName";

		print "svnadmin create $to\n";
		print "time svnadmin --force-uuid load $to < $dump\n";
	}
}

