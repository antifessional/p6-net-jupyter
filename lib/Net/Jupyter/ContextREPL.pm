#!/usr/bin/env perl6

unit module Net::Jupyter::ContextREPL;

use v6;
use nqp;

class ContextREPL {...}

my ContextREPL $repl;

my constant NAMELESS =  '__NAMELESS__';

sub set-globals {
  %*ENV<RAKUDO_LINE_EDITOR> = 'none';
  %*ENV<RAKUDO_ERROR_COLOR> = 0;
  %*ENV<RAKUDO_DISABLE_MULTILINE> = 1;
}
sub save-globals {
    my %env;
    for < RAKUDO_LINE_EDITOR RAKUDO_ERROR_COLOR  RAKUDO_DISABLE_MULTILINE > -> $k {
      %env{$k} = %*ENV{$k} // Any;
    }
    return %env;
}
sub restore-globals(%env) {
  for < RAKUDO_LINE_EDITOR RAKUDO_ERROR_COLOR  RAKUDO_DISABLE_MULTILINE > -> $k {
      if %env{$k}.defined {
        %*ENV{$k} = %env{$k};
      } else {
        %*ENV{$k}:delete;
      }
  }
}

class ContextREPL is REPL is export {
  has %!ctxs = Hash.new;

  method get-repl(::?CLASS:U:) {
    $repl .= new(nqp::getcomp('perl6'), {}) without $repl;
    return $repl;
  }

  method reset(Str $key  = NAMELESS ) {
    %!ctxs{ $key }:delete;
  }

  multi method eval($code, :$no-context! ) {
      return self.eval($code, Nil, False );
  }
  multi method eval($code, $key = NAMELESS, $keep-context=True ) {

    my $*CTXSAVE := self;
    my $*MAIN_CTX;
    my Exception $ex;
    my $value = Nil;
    my $ctx;

    $ctx := ( $keep-context && (%!ctxs{ $key }:exists) )
                  ?? %!ctxs{ $key }
                  !! nqp::null();

    my %env = save-globals;
    set-globals;

    $value = self.repl-eval($code, $ex , :outer_ctx($ctx));

    restore-globals(%env);

    $ex.throw if $ex.defined;

    %!ctxs{ $key } := $*MAIN_CTX
      if ( $keep-context && $*MAIN_CTX );

    #return Nil if ! $value.defined;
    return $value;
  }
}#ContextREPL
