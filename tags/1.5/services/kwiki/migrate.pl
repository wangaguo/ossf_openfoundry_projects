use strict;
use IO::All;
use File::Basename;

my $src = '/tmp/foundry_kwiki';
my $dest = '/usr/local/kwiki';
my $sample = "$dest/.sample";

chdir $src;
my @projects = glob "*";
#print join("##", @projects), "\n";
foreach my $project (@projects)
{
	print "project: $project\n";
#	next if not $project eq 'openfoundry';

#	mkdir "$dest/$project";
#	foreach my $linkSrc (glob "$sample/*")
#	{
#		my $item = basename($linkSrc);
#		next if $item =~ /^(README|database|plugin)$/;
#		symlink "../.default/$item", "$dest/$project/$item";
#	}
	`cp -p -R $sample $dest/$project`;
	`rm -fR $dest/$project/database $dest/$project/plugin`;
	`cp -p -R $src/$project/database $dest/$project/database`;


	io("$dest/$project/plugin/")->assert->mkdir;

	foreach my $p qw(protected private)
	{
		map { io("$dest/$project/plugin/page_privacy/" . basename($_) . "/$p")->assert->touch } glob "$src/$project/metabase/$p/*";
	}

#/tmp/foundry_kwiki/openfoundry/metabase/metadata/
#/tmp/new_kwiki/openfoundry/plugin/page_metadata/
	`cp -p -R $src/$project/metabase/metadata $dest/$project/plugin/page_metadata`;

	`chmod -R 777 "$dest/$project/database" "$dest/$project/plugin"`;

	#exit(1);
}
