#!/usr/bin/perl
use strict;
use OpenFoundry;
my $user = $ENV{'USER'};
my $cvsroot = $ENV{'CVSROOT'};

#/cvs/openfoundry/test####aaa####b.txt

if (my ($project) = $ARGV[0] =~ m#^$cvsroot/([^/]+)#)
{
        exit 1 if not $project;
        exit 1 if $project eq 'CVSROOT';
        my $of = OpenFoundry->init();
	exit(($of->isInRelationByName("admin", $project, $user) || $of->isInRelationByName("member", $project, $user)) ? 0 : 1);
}

exit 1;
