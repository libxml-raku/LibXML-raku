use LibXML::Node;

unit class LibXML::Dtd::ElementDecl
    is repr('CPointer')
    is LibXML::Node;

use LibXML::Enums;

use LibXML::Raw;
use NativeCall;

method new(|) { fail }
method raw { nativecast(xmlElementDecl, self) }

submethod TWEAK {
    with .raw.parent {
        .Reference if .type == XML_DTD_NODE;
    }
}

submethod DESTROY {
    with .raw.parent {
        .Unreference if .type == XML_DTD_NODE;
    }
}
