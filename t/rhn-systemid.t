#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use FusionInventory::Agent::Task::Inventory::OS::Linux;

my %tests = (
    'ID-1232324425' => 'ID-123232425'
);
plan tests => scalar keys %tests;

foreach my $test (keys %tests) {
    my $file = "resources/rhn-systemid/$test";
    my $rhenSysteId = FusionInventory::Agent::Task::Inventory::OS::Linux::_getRHNSystemId($file);
    ok($rhenSysteId, $tests{$test});
}
