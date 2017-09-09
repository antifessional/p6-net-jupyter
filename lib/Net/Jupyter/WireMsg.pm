#!/usr/bin/env perl6

use v6;

use Net::ZMQ::Context:auth('github:gabrielash');
use Net::ZMQ::Socket:auth('github:gabrielash');
use Net::ZMQ::Message:auth('github:gabrielash');
use Net::ZMQ::Poll:auth('github:gabrielash');
use JSON::Tiny;
use Digest::HMAC;
use Digest::SHA;
use UUID;

my $key ='';
constant IO_LOG = '3999';
constant DELIM = '<IDS|MSG>';
my $engine_id = UUID.new;



class WireMsg {
  has MsgRecv $.msg is required;
  has UInt $!begin;

  method TWEAK {
    $!begin = self.find-begin;
    die "signature mismatch. Exiting" unless self.signature eq self.auth;

  }

  method find-begin( --> Int ) {
    for 0..^$!msg.elems {
      return ($_ + 1) if $!msg[$_] eq DELIM;
    }
    die "malformed wire message " ~ $!msg.perl;
  }

  method identities()     {  return  $!msg[^$!begin]  }
  method signature()      {  return $!msg[$!begin] }
  method header()         {  return $!msg[$!begin + 1] }
  method parent-header()  {  return $!msg[$!begin + 2] }
  method metadata()       {  return $!msg[$!begin + 3] }
  method content()        {  return $!msg[$!begin + 4] }
  method extra()          {  return $!msg[ $!begin + 5..^$!msg.elems] }
  method auth() {
    return hmac-hex($key, self.header ~ self.parent-header ~ self.metadata ~ self.content, &sha256);
  }
  method id               {return from-json(self.header)< msg_id > }
  method type             {return from-json(self.header)< msg_type > }
  method version          {return from-json(self.header)< version > }

  multi method log(:$raw!) {

  }
  multi method log() {
    MsgBuilder.new\
                    .add("SHELL:\n________________", :newline)\
                    .add('header: ')\
                    .add("{ self.type } { self.version } { self.id }", :newline)\
                    .add('content: ')\
                    .add(self.content, :newline)\
                    .finalize;
                    #.send($iolog-sk);
  }
}
