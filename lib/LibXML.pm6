use v6;
use LibXML::Parser;
use LibXML::Config;

use LibXML::Attr;
use LibXML::CDATASection;
use LibXML::Comment;
use LibXML::Document;
use LibXML::DocumentFragment;
use LibXML::Element;
use LibXML::Text;
use LibXML::Native;

unit class LibXML
    is LibXML::Parser;

method parser-version {
    Version.new(xmlParserVersion.match(/ (.)? (..)+ $/).list.join: '.');
}

method config {
    LibXML::Config;
}

method createDocument(|c) {
    LibXML::Document.createDocument(|c);
}
