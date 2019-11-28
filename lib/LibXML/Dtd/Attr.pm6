use LibXML::Node;

unit class LibXML::Dtd::Attr
    is LibXML::Node;

use LibXML::Native;

submethod TWEAK(LibXML::Node :doc($)!, xmlAttrDecl:D :native($)!) { }

method native { callsame() // xmlAttrDecl }
