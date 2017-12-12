#!/usr/bin/env perl6

use v6;

use lib 'lib';

use Test;

BEGIN %*ENV<PERL6_TEST_DIE_ON_FAIL> = 1;

# plan 1;

say 'testing Magic grammer'; 

use Net::Jupyter::Magic;

sub fy(*@args) { return @args.join("\n") ~ "\n"};

sub test-magic(@code, :$o, :$f --> Magic ) {
  my $code = fy(@code); 
  say "CODE:\n$code\n---" if $o;
  my Magic $m = Magic.parse($code);
  my $perl-code = $m.perl-code;
  CATCH { when X::Jupyter::MalformedMagic { 
          if $f { ok 1, "invalid code test " ~ $code.substr(0,16) ~ " :$_"; return $m}
          else { ok 0, "valid code test " ~ $code.substr(0,16)  ~ " :$_"; return $m}
      }
  }
  
  say "PERL:\n$perl-code\n---" if $o;
  say "--perl6 -c -e '$perl-code'--" if $o;
  my $stderr = $o ?? '' !! ' 2>/dev/null';
  if $f {
    ok  (! shell "perl6 -c -e '$perl-code' $stderr" ), 'testing invalid code';
  } else {
    ok (shell "perl6 -c -e '$perl-code'"), 'testing valid code';
  }
  $m;
}

my @code = [
    [''],[' '], [';'] ,
    ['use v6;'
    , 'my $z=3;'
    ],
   [
    '%% > html %%',
    'my $y=7+(11/1);'
    ],
   [
    '%% | js > html %%',
    'my $y=7+(11/1);'
    ],
   [
    '%%|js>html%%',
    '%% > latex %%',
    'my $y=7+(11/1);'
    ],
   [
    '%%   class  MyClass    %%',
    'my $y=7+(11/1);'
    ],
  [
    '%% class  MyClass begin  %%',
    '%% class  MyClass end  %%',
    '%% class  MyClass cont  %%',
    '%% class  MyClass continue  %%',
    'my $y=7+(11/1);'
    ],
  [
    '%% ns None %%',
    '%%  ns  myNS   %%',
    '%% ns myNS::c1  %%',
    '%% ns ::c1  %%',
    '%% ns myUS reset %%',
    'my $y=7+(11/1);'
    ],
  [
    '%% @|  wr %%',
    '%% @>  wr   %%',
    '%% @@|  wr %%',
    '%% @@>  wr   %%',
    '%%@@>wr%%',
    '%% @ @ >  wr   %%',
    '%% wrap@ >  wr   %%',
    'my $y=7+(11/1);'
    ],
   [
    '%%   class  MyClass    %%',
    'my $y=7+(11/1);',
    '%%   class  MyClass    %%',
    'my $y=7+(11/1);',
    ],
   [
    '  %%   class  MyClass    %%  ',
    'my $y=7+(11/1);'
    ],
    [
    '%% ns %%',
    'my $y=7+(11/1);'
    ],
    [
    '%% ns None::c1  %%',
    'my $y=7+(11/1);'
    ],
    [
    '%% ns ::c1 reset %%',
    'my $y=7+(11/1);'
    ],

];

say 'syntax magic tests' ;
if 1 {
test-magic( @code[0] );
test-magic( @code[1] );
test-magic( @code[2] );
test-magic( @code[3] );
test-magic( @code[4] );
test-magic( @code[5] );
test-magic( @code[6] );
test-magic( @code[7] );
test-magic( @code[8] );
test-magic( @code[9] );
test-magic( @code[10] );
test-magic( @code[12] );

test-magic( @code[11], :f  );
test-magic( @code[13], :f);
test-magic( @code[14], :f);
}
test-magic( @code[15], :f );


say 'runtime magic tests' ;
pass "...";

done-testing;
