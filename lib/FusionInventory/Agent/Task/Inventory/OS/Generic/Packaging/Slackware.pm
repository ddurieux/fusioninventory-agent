package FusionInventory::Agent::Task::Inventory::OS::Generic::Packaging::Slackware;

use strict;
use warnings;

use FusionInventory::Agent::Tools;

sub isInventoryEnabled {
    return can_run("pkgtool");
}

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};


    opendir my $handle, '/var/log/packages/';
    while (my $file = readdir($handle)) {
        next if $file eq '.' or $file eq '..';

        my @array = split("-", $file);

        my $name;
        if ((@array - 4) > 0) {
            $name = $array[0];
            for (my $i = 1; $i <= (@array - 4); $i++) {
                $name .= "-".$array[$i];
            }
        } else {
            $name = $array[0];
        }

        my $version =
            $array[(@array - 3)] . 
            "-" . 
            $array[(@array - 2)] . 
            "-" . 
            $array[(@array - 1)];

        $inventory->addSoftware({
            NAME    => $name,
            VERSION => $version
        });
    }
    closedir $handle;
}

1;
