NAME
====

LibXML::DocumentFragment - LibXML's DOM L2 Document Fragment Implementation

SYNOPSIS
========

    use LibXML::Document;
    use LibXML::DocumentFragment;
    my LibXML::Document $doc .= new;
    my LibXML::DocumentFragment $frag .= parse: :balanced, :string('<foo/><bar/>');
    say $frag.Str; # '<foo/><bar/>';
    $frag.parse: :balanced, :string('<baz/>');
    say $frag.Str; # '<foo/><bar/><baz>';
    my LibXML::DocumentFragment $frag2 = $doc.createDocumentFragment;
    $frag2.appendChild: $doc.createElement('foo');
    $frag2.appendChild: $doc.createElement('bar');
    say $frag2.Str # '<foo/><bar/>'

DESCRIPTION
===========

This class is a helper class as described in the DOM Level 2 Specification. It is implemented as a node without name. All adding, inserting or replacing functions are aware of document fragments.

METHODS
=======

The class inherits from [LibXML::Node ](LibXML::Node ). The documentation for Inherited methods is not listed here.

  * new

        my LibXML::Document $doc; # owner document for the fragment;
        my LibXML::DocumentFragment $frag .= new: :$doc, *%parser-options;

    Creates a new empty document fragment to which nodes can be added; typically by calling the `parse()` method or using inherited `LibXML::Node` DOM methods, for example, `.addChild()`.

    parse

        my LibXML::DocumentFragment $frag .= parse: :balanced, :string('<foo/><bar/>'), :recover, :suppress-warnings, :suppress-errors, *%parser-options;

    Performs a parse of the given XML fragment and appends the resulting nodes to the fragment. The `parse()` method may be called multiple times on a document fragment object to append nodes.

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

