use v6;
use LibXML::Parser;
use LibXML::Config;

unit class LibXML
    is LibXML::Parser;

use  LibXML::Native;

method parser-version {
    Version.new(xmlParserVersion.match(/ (.)? (..)+ $/).list.join: '.');
}

method config {
    LibXML::Config;
}

