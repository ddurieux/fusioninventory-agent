package FusionInventory::Agent::Task::Inventory::OS::AIX::Mem;

use strict;
use warnings;

use FusionInventory::Agent::Tools;

sub isInventoryEnabled {
    return
        can_run("lsdev") ||
        can_run("which") ||
        can_run("lsattr");
}

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};

    my $memory;
    my $swap;

    #Memory informations
    #lsdev -Cc memory -F 'name' -t totmem
    #lsattr -EOlmem0
    my (@lsdev, @lsattr, @grep);
    $memory=0;
    @lsdev=`lsdev -Cc memory -F 'name' -t totmem`;
    for (@lsdev){
        @lsattr=`lsattr -EOl$_`;
        for (@lsattr){
            if (! /^#/){
                /^(.+):(.+)/;
                $memory += $2;
            }
        }
    }

    #Paging Space
    @grep=`lsps -s`;
    for (@grep){
        if ( ! /^Total/){
            /^\s*(\d+)\w*\s+\d+.+/;
            $swap=$1;
        }
    }

    $inventory->setHardware({
        MEMORY => $memory,
        SWAP => $swap 
    });

}

1;
