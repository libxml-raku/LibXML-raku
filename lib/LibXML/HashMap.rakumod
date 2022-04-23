#| Bindings to xmlHashTable
unit class LibXML::HashMap
    does Associative
    is repr('CPointer');

use LibXML::Item;
use LibXML::Node::Set;
use LibXML::Types :XPathRange;
use LibXML::Raw;
use LibXML::Raw::Defs :$XML2, :$CLIB, :xmlCharP;
use LibXML::Raw::HashTable;
use LibXML::Enums;
use LibXML::Dtd::Notation;
use LibXML::XPath::Object;
use NativeCall;
use Method::Also;

method raw { nativecast(xmlHashTable, self) }

method of {XPathRange}

method freeze(XPathRange $content) {
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
        Nil;
    }
}

method deallocator() {
    -> Pointer $p, Str $k {
        nativecast(xmlXPathObject, $_).Unreference
            with $p;
    }
}

method new(CArray :$pairs, xmlHashTable:D :$raw = xmlHashTable.new()) {
    $raw.add-pairs($_, $pairs.elems, self.deallocator)
        with $pairs;
    nativecast(self.WHAT, $raw);
}
method cleanup { .Free(self.deallocator) with self.raw; }
submethod DESTROY { self.cleanup }

subset OfType where XPathRange|LibXML::Dtd::Notation|Pointer;

method !CArray(Any:U $type = Pointer, UInt:D :$len = $.raw.Size ) {
    my $a := CArray[$type].new;
    $a[$len -1] = $type if $len;
    $a;
}

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
    (^$.elems).map: {
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
        FETCH => {with $.raw.LookupNs($key) { self.thaw($_) } else { self.of } },
        STORE => -> $, $val { self.ASSIGN-KEY($key, $val) },
    )
}
method EXISTS-KEY(Str() $key) { $.raw.LookupNs($key).defined; }
method ASSIGN-KEY(Str() $key, $val) is rw {
    my Pointer $ptr := $.freeze($val);
    $.raw.UpdateEntryNs($key, $ptr, $.deallocator); $val;
}
method DELETE-KEY(Str() $key) { $.raw.RemoveEntryNs($key, $.deallocator) }

role Assoc[Pointer $of] {
    method of { $of }
    method freeze(Pointer $p) { $p }
    method thaw(Pointer $p) { $p }
    method deallocator { -> | {} }
}

role Assoc[LibXML::Item $of] {
    method of {$of}
    method freeze(LibXML::Item $n where .isa($of)) {
        .raw.Reference with $n;
        nativecast(Pointer, $n);
    }
    method thaw(Pointer $p) {
        $of.box: itemNode.cast($p);
    }
    method deallocator() {
        -> Pointer $p, Str $k {
            itemNode.cast($_).Unreference with $p;
        }
    }
}

role Assoc[LibXML::Node::Set $of] {
    method of {$of}
    method freeze(LibXML::Node::Set:D $n) {
        given $n.raw.copy {
            nativecast(Pointer, $_);
        }
    }
    method thaw(Pointer $p) {
        my $raw = nativecast(xmlNodeSet, $p).copy;
        $of.new: :$raw, :deref;
    }
    method deallocator() {
        -> Pointer $p, Str $k {
            nativecast(xmlNodeSet, $_).Unreference with $p;
        }
    }
}

role Assoc[UInt $of] {
    method of {$of}
    method freeze(UInt()  $v) { Pointer.new($v); }
    method thaw(Pointer $p) { +$p }
    method deallocator { -> | {} }
}

role Assoc[Str $of] {
    sub free(Pointer) is native($CLIB) {*};
    method of {$of}
    sub pointerDup(Str --> Pointer) is native($XML2) is symbol('xmlStrdup') {*}
    sub stringDup(Pointer --> Str) is native($XML2) is symbol('xmlStrdup') {*}
    method freeze(Str() $v) { pointerDup($v) }
    method thaw(Pointer $p) { stringDup($p) }
    method deallocator { -> Pointer $p, xmlCharP $k { free($_) with $p } }
}

role Assoc[LibXML::Dtd::Notation $of] {
    method of {$of}
    method freeze(LibXML::Dtd::Notation $_) { .raw.Copy }
    method thaw(Pointer:D $p --> LibXML::Dtd::Notation:D) { $of.box: nativecast(xmlNotation, $p) }
    method deallocator() {
        -> Pointer $p, Str $k {
            nativecast(xmlNotation, $_).Free with $p;
        }
    }
}

role Assoc[XPathRange $of] {
    # default
    method of { $of }
}

method ^parameterize(Mu:U \p, OfType:U \t) {
    my $w := p.^mixin: Assoc[t];
    $w.^set_name: "{p.^name}[{t.^name}]";
    $w;
}

=begin pod

=head2 Synopsis

  my LibXML::HashMap $obj-hash .= new;
  my LibXML::HashMap[Pointer] $ptr-hash .= new;
  my LibXML::HashMap[UInt] $int-hash .= new;
  my LibXML::HashMap[Str] $str-hash .= new;
  my LibXML::HashMap[LibXML::Item] $item-hash .= new;
  my LibXML::HashMap[LibXML::Node::Set] $set-hash .= new;
  $set-hash = $node.findnodes($expr).Hash;
  $set-hash = $node.childNodes().Hash;
  # etc...

  $obj-hash<element> = LibXML::Element.new('test');
  $obj-hash<number> = 42e0;
  $obj-hash<string> = 'test';
  $obj-hash<bool> = True;

  say $obj-hash<element>.tagName;

=head2 Description

This module uses an xmlHashTable object as a raw hash-like store.

Both L<LibXML::Node::Set> and L<LibXML::Node::List> objects have a `Hash()` method that returns
a `LibXML::HashMap[LibXML::Node::Set]` object. For example

  use LibXML::HashMap;
  use LibXML::Document;
  use LibXML::Node::Set;

  my LibXML::Document $doc .= parse: "example/dromeds.xml";
  my LibXML::HashMap[LibXML::Node::Set] $nodes = $doc.findnodes('//*').Hash;
  # -OR-
  $nodes = $doc.getElementsByTagName('*').Hash;
  say $nodes<species>[1]<@name>.Str;

This is the nodes in the set or list collated by tag-name.

Several container types are available:  

  =item `LibXML::HashMap` By default XPath objects are used to store strings, floats, booleans, nodes or node-sets.
  =item `LibXML::HashMap[UInt]` - Positive integers
  =item `LibXML::HashMap[Str]` - Strings
  =item `LibXML::HashMap[LibXML::Node::Set]` - Sets of nodes
  =item `LibXML::HashMap[LibXML::Item]` - Individual nodes
  =item `LibXML::HashMap[LibXML::Dtd::Notation]` - Dtd notation table
  =item `LibXML::HashMap[LibXML::Dtd::ElementDecl]` - Dtd element declartion

=head2 Methods

=head3 method new

    my LibXML::HashMap $obj-hash .= new();
    my LibXML::HashMap[type] $type-hash .= new();

By default XPath Objects are used to containerize and store strings, floats, booleans or node-sets.

The other container types, `UInt`, `Str`, `LibXML::Item` and `LibXML::Node::Set` store values directly, without using an intermediate XPath objects.

=head3 method of

    method of() returns Any

Returns the container type for the LibXML::HashMap object.

=head3 method elems

    method elems() returns UInt

Returns the number of stored elements.

=head3 method keys

    method keys() returns Seq

Returns hash keys as a sequence of strings.

=head3 method values

    method values() returns Seq

Returns hash values as a sequence.

=head3 method pairs

    method pairs() returns Seq

Returns key values pairs as a sequence.

=head3 method kv

    method kv() returns Seq

Returns alternating keys and values as a sequence.

=head3 Hash

    method Hash() returns Hash

Coerces to a Raku Hash object.

=head3 method EXISTS-KEY

    method EXISTS-KEY(Str() $key) returns Bool
    say $h.EXISTS-KEY('foo');
    say $h<foo>:exists;

Returns True if an object exists at the given key

=head3 method AT-KEY

    method AT-KEY(Str() $key) returns Any
    say $h.AT-KEY('foo');
    say $h<foo>;

Returns the object at the given key

=head3 method ASSIGN-KEY

    method ASSIGN-KEY(Str() $key, Any $value) returns Any
    say $h.ASSIGN-KEY('foo', 42);
    $h<foo> = 42;

Stores an object at the given key

=head3 method DELETE-KEY

    method DELETE-KEY(Str() $key) returns Any
    say $h.DELETE-KEY('foo');
    $h<foo>:delete;

Removes the object at the given key

=end pod
