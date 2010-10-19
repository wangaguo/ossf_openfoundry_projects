use strict 'vars';


package OpenFoundry;
use Data::Dumper;
use LWP::Simple ();
use JSON::XS;
use FileHandle;
use Fatal qw(open close);
use Carp;

# see: app/models/project.rb
# VCS = { :NONE => 0, :CVS => 1, :SUBVERSION => 2, :REMOTE => -1 }.freeze
use constant { VCS_NONE => 0, VCS_CVS => 1, VCS_SUBVERSION => 2, VCS_REMOTE => -1 };

# Usage: my $of = OpenFoundry->init(); # use the backend specified in the conf
sub init
{
	my ($class) = @_;
	my $conf = loadConf();
	my $self = OpenFoundry::__loadJsonFile($conf->{$> == 0 ? ROOT_JSON_DUMP_CACHE_PATH : JSON_DUMP_CACHE_PATH});
	$self->{conf} = $conf;
	return bless $self, $class;
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

## wrappers
#sub getProjects
#{
#	my ($self) = @_;
#	return $self->{'projects'};
#}
#sub getUsers
#{
#	my ($self) = @_;
#	return $self->{'users'};
#}
#sub getFunctions
#{
#	my ($self) = @_;
#	return $self->{'functions'};
#}
#
## private utility, should be faster than grep
#my $sequential_search = sub {
#	my ($objs_array_ref, $attr, $val) = @_;
#	foreach my $obj (@{$objs_array_ref})
#	{
#		return $obj if $obj->{$attr} eq $val;
#	}
#	return undef;
#};
#
#sub getProjectById
#{
#	my ($self, $id) = @_;
#	return $sequential_search->($self->getProjects(), "id", $id);
#}
#sub getProjectByName
#{
#	my ($self, $name) = @_;
#	return $sequential_search->($self->getProjects(), "name", $name);
#}
#sub getUserById
#{
#	my ($self, $id) = @_;
#	return $sequential_search->($self->getUsers(), "id", $id);
#}
#sub getUserByName
#{
#	my ($self, $name) = @_;
#	return $sequential_search->($self->getUsers(), "name", $name);
#}
#
#sub hasFunction
#{
#	my ($self, $function, $projectId, $userId) = @_;
#	foreach (@{$self->getFunctions()->{$function}})
#	{
#		return 1 if $_->[0] eq $projectId and $_->[1] eq $userId;
#	}
#	return 0; 
#}
#sub hasFunctionByName
#{
#	my ($self, $function, $projectName, $userName) = @_;
#	my $p = $self->getProjectByName($projectName) || return 0;
#	my $u = $self->getUserByName($userName) || return 0;
#	return $self->hasFunction($function, $p->{id}, $u->{id});
#}
#
#sub getConf
#{
#	my ($self) = @_;
#	return $self->{conf};
#}
#
#sub getSessionInfo
#{
#	die "no default implementation";
#}

# static
# TODO: fix me !
sub _log
{
	my ($self, $msg) = @_;
	open my $F, ">>/tmp/openfoundry.log";
	print {$F} scalar(localtime()), "--", $msg, "--\n";
	close $F;
}

##########################################



#vcs# perl -MOpenFoundry -MBenchmark -e 'timethis(100, sub {OpenFoundry->init("RT")})'
#timethis 100:  3 wallclock secs ( 2.66 usr +  0.08 sys =  2.73 CPU) @ 36.57/s (n=100)
#
#vcs# perl -MOpenFoundry -MBenchmark -e 'timethis(100, sub {OpenFoundry->init("RT")->isInRelationByName("admin", "openfoundry", "LCamel") })'
#timethis 100:  3 wallclock secs ( 2.75 usr +  0.08 sys =  2.83 CPU) @ 35.36/s (n=100)


# static (for not loading old data)
# perl -MOpenFoundry -e 'OpenFoundry::refresh("vcs")'
# see: /usr/local/bin/openfoundry_sync_cache.sh
sub refresh
{
	my ($module) = @_;
	die "no module" if not $module;
	my $conf = OpenFoundry::loadConf();
	my $url = sprintf($conf->{DUMP_SOURCE_URL}, $conf->{DUMP_SECRET}, $module);
	my $json = LWP::Simple::get($url);
	# TODO: integrity check ??
	my $obj = decode_json($json);
	my $umask = umask 0077;
	open my $fh, ">", $conf->{ROOT_JSON_DUMP_CACHE_PATH};
	print {$fh} $json;
	close $fh;
	umask $umask;

	my $normal_user_data;
	if ($module eq "vcs")
	{
		$normal_user_data = { "functions" => $obj->{"functions"} };
	}
	# write a stripped-down version for non-root users
	open my $fh2, ">", $conf->{JSON_DUMP_CACHE_PATH};
	print {$fh2} encode_json($normal_user_data);
	close $fh2;
}


sub getSessionInfo
{
	my ($self, $SID, $projectName) = @_;
	my $url = sprintf($self->{conf}->{SSO_URL}, $SID, $projectName);
	my $tmp = LWP::Simple::get($url);
	$self->_log($url);
	$self->_log($self->{conf}->{SSO_URL});
	my ($userName, $role, $email) = split / /, $tmp;
	#_log("userName: $userName role: $role email: $email");
	return ($userName, $role, $email);
}

####################################
#
# perl -MOpenFoundry -e 'OpenFoundry::test()'
#
sub test
{
	my $of = OpenFoundry->init();
	print Dumper($of);
	#print "projects: ", join(", ", map { $_->{"name"} } @{$of->getProjects()}), "\n";
	#my $p = $of->getProjectByName("openfoundry");
	#print "project openfoundry: ", Dumper($p);
	#print "users: ", join(", ", map { $_->{"name"} } @{$of->getUsers()}), "\n";
	#my $u = $of->getUsers()->[0];
	#print "first user: ", Dumper($u);
	
}
	
1;
