[![Build Status](https://travis-ci.org/p6-xml/LibXML-raku.svg?branch=master)](https://travis-ci.org/p6-xml/LibXML-raku)

NAME
====

LibXML - Raku bindings to the libxml2 native library

SYNOPSIS
========

```raku
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
```

DESCRIPTION
===========

This module is an interface to libxml2, providing XML and HTML parsers with DOM, SAX and XMLReader interfaces, a large subset of DOM Layer 3 interface and a XML::XPath-like interface to XPath API of libxml2.

For further information, please check the following documentation:

DOM Objects
-----------

The nodes in the Document Object Model (DOM) are represented by the following classes (most of which "inherit" from [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node)):

  * [LibXML::Document](https://libxml-raku.github.io/LibXML-raku/Document) - LibXML DOM attribute class

  * [LibXML::Attr](https://libxml-raku.github.io/LibXML-raku/Attr) - LibXML attribute class

  * [LibXML::CDATA](https://libxml-raku.github.io/LibXML-raku/CDATA) - LibXML class for DOM CDATA sections

  * [LibXML::Comment](https://libxml-raku.github.io/LibXML-raku/Comment) - LibXML class for comment DOM nodes

  * [LibXML::DocumentFragment](https://libxml-raku.github.io/LibXML-raku/DocumentFragment) - LibXML's DOM L2 Document Fragment implementation

  * [LibXML::Dtd](https://libxml-raku.github.io/LibXML-raku/Dtd) - LibXML frontend for DTD validation

  * [LibXML::Element](https://libxml-raku.github.io/LibXML-raku/Element) - LibXML class for element nodes

  * [LibXML::Namespace](https://libxml-raku.github.io/LibXML-raku/Namespace) - LibXML DOM namespaces (Inherits from [LibXML::Item](https://libxml-raku.github.io/LibXML-raku/Item))

  * [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node) - LibXML DOM abstract base node class

  * [LibXML::Text](https://libxml-raku.github.io/LibXML-raku/Text) - LibXML text node class

  * [LibXML::PI](https://libxml-raku.github.io/LibXML-raku/PI) - LibXML DOM processing instruction nodes

Container/Mapping classes
-------------------------

  * [LibXML::Attr::Map](https://libxml-raku.github.io/LibXML-raku/Attr/Map) - LibXML DOM attribute map class

  * [LibXML::Node::List](https://libxml-raku.github.io/LibXML-raku/Node/List) - Sibling Node Lists

  * [LibXML::Node::Set](https://libxml-raku.github.io/LibXML-raku/Node/Set) - XPath Node Sets

Parsing
-------

  * [LibXML::Parser](https://libxml-raku.github.io/LibXML-raku/Parser) - LibXML Parser bindings

  * [LibXML::PushParser](https://libxml-raku.github.io/LibXML-raku/PushParser) - LibXML Push Parser bindings

  * [LibXML::Reader](https://libxml-raku.github.io/LibXML-raku/Reader) - LibXML Reader (pull parser) bindings

XPath and Searching
-------------------

  * [LibXML::XPath::Expression](https://libxml-raku.github.io/LibXML-raku/XPath/Expression) - XPath Compiled Expressions

  * [LibXML::XPath::Context](https://libxml-raku.github.io/LibXML-raku/XPath/Context) - XPath Evaluation Contexts

  * [LibXML::Pattern](https://libxml-raku.github.io/LibXML-raku/Pattern) - LibXML Patterns

  * [LibXML::RegExp](https://libxml-raku.github.io/LibXML-raku/RegExp) - LibXML Regular Expression bindings

Validation
----------

  * [LibXML::Schema](https://libxml-raku.github.io/LibXML-raku/Schema) - LibXML schema validation class

  * [LibXML::RelaxNG](https://libxml-raku.github.io/LibXML-raku/RelaxNG) - LibXML RelaxNG validation class

Other
-----

  * [LibXML::Config](https://libxml-raku.github.io/LibXML-raku/Config) - LibXML global configuration

  * [LibXML::Enums](https://libxml-raku.github.io/LibXML-raku/Enums) - LibXML XML_* enumerated constants

  * [LibXML::Native](https://libxml-raku.github.io/LibXML-raku/Native) - LibXML native interface

  * [LibXML::ErrorHandling](https://libxml-raku.github.io/LibXML-raku/ErrorHandling) - LibXML class for Error handling

  * [LibXML::InputCallback](https://libxml-raku.github.io/LibXML-raku/InputCallback) - LibXML class for Input callback handling

PREREQUISITES
=============

This module requires the libxml2 library to be installed. Please follow the instructions below based on your platform:

Debian Linux
------------

```shell
sudo apt-get install libxml2-dev
```

Mac OS X
--------

```shell
brew update
brew install libxml2
```

ACKNOWLEDGEMENTS
================

This Raku module:

  * is based on the Perl 5 XML::LibXML module; in particular, the test suite, and selected XS and C code.

  * derives SelectorQuery() and SelectorQueryAll() methods from the Perl 5 XML::LibXML::QuerySelector module.

  * also draws on an earlier attempt at a Perl 6 (nee Raku) port (XML::LibXML).

With thanks to: Christian Glahn, Ilya Martynov, Matt Sergeant, Petr Pajas, Shlomi Fish, Toby Inkster, Tobias Leich, Xliff.

VERSION
=======

0.3.0

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

