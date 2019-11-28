use LibXML::Node;

unit class LibXML::Dtd::Element
    is LibXML::Node;

use LibXML::Native;

submethod TWEAK(LibXML::Node :doc($)!, xmlElementDecl:D :native($)!) { }

method native { callsame() // xmlElementDecl }
