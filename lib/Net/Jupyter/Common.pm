#!/usr/bin/env perl6

unit module Net::Jupyter::Common;

use v6;

use UUID;

constant DELIM is export = '<IDS|MSG>';


sub uuid is export {
  return UUID.new(:version(4)).Str;
  #return UUID.new(:version(4)).Blob().gist.substr(14,47).split(' ').join('').uc();
}

sub random-name(Str :$prefix='a_') is export {
  return $prefix ~ UUID.new(:version(4)).Str.substr(0,12).split('-').join('');
}
