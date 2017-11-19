#!/usr/bin/env perl6

unit module Net::Jupyter::Utils;

use v6;

use Net::ZMQ::Context:auth('github:gabrielash');
use Net::ZMQ::Socket:auth('github:gabrielash');
use Net::ZMQ::Message:auth('github:gabrielash');
use Net::ZMQ::Poll:auth('github:gabrielash');
use JSON::Tiny;
use Digest::HMAC;
use Digest::SHA;
use UUID;


sub kernel-info-reply {
  my %info = <
    protocol_version 5.2.0
    implementation  perl6
    implementation_version 0.0.1 >;
  %info< language_info > = <
        name perl6
        version 6.c
        mimetype application/perl6
        file_extension .pl6>;
  %info< banner > = 'Perl6';
  %info<help_links> = [ %("text", "help here", "url", "http://perl6.org") ] ;
  return to-json(%info);
}

sub new-header(:$id, :$type)  {
  return qq:to/HEADER_END/;
  \{"date": "{ DateTime.new(now) }"
  "msg_id": "$id",
  "username": "kernel",
  "session": "$engine_id",
  "msg_type": "$type",
  "version": "5.0"\}
  HEADER_END
  #:
}

sub execution-reply($expressions, $counter) {
  my %content = qw/ status ok execution_count $counter/;
  %content< user_expressions>  = [ 'x' , 7 ];
  return to-json( %content );
}




sub ctrl-handler(MsgRecv $m) {

  my WireMsg:D $wire .= new(:msg($m));
  given $wire.type {
    when 'shutdown_request' {
      MsgBuilder.new\
              .add('shutdown_reply')\
              .add( new-header(:id($wire.id), :type('shutdown_reply')))\
              .add( $wire.header )\
              .add('{}')\
              .add( '{"restart": false }' )\
              .finalize\
              .send-all($iolog-sk, $iopub-sk);
      return  Any;
    }
  }

  1;
}

sub shell-handler(MsgRecv $m) {
  say "HANDLING SHELL";
  my WireMsg $wire .= new(:msg($m));
  $wire.log;
=begin c
  given $wire.type {
    when 'execute_request'  {

      MsgBuilder.new\
              .add('status')\
              .add( new-header(:id($wire.id), :type('status')))\
              .add( $wire.header )\
              .add('{}')\
              .add('{"execution_status":"busy" }')
              .finalize\
              .send-all($iolog-sk, $iopub-sk);
      my $content = execution-reply($wire.content, 1);
      MsgBuilder.new\
              .add('execution_reply')\
              .add( new-header(:id($wire.id), :type('execution_reply')))\
              .add( $wire.header )\
              .add('{}')\
              .add( $content )\
              .finalize\
              .send-all($iolog-sk, $iopub-sk);
    }
    when 'kernel_info_request' {
      MsgBuilder.new\
              .add('kernel_info_reply')\
              .add( new-header(:id($wire.id), :type('kernel_info_reply')))\
              .add( $wire.header )\
              .add('{}')\
              .add( kernel-info-reply() )\
              .finalize\
              .send-all($iolog-sk, $iopub-sk);
    }
    when 'shutdown_request' {
      MsgBuilder.new\
              .add('shutdown_reply')\
              .add( new-header(:id($wire.id), :type('shutdown_reply')))\
              .add( $wire.header )\
              .add('{}')\
              .add( '{"restart": false }' )\
              .finalize\
              .send-all($iolog-sk, $iopub-sk);
      return  Any;
    }
  }
=end c
=cut

  Any;
}

sub stdin-handler(MsgRecv $m) {
  1;
}
