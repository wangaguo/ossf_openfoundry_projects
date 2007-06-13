use strict 'vars';


package OpenFoundry;
use Data::Dumper;
use LWP::Simple ();
use JSON::XS ();
use FileHandle;

sub init
{
	my ($class, $backend) = @_;
	my $conf = __loadConf('/usr/local/etc/openfoundry.conf');
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

sub __loadConf
{
	my ($confPath) = @_; 
	my $conf = {};
	my $io = FileHandle->new($confPath, "r");
	local $/ = undef;
	$conf = JSON::XS->new->utf8->decode(<$io>);
        $io->close();
	return $conf;
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
	return $self->isInRelation($relation,
				   $self->getProjectByUnixName($projectUnixName)->{Id}, 
				   $self->getUserByName($userName)->{Id}); 
}



sub getSessionInfo
{
	die "no default implementation";
}

# static
sub _log
{
	my ($msg) = @_;
	open F, ">>/tmp/openfoundry.org";
	print F scalar(localtime()), " ", $msg, "\n";
	close F;
}

##########################################

package OpenFoundry::Impl::RT;
use vars qw(@ISA);
@ISA = ('OpenFoundry');

use LWP::Simple;
use Data::Dumper;
use JSON::XS;
use FileHandle;

sub new
{
	my ($class, $conf) = @_;
	my $dump;
	if (-e $conf->{JSON_DUMP_CACHE_PATH} &&
	    time() - (stat($conf->{JSON_DUMP_CACHE_PATH}))[9] < $conf->{JSON_DUMP_REFRESH_INTERVAL})
	{ 
		local $/ = undef;
		my $io = FileHandle->new($conf->{JSON_DUMP_CACHE_PATH}, "r");
		$dump = <$io>;
		$io->close();
	}
	else
	{
		my $url = 'http://rt.openfoundry.org/NoAuth/FoundryDumpJson.html?secret=' . $conf->{DUMP_SECRET};
		$dump = LWP::Simple::get($url);
		my $umask = umask 0077;
		my $io = FileHandle->new($conf->{JSON_DUMP_CACHE_PATH}, "w");
		$io->print($dump);
		$io->close();
		umask $umask;
	}
	#return bless JSON::XS->new->utf8->decode($dump), $class;
	my $self = JSON::XS->new->utf8->decode($dump);
	$self->{conf} = $conf;
	return bless $self, $class;
	
}

sub getSessionInfo
{
	my ($self, $SID, $projectUnixName) = @_;
	my $tmp = LWP::Simple::get("http://rt.openfoundry.org/NoAuth/Session.html?SID=$SID&projectUnixName=$projectUnixName");
	my ($userName, $role, $email) = split / /, $tmp;
	#_log("userName: $userName role: $role email: $email");
	return ($userName, $role, $email);
}



##########################################
__END__

package OpenFoundry::Impl::Mock;
use vars qw(@ISA);
@ISA = ('OpenFoundry');

sub new
{
	my ($class) = @_;
	my $self = bless {}, $class;

	$self->{'projects'} = 
		[
		{ 'id' => '1', 'unixname' => 'openfoundry', 'description' => 'ooppeennff...' },
		{ 'id' => '2', 'unixname' => 'closefoundry', 'description' => 'cclloo...ooppeennff...' },
		{ 'id' => '3', 'unixname' => 'nohaha', 'description' => 'cclloo...ooppeennff...' },
		{ 'id' => '4', 'unixname' => 'cs_sig', 'description' => 'cclloo...ooppeennff...' },
		{ 'id' => '5', 'unixname' => 'wow_sig', 'description' => 'cclloo...ooppeennff...' },
		];
	$self->{'users'} = 
		[
		{ 'id' => '100', 'name' => 'LCamel' },
		{ 'id' => '200', 'name' => 'RCamel' },
		{ 'id' => '300', 'name' => 'MiddleCamel' },
		{ 'id' => '400', 'name' => 'TopCamel' },
		];
	$self->{'relations'} = 
		{
		'admin' =>
			[
				[ '1', '100' ],
				[ '2', '100' ],
				[ '2', '200' ],
				[ '2', '300' ],
				[ '2', '400' ],
				[ '3', '400' ],
				[ '3', '200' ],
				[ '4', '300' ],
				[ '4', '400' ],
				[ '5', '300' ],
				[ '5', '400' ],
			],
		'member' =>
			[
				[ '1', '200' ],
			],
		};

			
	return $self;
}

