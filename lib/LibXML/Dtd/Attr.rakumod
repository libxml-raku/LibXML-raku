use LibXML::Node;

unit class LibXML::Dtd::Attr
    is LibXML::Node;

use LibXML::Native;

method native { callsame() // xmlAttrDecl }
