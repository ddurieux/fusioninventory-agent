package FusionInventory::Agent::Task::Inventory::OS::Win32::AntiVirus;

use strict;
use warnings;

use Config;
use Win32;
use Win32::OLE('in');
use Win32::OLE::Variant;

use FusionInventory::Agent::Tools::Win32;

sub doInventory {
    my $params = shift;

    my $inventory = $params->{inventory};



    # Doesn't works on Win2003 Server
    my $WMIServices = Win32::OLE->GetObject(
        "winmgmts:{impersonationLevel=impersonate,(security)}!//./root/SecurityCenter" );


    if (!$WMIServices) {
        print STDERR Win32::OLE->LastError();
        return;
    }


    my @properties;
    foreach my $properties ( Win32::OLE::in( $WMIServices->InstancesOf(
                "AntiVirusProduct" ) ) )
    {

        $inventory->addAntiVirus({
                COMPANY => $properties->{companyName},
                NAME => $properties->{displayName},
                GUID => $properties->{instanceGuid},
                ENABLED => $properties->{onAccessScanningEnabled},
                UPTODATE => $properties->{productUptoDate},
                VERSION => $properties->{versionNumber}
            });
    }

}
1;
