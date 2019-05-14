# LibXML-p6

A fresh attempt at a Perl 6 LibXML port


## Porting Notes:

Some current differences between Perl 5's XML::LibXML and this (Perl 6).

Subject to review before releasing this module:

### LibXML::Node

`->toString` maps to `.Str`, except for attributes (see below). For
formatted strings `$node->toString(1)` maps to `$node.Str(:format)`

`->properties` has been been replaced `.properties` and `.attributes` method;
Name spaces are returned separately via the `.namespaces` method:

    my %atts := $node.attributes;   # assoc view, tied
    my LibXML::Attr @props = $node.properties;   # list view
    my LibXML::Namespace @ns = $node.namespaces; 
    # to get namespaces and attributes aka Perl 5's ->properties method
    my @all = flat $node.properties, $node.namespaces;


## LibXML::Attr

->toString maps to .gist; .Str method returns just the node value

    my LibXML::Attr $att .= new: :name<foo>, :value<bar>;
    say $att.gist; # output: foo="bar"
    say $att.Str;  # output: bar


## LibXML::Parser

Issue #3 - would like to max all parsers 32bit safe (no 2.1Gb size limits). Needs to bw investigated.
