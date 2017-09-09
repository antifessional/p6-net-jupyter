#!/usr/bin/env perl6

use v6;

use lib 'lib';
use lib '/home/docker/workspace/perl6-net-zmq/lib';

use Test;

BEGIN %*ENV<PERL6_TEST_DIE_ON_FAIL> = 1;

# plan 1;

say "testing packages";

use-ok 'Net::Jupyter::Logger';
use-ok 'Net::Jupyter::WireMsg';

use Net::Jupyter::Logger;
use Net::Jupyter::WireMsg;

done-testing;
