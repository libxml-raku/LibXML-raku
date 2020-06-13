unit module LibXML::Raw::HashTable;

use NativeCall;
use LibXML::Raw::Defs :$XML2, :$BIND-XML2, :Opaque, :xmlCharP;

class xmlHashTable is repr(Opaque) is export {
    our sub New(int32 --> xmlHashTable) is native($XML2) is symbol('xmlHashCreate') {*}
    our sub DefaultDeallocator(Pointer, xmlCharP) is native($XML2) is symbol('xmlHashDefaultDeallocator') {*};
    our sub NullDeallocator(Pointer, xmlCharP) is native($BIND-XML2) is symbol('xml6_hash_null_deallocator') {*};
    method new(UInt :$size = 256) { New($size) }
    method AddEntry(Str, Pointer --> int32)  is symbol('xmlHashAddEntry') is native($XML2) {*}
    method UpdateEntry(Str, Pointer, &deallocator ( Pointer, xmlCharP ) --> int32)  is symbol('xmlHashUpdateEntry') is native($XML2) {*}
    method Lookup(Str --> Pointer) is symbol('xmlHashLookup') is native($XML2) {*}
    method RemoveEntry(Str, &deallocator ( Pointer, xmlCharP ) --> int32)  is symbol('xmlHashRemoveEntry') is native($XML2) {*}
    method Size(--> int32) is symbol('xmlHashSize') is native($XML2) {*}
    method Free( &deallocator ( Pointer, xmlCharP ) ) is symbol('xmlHashFree') is native($XML2) {*}
}
