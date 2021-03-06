package FusionInventory::Agent::Task::Inventory;

use strict;
use warnings;
use base 'FusionInventory::Agent::Task';

use English qw(-no_match_vars);
use File::Find;
use UNIVERSAL::require;

use FusionInventory::Agent::XML::Query::Inventory;

sub new {
    my ($class, $params) = @_;

    my $self = $class->SUPER::new($params);

    $self->{inventory} = FusionInventory::Agent::XML::Query::Inventory->new({
        target => $self->{target},
        logger => $self->{logger},
    });

    $self->{modules} = {};

     return $self;
}

sub run {
    my ($self) = @_;

    $self->_feedInventory();

    SWITCH: {
        if ($self->{target}->isa('FusionInventory::Agent::Target::Stdout')) {
            if ($self->{config}->{format} eq 'xml') {
                print $self->{inventory}->getContent();
            } else {
                print $self->{inventory}->getContentAsHTML();
            }
            last SWITCH;
        }

        if ($self->{target}->isa('FusionInventory::Agent::Target::Local')) {
            my $file =
                $self->{config}->{local} .
                "/" .
                $self->{target}->{deviceid} .
                '.ocs';

            if (open my $handle, '>', $file) {
                if ($self->{config}->{format} eq 'xml') {
                    print $handle $self->{inventory}->getContent();
                } else {
                    print $handle $self->{inventory}->getContentAsHTML();
                }
                close $handle;
                $self->{logger}->info("Inventory saved in $file");
            } else {
                warn "Can't open $file: $ERRNO"
            }
            last SWITCH;
        }

        if ($self->{target}->isa('FusionInventory::Agent::Target::Server')) {
            die "No prologresp!" unless $self->{prologresp};

            if ($self->{config}->{force}) {
                $self->{logger}->debug(
                    "Force enable, ignore prolog and run inventory."
                );
            } else {
                my $parsedContent = $self->{prologresp}->getParsedContent();
                if (
                    !$parsedContent ||
                    ! $parsedContent->{RESPONSE} ||
                    ! $parsedContent->{RESPONSE} eq 'SEND'
                ) {
                    $self->{logger}->debug(
                        "No inventory requested in the prolog, exiting"
                    );
                    return;
                }
            }

            # Add current ACCOUNTINFO values to the inventory
            $self->{inventory}->setAccountInfo(
                $self->{target}->getAccountInfo()
            );

            my $response = $self->{transmitter}->send(
                {message => $self->{inventory}}
            );

            return unless $response;
            $self->{inventory}->saveLastState();

            my $parsedContent = $response->getParsedContent();
            if (
                $parsedContent &&
                $parsedContent->{RESPONSE} &&
                $parsedContent->{RESPONSE} eq 'ACCOUNT_UPDATE'
            ) {
                # Update current ACCOUNTINFO values
                $self->{target}->setAccountInfo($parsedContent->{ACCOUNTINFO});
            }

            last SWITCH;
        }
    }

}

sub _initModList {
    my $self = shift;

    my $logger = $self->{logger};
    my $config = $self->{config};
    my $storage = $self->{storage};

    # compute a list of directories to scan
    my @dirToScan;
    if ($config->{devlib}) {
        # devlib enable, I only search for backend module in ./lib
        push (@dirToScan, './lib');
    } else {
        foreach my $dir (@INC) {
            my $subdir = $dir . '/FusionInventory/Agent/Task/Inventory';
            next unless -d $subdir;
            push @dirToScan, $subdir;
        }
    }
    
    die "No directory to scan for inventory modules" if !@dirToScan;

    # find a list of modules from files in those directories
    my %modules;
    my $wanted = sub {
        return unless -f $_;
        return unless $File::Find::name =~
            m{(FusionInventory/Agent/Task/Inventory/\S+)\.pm$};
        my $module = $1;
        $module =~ s{/}{::}g;
        $modules{$module}++;
    };
    File::Find::find(
        {
            wanted      => $wanted,
            follow      => 1,
            follow_skip => 2
        },
        @dirToScan
    );

    my @modules = keys %modules;
    die "No inventory module found" if !@modules;

    # first pass: compute all relevant modules
    foreach my $module (sort @modules) {
        # compute parent module:
        my @components = split('::', $module);
        my $parent = @components > 5 ?
            join('::', @components[0 .. $#components -1]) : '';

        # skip if parent is not allowed
        if ($parent && !$self->{modules}->{$parent}->{enabled}) {
            $logger->debug("module $module disabled: implicit dependency $parent not enabled");
            $self->{modules}->{$module}->{enabled} = 0;
            next;
        }

        $module->require();
        if ($EVAL_ERROR) {
            $logger->debug("module $module disabled: failure to load ($EVAL_ERROR)");
            $self->{modules}->{$module}->{enabled} = 0;
            next;
        }

        my $enabled = $self->_runWithTimeout($module, "isInventoryEnabled");
        if (!$enabled) {
            $logger->debug("module $module disabled");
            $self->{modules}->{$module}->{enabled} = 0;
            next;
        }

        $self->{modules}->{$module}->{enabled} = 1;
        $self->{modules}->{$module}->{done}    = 0;
        $self->{modules}->{$module}->{used}    = 0;

        no strict 'refs'; ## no critic
        $self->{modules}->{$module}->{runAfter} = [ 
            $parent ? $parent : (),
            ${$module . '::runAfter'} ? @${$module . '::runAfter'} : ()
        ];
    }

    # second pass: disable fallback modules
    foreach my $module (@modules) {
        no strict 'refs'; ## no critic

        next unless ${$module . '::runMeIfTheseChecksFailed'};

        my $failed;

        foreach my $other_module (@${$module . '::runMeIfTheseChecksFailed'}) {
            if ($self->{modules}->{$other_module}->{enabled}) {
                $failed = $other_module;
                last;
            }
        }

        if ($failed) {
            $self->{modules}->{$module}->{enabled} = 1;
            $logger->debug("module $module enabled: $failed failed");
        } else {
            $self->{modules}->{$module}->{enabled} = 0;
            $logger->debug("module $module disabled: no depended module failed");
        }
    }
}

sub _runMod {
    my ($self, $params) = @_;

    my $logger = $self->{logger};

    my $module = $params->{modname};

    return if ($self->{modules}->{$module}->{done});

    $self->{modules}->{$module}->{used} = 1; # lock the module
    # first I run its "runAfter"

    foreach my $other_module (@{$self->{modules}->{$module}->{runAfter}}) {
        if (!$self->{modules}->{$other_module}) {
            die "Module $other_module, needed before $module, not found";
        }

        if (!$self->{modules}->{$other_module}->{enabled}) {
            die "Module $other_module, needed before $module, not enabled";
        }

        if ($self->{modules}->{$other_module}->{used}) {
            # In use 'lock' is taken during the mod execution. If a module
            # need a module also in use, we have provable an issue :).
            die "Circular dependency between $module and  $other_module";
        }
        $self->_runMod({
            modname => $other_module
        });
    }

    $logger->debug ("Running $module");

    $self->_runWithTimeout($module, "doInventory");
    $self->{modules}->{$module}->{done} = 1;
    $self->{modules}->{$module}->{used} = 0; # unlock the module
}

sub _feedInventory {
    my ($self, $params) = @_;

    my $logger = $self->{logger};
    my $inventory = $self->{inventory};

    if (!keys %{$self->{modules}}) {
        $self->_initModList();
    }

    my $begin = time();
    my @modules =
        grep { $self->{modules}->{$_}->{enabled} }
        keys %{$self->{modules}};
    foreach my $module (sort @modules) {
        $self->_runMod ({
            modname => $module,
        });
    }

    # Execution time
    $inventory->setHardware({ETIME => time() - $begin});

    $inventory->{isInitialised} = 1;

}

sub _runWithTimeout {
    my ($self, $module, $function, $timeout) = @_;

    my $logger = $self->{logger};
    my $storage = $self->{storage};

    my $ret;
    
    if (!$timeout) {
        $timeout = $self->{config}{'backend-collect-timeout'};
    }

    eval {
        local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n require
        alarm $timeout;

        no strict 'refs'; ## no critic

        $ret = &{$module . '::' . $function}({
            config        => $self->{config},
            inventory     => $self->{inventory},
            logger        => $self->{logger},
            prologresp    => $self->{prologresp},
            storage       => $storage
        });
    };
    alarm 0;
    my $evalRet = $EVAL_ERROR;

    if ($evalRet) {
        if ($EVAL_ERROR ne "alarm\n") {
            $logger->debug("runWithTimeout(): unexpected error: $EVAL_ERROR");
        } else {
            $logger->debug("$module killed by a timeout.");
            return;
        }
    } else {
        return $ret;
    }
}

1;
__END__

=head1 NAME

FusionInventory::Agent::Task::Inventory - The inventory task for FusionInventory 
=head1 DESCRIPTION

This task extract various hardware and software informations on the agent host.
