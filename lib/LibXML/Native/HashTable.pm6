unit module LibXML::Native::HashTable;

use NativeCall;
use LibXML::Native::Defs :LIB, :BIND-LIB, :Stub, :xmlCharP;

class xmlHashTable is repr(Stub) is export {
    sub xmlHashCreate(int32 --> xmlHashTable) is native(LIB) {*}
    method new(UInt :$size = 256) { xmlHashCreate($size) }
    method Add(Str, Pointer --> int32)  is symbol('xmlHashAdd') is native(LIB) {*}
    method Update(Str, Pointer, &deallocator ( Pointer, xmlCharP ) --> int32)  is symbol('xmlHashUpdateEntry') is native(LIB) {*}
    method Lookup(Str --> Pointer) is symbol('xmlHashLookup') is native(LIB) {*}
    method Remove(Str, &deallocator ( Pointer, xmlCharP ) --> int32)  is symbol('xmlHashRemoveEntry') is native(LIB) {*}
    method Size(--> int32) is symbol('xmlHashSize') is native(LIB) {*}
    sub xmlHashDefaultDeallocator(Pointer, xmlCharP) is native(LIB) is export {*};
    sub xml6_hash_null_deallocator(Pointer, xmlCharP) is native(LIB) is export {*};
    method Free( &deallocator ( Pointer, xmlCharP ) ) is symbol('xmlHashFree') is native(LIB) {*}
    method keys(CArray[Str]) is native(BIND-LIB) is symbol('xml6_hash_keys') {*}
    method values(CArray[Pointer]) is native(BIND-LIB) is symbol('xml6_hash_values') {*}
    method key-values(CArray[Pointer]) is native(BIND-LIB) is symbol('xml6_hash_key_values') {*}
    method add-pairs(CArray, &deallocator ( Pointer, xmlCharP ) ) is native(BIND-LIB) is symbol('xml6_hash_add_pairs') {*}
}
