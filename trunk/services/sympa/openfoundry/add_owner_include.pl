#
# find /usr/local/sympa/expl -name "config" | xargs -n 1 perl /usr/local/checkout/trunk/services/sympa/openfoundry/add_owner_include.pl
#

$^I = ".orig";

#print $ARGV[0], "\n";
my ($listName) = $ARGV[0] =~ /([^\/]*)\/config$/;
#print "listName: $listName\n";
my ($projectName) = $listName =~ /^(.*?)-/;
#print "projectName: $projectName\n";
if (not $projectName)
{
	print "empty project name: $ARGV[0]\n";
	exit 0;
}


$/ = "\n\n";
while (<>)
{
        print if (not /^owner$/m);

print <<"EOF" if /^update/;
owner
email listmaster\@lists.openfoundry.org
profile privileged
reception nomail


owner_include
source openfoundry
profile normal
reception mail
source_parameters $projectName

EOF

}

