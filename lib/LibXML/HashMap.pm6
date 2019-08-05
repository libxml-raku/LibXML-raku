use v6;
unit class LibXML::HashMap does Associative;

use LibXML::Node :cast-elem;
use LibXML::Node::Set;
use LibXML::XPath::Object :XPathDomain;
use LibXML::Native::Defs :LIB, :xmlCharP;
use LibXML::Native::HashTable;
use NativeCall;
use Method::Also;

has xmlHashTable $!native;
method native { $!native }

role Assoc[LibXML::Node] {
    method of {LibXML::Node}
    method freeze(LibXML::Node $n) {
        with $n.native {
            .Reference;
            nativecast(Pointer, $_);
        }
        else {
            Pointer;
        }
    }
    method thaw(Pointer $p) {
        LibXML::Node.box: cast-elem($p);
    }
    method deallocator() {
        -> Pointer $p, Str $k {
            cast-elem($_).Unreference with $p;
        }
    }
}

# node sets - experimental!
role Assoc[LibXML::Node::Set] {
    method of {LibXML::Node::Set}
    method freeze(LibXML::Node::Set $n) {
        with $n.native {
            .Reference;
            nativecast(Pointer, $_);
        }
        else {
            Pointer;
        }
    }
    method thaw(Pointer $p) {
        my $native = nativecast(LibXML::Node::Set.native, $p);
        LibXML::Node::Set.new: :$native;
    }
    method deallocator() {
        -> Pointer $p, Str $k {
            nativecast(LibXML::Node::Set.native, $_).Unreference with $p;
        }
    }
}

# xpath objects experimental!
role Assoc[XPathDomain] {
    method of {XPathDomain}

    method freeze(XPathDomain $content is copy) {
        if $content ~~ LibXML::Node|LibXML::Node::Set {
            $content .= native;
            # node-sets can't be multiply referenced
            $content .= copy if $content ~~ LibXML::Node::Set;
            $content.Reference;
        }

        do with LibXML::XPath::Object.native.coerce($content) {
            .Reference;
            nativecast(Pointer, $_);
        } // Pointer;
    }

    method thaw(Pointer $p) {
        do with $p {
            my $native = nativecast(LibXML::XPath::Object.native, $p);
            given LibXML::XPath::Object.new: :$native {
                .select;
            }
        }
        else {
            Any;
        }
    }

    method deallocator() {
        -> Pointer $p, Str $k {
            nativecast(LibXML::XPath::Object.native, $_).Unreference with $p;
        }
    }
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

sub free(Pointer) is native {*};
method deallocator { -> Pointer $p, xmlCharP $k { free($_) with $p } }
submethod TWEAK(CArray :$pairs) is default {
    $!native .= new;
    $!native.add-pairs($_, self.deallocator)
        with $pairs;
}
submethod DESTROY { .Free(self.deallocator) with $!native; }

subset OfType where Str|UInt|LibXML::Node|LibXML::Node::Set|XPathDomain;

method ^parameterize(Mu:U \p, OfType:U \t) {
    my $w := p.^mixin: Assoc[t];
    $w.^set_name: "{p.^name}[{t.^name}]";
    $w;
}
method !CArray(Any:U $type = Pointer, UInt:D :$len = $!native.Size ) {
    my $a := CArray[$type].new;
    $a[$len -1] = $type if $len;
    $a;
}

method of { Pointer }
method key-of { Str }

method freeze(Pointer() $p) { $p }
method thaw(Pointer $p) { $p }
method elems is also<Numeric> { $!native.Size }
method keys  {
    my $buf := self!CArray(Str);
    $!native.keys($buf);
    $buf.list;
}
method values {
    my $buf := self!CArray;
    $!native.values($buf);
    $buf.map: {   
        $.thaw($_);
    }
}
method pairs is also<list List> {
    my $kbuf := self!CArray(Str);
    my $vbuf := self!CArray;
    $!native.keys($kbuf);
    $!native.values($vbuf);
    (0 ..^ $.elems).map: {
        $kbuf[$_] => $.thaw($vbuf[$_]);
    }
}
method kv {
     my $len := 2 * $.elems;
     my $kv := self!CArray(:$len);
     $!native.key-values($kv);
     my size_t $i = 0;
     $kv.map: {   
         $i++ %% 2 ?? nativecast(Str, $_) !! $.thaw($_);
     }
}
method Hash { %( self.pairs ) }
method AT-KEY(Str() $key) { self.thaw: $!native.Lookup($key); }
method EXISTS-KEY(Str() $key) { ? $!native.Lookup($key); }
method ASSIGN-KEY(Str() $key, $val) is rw {
    my Pointer $ptr := $.freeze($val);
    $!native.Update($key, $ptr, $.deallocator); $val;
}
method DELETE-KEY(Str() $key) { $!native.Remove($key, $.deallocator) }

