#!/usr/bin/env perl6

use v6;

use lib 'lib';

use Test;

BEGIN %*ENV<PERL6_TEST_DIE_ON_FAIL> = 1;

# plan 1;

say 'testing Executer'; 
use Net::Jupyter::Executer;

sub fy(*@args) { return @args.join("\n") ~ "\n"};

sub test-result(%r, $v, $o, $e) {
  ok %r<value>  === $v, "return value { $v.perl } correct";
  ok %r<out>    === $o, "output -->" ~ $o ~"<-- correct";
  if $e.defined {
    ok %r<error>.index($e).defined, "correct: %r<error>";
  } else {
    ok %r<error>  === Any, "Correct: No error";
  }
}

my %result;
my @code = [
    [''],
    ['use v6;'
    , 'my $z=3;'],
   [
    'my $y=7+(11/1);'
      , 'my  $x = 4 * 8 + $z;'
      , 'say q/YES/;'
      , 'say $x/1;'
    ],
    [ 'sub xx($d) {', 
      '  return $d*2;',
      '}',
      'xx($z)'
    ], 
    [
      'say xx(10);'
    ],
    [
      'say 10/0;'
    ],
    [
      'use NO::SUCH::MODULE;'
    ]
];

pass "...";

done-testing;
