#!/usr/bin/env perl6

use v6;
use lib '/home/docker/workspace/perl6-net-zmq/lib';
use lib '/home/docker/workspace/p6-log-zmq/lib';
use lib '/home/docker/workspace/perl6-jupyter/lib';

use Net::ZMQ::Context:auth('github:gabrielash');
use Net::ZMQ::Socket:auth('github:gabrielash');
use Net::ZMQ::Message:auth('github:gabrielash');
use Net::ZMQ::Poll:auth('github:gabrielash');
use Net::ZMQ::EchoServer:auth('github:gabrielash');

use Net::Jupyter::Common;
use Net::Jupyter::Utils;
use Net::Jupyter::Protocol;

use Log::ZMQ::Logger;

use JSON::Tiny;
use Digest::HMAC;
use Digest::SHA;
use UUID;

# **************************************************** //
use MONKEY-SEE-NO-EVAL;
# **************************************************** //

my $VERSION := '0.0.1';
my $AUTHOR  := 'Gabriel Ash';
my $LICENSE := 'Artistic-2.0';
my $SOURCE  :=  'https://github.com/gabrielash/jupyter-perl6';

my $err-str = 'Perl6 ikernel:';
my $engine-id;

constant POLL_DELAY = 10;

my Logger $LOG = Logging::instance('jupyter', :format(:zmq)).logger;

$LOG.log("$err-str init");

my Context $ctx;

my Str $key;
my Str $scheme;

my Socket $ctrl;
my Socket $shell;
my Socket $stdin;
my Socket $iopub;

my Str $uri-prefix;
my Str $ctrl-uri;
my Str $shell-uri;
my Str $stdin-uri;
my Str $iopub-uri;
my Str $heartbeat-uri;

my EchoServer $heartbeat;

sub close-all {
  $LOG.log("$err-str: Exiting now");
  $iopub.unbind.close;
  $stdin.unbind.close;
  $ctrl.unbind.close;
  $shell.unbind.close;
  $heartbeat.shutdown;
  $LOG.log("$err-str: Adieu");
}

sub uuid {
  return UUID.new(:version(4)).Str;
  #return UUID.new(:version(4)).Blob().gist.substr(14,47).split(' ').join('').uc();
}

sub new-header($type) {
    return qq:to/HEADER_END/;
      \{"date": "{ DateTime.new(now) }",
      "msg_id": "{ uuid() }",
      "username": "kernel",
      "session": "$engine-id",
      "msg_type": "$type",
      "version": "5.0"\}
      HEADER_END
      #:
}

sub send(Socket:D :$stream!, Str:D :$type!, :$content, :$parent-header, :$metadata, :@identities) {
    my $header = new-header($type);
    my $signature =  hmac-hex($key, $header ~ $parent-header ~ $metadata ~ $content,  &sha256);
    my MsgBuilder $m .= new;
    @identities.map( { $m.add($_) } );
    say "IDENTITES: ", @identities;

    my Message $msg = $m.add(DELIM)\
                        .add($signature)\
                        .add( $header )\
                        .add( $parent-header )\
                        .add($metadata)\
                        .add( $content )\
                        .finalize;
      $LOG.log("SENDING " ~ $msg.copy);

      $msg.send($stream);
  }

sub shell-handler(MsgRecv $m) {
  $LOG.log("$err-str: SHELL");

  my Protocol $pcol .= new(:msg($m), :key($key), :logger($LOG) );
  my $parent-header = $pcol.header();
  my $metadata = '{}';
  my @identities = $pcol.identities();

  given $pcol.type() {
    when 'kernel_info_request' {
        my $content = kernel_info-reply-content();
        send(:stream($shell), :type('kernel_info_reply'), :$content, :$parent-header, :$metadata, :@identities);
    }
    when 'execute_request' {
      my $count = 1;
      my $code = $pcol.code;
      my $result = EVAL($code);
      my $expressions = '{}';
      say "CODE:$code\nEVAL: $result";
      my @iopub-identities = 'execute_request';
      send(:stream($iopub), :type('status'), :content(" { status-content('busy') }")
            , :$parent-header, :metadata('{}'), :identities(@iopub-identities ));
      send(:stream($iopub), :type('execute_input'), :content(execute_input-content($count, $code))
            , :$parent-header, :metadata('{}'), :identities( @iopub-identities ));
      send(:stream($iopub), :type('stream'), :content(stream-content('stdout', $code))
            , :$parent-header, :metadata('{}'), :identities( @iopub-identities ));
      send(:stream($iopub), :type('execute_result'), :content(execute_result-content($count, $result, $metadata))
            , :$parent-header, :metadata('{}'), :identities( @iopub-identities ));
      send(:stream($iopub), :type('status'), :content(status-content('idle'))
            , :$parent-header, :metadata('{}'), :identities( @iopub-identities ));

      send(:stream($shell), :type('execute_reply')
          , :content(execute_reply-content($expressions, $count))
          , :$parent-header
          , :metadata(execute_reply_metadata($engine-id))
          , :@identities);
    }
    when 'comm_open' {
    }
    default {
      $LOG.log("message type $_ NOT IMPLEMENTED");
    }
  }
}

sub ctrl-handler(MsgRecv $m) {
  $LOG.log("$err-str: CTRL");
  die "CTRL";
  my Protocol $pcol .= new(:msg($m));
  $pcol.log;

}

sub MAIN( $connection-file ) {

  $engine-id = uuid();

  die "$err-str Connection file not found" unless $connection-file.IO.e;
  die "$err-str Connection file is not a file" unless $connection-file.IO.f;
  die "$err-str Connection file is not readable" unless $connection-file.IO.r;

  my $con = slurp $connection-file;
  my %conn = from-json($con);
  for %conn.kv -> $k, $v {say "$k = $v" };

  $uri-prefix = %conn{'transport'} ~ '://' ~ %conn{'ip'} ~ ':';
  $ctrl-uri = $uri-prefix ~ %conn{'control_port'};
  $shell-uri = $uri-prefix ~ %conn{'shell_port'};
  $heartbeat-uri = $uri-prefix ~ %conn{'hb_port'};
  $stdin-uri = $uri-prefix ~ %conn{'stdin_port'};
  $iopub-uri = $uri-prefix ~ %conn{'iopub_port'};

  $ctx .= new;
  $ctrl  .= new( $ctx, :router );
  $shell .= new( $ctx, :router );
  $stdin .= new( $ctx, :router );
  $iopub .= new( $ctx, :publisher );

  $iopub.bind( $iopub-uri );
  $ctrl.bind( $ctrl-uri );
  $shell.bind( $shell-uri );
  $stdin.bind( $stdin-uri );

  $key = %conn< key >;
  $scheme = %conn< signature_scheme >;
  die "hmac-sha256 is the only implemented signature scheme "
    unless $scheme eq 'hmac-sha256';

  $heartbeat = EchoServer.new( :uri($heartbeat-uri) );
  $LOG.log("$err-str heartbeat started $heartbeat-uri");

  my Poll $poller = PollBuilder.new\
#      .add( MsgRecvPollHandler.new($ctrl, &ctrl-handler ))\
      .add( MsgRecvPollHandler.new($shell, &shell-handler ))\
#      .add( MsgRecvPollHandler.new($stdin, &stdin-handler ))\
      .delay( POLL_DELAY)\
      .finalize;

  $LOG.log("$err-str polling set");

  loop {
      #die "POLL SETTING $shell-uri";
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
