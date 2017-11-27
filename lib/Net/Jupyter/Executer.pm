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
  has Str $.traceback;
  has Bool $.error = False;
  has Bool $.warning = False;
  has %.error-data;

  has @.payload;
  has %.metadata;


  method TWEAK {
      die "Executer called without code! { $!code.perl }" unless $!code.defined;
      ++$counter;

      %*ENV<RAKUDO_ERROR_COLOR> = 0;
      self!run-code;
      self!run-expressions
        unless $!error;
      %*ENV<RAKUDO_ERROR_COLOR> = 1;
   }



  multi method eval(Str $code, Bool $err is rw, Bool $warn is rw, %error, :$eval --> Str) {
      my $value;
      try {
          $value = EVAL(embed($code));
          $value = stringify($value);
          CONTROL {
            when CX::Return {
              $value = stringify($value);
            }
            default {
              $value = stringify($value);
              $warn = True;
              %error = extract-error($_, :full);
            }
          }
          CATCH {
            when X::Buf::AsStr {
              $value = $value.perl;
            }
            default {
              $err = True;
              %error = extract-error($_, :full);
              return Str;
            }
          }
        }
        return $value;
  }

  multi method eval(Str $code, :$async --> Str) {
    my $path ='/usr/local/bin/perl6';
    my @args = ();
    my $repl = Proc::Async.new( :$path, :@args, :w);
  }

  method !run-code {
    say embed($!code);
    my $out = $*OUT;
    my $capture ='';
    $*OUT = class { method print(*@args) {  $capture ~= @args.join; True }
                    method flush { True }
                  }
    $!return-value = self.eval($!code, $!error, $!warning, %!error-data, :eval);
    $*OUT = $out;
    $!stdout = $capture;
    if $!error {
      $!stderr = " %!error-data< type > : %!error-data< evalue >";
      $!stderr ~= " at %!error-data< context > " if %!error-data< context >;
      $!traceback = %!error-data< traceback >.join('');
    } elsif $!warning {
      $!stderr = "%!error-data< type > : %!error-data< evalue >";
      $!stderr ~= " at %!error-data< context > " if %!error-data< context >;
      say "\nRV: $!return-value";
    } else {
      say "\nRV: $!return-value";
    }

    @!payload = ();
    %!metadata  = ();
  }

  method !run-expressions {
    for %!user-expressions.kv -> $name, $expr {
      my $err;
      my $warn;
      my %error;
      my $value = self.eval($expr, $err, $warn, %error, :eval);
      if $err {
        %error< status > = 'error';
        %error< evalue > = "%error< type > : %error< evalue >";
        %error< evalue > ~= " at %error< context > " if %error< context >;
        %!user-expressions{ $name }  = %error;
      }else {
        %!user-expressions{ $name }  = $value;
      }
    }
  }


  method count {
    return $counter;
  }

}#executer



sub stringify($value) {
  return 'Nil'        if ($value === Nil);
  return $value.gist  if !$value.defined;
  return $value.Str;
}

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
        %error< context > = $context.split("\x23CF").join('***');
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
  my $_e = qq:to/ENCLOSED/;
    package $__random__name \{
      our sub __X  \{
        $code
      \}
    \}
    $__random__name\:\:__X();
    ENCLOSED
    #

    return $_e;
}
