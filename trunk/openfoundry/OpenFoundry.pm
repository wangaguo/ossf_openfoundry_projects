use strict 'vars';

#use OpenFoundry::Projects;
#use OpenFoundry::Users;


package OpenFoundry;
use Data::Dumper;
use LWP::Simple ();

sub init
{
	my ($class, $backend) = @_;
#	return bless $self,'OpenFoundry';
	if ($backend eq 'Mock')
	{
		return new OpenFoundry::Impl::Mock;
	}
	elsif ($backend eq 'Aguo')
	{
		return new OpenFoundry::Impl::Aguo;
	}
	else
	{
		die "wtf?";
	}
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
	return grep { $_->[0] eq $projectId and $_->[1] eq $userId } @{$self->getRelations()->{$relation}};
}


# static
sub getSessionInfo
{
	my ($SID, $projectUnixName) = @_;
	my $tmp = LWP::Simple::get("http://rt.openfoundry.org/NoAuth/Session.html?SID=$SID&projectUnixName=$projectUnixName");
	my ($userName, $role, $email) = split / /, $tmp;
	_log("userName: $userName role: $role email: $email");
	return ($userName, $role, $email);
}

#static
sub isAdmin
{
        my ($projectUnixName, $userName) = @_;
        my $tmp = LWP::Simple::get("http://rt.openfoundry.org/NoAuth/IsAdmin.html?projectUnixName=$projectUnixName&userName=$userName");
        return $tmp =~ /^1/; # TODO: output format ...
}


# static
sub _log
{
	my ($msg) = @_;
	open F, ">>/tmp/openfoundry.org";
	print F scalar(localtime()), " ", $msg, "\n";
	close F;
}
	
	

############################
#package OpenFoundry::Project;

#sub new
#{
#	my ($class) = @_;
#	return bless {}, $class;
#}

############################
package OpenFoundry::Impl::Aguo;
use vars qw(@ISA);
@ISA = ('OpenFoundry');

use LWP::Simple;

sub new
{
	my ($class) = @_;
	my $url = 'http://rt.openfoundry.org/NoAuth/FoundryDump.html?secret=--FOUNDRY_DUMP_SECRET--';
	my $self;
	{
		no strict "vars";
		$self = eval(get($url));
		die "Can't get data from $url: $@" if $@ or ref($self) ne 'HASH'; 
	}
	return bless $self, $class;
}

############################


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

