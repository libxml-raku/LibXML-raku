[![Build Status](https://travis-ci.org/p6-pdf/LibXML-p6.svg?branch=master)](https://travis-ci.org/p6-pdf/LibXML-p6)

NAME
====

LibXML - Perl 6 bindings to the libxml2 native library

SYNOPSIS
========

    use LibXML;
    use LibXML::Document;
    my LibXML::Document $doc =  LibXML.parse: :string('<Hello/>');
    $doc.root.nodeValue = 'World!';
    say $doc.Str;
    # <?xml version="1.0" encoding="UTF-8"?>
    # <Hello>World!</Hello>

DESCRIPTION
===========

** Under Construction **

This module implements Perl 6 bindings to the Gnome libxml2 library which provides functions for parsing and manipulating XML files.

SEE ALSO
========

Draft documents (So far)

DOM Objects
-----------

  * [LibXML::Attr](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Attr.md) - LibXML DOM attribute class

  * [LibXML::Attr::Map](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Attr/Map.md) - LibXML DOM attribute map class

  * [LibXML::CDATASection](https://github.com/p6-xml/LibXML-p6/blob/master/doc/CDATASection.md) - LibXML class for DOM CDATA sections

  * [LibXML::Comment](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Comment.md) - LibXML class for comment DOM nodes

  * [LibXML::Document](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Document.md) - LibXML's DOM L2 Document Fragment implementation

  * [LibXML::DocumentFragment](https://github.com/p6-xml/LibXML-p6/blob/master/doc/DocumentFragment.md) - LibXML DOM attribute class

  * [LibXML::Dtd](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Dtd.md) - LibXML frontend for DTD validation

  * [LibXML::Element](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Element.md) - LibXML class for DOM element nodes

  * [LibXML::Namespace](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Namespace.md) - LibXML DOM namespace nodes

  * [LibXML::Node](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Node.md) - LibXML DOM base node class

  * [LibXML::Text](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Text.md) - LibXML text node class

  * [LibXML::PI](https://github.com/p6-xml/LibXML-p6/blob/master/doc/PI.md) - LibXML DOM processing instruction nodes

Other
-----

  * [LibXML::Schema](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Schema.md) - LibXML schema validation class

  * [LibXML::RelaxNG](https://github.com/p6-xml/LibXML-p6/blob/master/doc/RelaxNG.md) - LibXML RelaxNG validation class

  * [LibXML::ErrorHandler](https://github.com/p6-xml/LibXML-p6/blob/master/doc/ErrorHandler.md) - LibXML class for Error handling

  * [LibXML::InputCallback](https://github.com/p6-xml/LibXML-p6/blob/master/doc/InputCallback.md) - LibXML class for Input callback handling

  * [LibXML::Parser](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Parser.md) - LibXML Regular Expression bindings

  * [LibXML::RegExp](https://github.com/p6-xml/LibXML-p6/blob/master/doc/RegExp.md) - LibXML Regular Expression bindings

  * [LibXML::XPath::Expression](https://github.com/p6-xml/LibXML-p6/blob/master/doc/XPath/Context.md) - XPath Compiled Expressions

  * [LibXML::XPath::Context](https://github.com/p6-xml/LibXML-p6/blob/master/doc/XPath/Context.md) - XPath Evaluation Contexts

