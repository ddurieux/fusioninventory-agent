package FusionInventory::Agent::Task::Inventory::OS::BSD::Archs::i386;

use strict;
use warnings;

use Config;

# Only run this module if dmidecode has not been found
our $runMeIfTheseChecksFailed =
    ["FusionInventory::Agent::Task::Inventory::OS::Generic::Dmidecode"];

sub isInventoryEnabled{
    return 
        $Config{'archname'} eq 'i386' || 
        $Config{'archname'} eq 'x86_64';
}

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};

    my( $SystemSerial , $SystemModel, $SystemManufacturer, $BiosManufacturer,
        $BiosVersion, $BiosDate);
    my ( $processort , $processorn , $processors );

    # use hw.machine for the system model
    # TODO see if we can do better
    chomp($SystemModel=`sysctl -n hw.machine`);

    # number of procs with sysctl (hw.ncpu)
    chomp($processorn=`sysctl -n hw.ncpu`);
    # proc type with sysctl (hw.model)
    chomp($processort=`sysctl -n hw.model`);
    # XXX quick and dirty _attempt_ to get proc speed through dmesg
    for(`dmesg`){
        my $tmp;
        if (/^cpu\S*\s.*\D[\s|\(]([\d|\.]+)[\s|-]mhz/i) { # XXX unsure
            $tmp = $1;
            $tmp =~ s/\..*//;
            $processors=$tmp;
            last
        }
    }

# Writing data
    $inventory->setBios ({
        SMANUFACTURER => $SystemManufacturer,
        SMODEL => $SystemModel,
        SSN => $SystemSerial,
        BMANUFACTURER => $BiosManufacturer,
        BVERSION => $BiosVersion,
        BDATE => $BiosDate,
    });

    $inventory->setHardware({
        PROCESSORT => $processort,
        PROCESSORN => $processorn,
        PROCESSORS => $processors
    });

}

1;
