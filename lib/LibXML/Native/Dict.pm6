unit module LibXML::Native::Dict;

use NativeCall;
use LibXML::Native::Defs :LIB, :Opaque;

class xmlDict is repr(Opaque) is export {
    sub Create(--> xmlDict) is native(LIB) is symbol('xmlDictCreate') {*};
    method Exists(Str, int32 --> Str) is native(LIB) is symbol('xmlDictExists') {*};
    method Lookup(Str, int32 --> Str) is native(LIB) is symbol('xmlDictLookup') {*};
    method Owns(Str --> int32) is native(LIB) is symbol('xmlDictOwns') {*};
    method Size(--> int32) is native(LIB) is symbol('xmlDictSize') {*};
    method Reference(--> int32) is native(LIB) is symbol('xmlDictReference') {*};
    # only actually frees the dict when reference count is zero
    method Unreference is native(LIB) is symbol('xmlDictFree') {*};
    method new(--> xmlDict:D) { Create() }
}
