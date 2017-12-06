#!/usr/bin/env perl6

unit module Net::Jupyter::MicroREPL;

use v6;
use nqp;

use Net::Jupyter::Common;

# **************************************************** //
use MONKEY-SEE-NO-EVAL;
# **************************************************** //

%*ENV<RAKUDO_LINE_EDITOR> = 'none';
%*ENV<RAKUDO_ERROR_COLOR> = 0;
%*ENV<RAKUDO_DISABLE_MULTILINE> = 1;


class MicroREPL is REPL {

  method eval(Str $code, Bool $err is rw, Bool $warn is rw) {
        my $value;
        my Exception $ex;

        try {
            $value = EVAL(embed($code));
            CONTROL {
              when CX::Return {
              }
              default {
                $warn = True;
                $ex := $_;
              }
            }
            CATCH {
              when X::Buf::AsStr {
                $value = $value.perl;
              }
              default {
                $err = True;
                $ex := $_;
                return Nil;
              }
            }
          }
        $value = Nil without $value;
          return $value;
    }

  method embed($_code_3437, $__random__name_7545 = random-name() ) {
      return qq:to/ENCLOSED/;
        package $__random__name_7545 \{
           our sub __X  \{
             $_code_3437
          \}
        \}
        $__random__name\:\:__X();
        ENCLOSED
        #
  }

}#MicroREPL
