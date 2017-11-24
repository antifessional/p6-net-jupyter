#!/usr/bin/env perl6

unit module Net::Jupyter::Executer;

use v6;
use Net::Jupyter::Common;

# **************************************************** //
use MONKEY-SEE-NO-EVAL;
# **************************************************** //

class Executer is export {

  #class
  my int $counter = 0;

  #mandatory
  has Str $.code;

  #optional
  has Bool $.silent = False;
  has Bool $.store-history = True;
  has %.user-expressions;

  # DO NOT initialize
  has Str $.return-value;
  has Str $.stderr;
  has Str $.stdout;
  has Bool $.error;
  has @.payloads;
  has %.metadata;

  method TWEAK {
      die "Executer called without code! { $!code.perl }" unless $!code.defined;
      ++$counter;

      self!run-code;
    #  self!run-expressions;
   }


  multi method eval(Str $code, Bool $err is rw,  :$eval) {
      $err = False;
      try {
        return EVAL(embed($code)).Str;
        CATCH {
          default {
            $err = True;
            return extract-error($_, :full);
          }
        }
        CONTROL {
          default {
            $err = True;
            return extract-error($_, :full);
          }
        }
      }
  }

  multi method eval(Str $code, :$async --> Str) {
    my $path ='/usr/local/bin/perl6';
    my @args = ();
    my $repl = Proc::Async.new( :$path, :@args, :w);
  }

  method !run-code {
    my Bool $err;
    my $value = self.eval($!code, $err, :eval);
    if ($err) {
      $!stderr = " $value< type > : $value< evalue >";
      $!stderr ~= " at $value< context > " if $value< context >;
      my $traceback = $value< traceback >.join('');
      $!stderr ~= "\n$traceback";
      $!stdout = 'ERROR';
    } else {
        $!stderr = Str;
        $!return-value = $value;
        $!stdout = "SUCCESS $value";
    }
    $!error = $err;
    @!payloads = ();
    %!metadata  = ();
  }

  method !run-expressions {
    my Bool $err;
    for %!user-expressions.kv -> $name, $expr {
      my $value = self.eval($expr, $err, :eval);
      if $err {
        my %error = qw< status error >;
        %error< ename > = $value< ename >;
        %error< evalue > = " $value< type > : $value< evalue >";
        %error< evalue > ~= " at $value< context > " if $value< context >;
        %error< traceback > = $value< traceback >.join('');
      }else {
        %!user-expressions{ $name }  = $value;
      }
    }
  }


  method count {
    return $counter;
  }

}#executer



sub extract-error(Exception $x, :$full ) {
    my %error;
    %error< ename >  = $x.^name;
    %error< evalue > = $x.message;
    given $x.is-compile-time {
      when 1 {
        my @lines = $x.gist.split("\n");
        my @alts = ();
        if $full {
          my $k = @lines.first( { .trim.substr(0,9) eq 'expecting' }, :k );
          @alts =   "  Expecting\n", | @lines[ ++$k..^@lines.elems ].map( { "$_\n" }) if $k.defined;
        }
        my $context = @lines.first( { .substr(0,7) ~~ '------>'} );
        %error< type  > = 'Compilation Error';
        %error< context > = $context;
        %error< traceback > = @alts;
      }
      when 0 {
        %error< type  > = 'Runtime Error';
        %error< context > = '';
        %error< traceback > = $x.backtrace ;
      }
    }
    return %error;
}

sub embed($code, $__random__name = random-name() ) {
  return qq:to/ENCLOSED/;
    package $__random__name \{
      our sub __X  \{ $code \}
    \}
    $__random__name\:\:__X();
    ENCLOSED
    #; ' / "
}
