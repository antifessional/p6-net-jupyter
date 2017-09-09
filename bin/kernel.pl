#!/usr/bin/env perl6

use v6;
use lib '/home/docker/workspace/perl6-net-zmq/lib';

use Net::ZMQ::Context:auth('github:gabrielash');
use Net::ZMQ::Socket:auth('github:gabrielash');
use Net::ZMQ::Message:auth('github:gabrielash');
use Net::ZMQ::Poll:auth('github:gabrielash');
use JSON::Tiny;
use Digest::HMAC;
use Digest::SHA;
use UUID;



my $VERSION := '0.0.1';
my $AUTHOR  := 'Gabriel Ash';
my $LICENSE := 'Artistic-2.0';
my $SOURCE  :=  'https://github.com/gabrielash/jupyter-perl6';
my $err-str = 'Perl6 ikernel:';

constant IO_LOG = '3999';
constant DELIM = '<IDS|MSG>';
my $engine_id = UUID.new;

my Context $ctx;
my Socket $iolog-sk;
my Str $iolog-uri;

my Str $key;
my Str $scheme;

my Socket $ctrl-sk;
my Socket $shell-sk;
my Socket $stdin-sk;
my Socket $hbeat-sk;
my Socket $iopub-sk;


my Str $uri-prefix;
my Str $ctrl-uri;
my Str $shell-uri;
my Str $heartbeat-uri;
my Str $stdin-uri;
my Str $iopub-uri;


sub close-all {
  say "$err-str: Exiting now";
  $iopub-sk.unbind.close;
  $stdin-sk.unbind.close;
  $ctrl-sk.unbind.close;
  $shell-sk.unbind.close;
  $iolog-sk.unbind.close;
  say "$err-str: Adieu!";
}



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


class WireMsg {
  has MsgRecv $.msg is required;
  has UInt $!begin;

  method TWEAK {
    $iolog-sk.send('TWEAKING' ~ $!msg.perl);
    $!begin = self.find-begin;
    die "$err-str signature mismatch. Exiting" unless self.signature eq self.auth;

  }

  method find-begin( --> Int ) {
    for 0..^$!msg.elems {
      return ($_ + 1) if $!msg[$_] eq DELIM;
    }
    die "$err-str malformed wire message " ~ $!msg.perl;
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
    $!msg.send($iolog-sk) ;
  }
  multi method log() {
    MsgBuilder.new\
                    .add("SHELL:\n________________", :newline)\
                    .add('header: ')\
                    .add("{ self.type } { self.version } { self.id }", :newline)\
                    .add('content: ')\
                    .add(self.content, :newline)\
                    .finalize\
                    .send($iolog-sk);
  }
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

sub MAIN( $connection-file ) {



  $ctx .= new;
  $iolog-uri = "tcp://127.0.0.1:3999";
  $iolog-sk .= new( $ctx , :push );
  $iolog-sk.bind( $iolog-uri );
  say " sent to log " , ~$iolog-sk.send("CONN: $connection-file");


  die "$err-str Connection file not found" unless $connection-file.IO.e;
  die "$err-str Connection file is not a file" unless $connection-file.IO.f;
  die "$err-str Connection file is not readable" unless $connection-file.IO.r;

  my $con = slurp $connection-file;
  my %conn = from-json($con);
  for %conn.kv -> $k, $v {say "$k = $v" };

  say " sent to log " , ~$iolog-sk.send( %conn.perl );

  $uri-prefix = %conn{'transport'} ~ '://' ~ %conn{'ip'} ~ ':';
  $ctrl-uri = $uri-prefix ~ %conn{'control_port'};
  $shell-uri = $uri-prefix ~ %conn{'shell_port'};
  $heartbeat-uri = $uri-prefix ~ %conn{'hb_port'};
  $stdin-uri = $uri-prefix ~ %conn{'stdin_port'};
  $iopub-uri = $uri-prefix ~ %conn{'iopub_port'};


  $ctrl-sk  .= new( $ctx , :router );
  $shell-sk .= new( $ctx , :router );
  $stdin-sk .= new( $ctx , :router );
  $iopub-sk .= new( $ctx , :publisher );


  $iopub-sk.bind( $iopub-uri );
  $ctrl-sk.bind( $ctrl-uri );
  $shell-sk.bind( $shell-uri );
  $stdin-sk.bind( $stdin-uri );

  $key = %conn< key >;
  $scheme = %conn< signature_scheme >;

  say " sent to log " , ~$iolog-sk.send("starting");

  my $hb-thread = start {
      my $hctx .= new;
      $hbeat-sk .= new( $hctx , :server );
      $hbeat-sk.bind( $heartbeat-uri );
      my Proxy $proxy .=new(:frontend($hbeat-sk)
                            ,:backend($hbeat-sk));
      loop {
        $proxy.run();
        CATCH {
          default {
            $hbeat-sk.unbind.close;
            .Str.say;
            die "$err-str Proxy hearbeat died - " ~ .Str;
          }
        }
      }
  }

 say " sent to log " , ~$iolog-sk.send("Heartbeat set");


 my Poll $poller = PollBuilder.new\
      .add( MsgRecvPollHandler.new($ctrl-sk, &ctrl-handler ))\
      .add( MsgRecvPollHandler.new($shell-sk, &shell-handler ))\
      .add( MsgRecvPollHandler.new($stdin-sk, &stdin-handler ))\
      .delay(10)\
      .finalize;

  say  " sent to log " , ~$iolog-sk.send("Poll set");

  loop {
      say "polling";
      last if Any === $poller.poll();
  }


  close-all;
}


sub USAGE {

  say qq:to/END/;

    Perl6 Jupyter Kernel
    Usage
          perl6 scriptname connection

    Version   $VERSION
    Author    $AUTHOR
    License   $LICENSE
    sources   $SOURCE

    END
    #:

}

=begin c
{
  "control_port": 50160,
  "shell_port": 57503,
  "transport": "tcp",
  "signature_scheme": "hmac-sha256",
  "stdin_port": 52597,
  "hb_port": 42540,
  "ip": "127.0.0.1",
  "iopub_port": 40885,
  "key": "a0436f6c-1916-498b-8eb9-e81ab9368e84"
}
=end c
=cut
