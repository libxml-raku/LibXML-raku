use v6;
unit class LibXML::HashMap does Associative;

use LibXML::Node :cast-elem;
use LibXML::Node::Set;
use LibXML::XPath::Object :XPathDomain;
use LibXML::Native::Defs :LIB, :xmlCharP;
use LibXML::Native::HashTable;
use LibXML::Enums;
use NativeCall;
use Method::Also;

has xmlHashTable $!native;

role Assoc[LibXML::Node $of] {
    method of {$of}
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
role Assoc[LibXML::Node::Set $of] {
    method of {$of}
    method freeze(LibXML::Node::Set:D $n) {
        given $n.native.copy {
            .Reference;
            nativecast(Pointer, $_);
        }
    }
    method thaw(Pointer $p) {
        my $native = nativecast(LibXML::Node::Set.native, $p).copy;
        LibXML::Node::Set.new: :$native;
    }
    method deallocator() {
        -> Pointer $p, Str $k {
            nativecast(LibXML::Node::Set.native, $_).Unreference with $p;
        }
    }
}

# xpath objects experimental!
role Assoc[LibXML::XPath::Object] {
    method of {XPathDomain}

    method freeze(XPathDomain $content) {
        given LibXML::XPath::Object.coerce-to-native($content) {
            .Reference;
            nativecast(Pointer, $_);
        }
    }

    method thaw(Pointer $p) {
        do with $p {
            my $native = nativecast(LibXML::XPath::Object.native, $_);
            given LibXML::XPath::Object.new: :$native {
                .value;
            }
        }
        else {
            Any;
        }
    }

    method deallocator() {
        -> Pointer $p, Str $k {
            with $p {
                with nativecast(LibXML::XPath::Object.native, $p) {
                    .Unreference;
                }
            }
        }
    }
}

role Assoc[UInt $of] {
    method of {$of}
    method deallocator { -> | {} }
    method freeze(UInt()  $v) { Pointer.new($v); }
    method thaw(Pointer $p) { +$p }
}

role Assoc [Str $of] {
    method of {$of}
    sub pointerDup(Str --> Pointer) is native(LIB) is symbol('xmlStrdup') {*}
    sub stringDup(Pointer --> Str) is native(LIB) is symbol('xmlStrdup') {*}
    method freeze(Str() $v) { pointerDup($v) }
    method thaw(Pointer $p) { stringDup($p) }

}

sub free(Pointer) is native {*};
method deallocator { -> Pointer $p, xmlCharP $k { free($_) with $p } }
submethod TWEAK(CArray :$pairs) is default {
    $!native .= new;
    $!native.add-pairs($_, self.deallocator)
        with $pairs;
    $!native.Lookup('wtf');
}
submethod DESTROY { .Free(self.deallocator) with $!native; }

subset OfType where Str|UInt|LibXML::Node|LibXML::Node::Set|LibXML::XPath::Object;

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
method AT-KEY(Str() $key) is rw {
    Proxy.new(
        FETCH => { with $!native.Lookup($key) { self.thaw($_) } else { self.of } },
        STORE => -> $, $val { self.ASSIGN-KEY($key, $val) },
    )
}
method EXISTS-KEY(Str() $key) { $!native.Lookup($key); }
method ASSIGN-KEY(Str() $key, $val) is rw {
    my Pointer $ptr := $.freeze($val);
    $!native.Update($key, $ptr, $.deallocator); $val;
}
method DELETE-KEY(Str() $key) { $!native.Remove($key, $.deallocator) }

=begin pod
=head1 NAME

LibXML::HashMap - LibXML::HashMap Class for Mapped XPath Objects

=head1 SYNOPSIS

my LibXML::HashMap[UInt] $int-hash .= new;
my LibXML::HashMap[Str] $str-hash .= new;
my LibXML::HashMap[LibXML::Node::Set] $set-hash .= new;
my LibXML::HashMap[LibXML::Node] $node-hash .= new;
my LibXML::HashMap[LibXML::XPath::Object] $obj-hash .= new;

$obj-hash<element> = LibXML::Element.new('test');
$obj-hash<number> = 42e0;
$obj-hash<string> = 'test';

say $obj-hash<element>.tagName;

=head1 DESCRIPTION

**Experimental**

This module uses an xmlHash object as a native store for various object types.

=end pod
