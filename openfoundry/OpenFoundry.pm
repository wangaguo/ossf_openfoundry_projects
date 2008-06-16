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
	elsif ($backend eq 'OF')
	{
		return new OpenFoundry::Impl::OF($conf);
	}
	elsif ($backend eq 'RT')
	{
		die "The RT backend should no longer be used";
		#return new OpenFoundry::Impl::RT($conf);
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
		return $p if $p->{'id'} eq $id;
	}
	return undef;
#	return grep { $_->{'id'} eq $id } @{$self->getProjects()};
}
sub getProjectByName
{
	my ($self, $name) = @_;
	foreach my $p (@{$self->getProjects()})
	{
		return $p if $p->{'name'} eq $name;
	}
	return undef;
}
sub getUserById
{
	my ($self, $id) = @_;
	foreach my $u (@{$self->getUsers()})
	{
		return $u if $u->{'id'} eq $id;
	}
	return undef;
#	return grep { $_->{'id'} eq $id } @{$self->getUsers()};
}
sub getUserByName
{
	my ($self, $name) = @_;
	foreach my $u (@{$self->getUsers()})
	{
		return $u if $u->{'name'} eq $name;
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
	my ($self, $relation, $projectName, $userName) = @_;
	my $p = $self->getProjectByName($projectName) || return 0;
	my $u = $self->getUserByName($userName) || return 0;
	return $self->isInRelation($relation, $p->{id}, $u->{id});
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
	my ($self, $msg) = @_;
	open my $F, ">>/tmp/openfoundry.log";
	print {$F} scalar(localtime()), "--", $msg, "--\n";
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
	my $url = $conf->{DUMP_SOURCE_URL} . $conf->{DUMP_SECRET};
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
	print {$fh2} encode_json($obj);
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
##########################################

package OpenFoundry::Impl::OF;
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
	my $url = $conf->{DUMP_SOURCE_URL} . $conf->{DUMP_SECRET};
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
	print {$fh2} encode_json($obj);
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
############################
package OpenFoundry::Sympa;
use lib '/usr/local/lib/sympa';
use List;
use Conf;
use Data::Dumper;

sub deleteDuplicateEmailAddresses
{
	my @sql;
	my $of = OpenFoundry->init('Aguo');
	my $users = $of->getUsers;

	my $config_file = '/usr/local/etc/sympa/sympa.conf';
 
	Conf::load($config_file);
	List::db_connect();
	my $dbh = List::db_get_handler();
	
	foreach my $user (@{$users}){
		my $email_true=$user->{'Email'};
		my $email_false=$user->{'Name'}."\@users.openfoundry.org";
		#push @sql,"update ignore user_table set email_user = '".$user->{'Emailaddress'}."' where email_user = '".$user->{'Name'}."\@users.openfoundry.org'\n";

		#push @sql,"update user_table set email_user = '".$user->{'Emailaddress'}."' where email_user = '".$user->{'Name'}."\@users.openfoundry.org';\n";

		#push @sql,"update subscriber_table set user_subscriber = '".$user->{'Emailaddress'}."' where user_subscriber = '".$user->{'Name'}."\@users.openfoundry.org';\n";
	 	{	
		my $sql="select count(*) AS c from user_table where email_user in (?, ?) having c>1;";

		my $lists=$dbh->selectcol_arrayref($sql, {}, $email_true, $email_false);	
		#print $user->{'Name'}, " ", Dumper($lists) if @$lists;
		if(@$lists)
		{
			my $delsql = "delete from user_table where email_user = ? ";
			print  $email_true," ", $email_false, "\n";
			$dbh->do($delsql, {}, $email_false);
			#print Dumper($dbh->selectall_arrayref("select * from user_table where email_user in (?,?) ",{},$email_true,$email_false)),"\n";
				
		}
		$dbh->do("update user_table set email_user = ? where email_user= ?", {}, $email_true, $email_false);


		}

		if(0)
		{
		my $sql="select a from (select list_subscriber a , count(*) AS c from subscriber_table where user_subscriber in (?, ?) group by a having c>1) as dummy;";

		my $lists=$dbh->selectcol_arrayref($sql, {}, $email_true, $email_false);
		print $user->{'Name'}, " ", Dumper($lists) if @$lists;
		foreach my $list (@$lists)
		{
			my $delsql = "delete from subscriber_table where list_subscriber = ? and user_subscriber = ?";
			print $list, " ", $email_false, "\n";
			$dbh->do($delsql, {}, $list, $email_false);
		}


		$dbh->do("update subscriber_table set user_subscriber = ? where user_subscriber = ?", {}, $email_true, $email_false);
	
		}
	}
	#print "SQL: \n";
	#print Dumper(@sql);
	#print join( ' ',@sql);
	List::db_disconnect();
}
# only invoked by "sympa.pl --sync_with_foundry"
sub syncWithFoundry
{
	my $table = "foundry_owner";
	my $table_tmp = "foundry_owner_tmp";

	my $of = OpenFoundry->init();

	# admin
	my $relations = $of->getRelations();
	my $dbh = List::db_get_handler();
	print "dbh : $dbh \n";

	print "Creating tables: '$table' '$table_tmp'\n";
	$dbh->do("create table $table (email varchar(100), project_unix_name varchar(20))");
	$dbh->do("create table $table_tmp (email varchar(100), project_unix_name varchar(20))");

	
	#clear the 'owner_include' table
	my $sql="truncate $table_tmp";
	unless($dbh->do($sql)){
		print "SQL error-> $sql, $dbh->errstr\n";
	}

	#insert new entries into tmp table
	my $sth = $dbh->prepare("insert into $table_tmp values (?, ?)");
	foreach my $pu (@{$relations->{'admin'}})
	{
		my ($projectId, $userId) = @$pu;
		my $u=$of->getUserById($userId);
		my $p=$of->getProjectById($projectId);
		#die "why??" if (not $u or not $p);
		$sth->execute($u->{'Email'}, $p->{'name'});
	}	


	#
	# compute the projects having diff
	#
	$sql = <<"END_OF_SQL";
select aa.project_unix_name from $table aa
left  join $table_tmp bb on aa.email = bb.email and aa.project_unix_name = bb.project_unix_name
where bb.email is null
union
select bb.project_unix_name from $table aa
right join $table_tmp bb on aa.email = bb.email and aa.project_unix_name = bb.project_unix_name
where aa.email is null
END_OF_SQL
	#print "the SQL: $sql\n";
	my $projects = $dbh->selectcol_arrayref($sql);
	print "projects need to be updated: ", Dumper($projects);


	#
	# RENAME $table_tmp to $table and REMOVE $table
	#
	$sql="drop table $table";
	$dbh->do($sql);
	$sql="alter table $table_tmp rename to $table";
	$dbh->do($sql);


	#update owner, editor in List::new
	List::get_lists_by_prefix(undef, undef, $projects);

	return 1;
}

package List;
use Data::Dumper;
sub get_lists_by_prefix {
	#print STDERR "the prefix = ".Dumper(\@_)."\n";
	return get_lists_by_regex($_[0],$_[1],"^(?:".join( "|",@{$_[2]}).")-");
}
sub get_lists_by_regex {
    my $robot_context = shift || '*';
    my $options = shift;

my $regex = shift;
print STDERR "get_lists_by_prefix: regex = $regex\n";
$regex = qr/$regex/;
#my %prefixes = map { $_ => $_ } @$prefixes;

    my(@lists, $l,@robots);
    do_log('debug2', 'List::get_lists(%s)',$robot_context);

    if ($robot_context eq '*') {
	@robots = &get_robots ;
    }else{
	push @robots, $robot_context ;
    }

    
    foreach my $robot (@robots) {
    
	my $robot_dir =  $Conf{'home'}.'/'.$robot ;
	$robot_dir = $Conf{'home'}  unless ((-d $robot_dir) || ($robot ne $Conf{'host'}));
	
	unless (-d $robot_dir) {
	    do_log('err',"unknown robot $robot, Unable to open $robot_dir");
	    return undef ;
	}
	
	unless (opendir(DIR, $robot_dir)) {
	    do_log('err',"Unable to open $robot_dir");
	    return undef;
	}
	foreach my $l (sort readdir(DIR)) {
#print "##", (split($l, '-'))[0], "##\n"; 
#next if not $prefixes{(split(/-/, $l))[0]};
#print STDERR "!!!the listname = $l\n";
next if not $l =~ $regex;
	    next if (($l =~ /^\./o) || (! -d "$robot_dir/$l") || (! -f "$robot_dir/$l/config"));

	    my $list = new List ($l, $robot, $options);

	    next unless (defined $list);

	    push @lists, $list;
	    
	}
	closedir DIR;
    }
    return \@lists;
}
