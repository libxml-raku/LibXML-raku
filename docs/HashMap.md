[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [HashMap](https://libxml-raku.github.io/LibXML-raku/HashMap)

class LibXML::HashMap
---------------------

Bindings to xmlHashTable

Synopsis
--------

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

Description
-----------

This module uses an xmlHashTable object as a raw hash-like store.

Both [LibXML::Node::Set](https://libxml-raku.github.io/LibXML-raku/Node/Set) and [LibXML::Node::List](https://libxml-raku.github.io/LibXML-raku/Node/List) objects have a `Hash()` method that returns a `LibXML::HashMap[LibXML::Node::Set]` object. For example

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

  * `LibXML::HashMap` By default XPath objects are used to store strings, floats, booleans, nodes or node-sets.

  * `LibXML::HashMap[UInt]` - Positive integers

  * `LibXML::HashMap[Str]` - Strings

  * `LibXML::HashMap[LibXML::Node::Set]` - Sets of nodes

  * `LibXML::HashMap[LibXML::Item]` - Individual nodes

  * `LibXML::HashMap[LibXML::Dtd::Notation]` - Dtd notation table

Methods
-------

### method new

    my LibXML::HashMap $obj-hash .= new();
    my LibXML::HashMap[type] $type-hash .= new();

By default XPath Objects are used to containerize and store strings, floats, booleans or node-sets.

The other container types, `UInt`, `Str`, `LibXML::Item` and `LibXML::Node::Set` store values directly, without using an intermediate XPath objects.

### method of

    method of() returns Any

Returns the container type for the LibXML::HashMap object.

### method elems

    method elems() returns UInt

Returns the number of stored elements.

### method keys

    method keys() returns Seq

Returns hash keys as a sequence of strings.

### method values

    method values() returns Seq

Returns hash values as a sequence.

### method pairs

    method pairs() returns Seq

Returns key values pairs as a sequence.

### method kv

    method kv() returns Seq

Returns alternating keys and values as a sequence.

### Hash

    method Hash() returns Hash

Coerces to a Raku Hash object.

### method EXISTS-KEY

    method EXISTS-KEY(Str() $key) returns Bool
    say $h.EXISTS-KEY('foo');
    say $h<foo>:exists;

Returns True if an object exists at the given key

### method AT-KEY

    method AT-KEY(Str() $key) returns Any
    say $h.AT-KEY('foo');
    say $h<foo>;

Returns the object at the given key

### method ASSIGN-KEY

    method ASSIGN-KEY(Str() $key, Any $value) returns Any
    say $h.ASSIGN-KEY('foo', 42);
    $h<foo> = 42;

Stores an object at the given key

### method DELETE-KEY

    method DELETE-KEY(Str() $key) returns Any
    say $h.DELETE-KEY('foo');
    $h<foo>:delete;

Removes the object at the given key

