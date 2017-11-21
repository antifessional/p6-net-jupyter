#!/usr/bin/env perl6

unit module Net::Jupyter::Protocol;

use v6;

use Log::ZMQ::Logger;

use Net::Jupyter::Common;
#use Net::Jupyter::Utils;

use Net::ZMQ::Context:auth('github:gabrielash');
use Net::ZMQ::Socket:auth('github:gabrielash');
use Net::ZMQ::Message:auth('github:gabrielash');
use Net::ZMQ::Poll:auth('github:gabrielash');

use JSON::Tiny;
use Digest::HMAC;
use Digest::SHA;


#my $key ='';


class Protocol is export {
  has MsgRecv $.msg is required;
  has UInt $!begin;
  has $.logger;
  has $.key;


  method TWEAK {
    $!begin = self.find-begin;

    unless self.signature eq self.auth {
      $!logger.log(self.auth ~ "<-->" ~ self.signature );
      die "signature mismatch. Exiting" ~ $!msg.perl;
     }

     self.log;
  }

  method find-begin( --> Int ) {
    for 0..^$!msg.elems {
      return $_ if $!msg[$_] eq DELIM;
    }
    $!logger.log('exiting, malformed message' ~ $!msg.perl);
    die "malformed wire message " ~ $!msg.perl;
  }

  method identities( --> List)     {  return  $!msg[ ^$!begin ]  }
  method extra( --> List)          {  return $!msg[ ($!begin + 6)..^$!msg.elems] }

  method signature()               {  return $!msg[$!begin + 1] }
  method header()                  {  return $!msg[$!begin + 2] }
  method parent-header()           {  return $!msg[$!begin + 3] }
  method metadata()                {  return $!msg[$!begin + 4] }
  method content()                 {  return $!msg[$!begin + 5] }

  method id()             {return from-json(self.header)< msg_id > }
  method type()           {return from-json(self.header)< msg_type > }
  method version()        {return from-json(self.header)< version > }

  method auth() {
    return hmac-hex($!key, self.header ~ self.parent-header ~ self.metadata ~ self.content, &sha256);
  }

  method log() {
    $!logger.log(qq:to/END/);
      header: { self.type } { self.version } { self.id } {self.signature }
      identities: { self.identities }
      content: { self.content}
      END
      #:
  }



}
