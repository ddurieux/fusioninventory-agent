package FusionInventory::Agent::Task::Inventory::OS::HPUX::CPU;

use strict;
use warnings;

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

###                                                                                                
# Version 1.1                                                                                      
# Correction of Bug n 522774                                                                       
#                                                                                                  
# thanks to Marty Riedling for this correction                                                     
#                                                                                                  
###                                                                                                

sub isInventoryEnabled  { 
    return $OSNAME eq 'hpux';
}

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};

    my $CPUinfo = {
        MANUFACTURER => 'unknow',
        TYPE         => 'unknow',
        SERIAL       => 'No Serial Number available!',
        SPEED        => 0
    };
    my $CPUcount;

    # Using old system HpUX without machinfo
    # the Hpux whith machinfo will be done after
    my %cpuInfos = (
        "D200" => "7100LC 75",
        "D210" => "7100LC 100",
        "D220" => "7300LC 132",
        "D230" => "7300LC 160",
        "D250" => "7200 100",
        "D260" => "7200 120",
        "D270" => "8000 160",
        "D280" => "8000 180",
        "D310" => "7100LC 100",
        "D320" => "7300LC 132",
        "D330" => "7300LC 160",
        "D350" => "7200 100",
        "D360" => "7200 120",
        "D370" => "8000 160",
        "D380" => "8000 180",
        "D390" => "8200 240",
        "K360" => "8000 180",
        "K370" => "8200 200",
        "K380" => "8200 240",
        "K400" => "7200 100",
        "K410" => "7200 120",
        "K420" => "7200 120",
        "K460" => "8000 180",
        "K570" => "8200 200",
        "K580" => "8200 240",
        "L1000-36" => "8500 360",
        "L1500-7x" => "8700 750",
        "L3000-7x" => "8700 750",
        "N4000-44" => "8500 440",
        "ia64 hp server rx1620" => "itanium 1600"
    );

    if ( can_run ("/usr/contrib/bin/machinfo") ) {
        my @machinfo = `/usr/contrib/bin/machinfo`;
        s/\s+/ /g for (@machinfo);
        foreach (@machinfo) {
            if (/Number of CPUs = (\d+)/) {
                $CPUcount = $1;
            } elsif (/processor model: \d+ (.+)$/) {
                $CPUinfo->{TYPE} = $1;
            } elsif (/Clock speed = (\d+) MHz/) {
                $CPUinfo->{SPEED} = $1;
            } elsif (/vendor information =\W+(\w+)/) {
                $CPUinfo->{MANUFACTURER} = $1;
            } elsif (/Cache info:/) {
                # last; #Not tested on versions other that B11.23
            }
            # Added for HPUX 11.31
            if ( /Intel\(R\) Itanium 2 9000 series processor \((\d+\.\d+)/ ) {
                $CPUinfo->{SPEED} = $1*1000;
            }
            if ( /(\d+) logical processors/ ) {
                $CPUcount = $1;
            }
            # end HPUX 11.31
        }
    } else {
        chomp(my $DeviceType =`model |cut -f 3- -d/`);
        my $tempCpuInfo = $cpuInfos{"$DeviceType"};
        if ( $tempCpuInfo =~ /^(\S+)\s(\S+)/ ) {
            $CPUinfo->{TYPE} = $1;
            $CPUinfo->{SPEED} = $2;
        } else {
            for ( `echo 'sc product cpu;il' | /usr/sbin/cstm` ) {
                next unless /CPU Module/;
                if ( /(\S+)\s+CPU\s+Module/ ) {
                    $CPUinfo->{TYPE} = $1;
                }
            }
            for ( `echo 'itick_per_usec/D' | adb -k /stand/vmunix /dev/kmem` ) {
                if ( /tick_per_usec:\s+(\d+)/ ) {
                    $CPUinfo->{SPEED} = $1;
                }
            }
        }
        # NBR CPU
        chomp($CPUcount=`ioscan -Fk -C processor | wc -l`);
    }

    my $serie;
    chomp($serie = `uname -m`);
    if ( $CPUinfo->{TYPE} eq 'unknow' and $serie =~ /ia64/) {
        $CPUinfo->{TYPE} = "Itanium"
    }
    if ( $serie =~ /9000/) {
        $CPUinfo->{TYPE} = "PA" . $CPUinfo->{TYPE};
    }

    foreach ( 1..$CPUcount ) { $inventory->addCPU($CPUinfo) }
}

1;
