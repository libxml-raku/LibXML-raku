use v6;
use LibXML::Parser;

unit class LibXML
    is LibXML::Parser;

use  LibXML::Native;

method parser-version {
    Version.new(xmlParserVersion.match(/ (.)? (..)+ $/).list.join: '.');
}

