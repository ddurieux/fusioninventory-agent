#!/usr/bin/perl

use strict;
use warnings;
use FusionInventory::Agent::Task::Inventory::OS::Generic::Lspci::Sounds;
use FusionInventory::Logger;
use Test::More;

my %tests = (
    'latitude-xt2' => [
        {
            NAME => 'Audio device',
            DESCRIPTION => 'rev 03',
            MANUFACTURER => 'Intel Corporation 82801I (ICH9 Family) HD Audio Controller'
        }
    ]
);

plan tests => scalar keys %tests;

my $logger = FusionInventory::Logger->new();

foreach my $test (keys %tests) {
    my $file = "resources/lspci/$test";
    my $sounds = FusionInventory::Agent::Task::Inventory::OS::Generic::Lspci::Sounds::_getSoundControllers($logger, $file);
    is_deeply($sounds, $tests{$test}, $test);
}
