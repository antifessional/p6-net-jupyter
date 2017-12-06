#!/usr/bin/env perl6

unit module Net::Jupyter::Executer;

use v6;

use Net::Jupyter::Common;
use Net::Jupyter::EvalError;
use Net::Jupyter::ContextREPL;

class Executer is export {

  #class
  my int $counter = 0;

  has Str $.code is required;

  #optional
  has Bool $.silent = False;
  has Bool $.store-history = True;
  has %.user-expressions;

  # DO NOT initialize
  has Str $.return-value;
  has Str $.stderr;
  has Str $.stdout;
  has $.traceback;
  has %.error;
  has Bool $.dependencies-met = True;

  has @.payload;
  has %.metadata;
  has $!repl;

  method TWEAK {
      die "Executer called without code! { $!code.perl }" without $!code;
      ++$counter;
      $!repl = ContextREPL.get-repl;

      self!run-code;
      self!run-expressions
        with %!error;

   }

  method !run-code {
    say $!code;
    my $out = $*OUT;
    my $capture ='';
    $*OUT = class { method print(*@args) {  $capture ~= @args.join; True }
                    method flush { True }}
    try {
      $!return-value = $!repl.eval($!code);
      CATCH {
        default {
          my $error .= new( :exception( Exception($_)));
          %!error =  $error.extract;
          $!stderr = $error.format(:short);
          $!traceback = %!error< traceback >;
          $.return-value = Nil;
          $.dependencies-met = ! so %!error<  dependencies-error >;
        }
      }
    }
    $*OUT = $out;
    $!stdout = $capture;
  }

  method !run-expressions {
    for %!user-expressions.kv -> $name, $expr {
      try {
        my $value = $!repl.eval($expr, :null-context);
        %!user-expressions{ $name }  = $value;
        CATCH {
          default {
            my $err .= new( :exception( Exception($_)));
            my %error = $err.extract;
            %!user-expressions{ $name }  = %error< status evalue>;}}}}}


  method count {
    return $counter;
  }


}#executer



sub stringify($value) {
  return 'Nil'        if ($value === Nil);
  return $value.gist  if !$value.defined;
  return $value.Str;
}
