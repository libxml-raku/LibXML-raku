#| Bindings to xmlHashTable
unit class LibXML::HashMap
    does Associative
    is repr('CPointer');

use LibXML::Node;
use LibXML::Node::Set;
use LibXML::XPath::Object :XPathDomain;
use LibXML::Raw;
use LibXML::Raw::Defs :$XML2, :xmlCharP;
use LibXML::Raw::HashTable;
use LibXML::Enums;
use NativeCall;
use Method::Also;

method raw { nativecast(xmlHashTable, self) }

sub cast-item(Pointer $p) { nativecast(itemNode, $p).delegate }

role Assoc[LibXML::Node $of] {
    method of {$of}
    method freeze(LibXML::Node $n) {
        with $n.raw {
            .Reference;
            nativecast(Pointer, $_);
        }
        else {
            Pointer;
        }
    }
    method thaw(Pointer $p) {
        LibXML::Node.box: cast-item($p);
    }
    method deallocator() {
        -> Pointer $p, Str $k {
            with $p {
                my $n := cast-item($_);
                $n.Unreference;
            }
        }
    }
}

# node sets - experimental!
role Assoc[LibXML::Node::Set $of] {
    method of {$of}
    method freeze(LibXML::Node::Set:D $n) {
        given $n.raw.copy {
            .Reference;
            nativecast(Pointer, $_);
        }
    }
    method thaw(Pointer $p) {
        my $raw = nativecast(xmlNodeSet, $p).copy;
        LibXML::Node::Set.new: :$raw;
    }
    method deallocator() {
        -> Pointer $p, Str $k {
            nativecast(xmlNodeSet, $_).Unreference with $p;
        }
    }
}

# xpath objects experimental!
role Assoc[LibXML::XPath::Object] {
    method of {XPathDomain}

    method freeze(XPathDomain $content) {
        given LibXML::XPath::Object.coerce-to-raw($content) {
            .Reference;
            nativecast(Pointer, $_);
        }
    }

    method thaw(Pointer $p) {
        do with $p {
            my $raw = nativecast(xmlXPathObject, $_);
            LibXML::XPath::Object.value: :$raw;
        }
        else {
            Any;
        }
    }

    method deallocator() {
        -> Pointer $p, Str $k {
            with $p {
                given nativecast(xmlXPathObject, $_) {
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
    sub pointerDup(Str --> Pointer) is native($XML2) is symbol('xmlStrdup') {*}
    sub stringDup(Pointer --> Str) is native($XML2) is symbol('xmlStrdup') {*}
    method freeze(Str() $v) { pointerDup($v) }
    method thaw(Pointer $p) { stringDup($p) }

}

sub free(Pointer) is native {*};
method deallocator { -> Pointer $p, xmlCharP $k { free($_) with $p } }

method new(CArray :$pairs) {
    my xmlHashTable:D $raw .= new();
    $raw.add-pairs($_, $pairs.elems, self.deallocator)
        with $pairs;
    nativecast(self.WHAT, $raw);
}
submethod DESTROY { .Free(self.deallocator) with self.raw; }

subset OfType where Str|UInt|LibXML::Node|LibXML::Node::Set|LibXML::XPath::Object;

method ^parameterize(Mu:U \p, OfType:U \t) {
    my $w := p.^mixin: Assoc[t];
    $w.^set_name: "{p.^name}[{t.^name}]";
    $w;
}
method !CArray(Any:U $type = Pointer, UInt:D :$len = $.raw.Size ) {
    my $a := CArray[$type].new;
    $a[$len -1] = $type if $len;
    $a;
}

method of { Pointer }
method key-of { Str }

method freeze(Pointer() $p) { $p }
method thaw(Pointer $p) { $p }
method elems is also<Numeric> { $.raw.Size }
method keys  {
    my $buf := self!CArray(Str);
    $.raw.keys($buf);
    $buf.list;
}
method values {
    my $buf := self!CArray;
    $.raw.values($buf);
    $buf.map: {   
        $.thaw($_);
    }
}
method pairs is also<list List> {
    my $kbuf := self!CArray(Str);
    my $vbuf := self!CArray;
    $.raw.keys($kbuf);
    $.raw.values($vbuf);
    (0 ..^ $.elems).map: {
        $kbuf[$_] => $.thaw($vbuf[$_]);
    }
}
method kv {
     my $len := 2 * $.elems;
     my $kv := self!CArray(:$len);
     $.raw.key-values($kv);
     my size_t $i = 0;
     $kv.map: {   
         $i++ %% 2 ?? nativecast(Str, $_) !! $.thaw($_);
     }
}
method Hash { %( self.pairs ) }
method AT-KEY(Str() $key) is rw {
    Proxy.new(
        FETCH => { with $.raw.Lookup($key) { self.thaw($_) } else { self.of } },
        STORE => -> $, $val { self.ASSIGN-KEY($key, $val) },
    )
}
method EXISTS-KEY(Str() $key) { $.raw.Lookup($key).defined; }
method ASSIGN-KEY(Str() $key, $val) is rw {
    my Pointer $ptr := $.freeze($val);
    $.raw.UpdateEntry($key, $ptr, $.deallocator); $val;
}
method DELETE-KEY(Str() $key) { $.raw.RemoveEntry($key, $.deallocator) }

=begin pod
=head2 Name

LibXML::HashMap - LibXML hash table bindings

=head2 Synopsis

  my LibXML::HashMap[UInt] $int-hash .= new;
  my LibXML::HashMap[Str] $str-hash .= new;
  my LibXML::HashMap[LibXML::Node::Set] $set-hash .= new;
  my LibXML::HashMap[LibXML::XPath::Object] $obj-hash .= new;

  $obj-hash<element> = LibXML::Element.new('test');
  $obj-hash<number> = 42e0;
  $obj-hash<string> = 'test';
  $obj-hash<bool> = True;

  say $obj-hash<element>.tagName;

=head2 Description

**Experimental**

This module uses an xmlHashTable object as a raw store for several container types, include integers, strings, node sets and XPath objects (which may contain strings, floats, booleans or node-sets).

=end pod
