unit module LibXML::Native::Dict;

use NativeCall;
use LibXML::Native::Defs :LIB, :Stub;

class xmlDict is repr(Stub) is export {
    sub Create(--> xmlDict) is native(LIB) is symbol('xmlDictCreate') {*};
    method Free is native(LIB) is symbol('xmlDictFree') {*};
    method Exists(Str, int32 --> Str) is native(LIB) is symbol('xmlDictExists') {*};
    method Lookup(Str, int32 --> Str) is native(LIB) is symbol('xmlDictLookup') {*};
    method Owns(Str --> int32) is native(LIB) is symbol('xmlDictOwns') {*};
    method Size(--> int32) is native(LIB) is symbol('xmlDictSize') {*};
    method Reference(--> int32) is native(LIB) is symbol('xmlDictReference') {*};
    method new(--> xmlDict:D) { Create() }
}
