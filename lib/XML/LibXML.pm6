use v6;
use XML::LibXML::Parser;

unit class XML::LibXML
    is XML::LibXML::Parser;

use XML::LibXML::Native;
use XML::LibXML::Document;

method skip-xml-declaration is rw { $XML::LibXML::Document::skipXMLDeclaration }
method skip-dtd is rw { $XML::LibXML::Document::skipDTD }
method indent-tree-output is rw { $XML::LibXML::Native::xmlIndentTreeOutput }
method keep-blanks-default is rw { XML::LibXML::Native.keep-blanks-default }

method parser-version {
    Version.new(xmlParserVersion.match(/ (.)? (..)+ $/).list.join: '.');
}

