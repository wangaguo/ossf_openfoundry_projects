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

sub syncWithFoundry
{
	my $table = "foundry_owner";
	my $table_tmp = "foundry_owner_tmp";

	my $config_file = '/usr/local/etc/sympa/sympa.conf';
 
	Conf::load($config_file);
	#my $of = OpenFoundry->init('Mock');
	my $of = OpenFoundry->init('Aguo');

	# admin
	my $relations = $of->getRelations();
	List::db_connect();
	my $dbh = List::db_get_handler();
	print "dbh : $dbh \n";

	print "going to create table $table and $table_tmp\n";
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
#		$insert_body = sprintf "('%s\@users.openfoundry.org','%s')", $u[0]{'name'}, $p[0]{'unixname'};
#		my $sql = "insert into testsympa values ('$u->{'name'}\@users.openfoundry.org','$p->{'unixname'}')";
#		$sth->execute("$u->{'Name'}\@users.openfoundry.org", $p->{'UnixName'});
		$sth->execute($u->{'Email'}, $p->{'UnixName'});
#		$dbh->do($sql);
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


	
#	my $lists = List::get_lists_by_prefix(undef, undef, $projects);

	#my $lists = List::get_lists_by_prefix(undef, undef, [ 'openfoundry', 'newname' ]);
	my $lists = List::get_lists_by_prefix(undef, undef, [ 'openfoundry' ]);
	foreach my $list (@$lists)
	{
		print "list name: ", $list->{'name'}, "\n";
		my $rtn = $list->sync_include_admin();
		#print "rtn: ", Dumper($rtn);
		#print "error! sync_include returns: $rtn\n" if $rtn != 1;
#`sympa.pl --sync_include=openfoundry-devel`;
#`sympa.pl --sync_include=$list->{'name'}`;
	}


	List::db_disconnect();
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
print STDERR "!!!!!the regex = $regex\n";
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

#__END__
#sub getProjectAndMailingLists
#{
#	
#	my $sympa_expl_dir = '/tmp/ossf/jail2/usr/local/sympa/expl';
#	foreach my $d (<$sympa_expl_dir/*-*>)
#	{
#		next if not (-d $d);
#		$d =~ s#.*/##;
##		print "##$d##\n";
#		my ($projectUnixName, $list) = split(/-/, $d, 2);
#		print "$projectUnixName##$list\n";
#	}
#}


############################


package main;

use Data::Dumper;
#my $of = OpenFoundry->init('Aguo');
#print Dumper($of->getUsers());
#print Dumper($of->getUserByName('LCamel'));
#print Dumper($of);
#OpenFoundry::Sympa::syncWithFoundry();
#OpenFoundry::Sympa::deleteDuplicateEmailAddresses();
__END__
my $of = OpenFoundry->init('Mock');

my $projects = $of->getProjects();
#print "projects: ", Dumper($projects), "\n";
my $users = $of->getUsers();
#print "users: ", Dumper($users), "\n";
my $relations = $of->getRelations();
print Dumper($relations), "\n";


#print "getUserById: ", Dumper($of->getUserById('200')), "\n";

print "in.. ", Dumper($of->isInRelation('admin', '1', '100')), "\n";
print "in.. ", Dumper($of->isInRelation('admin', '1', '200')), "\n";




1;
