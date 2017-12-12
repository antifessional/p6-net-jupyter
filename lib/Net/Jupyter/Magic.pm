unit module Net::Jupyter::Magic;

use v6;

class X::Jupyter::MalformedMagic is Exception {
  has Str $.message = 'malformed magic declaration';
  method is-compile-time { True }
}


role ActionParser[::Actions, ::Grammar ] {

  has $._match is rw;

  method parse(::Actions: $str) {
    my Actions $ga .= new;
    $ga._match = Grammar.parse($str, actions => $ga);
    return $ga;
  }
}

grammar MagicGrammar {...}
class Magic {...}

class Magic is export does ActionParser[Magic, MagicGrammar ] {
  has $.wrap-output-each;
  has $.wrap-value-each;
  has $.wrap-output;
  has $.wrap-value;

  has $.ns;
  has $.name;
  has $.class;
  has $.class-status;
  has $.output-mime;
  has $.value-mime;
  has Bool $.reset-ns;
  has Str $.perl-code;


  method TOP($/)     { make $!perl-code }

  method code($/)    { $!perl-code = $/.Str }
  method magic($/)   { #say $/;
  }
  method malformed($/){
    make ~ $/;
    X::Jupyter::MalformedMagic.new(message =>
        'Malformed magic declaration: ' ~ $/.made).throw;
  }

  method declaration:sym<ns>($/) {
   $!name = $<cell>.Str if $<cell>.defined;
   $!ns =  $<namespace>.Str if $<namespace>.defined;
   $!reset-ns = $<reset>.defined;
   #say $!name.perl ~ ':' ~$!ns.perl ~ ':' ~ $!reset-ns;

   X::Jupyter::MalformedMagic.new(message =>
        'Malformed namespace: what am I supposed to reset?').throw
     if (! $!ns.defined && $!reset-ns);

   X::Jupyter::MalformedMagic.new(message =>
        'Malformed namespace: None means None').throw
      if ($!ns eq 'None') && ( $!name.defined || $!reset-ns ) ;
  }

  method declaration:sym<class>($/) {
    $!class = $<classname>.Str;
    $!class-status = $<class_status>.Str if $<class_status>.defined;
  }

  method directive($/) {
    given $<scope>.Str {
        when '>' { $!output-mime = $<mimetype>.Str;  }
        when '|' { $!value-mime =  $<mimetype>.Str; }
    }
  }

}#Magic

grammar MagicGrammar {
  token TOP { <magic>* <code>  }
  token ws  { \h* }
  token code { .* { make $/.Str } }
  rule magic  { \h* '%%' [ <directive>+ | <declaration> | <malformed> ] '%%' \n+  }

  rule malformed { [\w+\s*]* }

  proto token declaration { * }
    token declaration:sym<ns> {
      <sym> \h+  [ <namespace=identifier> ]? [ '::' <cell=identifier> ]? [ \h+ <reset> ]? \h+
    }

    token declaration:sym<class>  {
      <sym> \h+ <classname=identifier> [ \h+ <class_status> ]? \h+
    }

    rule declaration:sym<wrap>  {
      [ <sym> | '@' ] <each>? <scope> [ <wrapper=identifier> | '{' <wrap_body> '}' ]
    }

  rule directive {
      <scope> <mimetype>
  }

  token wrap_body     { [ \w+\s* ]+ }
  token each          { '@' }
  token reset         { 'reset' }
  token class_status  { [ 'begin' | 'cont' ['inue']? | 'end' ] }
  token scope         { '>' | '|' }
  token mimetype      { 'js' | 'html' | 'latex' }
  token identifier    {  \w+ }
}

#    method parse(**@args) { return $!m.parse(@args) }




#.parse(\"%% > js | html %%\n%% ns name1::c1 %%\n%% bad magic %%\n%% @| c1 %%\n%% class Class cont %%\nmy \$x=7;\");"
