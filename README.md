[![Build Status](https://travis-ci.org/libxml-raku/LibXML-raku.svg?branch=master)](https://travis-ci.org/libxml-xml/LibXML-raku)

NAME
====

LibXML - Raku bindings to the libxml2 native library

SYNOPSIS
========

    use LibXML::Document;
    my LibXML::Document $doc .=  parse: :string('<Hello/>');
    $doc.root.nodeValue = 'World!';
    say $doc.Str;
    # <?xml version="1.0" encoding="UTF-8"?>
    # <Hello>World!</Hello>
    say $doc<Hello>;
    # <Hello>World!</Hello>

    my Version $library-version = LibXML.version;
    my Version $module-version = LibXML.^ver;

DESCRIPTION
===========

This module is an interface to libxml2, providing XML and HTML parsers with DOM, SAX and XMLReader interfaces, a large subset of DOM Layer 3 interface and a XML::XPath-like interface to XPath API of libxml2.

For further information, please check the following documentation:

DOM Objects
-----------

The nodes in the Document Object Model (DOM) are represented by the following classes (most of which "inherit" from [LibXML::Node ](LibXML::Node )):

  * [LibXML::Document](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Document.md) - LibXML DOM attribute class

  * [LibXML::DocumentFragment](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/DocumentFragment.md) - LibXML's DOM L2 Document Fragment implementation

  * [LibXML::Element](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Element.md) - LibXML class for element nodes

  * [LibXML::Attr](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Attr.md) - LibXML attribute class

  * [LibXML::CDATA](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/CDATA.md) - LibXML class for DOM CDATA sections

  * [LibXML::Comment](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Comment.md) - LibXML class for comment DOM nodes

  * [LibXML::Dtd](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Dtd.md) - LibXML frontend for DTD validation

  * [LibXML::Namespace](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Namespace.md) - LibXML DOM namespaces (Inherits from [LibXML::Item](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Item.md))

  * [LibXML::Node](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Node.md) - LibXML DOM base node class

  * [LibXML::Text](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Text.md) - LibXML text node class

  * [LibXML::PI](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/PI.md) - LibXML DOM processing instruction nodes

Container/Mapping classes
-------------------------

  * [LibXML::Attr::Map](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Attr/Map.md) - LibXML DOM attribute map class

  * [LibXML::Node::List](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Node/List.md) - Sibling Node Lists

  * [LibXML::Node::Set](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Node/Set.md) - XPath Node Sets

Parsing
-------

  * [LibXML::Parser](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Parser.md) - LibXML Parser bindings

  * [LibXML::PushParser](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Parser.md) - LibXML Push Parser bindings

  * [LibXML::Reader](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Reader.md) - LibXML Reader (pull parser) bindings

XPath and Searching
-------------------

  * [LibXML::XPath::Expression](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/XPath/Context.md) - XPath Compiled Expressions

  * [LibXML::XPath::Context](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/XPath/Context.md) - XPath Evaluation Contexts

  * [LibXML::Pattern](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Pattern.md) - LibXML Patterns

  * [LibXML::RegExp](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/RegExp.md) - LibXML Regular Expression bindings

Validation
----------

  * [LibXML::Schema](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Schema.md) - LibXML schema validation class

  * [LibXML::RelaxNG](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/RelaxNG.md) - LibXML RelaxNG validation class

Other
-----

  * [LibXML::Config](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Config.md) - LibXML global configuration

  * [LibXML::Native](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Native.md) - LibXML native interface

  * [LibXML::ErrorHandling](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/ErrorHandling.md) - LibXML class for Error handling

  * [LibXML::InputCallback](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/InputCallback.md) - LibXML class for Input callback handling

PREREQUISITES
=============

This module requires the libxml2 library to be installed. Please follow the instructions below based on your platform:

Debian Linux
------------

    sudo apt-get install libxml2-dev

Mac OS X
--------

    brew update
    brew install libxml2

ACKNOWLEDGEMENTS
================

This Raku module:

  * is based on the Perl 5 XML::LibXML module; in particular, the test suite, and selected XS and C code.

  * derives SelectorQuery() and SelectorQueryAll() methods from the Perl 5 XML::LibXML::QuerySelector module.

  * also draws on an earlier attempt at a Perl 6 (nee Raku) port (XML::LibXML).

With thanks to: Christian Glahn, Ilya Martynov, Matt Sergeant, Petr Pajas, Shlomi Fish, Toby Inkster, Tobias Leich, Xliff.

VERSION
=======

0.2.6

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

