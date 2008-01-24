use strict 'vars';


package OpenFoundry;
use Data::Dumper;
use LWP::Simple ();
use JSON::XS;
use FileHandle;
use Fatal qw(open close);

sub init
{
	#my ($class, $backend) = @_;
	my $conf = loadConf();
	my $backend = $conf->{DATA_BACKEND};
	if ($backend eq 'Mock')
	{
		return new OpenFoundry::Impl::Mock;
	}
	elsif ($backend eq 'RT')
	{
		return new OpenFoundry::Impl::RT($conf);
	}
	else
	{
		die "We have no implementation named '$backend'";
	}
}
# static
# TODO: cache loaded conf ?
sub loadConf
{
	my $openfoundry_etc = "--OPENFOUNDRY_ETC--";
	my $conf = __loadJsonFile("$openfoundry_etc/openfoundry.conf");
	return $conf if $> != 0;

	my $root_conf = __loadJsonFile("$openfoundry_etc/openfoundry_root.conf");
	$conf->{$_} = $root_conf->{$_} foreach (keys %{$root_conf});
	return $conf;
}
# static
sub __loadJsonFile
{
	my ($path) = @_; 
	open my $fh, '<', $path; # auto close
	local $/;
	return decode_json(scalar(<$fh>));
}

sub getProjects
{
	my ($self) = @_;
	return $self->{'projects'};
}
sub getUsers
{
	my ($self) = @_;
	return $self->{'users'};
}
sub getRelations
{
	my ($self) = @_;
	return $self->{'relations'};
}

sub getProjectById
{
	my ($self, $id) = @_;
	foreach my $p (@{$self->getProjects()})
	{
		return $p if $p->{'Id'} eq $id;
	}
	return undef;
#	return grep { $_->{'id'} eq $id } @{$self->getProjects()};
}
sub getProjectByUnixName
{
	my ($self, $unixName) = @_;
	foreach my $p (@{$self->getProjects()})
	{
		return $p if $p->{'UnixName'} eq $unixName;
	}
	return undef;
}
sub getUserById
{
	my ($self, $id) = @_;
	foreach my $u (@{$self->getUsers()})
	{
		return $u if $u->{'Id'} eq $id;
	}
	return undef;
#	return grep { $_->{'id'} eq $id } @{$self->getUsers()};
}
sub getUserByName
{
	my ($self, $name) = @_;
	foreach my $u (@{$self->getUsers()})
	{
		return $u if $u->{'Name'} eq $name;
	}
	return undef;
}

sub isInRelation
{
	my ($self, $relation, $projectId, $userId) = @_;
	foreach (@{$self->getRelations()->{$relation}})
	{
		return 1 if $_->[0] eq $projectId and $_->[1] eq $userId;
	}
	return 0; 
	#return grep { $_->[0] eq $projectId and $_->[1] eq $userId } @{$self->getRelations()->{$relation}};
}

sub isInRelationByName
{
	my ($self, $relation, $projectUnixName, $userName) = @_;
	my $p = $self->getProjectByUnixName($projectUnixName) || return 0;
	my $u = $self->getUserByName($userName) || return 0;
	return $self->isInRelation($relation, $p->{Id}, $u->{Id});
}

sub getConf
{
	my ($self) = @_;
	return $self->{conf};
}




sub getSessionInfo
{
	die "no default implementation";
}

# static
# TODO: fix me !
sub _log
{
	my ($msg) = @_;
	open my $F, ">>/tmp/openfoundry.org";
	print {$F} scalar(localtime()), " ", $msg, "\n";
	close $F;
}

##########################################

package OpenFoundry::Impl::RT;
use vars qw(@ISA);
@ISA = ('OpenFoundry');

use LWP::Simple;
use Data::Dumper;
use JSON::XS;
use Carp;
use Fatal qw(open close);

#vcs# perl -MOpenFoundry -MBenchmark -e 'timethis(100, sub {OpenFoundry->init("RT")})'
#timethis 100:  3 wallclock secs ( 2.66 usr +  0.08 sys =  2.73 CPU) @ 36.57/s (n=100)
#
#vcs# perl -MOpenFoundry -MBenchmark -e 'timethis(100, sub {OpenFoundry->init("RT")->isInRelationByName("admin", "openfoundry", "LCamel") })'
#timethis 100:  3 wallclock secs ( 2.75 usr +  0.08 sys =  2.83 CPU) @ 35.36/s (n=100)

sub new
{
	my ($class, $conf) = @_;
	my $self = OpenFoundry::__loadJsonFile($conf->{$> == 0 ? ROOT_JSON_DUMP_CACHE_PATH : JSON_DUMP_CACHE_PATH});
	$self->{conf} = $conf;
	return bless $self, $class;
}

# static (for not loading old data)
# perl -MOpenFoundry -e 'OpenFoundry::Impl::RT::refresh'
# see: /usr/local/bin/openfoundry_sync_cache.sh
sub refresh
{
	my $conf = OpenFoundry::loadConf();
	my $url = 'http://rt.openfoundry.org/NoAuth/FoundryDumpJson.html?secret=' . $conf->{DUMP_SECRET};
	my $json = LWP::Simple::get($url);
	# TODO: integrity check ??
	my $umask = umask 0077;
	open my $fh, ">", $conf->{ROOT_JSON_DUMP_CACHE_PATH};
	print {$fh} $json;
	close $fh;
	umask $umask;

	# write a stripped-down version for non-root users
	my $obj = decode_json($json);
	foreach my $user (@{$obj->{users}})
	{
		$user->{Password} = $user->{Email} = '';
	}
	open my $fh2, ">", $conf->{JSON_DUMP_CACHE_PATH};
	print {$fh2} to_json($obj);
	close $fh2;
}


sub getSessionInfo
{
	my ($self, $SID, $projectUnixName) = @_;
	my $tmp = LWP::Simple::get("http://rt.openfoundry.org/NoAuth/Session.html?SID=$SID&projectUnixName=$projectUnixName");
	my ($userName, $role, $email) = split / /, $tmp;
	#_log("userName: $userName role: $role email: $email");
	return ($userName, $role, $email);
}
