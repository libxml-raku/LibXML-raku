unit module LibXML::Native::HashTable;

use NativeCall;
use LibXML::Native::Defs :LIB, :Stub;

class xmlHashTable is repr(Stub) is export {
    sub xmlHashCreate(int32 --> xmlHashTable) is native(LIB) {*}
    method new(UInt :$size = 256) { xmlHashCreate($size) }
    method Add(Str, Pointer --> int32)  is symbol('xmlHashAdd') is native(LIB) {*}
    method Update(Str, Pointer, Pointer --> int32)  is symbol('xmlHashUpdateEntry') is native(LIB) {*}
    method Lookup(Str --> Pointer) is symbol('xmlHashLookup') is native(LIB) {*}
    method Remove(Str, Pointer --> int32)  is symbol('xmlHashRemoveEntry') is native(LIB) {*}
    method Size(--> int32) is symbol('xmlHashSize') is native(LIB) {*}
    method Free is symbol('xmlHashFree') is native(LIB) {*}
    
}
