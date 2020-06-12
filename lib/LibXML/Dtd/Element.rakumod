use LibXML::Node;

unit class LibXML::Dtd::Element
    is repr('CPointer')
    is LibXML::Node;

use LibXML::Native;
use NativeCall;

method new(|) { fail }
method raw { nativecast(xmlElementDecl, self) }
