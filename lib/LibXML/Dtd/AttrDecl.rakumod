use LibXML::Node;

#| LibXML DtD Element attribute declaration introspection (experimental)
unit class LibXML::Dtd::AttrDecl
    is repr('CPointer')
    is LibXML::Node;

use LibXML::Raw;
use NativeCall;

method new(|) { fail }
method raw { nativecast(xmlAttrDecl, self) }
