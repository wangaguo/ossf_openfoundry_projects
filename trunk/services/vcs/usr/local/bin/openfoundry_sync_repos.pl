#!/usr/bin/perl
use strict;
use OpenFoundry;
use File::Find;
use Carp;
use Fatal qw(chown symlink);

use Data::Dumper;

my $of = OpenFoundry->init("RT");
my %conf = %{ $of->getConf() };

die "cvs directory '$conf{CVSROOT}' dose not exist" if not -d $conf{CVSROOT};
die "svn directory '$conf{SVN_PARENT_PATH}' dose not exist" if not -d $conf{SVN_PARENT_PATH};



foreach my $p (@{$of->{'projects'}})
{
	my $unixName = $p->{UnixName};
	my $vcs = $p->{VCS};
	if ($vcs eq 'cvs') {
		my $dir = "$conf{CVSROOT}/$unixName"; 
		mkdir $dir;
		chown $conf{CVS_OWNER}, $conf{CVS_GROUP}, $dir;
	} elsif ($vcs eq 'svn') {
		my $dir = "$conf{SVN_PARENT_PATH}/$unixName";
		next if -d $dir;

		print "Creating svn repository in $dir\n";

		system 'svnadmin', 'create', $dir
			and croak "Couldn't run: 'svnadmin', 'create', $dir : ($!)";
		find(sub { chown $conf{SVN_OWNER}, $conf{SVN_GROUP}, $File::Find::name }, $dir);
		# TODO: chown for db/ only ?

		symlink '../../.default/hooks/pre-commit', "$dir/hooks/pre-commit";
		symlink '../../.default/hooks/pre-revprop-change', "$dir/hooks/pre-revprop-change";
	} else {
		print ".... $p->{UnixName} #$vcs#\n";
	}
}

print "\ndone\n";
