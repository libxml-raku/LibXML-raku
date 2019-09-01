unit module LibXML::Native::HashTable;

use NativeCall;
use LibXML::Native::Defs :LIB, :BIND-LIB, :Opaque, :xmlCharP;

class xmlHashTable is repr(Opaque) is export {
    sub xmlHashCreate(int32 --> xmlHashTable) is native(LIB) {*}
    sub xmlHashDefaultDeallocator(Pointer, xmlCharP) is native(LIB) is export {*};
    sub xml6_hash_null_deallocator(Pointer, xmlCharP) is native(LIB) is export {*};
    method new(UInt :$size = 256) { xmlHashCreate($size) }
    method AddEntry(Str, Pointer --> int32)  is symbol('xmlHashAddEntry') is native(LIB) {*}
    method UpdateEntry(Str, Pointer, &deallocator ( Pointer, xmlCharP ) --> int32)  is symbol('xmlHashUpdateEntry') is native(LIB) {*}
    method Lookup(Str --> Pointer) is symbol('xmlHashLookup') is native(LIB) {*}
    method RemoveEntry(Str, &deallocator ( Pointer, xmlCharP ) --> int32)  is symbol('xmlHashRemoveEntry') is native(LIB) {*}
    method Size(--> int32) is symbol('xmlHashSize') is native(LIB) {*}
    method Free( &deallocator ( Pointer, xmlCharP ) ) is symbol('xmlHashFree') is native(LIB) {*}
}
