use LibXML::Node;

unit class LibXML::ElementDecl
    is LibXML::Node;

use LibXML::Native;

submethod TWEAK(LibXML::Node :doc($)!, xmlElementDecl:D :native($)!) { }
