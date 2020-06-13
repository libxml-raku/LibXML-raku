use LibXML::Node;

unit class LibXML::Dtd::Element
    is repr('CPointer')
    is LibXML::Node;

use LibXML::Raw;
use NativeCall;

method new(|) { fail }
method raw { nativecast(xmlElementDecl, self) }
