package FusionInventory::Agent::Task::Inventory::OS::MacOS::Printers;

use strict;
use warnings;

use FusionInventory::Agent::Tools;

use constant DATATYPE => 'SPPrintersDataType';

sub isInventoryEnabled {
    return 
        -r '/usr/sbin/system_profiler' &&
        can_load("Mac::SysProfile");
}

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};
    my $config = $params->{config};

    return if $config->{'no-printer'};

    my $pro = Mac::SysProfile->new();
    my $h = $pro->gettype(DATATYPE());
    return(undef) unless(ref($h) eq 'HASH');

    foreach my $printer (keys %$h){
        if ($printer && $printer =~ /^The printers list is empty. To add printers/) {
#http://forge.fusioninventory.org/issues/169
                next;
        }

        $inventory->addPrinter({
                NAME    => $printer,
                DRIVER  => $h->{$printer}->{'PPD'},
		PORT	=> $h->{$printer}->{'URI'},
        });
    }

}
1;
