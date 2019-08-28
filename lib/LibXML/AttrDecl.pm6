use LibXML::Node;

unit class LibXML::AttrDecl
    is LibXML::Node;

use LibXML::Native;

submethod TWEAK(LibXML::Node :doc($)!, xmlAttrDecl:D :native($)!) { }

method native { callsame() // xmlAttrDecl }
