package FusionInventory::Agent::Task::Inventory::OS::AIX;

use strict;
use warnings;

use English qw(-no_match_vars);

our $runAfter = ["FusionInventory::Agent::Task::Inventory::OS::Generic"];

sub isInventoryEnabled {
    return $OSNAME eq 'aix';
}

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};

    my @tabOS;
    my $OSName;
    my $OSComment;
    my $OSVersion;
    my $OSLevel;
    #Operating system informations
    chomp($OSName=`uname -s`);
    # AIX OSVersion = oslevel, OSComment=oslevel -r affiche niveau de maintenance
    chomp($OSVersion=`oslevel`);
    chomp($OSLevel=`oslevel -r`);
    @tabOS=split(/-/,$OSLevel);
    $OSComment="Maintenance Level :".$tabOS[1];

    $OSVersion =~ s/(.0)*$//;
    $inventory->setHardware({
        OSNAME => "$OSName $OSVersion",
        OSCOMMENTS => $OSComment,
        OSVERSION => $OSLevel,
    });
}

1;
