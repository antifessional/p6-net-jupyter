#!/usr/bin/env perl6

use v6;

use lib 'lib';
use lib '/home/docker/workspace/perl6-net-zmq/lib';

use Test;

BEGIN %*ENV<PERL6_TEST_DIE_ON_FAIL> = 1;

# plan 1;

say "testing packages";

use Net::ZMQ::Context:auth('github:gabrielash');
use Net::ZMQ::Socket:auth('github:gabrielash');

use Net::Jupyter::Logger;

my $prefix = 'test';
my $logsys = Logging::logging;
my $logger = $logsys.logger(:$prefix);
my $logger2 = $logsys.logger(:prefix("--$prefix"), :debug);

ok $logger.defined , 'got logger test';

lives-ok { $logger.domains('dom1', 'dom2' ); } ,"set domains";
lives-ok { $logger.default-level(:info); } ,"set level info";
lives-ok { $logger.target('syslog'); } ,"set target syslog";
lives-ok { $logger.style(:yaml);} ,"set style yaml";
lives-ok { $logger2.style(:yaml);} ,"set style yaml";

my $cnt = 0;
my $promise = start { 
      my $ctx = Context.new:throw-everything;
      my $s1 = Socket.new($ctx, :subscriber, :throw-everything);
      ok $s1.connect($logsys.uri).defined, "log subscriber connected";
      ok $s1.subscribe($prefix).defined, "log filtered on dom1" ;
      say "log subscriber ready"; 
      loop {
          my $m = $s1.receive :slurp; 
          say "LOG SUBS\n$m";
          $cnt++;
          last if $m ~~ / critical /;
          sleep 1;
      }
    }

$logger.log('nice day');
$logger2.log('you will never see this', :level('debug') );
$logger.log('another nice day', :level('critical') );

ok $cnt = 2, "correct messages seen";
await $promise;


done-testing;
