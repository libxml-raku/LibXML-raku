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
use LibXML::Native;
use LibXML::Node::Set;
use LibXML::Node::List;
use LibXML::XPath::Object;
use LibXML::XPath::Context;

unit class LibXML:ver<0.3.1>
    is LibXML::Parser;

method config handles <version config-version have-compression have-reader have-schemas have-threads skip-xml-declaration skip-dtd keep-blanks-default tag-expansion> {
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
classes (most of which "inherit" from L<<<<<< LibXML::Node >>>>>>):

=item [LibXML::Document](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Document.md) - LibXML DOM attribute class

=item [LibXML::DocumentFragment](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/DocumentFragment.md) - LibXML's DOM L2 Document Fragment implementation

=item [LibXML::Element](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Element.md) - LibXML class for element nodes

=item [LibXML::Attr](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Attr.md) - LibXML attribute class

=item [LibXML::CDATA](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/CDATA.md) - LibXML class for DOM CDATA sections

=item [LibXML::Comment](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Comment.md) - LibXML class for comment DOM nodes

=item [LibXML::Dtd](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Dtd.md) - LibXML frontend for DTD validation

=item [LibXML::Namespace](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Namespace.md) - LibXML DOM namespaces (Inherits from [LibXML::Item](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Item.md))

=item [LibXML::Node](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Node.md) - LibXML DOM base node class

=item [LibXML::Text](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Text.md) - LibXML text node class

=item [LibXML::PI](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/PI.md) - LibXML DOM processing instruction nodes

=head2 Container/Mapping classes

=item [LibXML::Attr::Map](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Attr/Map.md) - LibXML DOM attribute map class

=item [LibXML::Node::List](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Node/List.md) - Sibling Node Lists

=item [LibXML::Node::Set](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Node/Set.md) - XPath Node Sets

=head2 Parsing

=item [LibXML::Parser](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Parser.md) - LibXML Parser bindings

=item [LibXML::PushParser](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Parser.md) - LibXML Push Parser bindings

=item [LibXML::Reader](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Reader.md) - LibXML Reader (pull parser) bindings

=head2 XPath and Searching

=item [LibXML::XPath::Expression](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/XPath/Context.md) - XPath Compiled Expressions

=item [LibXML::XPath::Context](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/XPath/Context.md) - XPath Evaluation Contexts

=item [LibXML::Pattern](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Pattern.md) - LibXML Patterns

=item [LibXML::RegExp](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/RegExp.md) - LibXML Regular Expression bindings

=head2 Validation

=item [LibXML::Schema](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Schema.md) - LibXML schema validation class

=item [LibXML::RelaxNG](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/RelaxNG.md) - LibXML RelaxNG validation class

=head2 Other

=item [LibXML::Config](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Config.md) - LibXML global configuration

=item [LibXML::Native](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/Native.md) - LibXML native interface

=item [LibXML::ErrorHandling](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/ErrorHandling.md) - LibXML class for Error handling

=item [LibXML::InputCallback](https://github.com/libxml-raku/LibXML-raku/blob/master/docs/InputCallback.md) - LibXML class for Input callback handling

=head1 PREREQUISITES

This module requires the libxml2 library to be installed. Please follow the instructions below based on your platform:

=head2 Debian Linux

  sudo apt-get install libxml2-dev

=head2 Mac OS X

  brew update
  brew install libxml2

=head1 ACKNOWLEDGEMENTS

This Raku module:

   =item is based on the Perl 5 XML::LibXML module; in particular, the test suite, and selected XS and C code.
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
Xliff.


=head1 VERSION

0.2.6

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod