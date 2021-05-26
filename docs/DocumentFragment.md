[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [DocumentFragment](https://libxml-raku.github.io/LibXML-raku/DocumentFragment)

class LibXML::DocumentFragment
------------------------------

LibXML's DOM L2 Document Fragment Implementation

Synopsis
--------

    use LibXML::Document;
    use LibXML::DocumentFragment;
    my LibXML::Document $doc .= new;

    my LibXML::DocumentFragment $frag .= parse: :balanced, :string('<foo/><bar/>');
    say $frag.Str; # '<foo/><bar/>';
    $frag.parse: :balanced, :string('<baz/>');
    say $frag.Str; # '<foo/><bar/><baz>';

    $frag = $doc.createDocumentFragment;
    $frag.appendChild: $doc.createElement('foo');
    $frag.appendChild: $doc.createElement('bar');
    $frag.parse: :balanced, :string('<baz/>');
    say $frag.Str # '<foo/><bar/><baz/>'

    $frag = $some-elem.removeChildNodes();

    use LibXML::Item :&ast-to-xml;
    $frag = ast-to-xml([
                 '#comment' => 'demo',         # comment
                 "\n  ",                       # white-space
                 :baz[],                       # element
                 '#cdata' => 'a&b',            # CData section
                  "Some text.\n",               # text content
        ]);
    say $frag; # <!--demo--><baz/><![CDATA[a&b]]>Some text.

Description
-----------

A Document Fragment differs from a [LibXML::Document](https://libxml-raku.github.io/LibXML-raku/Document) in that it may contain multiple root nodes. It is commonly used as an intermediate object when assembling or editing documents. All adding, inserting or replacing functions are aware of document fragments.

It is a helper class as described in the DOM Level 2 Specification.

Methods
-------

The class inherits from [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node). The documentation for Inherited methods is not listed here.

### method new

    method new(LibXML::Document :$doc) returns LibXML::DocumentFragment

Creates a new empty document fragment to which nodes can be added; typically by calling the `parse()` method or using inherited `LibXML::Node` DOM methods, for example, `.addChild()`.

### method parse

```raku
method parse(
    Str(Any) :$string!,
    Bool :balanced($)! where { ... },
    NativeCall::Types::Pointer :$user-data,
    |c
) returns LibXML::DocumentFragment
```

parses a balanced XML chunk

Returns a new document fragment object, if called on a class; appends nodes if called on an object instance. Example:

    my LibXML::DocumentFragment $frag .= parse(
        :balanced, :string('<foo/><bar/>'),
        :recover, :suppress-warnings, :suppress-errors
    );

Performs a parse of the given XML fragment and appends the resulting nodes to the fragment. The `parse()` method may be called multiple times on a document fragment object to append nodes.

It accepts a full range of parser options as described in [LibXML::Parser](https://libxml-raku.github.io/LibXML-raku/Parser)

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

