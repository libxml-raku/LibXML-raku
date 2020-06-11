use LibXML::Node;

unit class LibXML::Dtd::Element
    is LibXML::Node;

use LibXML::Native;

method native { callsame() // xmlElementDecl }
