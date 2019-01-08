use v6;
use XML::LibXML::Parser;

unit class XML::LibXML
    is XML::LibXML::Parser;

use  XML::LibXML::Native;

method parser-version {
    Version.new(xmlParserVersion.match(/ (.)? (..)+ $/).list.join: '.');
}

