use v6;
unit class LibXML::Dict does Associative;

use LibXML::Native::Dict;
has xmlDict $!native;

multi submethod TWEAK(xmlDict:D :$!native!) { $!native.Reference }
multi submethod TWEAK is default { $!native .= new; }

submethod DESTROY {
    .Unreference with $!native;
}

method of { Str }
method key-of { Str }

method elems { $!native.Size }

method AT-KEY(Str() $key) { $!native.Exists($key, -1); }
method EXISTS-KEY(Str() $key) { ? $!native.Exists($key, -1); }
method ASSIGN-KEY(Str() $key, Str() $ where $key) is rw { $!native.Lookup($key, -1); $key }

