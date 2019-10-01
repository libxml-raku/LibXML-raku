[![Build Status](https://travis-ci.org/p6-xml/LibXML-p6.svg?branch=master)](https://travis-ci.org/p6-xml/LibXML-p6)

NAME
====

LibXML - Perl 6 bindings to the libxml2 native library

SYNOPSIS
========

    use LibXML::Document;
    my LibXML::Document $doc .=  parse: :string('<Hello/>');
    $doc.root.nodeValue = 'World!';
    say $doc.Str;
    # <?xml version="1.0" encoding="UTF-8"?>
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

  * [LibXML::Document](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Document.md) - LibXML DOM attribute class

  * [LibXML::DocumentFragment](https://github.com/p6-xml/LibXML-p6/blob/master/doc/DocumentFragment.md) - LibXML's DOM L2 Document Fragment implementation

  * [LibXML::Element](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Element.md) - LibXML class for element nodes

  * [LibXML::Attr](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Attr.md) - LibXML attribute class

  * [LibXML::CDATA](https://github.com/p6-xml/LibXML-p6/blob/master/doc/CDATA.md) - LibXML class for DOM CDATA sections

  * [LibXML::Comment](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Comment.md) - LibXML class for comment DOM nodes

  * [LibXML::Dtd](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Dtd.md) - LibXML frontend for DTD validation

  * [LibXML::Namespace](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Namespace.md) - LibXML DOM namespaces (Inherits from LibXML::Item)

  * [LibXML::Node](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Node.md) - LibXML DOM base node class

  * [LibXML::Text](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Text.md) - LibXML text node class

  * [LibXML::PI](https://github.com/p6-xml/LibXML-p6/blob/master/doc/PI.md) - LibXML DOM processing instruction nodes

Container/Mapping classes
-------------------------

  * [LibXML::Attr::Map](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Attr/Map.md) - LibXML DOM attribute map class

  * [LibXML::Node::List](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Node/Set.md) - Sibling Node Lists

  * [LibXML::Node::Set](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Node/Set.md) - XPath Node Sets

Parsing
-------

  * [LibXML::Parser](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Parser.md) - LibXML Parser bindings

  * [LibXML::PushParser](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Parser.md) - LibXML Push Parser bindings

  * [LibXML::Reader](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Reader.md) - LibXML Reader (pull parser) bindings

XPath and Searching
-------------------

  * [LibXML::XPath::Expression](https://github.com/p6-xml/LibXML-p6/blob/master/doc/XPath/Context.md) - XPath Compiled Expressions

  * [LibXML::XPath::Context](https://github.com/p6-xml/LibXML-p6/blob/master/doc/XPath/Context.md) - XPath Evaluation Contexts

  * [LibXML::Pattern](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Pattern.md) - LibXML Patterns

  * [LibXML::RegExp](https://github.com/p6-xml/LibXML-p6/blob/master/doc/RegExp.md) - LibXML Regular Expression bindings

Validation
----------

  * [LibXML::Schema](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Schema.md) - LibXML schema validation class

  * [LibXML::RelaxNG](https://github.com/p6-xml/LibXML-p6/blob/master/doc/RelaxNG.md) - LibXML RelaxNG validation class

Other
-----

  * [LibXML::Native](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Native.md) - LibXML native interface

  * [LibXML::ErrorHandler](https://github.com/p6-xml/LibXML-p6/blob/master/doc/ErrorHandler.md) - LibXML class for Error handling

  * [LibXML::InputCallback](https://github.com/p6-xml/LibXML-p6/blob/master/doc/InputCallback.md) - LibXML class for Input callback handling

Prerequisites
=============

This module requires the libxml library to be installed. Please follow the instructions below based on your platform:

Debian Linux
------------

    sudo apt-get install libxml2-dev

Mac OS X
--------

    brew update
    brew install libxml2

CONTRIBUTERS
============

With thanks to: Christian Glahn, Ilya Martynov, Matt Sergeant, Petr Pajas, Shlomi Fish, Tobias Leich, Xliff.

VERSION
=======

0.1.0

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

