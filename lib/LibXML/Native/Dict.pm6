unit module LibXML::Native::Dict;

use NativeCall;
use LibXML::Native::Defs :XML2, :Opaque;

class xmlDict is repr(Opaque) is export {
    sub Create(--> xmlDict) is native(XML2) is symbol('xmlDictCreate') {*};
    method Exists(Str, int32 --> Str) is native(XML2) is symbol('xmlDictExists') {*};
    method Lookup(Str, int32 --> Str) is native(XML2) is symbol('xmlDictLookup') {*};
    method Owns(Str --> int32) is native(XML2) is symbol('xmlDictOwns') {*};
    method Size(--> int32) is native(XML2) is symbol('xmlDictSize') {*};
    method Reference(--> int32) is native(XML2) is symbol('xmlDictReference') {*};
    # only actually frees the dict when reference count is zero
    method Unreference is native(XML2) is symbol('xmlDictFree') {*};
    method new(--> xmlDict:D) { Create() }
}
