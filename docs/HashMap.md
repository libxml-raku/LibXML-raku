class LibXML::HashMap
---------------------

Bindings to xmlHashTable

Name
----

LibXML::HashMap - LibXML hash table bindings

Synopsis
--------

    my LibXML::HashMap[UInt] $int-hash .= new;
    my LibXML::HashMap[Str] $str-hash .= new;
    my LibXML::HashMap[LibXML::Node::Set] $set-hash .= new;
    my LibXML::HashMap[LibXML::XPath::Object] $obj-hash .= new;

    $obj-hash<element> = LibXML::Element.new('test');
    $obj-hash<number> = 42e0;
    $obj-hash<string> = 'test';
    $obj-hash<bool> = True;

    say $obj-hash<element>.tagName;

Description
-----------

**Experimental**

This module uses an xmlHashTable object as a raw store for several container types, include integers, strings, node sets and XPath objects (which may contain strings, floats, booleans or node-sets).

