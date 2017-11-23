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
      self!run-expressions;
   }

  method eval(Str $code --> Str) {
    return EVAL($code).Str;
  }

  method !run-code {
      $!return-value = self.eval($!code);
      $!stderr = 'NO ERR';
      $!stdout = 'SUCCESS';
      $!error = False;
      @!payloads = ();
      %!metadata  = ();
  }

  method !run-expressions {
      for %!user-expressions.kv -> $name, $expr {
        %!user-expressions{ $name } = self.eval($expr);
      }
  }


  method count {
    return $counter;
  }



}#executer
