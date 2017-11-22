#!/usr/bin/env perl6

unit module Net::Jupyter::Utils;

use v6;

use JSON::Tiny;
use Digest::HMAC;
use Digest::SHA;
use UUID;


constant NHASH = '{}';
constant NARRAY = '[]';


sub uuid is export {
  return UUID.new(:version(4)).Str;
  #return UUID.new(:version(4)).Blob().gist.substr(14,47).split(' ').join('').uc();
}

sub new-header($type, $engine-id) is export {
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


sub error-content($name, $value, $traceback='[]') is export {
  return qq:to/ERROR_END/;
    \{ "status" : "error",
    "ename" : "$name",
    "evalue" : "$value",
    "traceback" : $traceback \}
    ERROR_END
    #;
}

sub status-content($status) is export {
  die "Bad status: $status" unless ('idle','busy').grep( $status );
  return to-json( %( qqw/ execuution_state $status/)  );
}


sub execute_input-content($count, $code) is export {
  return qq:to/EX_IN_END/;
    \{"execution_count": $count,
      "code": "$code" \}
    EX_IN_END
    #;

}

sub stream-content($stream, $text) is export {
  return qq:to/STREAM_END/;
    \{"name": "$stream",
      "text": "$text" \}
    STREAM_END
    #;

}

sub execute_result-content($count, $result, $metadata) is export {
  return qq:to/EX_RES_END/;
    \{"execution_count": $count,
      "data": \{ "text/plain": "$result" \},
      "metadata": \{\} \}
    EX_RES_END
    #;
}

sub execute_reply-content($expressions, $count) is export {
  return qq:to/EXECUTE_END/;
  \{ "status": "ok",
    "execution_count": $count,
    "payload": [],
    "user_expressions": $expressions \}
  EXECUTE_END
  #;
}

sub execute_reply_metadata($id) is export {
  return qq:to/EX_META_END/;
    \{"started": "{ DateTime.new(now) }",
    "dependencies_met": true,
    "engine": "$id",
    "status": "ok"\}
    EX_META_END
}


sub kernel_info-reply-content is export {
  my %info = <
    protocol_version 5.2.0
    implementation  iperl6
    implementation_version 0.0.1 >;
  my %language_info = <
        name perl6
        version 6.c
        mimetype application/perl6
        file_extension .pl6>;
=begin c
        # Pygments lexer, for highlighting. Only needed if it differs from the 'name' field.
        'pygments_lexer': str,

        # Codemirror mode, for for highlighting in the notebook.  Only needed if it differs from the 'name' field.
        'codemirror_mode': str or dict,

        # Nbconvert exporter, if notebooks written with this kernel should be exported with something other than the general 'script' exporter.
        'nbconvert_exporter': str,
=end c
=cut

  %info< banner > = 'Awesomest Perl6';
  %info<help_links> = [ %("text", "help here", "url", "http://perl6.org") ] ;
  %info< language_info > = %language_info;
  return to-json(%info);
}


=begin c
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
=end c
=cut
