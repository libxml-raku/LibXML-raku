use v6;
use LibXML::Parser;
use LibXML::Config;

# Preload stuff to avoid some Rakudo buglets
use LibXML::Attr;
use LibXML::Attr::Map;
use LibXML::CDATA;
use LibXML::Comment;
use LibXML::Document;
use LibXML::DocumentFragment;
use LibXML::Element;
use LibXML::Entity;
use LibXML::Text;
use LibXML::Native;
use LibXML::Node::Set;
use LibXML::Node::List;
use LibXML::XPath::Object;
use LibXML::XPath::Context;

unit class LibXML:ver<0.1.6>
    is LibXML::Parser;

method config handles <version config-version have-compression have-reader have-schemas have-threads skip-xml-declaration skip-dtd keep-blanks-default tag-expansion> {
    LibXML::Config;
}

method createDocument(|c) {
    LibXML::Document.createDocument(|c);
}

=begin pod

=head1 NAME

LibXML - Perl 6 bindings to the libxml2 native library

=head1 SYNOPSIS

  use LibXML::Document;
  my LibXML::Document $doc .=  parse: :string('<Hello/>');
  $doc.root.nodeValue = 'World!';
  say $doc.Str;
  # <?xml version="1.0" encoding="UTF-8"?>
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

=item [LibXML::Document](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Document.md) - LibXML DOM attribute class

=item [LibXML::DocumentFragment](https://github.com/p6-xml/LibXML-p6/blob/master/doc/DocumentFragment.md) - LibXML's DOM L2 Document Fragment implementation

=item [LibXML::Element](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Element.md) - LibXML class for element nodes

=item [LibXML::Attr](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Attr.md) - LibXML attribute class

=item [LibXML::CDATA](https://github.com/p6-xml/LibXML-p6/blob/master/doc/CDATA.md) - LibXML class for DOM CDATA sections

=item [LibXML::Comment](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Comment.md) - LibXML class for comment DOM nodes

=item [LibXML::Dtd](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Dtd.md) - LibXML frontend for DTD validation

=item [LibXML::Namespace](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Namespace.md) - LibXML DOM namespaces (Inherits from LibXML::Item)

=item [LibXML::Node](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Node.md) - LibXML DOM base node class

=item [LibXML::Text](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Text.md) - LibXML text node class

=item [LibXML::PI](https://github.com/p6-xml/LibXML-p6/blob/master/doc/PI.md) - LibXML DOM processing instruction nodes

=head2 Container/Mapping classes

=item [LibXML::Attr::Map](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Attr/Map.md) - LibXML DOM attribute map class

=item [LibXML::Node::List](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Node/List.md) - Sibling Node Lists

=item [LibXML::Node::Set](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Node/Set.md) - XPath Node Sets

=head2 Parsing

=item [LibXML::Parser](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Parser.md) - LibXML Parser bindings

=item [LibXML::PushParser](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Parser.md) - LibXML Push Parser bindings

=item [LibXML::Reader](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Reader.md) - LibXML Reader (pull parser) bindings

=head2 XPath and Searching

=item [LibXML::XPath::Expression](https://github.com/p6-xml/LibXML-p6/blob/master/doc/XPath/Context.md) - XPath Compiled Expressions

=item [LibXML::XPath::Context](https://github.com/p6-xml/LibXML-p6/blob/master/doc/XPath/Context.md) - XPath Evaluation Contexts

=item [LibXML::Pattern](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Pattern.md) - LibXML Patterns

=item [LibXML::RegExp](https://github.com/p6-xml/LibXML-p6/blob/master/doc/RegExp.md) - LibXML Regular Expression bindings

=head2 Validation

=item [LibXML::Schema](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Schema.md) - LibXML schema validation class

=item [LibXML::RelaxNG](https://github.com/p6-xml/LibXML-p6/blob/master/doc/RelaxNG.md) - LibXML RelaxNG validation class

=head2 Other

=item [LibXML::Native](https://github.com/p6-xml/LibXML-p6/blob/master/doc/Native.md) - LibXML native interface

=item [LibXML::ErrorHandling](https://github.com/p6-xml/LibXML-p6/blob/master/doc/ErrorHandling.md) - LibXML class for Error handling

=item [LibXML::InputCallback](https://github.com/p6-xml/LibXML-p6/blob/master/doc/InputCallback.md) - LibXML class for Input callback handling

=head1 PREREQUISITES

This module requires the libxml2 library to be installed. Please follow the instructions below based on your platform:

=head2 Debian Linux

  sudo apt-get install libxml2-dev

=head2 Mac OS X

  brew update
  brew install libxml2

=head1 CONTRIBUTERS

With thanks to:
Christian Glahn,
Ilya Martynov,
Matt Sergeant,
Petr Pajas,
Shlomi Fish,
Tobias Leich,
Xliff.


=head1 VERSION

0.1.6

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
