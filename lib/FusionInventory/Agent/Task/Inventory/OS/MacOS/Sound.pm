package FusionInventory::Agent::Task::Inventory::OS::MacOS::Sound;

use strict;
use warnings;

use FusionInventory::Agent::Tools;

use constant DATATYPE   => 'SPAudioDataType'; # may need to fix to work with older versions of osx

sub isInventoryEnabled {
    return 
        -r '/usr/sbin/system_profiler' &&
        can_load("Mac::SysProfile");
}

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};

    # create profiler obj, bail if datatype fails
    my $pro = Mac::SysProfile->new();
    my $h = $pro->gettype(DATATYPE());
    return(undef) unless(ref($h) eq 'HASH');

    # add sound cards
    foreach my $x (keys %$h){
        $inventory->addSound({
            'NAME'          => $x,
            'MANUFACTURER'  => $x,
            'DESCRIPTION'   => $x,
        });
    }
}
1;
