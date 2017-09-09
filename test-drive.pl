#!/usr/bin/env perl6

use v6;
use lib '../perl6-net-zmq/lib';

use Net::ZMQ::Context:auth('github:gabrielash');
use Net::ZMQ::Socket:auth('github:gabrielash');
use Net::ZMQ::Message:auth('github:gabrielash');
use Net::ZMQ::Poll:auth('github:gabrielash');
use JSON::Tiny;

my $err-str = 'Perl6 ikernel:';
constant IO_LOG = '3999';

my Context $ctx;

my Socket $ctrl-sk;
my Socket $shell-sk;
my Socket $stdin-sk;
my Socket $hbeat-sk;
my Socket $iopub-sk;
my Socket $iolog-sk;

my Str $uri-prefix;
my Str $ctrl-uri;
my Str $shell-uri;
my Str $heartbeat-uri;
my Str $stdin-uri;
my Str $iopub-uri;
my Str $iolog-uri;


sub close-all {
  say "$err-str: Exiting now";
  $iopub-sk.disconnect.close;
  $stdin-sk.unbind.close;
  $ctrl-sk.unbind.close;
  $shell-sk.unbind.close;
  $hbeat-sk.disconnect.close;
  $iolog-sk.unbind.close;
  say "$err-str: Adieu!";
}
sub MAIN( $connection-file ) {

  die "$err-str Connection file not found" unless $connection-file.IO.e;
  die "$err-str Connection file is not a file" unless $connection-file.IO.f;
  die "$err-str Connection file is not readable" unless $connection-file.IO.r;

  my $con = slurp $connection-file;
  my %conn = from-json($con);
  for %conn.kv -> $k, $v {say "$k = $v" };

  $ctx .= new;
  $uri-prefix = %conn{'transport'} ~ '://' ~ %conn{'ip'} ~ ':';
  $ctrl-uri = $uri-prefix ~ %conn{'control_port'};
  $shell-uri = $uri-prefix ~ %conn{'shell_port'};
  $heartbeat-uri = $uri-prefix ~ %conn{'hb_port'};
  $stdin-uri = $uri-prefix ~ %conn{'stdin_port'};
  $iopub-uri = $uri-prefix ~ %conn{'iopub_port'};

  $iolog-uri = $uri-prefix ~ IO_LOG;

#  $hbeat-sk  .= new( $ctx , :client );
#  $ctrl-sk  .= new( $ctx , :dealer );
#  $shell-sk .= new( $ctx , :dealer );
#  $stdin-sk .= new( $ctx , :dealer );
#  $iopub-sk .= new( $ctx , :subscriber );

  $iolog-sk .= new( $ctx , :pull );

#  $hbeat-sk.connect( $heartbeat-uri );
#  $iopub-sk.connect( $iopub-uri );
#  $ctrl-sk.bind( $ctrl-uri );
#  $shell-sk.bind( $shell-uri );
#  $stdin-sk.bind( $stdin-uri );

   $iolog-sk.connect( $iolog-uri );

  loop {
    my $r = MsgRecv.new;
    $r.slurp($iolog-sk);
    say " \t\tlog:";
    say $r[$_] for 0..^$r.elems;
  }
}

END { close-all}
