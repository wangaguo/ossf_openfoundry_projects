#!/usr/bin/perl
use strict;
use OpenFoundry;
use File::Find;
use Carp;
use Fatal qw(chown symlink);

use Data::Dumper;

my $of = OpenFoundry->init();
my %conf = %{ $of->getConf() };

die "cvs directory '$conf{CVSROOT}' dose not exist" if not -d $conf{CVSROOT};
die "svn directory '$conf{SVN_PARENT_PATH}' dose not exist" if not -d $conf{SVN_PARENT_PATH};

my $SVNADMIN_CMD = '/usr/local/bin/svnadmin';


foreach my $p (@{$of->getProjects()})
{
	my $unixName = $p->{UnixName};
	my $vcs = $p->{VCS};
	if ($vcs eq 'cvs') {
		my $dir = "$conf{CVSROOT}/$unixName"; 
		next if -d $dir;

		mkdir $dir;
		chown $conf{CVS_OWNER}, $conf{CVS_GROUP}, $dir;
	} elsif ($vcs eq 'svn') {
		my $dir = "$conf{SVN_PARENT_PATH}/$unixName";
		next if -d $dir;

		print "Creating svn repository in $dir\n";

		system $SVNADMIN_CMD, 'create', $dir
			and croak "Couldn't run: $SVNADMIN_CMD, 'create', $dir : ($!)";
		find(sub { chown $conf{SVN_OWNER}, $conf{SVN_GROUP}, $File::Find::name }, $dir);
		# TODO: chown for db/ only ?

		symlink '../../.default/hooks/pre-commit', "$dir/hooks/pre-commit";
		symlink '../../.default/hooks/pre-revprop-change', "$dir/hooks/pre-revprop-change";
	} else {
		print ".... $p->{UnixName} #$vcs#\n";
	}
}

print "\ndone\n";
