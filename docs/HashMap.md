class LibXML::HashMap
---------------------

Bindings to xmlHashTable

Name
----

LibXML::HashMap - LibXML hash table bindings

Synopsis
--------

    my LibXML::HashMap $obj-hash .= new;
    my LibXML::HashMap[Pointer] $ptr-hash .= new;
    my LibXML::HashMap[UInt] $int-hash .= new;
    my LibXML::HashMap[Str] $str-hash .= new;
    my LibXML::HashMap[LibXML::Item] $item-hash .= new;
    my LibXML::HashMap[LibXML::Node::Set] $set-hash .= new;

    $obj-hash<element> = LibXML::Element.new('test');
    $obj-hash<number> = 42e0;
    $obj-hash<string> = 'test';
    $obj-hash<bool> = True;

    say $obj-hash<element>[0].tagName;

Description
-----------

**Experimental**

This module uses an xmlHashTable object as a raw hash-like store. By default it uses include XPath objects to store strings, floats, booleans or node-sets.

It also allows direct hash storage of types: Pointer, UInt, Str, LibXML::Item or LibXML::Node::Set.

Methods
-------

### method new

    my LibXML::HashMap $obj-hash .= new();
    my LibXML::HashMap[type] $type-hash .= new();

By default XPath Objects to containerize and store strings, floats, booleans or node-sets.

The other container types, `UInt`, `Str`, `Pointer`, `LibXML::Item` and `LibXML::Node::Set` store values directly, without using an intermediate XPath objects.

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

### method EXITS-KEY

    method EXIST-KEY(Str() $key) returns Bool
    say $h.EXISTS-KEY('foo');
    say $h<foo>:exists;

Returns True if the object exists

### method AT-KEY

    method AT-KEY(Str() $key) returns Any
    say $h.AT-KEY('foo');
    say $h<foo>;

Returns the object

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

