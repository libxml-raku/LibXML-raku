use v6;
use LibXML::Parser;
use LibXML::Config;

# Preload stuff to avoid some Rakudo buglets
use LibXML::Attr;
use LibXML::CDATASection;
use LibXML::Comment;
use LibXML::Document;
use LibXML::DocumentFragment;
use LibXML::Element;
use LibXML::Text;
use LibXML::Native;
use LibXML::Node::Set;
use LibXML::Node::List;

unit class LibXML
    is LibXML::Parser;

method parser-version {
    Version.new(xmlParserVersion.match(/ (.)? (..)+ $/).list.join: '.');
}

method config handles <skip-xml-declaration skip-dtd keep-blanks-default tag-expansion> {
    LibXML::Config;
}

method createDocument(|c) {
    LibXML::Document.createDocument(|c);
}
