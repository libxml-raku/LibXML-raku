use LibXML::Node;

unit class LibXML::EntityDecl
    is LibXML::Node;

use LibXML::Native;

submethod TWEAK(LibXML::Node :doc($)!, domNode:D :struct($)!) { }
