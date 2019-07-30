use v6;
unit class LibXML::Dict does Associative;

use LibXML::Native;
has xmlDict $!native;
use Method::Also;

submethod TWEAK { $!native .= new; }

method of is also<key-of> { Str }

method elems { $!native.Size }

method AT-KEY(Str() $key) { $!native.Exists($key, -1); }
method EXISTS-KEY(Str() $key) { ? $!native.Exists($key, -1); }
method ASSIGN-KEY(Str() $key, Str() $ where $key) is rw { $!native.Lookup($key, -1); $key }

submethod DESTROY { .Free with $!native }
