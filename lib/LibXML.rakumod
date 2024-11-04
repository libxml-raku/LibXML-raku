use LibXML::Parser;
use W3C::DOM;

# Needed for Rakudo 2020.5.1 - see #59
use LibXML::XPath::Context;

unit class LibXML:ver<0.10.10>:api<0.10.0>
    is LibXML::Parser
    does W3C::DOM::Implementation;

use LibXML::Config;
use LibXML::Document;
use LibXML::Types :QName;

proto method config() handles <
      version config-version load-catalog
      have-compression have-reader have-schemas have-threads have-writer
      skip-xml-declaration skip-dtd tag-expansion external-entity-loader> {*}
multi method config(::?CLASS:U:) { LibXML::Config }
multi method config(::?CLASS:D:) { nextsame }

method createDocument(|c) {
    LibXML::Document.createDocument(|c);
}

method createDocumentType(QName $name, Str $external-id, Str $system-id) {
    LibXML::Document
      .new()
      .createInternalSubset($name, $external-id, $system-id);
}

method hasFeature(Str:D() $feature, $?) {
    $feature ~~ /:i ^[xml|html|core]$ /;
}

=begin pod

=head1 NAME

LibXML - Raku bindings to the libxml2 native library

=head1 SYNOPSIS

    use LibXML;
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

  =item L<LibXML::Document> - LibXML DOM document class

  =item L<LibXML::Attr> - LibXML attribute class

  =item L<LibXML::CDATA> - LibXML class for DOM CDATA sections

  =item L<LibXML::Comment> - LibXML class for comment DOM nodes

  =item L<LibXML::DocumentFragment> - LibXML's DOM L2 Document Fragment implementation

  =item L<LibXML::Dtd> - LibXML front-end for DTD validation

  =item L<LibXML::Element> - LibXML class for element nodes

  =item L<LibXML::EntityRef> - LibXML class for entity references

  =item L<LibXML::Namespace> - LibXML namespaces (Inherits from L<LibXML::Item>)

  =item L<LibXML::Node> - LibXML DOM abstract base node class

  =item L<LibXML::Text> - LibXML text node class

  =item L<LibXML::PI> - LibXML DOM processing instruction nodes

See also L<LibXML::DOM>, which summarizes DOM classes and methods.

=head2 Container/Mapping classes

=item L<LibXML::Attr::Map> - LibXML DOM attribute map class

=item L<LibXML::Node::List> - Sibling Node Lists

=item L<LibXML::Node::Set> - XPath Node Sets

=item L<LibXML::HashMap> - LibXML Hash Bindings

=head2 Parsing

=item L<LibXML::Parser> - LibXML Parser bindings

=item L<LibXML::PushParser> - LibXML Push Parser bindings

=item L<LibXML::Reader> - LibXML Reader (pull parser) bindings

=head3 SAX Parser

=item L<LibXML::SAX::Builder> - Builds SAX callback sets
=item L<LibXML::SAX::Handler::SAX2> - SAX handler base class
=item L<LibXML::SAX::Handler::XML> - SAX Handler for XML

=head2 XPath and Searching

=item L<LibXML::XPath::Expression> - XPath Compiled Expressions

=item L<LibXML::XPath::Context> - XPath Evaluation Contexts

=item L<LibXML::Pattern> - LibXML Patterns

=item L<LibXML::RegExp> - LibXML Regular Expression bindings

=head2 Validation

=item L<LibXML::Dtd> - LibXML DTD validation class
=item L<LibXML::Schema> - LibXML schema validation class
=item L<LibXML::RelaxNG> - LibXML RelaxNG validation class

=head2 Other

=item L<LibXML::Config> - LibXML global and local configuration

=item L<LibXML::Enums> - XML_* enumerated constants

=item L<LibXML::Raw> - LibXML native interface

=item L<LibXML::ErrorHandling> - LibXML class for Error handling

=item L<LibXML::InputCallback> - LibXML class for Input callback handling

=item See also L<LibXML::Threads>, for notes on threading and concurrency

=head1 PREREQUISITES

This module may requires the libxml2 library to be installed. Please follow the instructions below based on your platform:

=head2 Debian/Ubuntu Linux
    =begin code :lang<shell>
    sudo apt-get install libxml2-dev
    =end code

Additional packages (such as build-essential) may be required
to enable make, C compilation and linking.

=head2 Mac OS X
    =begin code :lang<shell>
    brew update
    brew install libxml2
    =end code

The Xcode package also needs to be installed to enable compilation.

=head2 Windows

This module uses prebuilt DLLs on Windows. There are currently some configuration (`LibXML::Config`) restrictions:

=item `parser-locking` is set `True` to to disable concurrent parsing. This is due to known threading issues and unresolved failures in `t/90threads.t`

=item `iconv` is `False`. The library is built without full Unicode support, which restricts the ability to read and write various encoding schemes.

=item `compression` is `False`. The library is built without full compression, and is unable to read and write compressed XML directly.

=head1 ACKNOWLEDGEMENTS

This Raku module:

   =item is based on the Perl XML::LibXML module; in particular, the test suite, selected XS and C code and documentation.
   =item derives SelectorQuery() and SelectorQueryAll() methods from the Perl XML::LibXML::QuerySelector module.
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

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
