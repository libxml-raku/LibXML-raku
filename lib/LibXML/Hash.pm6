use v6;
unit class LibXML::Hash does Associative;

use LibXML::Native::Defs :LIB;
use NativeCall;
use LibXML::Native::HashTable;
has xmlHashTable $!native;

use LibXML::Attr;
role Assoc[LibXML::Attr] {
    method of {LibXML::Attr}
    method freeze(|) {...}
    method thaw(|) {...}
    method deallocate(|c) {...}
}

use LibXML::XPath::Object;
role Assoc[LibXML::XPath::Object] {
    method of {LibXML::XPath::Object}
    method freeze(|) {...}
    method thaw(|) {...}
    method deallocate(|c) {...}
}

role Assoc[Str] {
    method of {Str}
    method freeze(|) {...}
    method thaw(|) {...}
    method deallocate(|c) {...}
}

submethod TWEAK is default { $!native .= new; }
submethod DESTROY { .Free with $!native; }

subset OfType where LibXML::Attr|LibXML::XPath::Object|Str;

method ^parameterize(Mu:U \p, OfType:U \t) {
    my $w := p.^mixin: Assoc[t];
    $w.^set_name: "{p.^name}[{t.^name}]";
    $w;
}

method of { Str }
method key-of { Str }

sub toPointer(Str --> Pointer) is native(LIB) is symbol('xmlStrdup') {*}
sub toStr(Pointer --> Str) is native(LIB) is symbol('xmlStrdup') {*}

my class Scoped {
    class Freed is repr('CPointer') {
        method Free is native(LIB) is symbol('xmlFree') {*}
    }
    has Freed $!native;
    submethod TWEAK(:$native!) {
        $!native = nativecast(Freed, $!native);
    }
    submethod DESTROY {
        .Free with $!native;
    }
}

method freeze(Str $v) { toPointer($v) }
method thaw(Pointer $p) { toStr($p) }

method elems { $!native.Size }
method keys  {
    my $keys := $!native.keys;
    my $t = Scoped.new: :native($keys);
    $keys[0 ..^ $.elems];
}

method AT-KEY(Str() $key) { self.thaw: $!native.Lookup($key); }
method EXISTS-KEY(Str() $key) { ? $!native.Lookup($key); }
method ASSIGN-KEY(Str() $key, Str() $val) is rw { $!native.Update($key, $.freeze($val), Pointer); $val }
method DELETE-KEY(Str() $key) { $!native.Remove($key, Pointer) }

