#!/usr/bin/env perl6

use v6;

use lib 'lib';
use lib '/home/docker/workspace/perl6-net-zmq/lib';

use Test;

BEGIN %*ENV<PERL6_TEST_DIE_ON_FAIL> = 1;

# plan 1;

say "testing LogCatcher";

use-ok 'Net::Jupyter::LogCatcher', "log catcher module loads ok";

use Net::ZMQ::Context:auth('github:gabrielash');
use Net::ZMQ::Socket:auth('github:gabrielash');

use Net::Jupyter::LogCatcher;
use Net::Jupyter::Logger;

my $prefix = 'test';
my $logsys = Logging::logging;
my $logger = $logsys.logger(:$prefix);
my $logger2 = $logsys.logger(:prefix("--$prefix"));

$logger.domains('dom1', 'dom2' );
$logger.default-level(:info);
$logger.target('log2');
$logger.format(:zmq);
$logger2.format(:yaml);


my $catcher = LogCatcher.new :debug;
ok $catcher.subscribe(''), "subscribed ok";
#$catcher.set-domains-filter( 'dom1', 'none' );
$catcher.set-level-filter :trace;

sleep 1;

$logger.log('nice day');
$logger2.log('you will never see this', :critical );
$logger.log('another nice day', :warning, :dom2);

sleep 1;
pass "log catching not tested yet";
$catcher.unsubscribe();

sleep 1;

done-testing;
