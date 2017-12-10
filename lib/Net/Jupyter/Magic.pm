
my  $wrap-output-each;
my  $wrap-value-each;
my  $wrap-output;
my  $wrap-value;

my $ns;
my $name;
my $class;
my $class-status;
my $output-mime;
my $value-mime;
my $reset;




class X::Jupyter:MalformedMagic is Exception {
  has Str $.message = 'malformed magic declaration';
  method is-compile-time { True }
}

Grammar Magic {
  token TOP { <magic>* <code> }
  token ws  { \h* }
  token code { .* }
  rule magic  { '%%' [ <directive>+ | <declaration> | <malformed> ] '%%' \n+  }

  rule malformed { [\w+\s*]*  
                    { make ~ $/;
                      X::Jupyter:MalformedMagic.new(message => 
                              'Malformed magic declaration: ' ~ $/.made).throw;
                    }
                  }

  proto token declaration { * }
    token declaration:sym<ns> {
      <sym> \h+  <namespace=identifier> [ '::' <cell=identifier> ]? [ \h+ <reset> ]? \h+
          { $name = ~ $<cell> if $<cell>.defined; 
            $ns = ~ $<namespace>;
            $reset = $<reset>.defined;
          }
    }

    token declaration:sym<class>  { 
      <sym> \h+ <classname=identifier> \h+ <class-status>? \h+ 
        { $class= ~ $<classname>;
          $class-status = ~ $<class_status> if $<class_status>.defined;
        }
    }

    rule declaration:sym<wrap>  { 
      [ <sym> | '@' ] <each>? <scope> [ <wrapper=identifier> | '{' <wrap_body> '}' ] 

    }
  
  rule directive { 
      <scope> <mimetype> 
        {  given $<scope>.Str {
              when '>' { $output-mime = ~ $<mimetype>;  }
              when '|' {  $value-mime = ~ $<mimetype>; }
            }
        }
  }

  token wrap_body     { [ \w+\s* ]+ }
  token each          { '@' }
  token reset         { 'reset' }  
  token class_status  { [ 'begin' | 'cont' | 'end' ] }
  token scope         { '>' | '|' }
  token mimetype      { 'js' | 'html' | 'latex' } 
  token identifier    {  \w+ }
}


#.parse(\"%% > js | html %%\n%% ns name1::c1 %%\n%% bad magic %%\n%% @| c1 %%\n%% class Class cont %%\nmy \$x=7;\");"
