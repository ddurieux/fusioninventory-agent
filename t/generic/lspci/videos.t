#!/usr/bin/perl

use strict;
use warnings;
use FusionInventory::Agent::Task::Inventory::OS::Generic::Lspci::Videos;
use FusionInventory::Logger;
use Test::More;

my %tests = (
    'latitude-xt2' => [
        {
            NAME    => 'Intel Corporation Mobile 4 Series Chipset Integrated Graphics Controller',
            CHIPSET => 'VGA compatible controller'
        },
        {
            NAME    => 'Intel Corporation Mobile 4 Series Chipset Integrated Graphics Controller',
            CHIPSET => 'Display controller'
        }
      ]
);

plan tests => scalar keys %tests;

my $logger = FusionInventory::Logger->new();

foreach my $test (keys %tests) {
    my $file = "resources/lspci/$test";
    my $videos = FusionInventory::Agent::Task::Inventory::OS::Generic::Lspci::Videos::_getVideoControllers($logger, $file);
    is_deeply($videos, $tests{$test}, $test);
}
