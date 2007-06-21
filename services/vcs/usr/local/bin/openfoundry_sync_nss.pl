#!/usr/bin/perl
use strict;
use OpenFoundry;
use DBI;

# http://search.cpan.org/~timb/DBI-1.56/DBI.pm
# http://search.cpan.org/dist/DBD-mysql/lib/DBD/mysql.pm

my $of = OpenFoundry->init("RT");

my $dbh = DBI->connect("DBI:mysql:database=$of->{conf}->{NSS_DATABASE}",
                       $of->{conf}->{NSS_DATABASE_USER},
                       $of->{conf}->{NSS_DATABASE_PASSWORD},
                       { RaiseError => 1, AutoCommit => 0 });
$dbh->do("delete from users");
my $sth = $dbh->prepare("INSERT INTO users values (?, ?)");
foreach my $u (@{$of->{'users'}})
{
	$sth->execute($u->{Name}, $u->{Password});
	print ".";
}
$dbh->commit();
$dbh->disconnect();
print "\ndone\n";
