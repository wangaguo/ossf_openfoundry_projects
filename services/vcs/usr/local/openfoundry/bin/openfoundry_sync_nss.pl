#!/usr/bin/perl
use strict;
use OpenFoundry;
use DBI;

# http://search.cpan.org/~timb/DBI-1.56/DBI.pm
# http://search.cpan.org/dist/DBD-mysql/lib/DBD/mysql.pm

my $of = OpenFoundry->init();
my %conf = %{ $of->getConf() };
my $dbh = DBI->connect("DBI:mysql:database=$conf{NSS_DATABASE}",
                       $conf{NSS_DATABASE_USER},
                       $conf{NSS_DATABASE_PASSWORD},
                       { RaiseError => 1, AutoCommit => 0 });
$dbh->do("delete from users");
my $sth = $dbh->prepare("INSERT INTO users values (?, ?)");
foreach my $u (@{$of->getUsers()})
{
	$sth->execute($u->{name}, $u->{password});
	print ".";
}
$dbh->do("INSERT INTO users values ('$conf{ANONYMOUS_CVS_ACCOUNT}', '\$1\$abcd\$CwbBDotm4UoKv5fATTtzT.')");
$dbh->commit();
$dbh->disconnect();
print "\ndone\n";
