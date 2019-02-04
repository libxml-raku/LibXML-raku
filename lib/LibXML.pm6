use v6;
use LibXML::Parser;
use LibXML::Config;

use LibXML::Attr;
use LibXML::CDATASection;
use LibXML::Comment;
use LibXML::DocumentFragment;
use LibXML::Element;
use LibXML::Text;

unit class LibXML
    is LibXML::Parser;

use  LibXML::Native;

method parser-version {
    Version.new(xmlParserVersion.match(/ (.)? (..)+ $/).list.join: '.');
}

method config {
    LibXML::Config;
}

