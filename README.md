# Net::ZMQ

## SYNOPSIS

Net::Jupyter is a Perl6 Jupyter kernel

## Introduction

#### Status

This is in development. The only certainty is that the tests pass on my machine.  

#### Alternatives

#### Versions

#### Portability

## Example Code

## Documentation

#### Net::Jupyter::Logging  (to be moved to separate rep)

  The logging framework based on ZMQ. Usually a singleton summoned with 

    my $log-system = Logging::logging;

  but can also be initialized with a desired uri:

    my $log-system = Logging.new( 'tcp://127.127.8.17:8022' );

#### Net::Jupyter::Logging  (to be moved to separate rep)

A logger that logs to a ZMQ socket.

    Attributes
      prefix;   required
      level; (default level  = warning)
      target; (default target = user )
      style;   defaulr yaml
      default-domain; default 'none';
      %domains ; keys are legit domain
      debug ;  default False;

    setters
      default-level
      domains( @list)
      target
      style

    Methods
      log( log-message, :level, :domain )
        
The logging uses a publisher sopcket. All protocols send first
  1. prefix
  2. style [ zmq | yaml | json | ... ]
  3. empty frame

the next frames depend on the style. For zmq
  4. content
  5. timestamp
  6. prefix
  7. level
  8. domain
  9. target

for yaml/json
  4. yaml/json formatted  

To add your own formatter, add a role to the logger with a method 
  method name-format(MsgBuilder :builder, :prefix, :timestamp, :level , :domain, :target, :content
                        --> MsgBuilder ) {
  ... your code here ...
  return $builder;
  }
the builder should be returned unfinalized. 
then set the style to name:
  $logger.style('name');







  













my $logger = $logsys.logger(:$prefix);
my $logger2 = $logsys.logger(:prefix("--$prefix"), :debug);

ok $logger.defined , 'got logger test';

lives-ok { $logger.domains('dom1', 'dom2' ); } ,"set domains";
lives-ok { $logger.default-level(:info); } ,"set level info";
lives-ok { $logger.target('syslog'); } ,"set target syslog";
lives-ok { $logger.style(:yaml);} ,"set style yaml";
lives-ok { $logger2.style(:yaml);} ,"set style yaml";





## LICENSE

All files (unless noted otherwise) can be used, modified and redistributed
under the terms of the Artistic License Version 2. Examples (in the
documentation, in tests or distributed as separate files) can be considered
public domain.

ⓒ 2017 Gabriel Ash
