#!/usr/bin/perl
use strict;
use OpenFoundry;
use Carp;
use Fatal qw(chown symlink);
use File::Path;

my $of = OpenFoundry->init();
my %conf = %{ $of->getConf() };

die "cvs directory '$conf{CVSROOT}' dose not exist" if not -d $conf{CVSROOT};
die "svn directory '$conf{SVN_PARENT_PATH}' dose not exist" if not -d $conf{SVN_PARENT_PATH};
die "no svn backup directory specified: SVN_BACKUP_PATH" if not $conf{SVN_BACKUP_PATH};


my $SVNADMIN_CMD = '/usr/local/bin/svnadmin';

print "Removing $conf{SVN_BACKUP_PATH}\n";
rmtree $conf{SVN_BACKUP_PATH};
mkdir $conf{SVN_BACKUP_PATH};
print "Removed.";

foreach my $p (@{$of->getProjects()})
{
	my $name = $p->{name};
	my $vcs = $p->{vcs};
	if ($vcs eq OpenFoundry::VCS_CVS) {
#		my $dir = "$conf{CVSROOT}/$unixName"; 
#		next if -d $dir;
#
#		mkdir $dir;
#		chown $conf{CVS_OWNER}, $conf{CVS_GROUP}, $dir;
	} elsif ($vcs eq OpenFoundry::VCS_SUBVERSION) {
		my $dir = "$conf{SVN_PARENT_PATH}/$name";
		my $backup_dir = "$conf{SVN_BACKUP_PATH}/$name";
		print "backup svn: $dir => $backup_dir >>>> " .  localtime(), "\n";
		system $SVNADMIN_CMD, 'hotcopy', $dir, $backup_dir
			and carp "Couldn't run: $SVNADMIN_CMD, 'hotcopy', $dir, $backup_dir : ($!)";
		print "backup svn: $dir => $backup_dir <<<< " .  localtime(), "\n";
	} else {
		print ".... $p->{name} #$vcs#\n";
	}
}

print "\ndone\n";
