#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

if (!$ENV{TEST_AUTHOR}) {
    my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan(skip_all => $msg);
}

plan tests => 2;

my $help = `./fusioninventory-agent --devlib --help 2>&1`;
ok(-f 'README', 'README does not exist, run ./tools/refresh-doc.sh');
ok(-f 'README.html', 'README.html does not exist, run ./tools/refresh-doc.sh');
