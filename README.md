# LibXML-p6

A fresh attempt at a Perl 6 LibXML port

Will use this + CSS::Module to implement CSS Selectors.

## Porting Notes:

Some current differences between Perl 5's XML::LibXML and this (Perl 6).

Subject to review before releasing this module:

### LibXML::Node

->toString maps to .Str, except for attributes (see below). For
formatted strings $node->toString(1) maps to $node.Str(:format)

->properties has been been replaced .properties and .attributes method;
Name spaces are returned separately via the .namespaces method:

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

## General

A bit inconsistant atm wrt to getXxx setXxx accessors:

    $doc.encoding = 'UTF-8'; # vs $doc->setEncoding('UTF-8');

Will need a refactor one-way or the other, for consistency, before going live.