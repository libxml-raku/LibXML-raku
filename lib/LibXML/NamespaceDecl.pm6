use LibXML::Node;

unit class LibXML::NamespaceDecl
    is LibXML::Node;

use LibXML::Native;
use LibXML::Native::Defs :XML_XML_NS;

submethod TWEAK(LibXML::Node :doc($)!, domNode:D :native($)!) { }

method getNamespaceURI { XML_XML_NS }
method getPrefix { 'xml' }
