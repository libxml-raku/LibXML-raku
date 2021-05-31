use LibXML::Node;

unit class LibXML::Dtd::ElementDecl
    is repr('CPointer')
    is LibXML::Node;

use LibXML::Enums;

use LibXML::Raw;
use NativeCall;

method new(|) { fail }
method raw { nativecast(xmlElementDecl, self) }

