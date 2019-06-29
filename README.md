[![Build Status](https://travis-ci.org/p6-pdf/Font-FreeType-p6.svg?branch=master)](https://travis-ci.org/p6-pdf/Font-FreeType-p6)

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

  * [LibXML::Attr](https://github.com/p6-pdf/LibXML-p6/blob/master/doc/Attr.md) - LibXML DOM attribute class

  * [LibXML::CDATASection](https://github.com/p6-pdf/LibXML-p6/blob/master/doc/Attr.md) - LibXML class for DOM CDATA sections

  * [LibXML::Comment](https://github.com/p6-pdf/LibXML-p6/blob/master/doc/Comment.md) - LibXML class for comment DOM nodes

  * [LibXML::Document](https://github.com/p6-pdf/LibXML-p6/blob/master/doc/Document.md) - LibXML's DOM L2 Document Fragment implementation

  * [LibXML::DocumentFragment](https://github.com/p6-pdf/LibXML-p6/blob/master/doc/DocumentFragment.md) - LibXML DOM attribute class

  * [LibXML::Dtd](https://github.com/p6-pdf/LibXML-p6/blob/master/doc/Dtd.md) - LibXML frontend for DTD validation

  * [LibXML::Element](https://github.com/p6-pdf/LibXML-p6/blob/master/doc/Element.md) - LibXML class for DOM element nodes

  * [LibXML::Namespace](https://github.com/p6-pdf/LibXML-p6/blob/master/doc/Namespace.md) - LibXML DOM namespace nodes

  * [LibXML::PI](https://github.com/p6-pdf/LibXML-p6/blob/master/doc/PI.md) - LibXML DOM processing instruction nodes

  * [LibXML::RegExp](https://github.com/p6-pdf/LibXML-p6/blob/master/doc/RegExp.md) - LibXML Regular Expression bindings

