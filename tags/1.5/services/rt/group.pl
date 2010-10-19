use strict;
use lib ( "/usr/local/rt3/local/lib", "/usr/local/rt3/lib" );
use RT;
use JSON;

sub array_substract
{
    my ($a1, $a2) = @_;
    my %hash;
    $hash{$_}=1 foreach @{$a2};
    grep { not $hash{$_} } @{$a1};
}


use Data::Dumper;
my $json = from_json(`cat b.json`);

print ">>>> Init()\n";
RT::LoadConfig();
RT::Init();
print "<<<< Init()\n";




# sub DeleteMember /usr/local/rt3/lib/RT/Group_Overlay.pm

foreach my $proj (@{$json->{'projects'}})
{
    print "====\n";
    my ($queueId, $name, $summary) = @{$proj};
#next if not $queueId == 1;
    print "project: " . $queueId . "\n";

    my $Queue = new RT::Queue($RT::SystemUser);
    if ($Queue->Load($queueId)) {
        my @results = $Queue->Update(AttributesRef => ["Name", "Description"],
                                    ARGSRef => {Name => $name, Description => $summary});
        print "Queue $queueId, $name, $summary, @results ok\n";
    } else {
        print "Queue $queueId does not exist!\n";
        my ($val, $msg) =  $Queue->Create(Id => $queueId, Name => $name, Description => $summary);
        if ($val == 0) {
            print "Create queue failed: id: $queueId  name: $name  message: $msg\n";
        }
    }

    #
    # currently we have no create user
    # if we really want to do it, maybe we have to copy and modify 
    # Create() in /usr/local/rt3/lib/RT/User_Overlay.pm




    my %rt_role_to_function = ("AdminCc" => "rt_admin", "Cc" => "rt_member");

    foreach my $rt_role (keys %rt_role_to_function) {
        my $group = RT::Group->new($RT::SystemUser);
        $group->LoadQueueRoleGroup(Queue => $queueId, Type=> $rt_role);
        #print "Group id: ", $group->Id, "\n";

        my @db_members = ();
        my $members = $group->MembersObj;
        while (my $gm = $members->Next()) {
            #print $gm->MemberId . "\n";
            push @db_members, $gm->MemberId;
        }
        print join(", ", sort @db_members) . "\n";

        my @dump_members = @{ $json->{'functions'}->{$queueId}->{ $rt_role_to_function{$rt_role} } };
        print join(", ", sort @dump_members) . "\n";

        my @should_add = array_substract(\@dump_members, \@db_members);
        my @should_remove = array_substract(\@db_members, \@dump_members);
        printf "%d should add $rt_role %s\n", $queueId, join(", ", @should_add) . "\n" if @should_add;
        printf "%d should remove $rt_role %s\n", $queueId, join(", ", @should_remove) . "\n" if @should_remove;
        

        # using internal API may subject to change
        foreach my $uid (@should_add) {
            $group->_AddMember(PrincipalId => $uid);
        }
        foreach my $uid (@should_remove) {
            $group->_DeleteMember($uid);
        }
    }
    
   
}
