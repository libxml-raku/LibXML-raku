use LibXML::Node;

unit class LibXML::NamespaceDecl
    is LibXML::Node;

use LibXML::Native;

submethod TWEAK(LibXML::Node :doc($)!, domNode:D :struct($)!) { }
