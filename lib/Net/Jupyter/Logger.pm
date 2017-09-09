#!/usr/bin/env perl6

unit module Net::Jupyter::Logger;

use v6;
use JSON::Tiny;

use Net::ZMQ::Context:auth('github:gabrielash');
use Net::ZMQ::Socket:auth('github:gabrielash');
use Net::ZMQ::Message:auth('github:gabrielash');


my %LEVELS = ( :critical(0) :error(1) :warning(2) :info(3) :debug(4) :trace(5) );
my %ILVELS = zip(%LEVELS.values, %LEVELS.keys).flat;

my %STYLES = ( :json, :zmq, :yaml );

my $log-uri := "tcp://127.0.0.1:3999";

my Str $level = 'warning';
my Str $target = 'user';
my Str $style = 'simple';
my Str $default-domain = 'none';
my %domains = %('none' => 1);

class Logger {...}
class Logging {...}

role yaml-format {
  method yaml-format(:$builder, :$prefix, :$timestamp, :$level, :$domain, :$content, :$target ) {
    $builder.add(qq:to/END_YAML/)
      timestamp: $timestamp
      prefix: "$prefix"
      level: $level
      domain: $domain
      target: $target
      content: "$content"
      END_YAML
      #:
  }
}

role zmq-format {
  method zmq-format(:$builder, :$prefix, :$timestamp, :$level, :$domain, :$content, :$target) {
    $builder.add($content)\
    .add($timestamp)\
    .add($prefix)\
    .add($level)\
    .add($domain)\
    .add($target);
  }
}

role json-format {
  method json-format(:$builder, :$prefix, :$timestamp, :$level, :$domain, :$content, :$target ) {
    my %h = qqw/prefix $prefix level $level domain $domain target $target/;
    %h{'content'}  = $content;
    %h{'timestamp'} = $timestamp;
    $builder.add(to-json(%h));
  }
}

my Logging $log-publisher;

class Logging is export {
  trusts Logger;

  has Context $!ctx;
  has Socket $!socket;
  has Str $.uri = $log-uri;

  our sub logging() is export {
    $log-publisher := Logging.new unless $log-publisher.defined;
    return $log-publisher;
  }

  method TWEAK()  {
    $!ctx .= new;
    $!socket .= new( $!ctx , :publisher );
    $!socket.bind( $!uri );
  }

  method !socket() { return $!socket  };

  method logger(:$prefix!, :$debug) {
       return  Logger.new(
                        :$level
                        , :$target
                        , :$style
                        , :$default-domain
                        , :$prefix
                        , :%domains
                        , :$debug
                        , :logging(self)
                        );

  }

  method DESTROY()  {
    $!ctx.shutdown;
    $!socket.unbind.close;
  }

}

class Logger does yaml-format does zmq-format does json-format is export {
  has Logging $.logging;
  has Str $.level = 'warning';
  has Str $.target = 'user';
  has Str $.style = 'yaml';
  has Str $.default-domain = 'none';
  has Str $.prefix is required;
  has %.domains = %('none' => 1);
  has $.debug = False;
  has %!styles;

 method TWEAK {
   my %methods = self.WHAT.^methods.map( { [ $_.name, $_ ] } ).flat;
   %!styles = %methods.keys.grep(/ \-format$ / )\
                                .map( { $_ ~~ m/(.+) \-format$  /;
                                        [ "$0", %methods{$_}] }  )\
                                .flat;
 }

  method default-level(*%h ) { say  %h.keys[0];
    die "level must be one of { %LEVELS.keys }" unless %h.elems == 1 and  %LEVELS{ %h.keys[0] }:exists;
    $!level = %h.keys[0];
    return self;
  }

  method domains(*@domains) {
    die "at least one domain is required"   unless @domains.elems > 0;
    %!domains = zip(@domains.flat
                      .map( { die "domain $_ is not a String" unless $_.isa(Str) ;$_ }  )
                        , (1 for 0..^@domains.flat.elems)).flat;
    $!default-domain = @domains[0];
    say %!domains;
    return self;
  }

  method target(Str $target) {
    $!target = $target;
    return self;
  }

  method style(*%h) {
    die "style must be one of { %!styles.keys }" unless %h.elems == 1 and  %!styles{ %h.keys[0] }:exists;
    $!style = %h.keys[0];
    return self;
  }

  method log(Str $content
              , :$level where { !$level.defined or  %LEVELS{$level}:exists }
              , :$domain where { !$domain.defined or  %!domains{$domain}:exists } ) {
    my $lvl = $level.defined ?? $level !! $!level;
    my $dom = $domain.defined ?? $domain !! $!default-domain ;
    self!log-send($content, $lvl, $dom);
  }

  method !log-send(Str $content, $level, $domain )  {
    my $timestamp = DateTime.new(now).Str;
    my $builder = MsgBuilder.new\
        .add($!prefix, :newline)\
        .add(:empty)
        .add($!style, :newline);

    my Method $m = %!styles{$!style};
    $builder = self.$m(:$builder, :$!prefix, :$timestamp
                                            , :$level, :$domain, :$!target, :$content );

    $builder.finalize.send( $!logging!Logging::socket );
    say $builder.copy if $!debug;
  }


}
