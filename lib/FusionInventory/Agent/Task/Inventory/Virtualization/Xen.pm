package FusionInventory::Agent::Task::Inventory::Virtualization::Xen;

use strict;
use warnings;

our $runMeIfTheseChecksFailed = ["FusionInventory::Agent::Task::Inventory::Virtualization::Libvirt"];

sub isInventoryEnabled {
    return 1;
}

1;
