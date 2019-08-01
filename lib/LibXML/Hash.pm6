use v6;
unit class LibXML::Hash does Associative;

use LibXML::Native::Defs :LIB, :xmlCharP;
use NativeCall;
use LibXML::Native::HashTable;
has xmlHashTable $!native;

use LibXML::Node :cast-elem;
role Assoc[LibXML::Node] {
    method of {LibXML::Node}
    method freeze(LibXML::Node $n) {
        with $n { nativecast(Pointer, .native) } else { Pointer }
    }
    method thaw(Pointer $p) {
        LibXML::Node.box: cast-elem($p);
    }
    method allocator(LibXML::Node $n, Str $k) {
        .native.add-reference with $n;
    }
    method deallocator() {
        -> Pointer $p, Str $k {
            .release with cast-elem($p);
        }
    }
}

use LibXML::XPath::Object;
role Assoc[LibXML::XPath::Object] {
    method of {LibXML::XPath::Object}
    method freeze(|) {...}
    method thaw(|) {...}
    method deallocator(|c) {...}
}

role Assoc[UInt] {
    method of {UInt}
    method deallocator { -> | {} }
    method freeze(UInt()  $v) { Pointer.new($v); }
    method thaw(Pointer $p) { +$p }
}

role Assoc [Str] {
    method of { Str }
    sub toPointer(Str --> Pointer) is native(LIB) is symbol('xmlStrdup') {*}
    sub toStr(Pointer --> Str) is native(LIB) is symbol('xmlStrdup') {*}

    method freeze(Str() $v) { toPointer($v) }
    method thaw(Pointer $p) { toStr($p) }

}

method allocator($,$) { }
method deallocator { -> Pointer $p, xmlCharP $k { xmlHashDefaultDeallocator($p, $k) } }
submethod TWEAK is default { $!native .= new; }
submethod DESTROY { .Free(self.deallocator) with $!native; }

subset OfType where Str|UInt|LibXML::Node;

method ^parameterize(Mu:U \p, OfType:U \t) {
    my $w := p.^mixin: Assoc[t];
    $w.^set_name: "{p.^name}[{t.^name}]";
    $w;
}

method of { Pointer }
method key-of { Str }

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

method freeze(Pointer() $p) { $p }
method thaw(Pointer $p) { $p }
method elems { $!native.Size }
method keys  {
    my CArray[Str] $keys := $!native.keys;
    my $t = Scoped.new: :native($keys);
    $keys[0 ..^ $.elems];
}
method values {
    my $values := nativecast(CArray[$.of], $!native.values);
    my $t = Scoped.new: :native($values);
    $values[0 ..^ $.elems];
}
method pairs {
    $.keys.list Z=> $.values.list;
}

method AT-KEY(Str() $key) { self.thaw: $!native.Lookup($key); }
method EXISTS-KEY(Str() $key) { ? $!native.Lookup($key); }
method ASSIGN-KEY(Str() $key, $val) is rw {
    $.allocator($val, $key);
    my $v := $.freeze($val);
    $!native.Update($key, $v, $.deallocator); $val;
}
method DELETE-KEY(Str() $key) { $!native.Remove($key, $.deallocator) }

