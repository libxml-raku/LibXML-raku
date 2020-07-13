use v6;
use LibXML::Parser;
use LibXML::Config;

# Preload stuff to avoid some Rakudo <= 2019.03 buglets
use LibXML::Attr;
use LibXML::Attr::Map;
use LibXML::CDATA;
use LibXML::Comment;
use LibXML::Document;
use LibXML::DocumentFragment;
use LibXML::Dtd::Element;
use LibXML::Dtd::Attr;
use LibXML::Element;
use LibXML::Entity;
use LibXML::Text;
use LibXML::Raw;
use LibXML::Node::Set;
use LibXML::Node::List;
use LibXML::XPath::Object;
use LibXML::XPath::Context;

unit class LibXML:ver<0.5.6>
    is LibXML::Parser;

method config handles <version config-version have-compression have-reader have-schemas have-threads skip-xml-declaration skip-dtd keep-blanks-default tag-expansion external-entity-loader> {
    LibXML::Config;
}

method createDocument(|c) {
    LibXML::Document.createDocument(|c);
}

=begin pod

=head1 NAME

LibXML - Raku bindings to the libxml2 native library

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This module is an interface to libxml2, providing XML and HTML parsers with
DOM, SAX and XMLReader interfaces, a large subset of DOM Layer 3 interface and
a XML::XPath-like interface to XPath API of libxml2.

For further information, please check the following documentation:

=head2 DOM Objects

The nodes in the Document Object Model (DOM) are represented by the following
classes (most of which "inherit" from L<LibXML::Node>):

  =item L<LibXML::Document> - LibXML DOM attribute class

  =item L<LibXML::Attr> - LibXML attribute class

  =item L<LibXML::CDATA> - LibXML class for DOM CDATA sections

  =item L<LibXML::Comment> - LibXML class for comment DOM nodes

  =item L<LibXML::DocumentFragment> - LibXML's DOM L2 Document Fragment implementation

  =item L<LibXML::Dtd> - LibXML frontend for DTD validation

  =item L<LibXML::Element> - LibXML class for element nodes

  =item L<LibXML::Namespace> - LibXML DOM namespaces (Inherits from L<LibXML::Item>)

  =item L<LibXML::Node> - LibXML DOM abstract base node class

  =item L<LibXML::Text> - LibXML text node class

  =item L<LibXML::PI> - LibXML DOM processing instruction nodes

=head2 Container/Mapping classes

=item L<LibXML::Attr::Map> - LibXML DOM attribute map class

=item L<LibXML::Node::List> - Sibling Node Lists

=item L<LibXML::Node::Set> - XPath Node Sets

=item L<LibXML::HashMap> - LibXML Hash Bindings

=head2 Parsing

=item L<LibXML::Parser> - LibXML Parser bindings

=item L<LibXML::PushParser> - LibXML Push Parser bindings

=item L<LibXML::Reader> - LibXML Reader (pull parser) bindings

=head2 XPath and Searching

=item L<LibXML::XPath::Expression> - XPath Compiled Expressions

=item L<LibXML::XPath::Context> - XPath Evaluation Contexts

=item L<LibXML::Pattern> - LibXML Patterns

=item L<LibXML::RegExp> - LibXML Regular Expression bindings

=head2 Validation

=item L<LibXML::Schema> - LibXML schema validation class

=item L<LibXML::RelaxNG> - LibXML RelaxNG validation class

=head2 Other

=item L<LibXML::Config> - LibXML global configuration

=item L<LibXML::Enums> - LibXML XML_* enumerated constants

=item L<LibXML::Raw> - LibXML native interface

=item L<LibXML::ErrorHandling> - LibXML class for Error handling

=item L<LibXML::InputCallback> - LibXML class for Input callback handling

=head1 PREREQUISITES

This module requires the libxml2 library to be installed. Please follow the instructions below based on your platform:

=head2 Debian Linux
    =begin code :lang<shell>
    sudo apt-get install libxml2-dev
    =end code

=head2 Mac OS X
    =begin code :lang<shell>
    brew update
    brew install libxml2
    =end code

=head1 ACKNOWLEDGEMENTS

This Raku module:

   =item is based on the Perl 5 XML::LibXML module; in particular, the test suite, selected XS and C code and documentation.
   =item derives SelectorQuery() and SelectorQueryAll() methods from the Perl 5 XML::LibXML::QuerySelector module.
   =item also draws on an earlier attempt at a Perl 6 (nee Raku) port (XML::LibXML).

With thanks to:
Christian Glahn,
Ilya Martynov,
Matt Sergeant,
Petr Pajas,
Shlomi Fish,
Toby Inkster,
Tobias Leich,
Xliff,
and others.

=head1 VERSION

0.5.6

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
