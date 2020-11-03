use v6;
unit class LibXML::Dict does Associative;

use LibXML::Raw::Dict;
use Method::Also;

has xmlDict $!native;

multi submethod TWEAK(xmlDict:D :$!native!) { $!native.Reference }
multi submethod TWEAK is default { $!native .= new; $!native.Reference }

submethod DESTROY {
    .Unreference with $!native;
}

method of { Str }
method key-of { Str }

method elems { $!native.Size }

method AT-KEY(Str() $key) { $!native.Exists($key, -1); }
method EXISTS-KEY(Str() $key) is also<seen> { ? $!native.Exists($key, -1); }
method ASSIGN-KEY(Str() $key, Str() $ where $key) is rw { $!native.Lookup($key, -1); $key }

multi method see(Str:D() $key) {
    $!native.Lookup($key, -1);
}
multi method see(@k) {
    $!native.Lookup($_, -1) for @k;
}

=begin pod

=head2 Synopsis

  my LibXML::Dict $dict .= new;
  $dict.see('a');
  $dict.see: <x y z>;
  say $dict.seen('a'); # True
  say $dict.seen('b'); # False
  say $dict<a>:exists; # True
  say $dict<b>:exists; # False
  say $dict.elems; # a x y z

=head2 Description

A LibXML::Dict bins to the xmlDict data structure, which is used to uniquely identify
and store strings.

Please see also L<LibXML::HashMap>, for a more general-purpose associative interface.

=end pod
