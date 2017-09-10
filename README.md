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

  Methods
    logger(:prefix)  ; returns a Logger 
  

#### Net::Jupyter::Logger  (to be moved to separate rep)

A logger that logs to a ZMQ socket.

    Example 1 simple:
      my $l = Logging::logging.logger;
      $l.log 'an important message';

    Example 2 less simple: 
      my $logger = Logging::logging('tcp://78.78.1.7')\
                                    .logger\
                                    .default-level( :warning )\
                                    .domains( < database engine front-end nativecall > )\
                                    .target( 'debug' )\
                                    .format(:json);

      $logger.log( 'an important message' :critical :front-end );



    
    Attributes
      prefix;   required
      level; (default level  = warning)
      target; (default target = user )
      format;   defaulr yaml
      default-domain; default 'none';
      %domains ; keys are legit domain
      debug ;  default False;

    setters
      default-level
      domains( @list)
      target
      format

    Methods
      log( log-message, :level, :domain )
        
The logging uses a publisher sopcket. All protocols send first
  1. prefix
  2. domain
  3. level
  4. format [ zmq | yaml | json | ... ]
  5. empty frame

the next frames depend on the format. For zmq
  6. content
  7. timestamp
  8. target

for yaml/json
  6. yaml/json formatted  

To add your own formatter, add a role to the logger with a method 
  method name-format(MsgBuilder :builder, :prefix, :timestamp, :level , :domain, :target, :content
                        --> MsgBuilder ) {
  ... your code here ...
  return $builder;
  }
the builder should be returned unfinalized. 
then set the format to name:
  $logger.format('name');

## LICENSE

All files (unless noted otherwise) can be used, modified and redistributed
under the terms of the Artistic License Version 2. Examples (in the
documentation, in tests or distributed as separate files) can be considered
public domain.

ⓒ 2017 Gabriel Ash
