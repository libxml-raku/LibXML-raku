unit module LibXML::Raw::HashTable;

use NativeCall;
use LibXML::Raw::Defs :$XML2, :$BIND-XML2, :Opaque, :xmlCharP;

class xmlHashTable is repr(Opaque) is export {
    our sub New(int32 --> xmlHashTable) is native($XML2) is symbol('xmlHashCreate') {*}
    our sub DefaultDeallocator(Pointer, xmlCharP) is native($XML2) is symbol('xmlHashDefaultDeallocator') {*};
    method new(UInt :$size = 256) { New($size) }
    method AddEntry(Str, Pointer --> int32)  is symbol('xml6_hash_add_entry') is native($BIND-XML2) {*}
    method UpdateEntry(Str, Pointer, &deallocator ( Pointer, xmlCharP ) --> int32)  is symbol('xmlHashUpdateEntry') is native($XML2) {*}
    method Lookup(Str --> Pointer) is symbol('xmlHashLookup') is native($XML2) {*}
    method LookupNs(Str --> Pointer) is symbol('xml6_hash_lookup_ns') is native($BIND-XML2) {*}
    method RemoveEntry(Str, &deallocator ( Pointer, xmlCharP ) --> int32)  is symbol('xmlHashRemoveEntry') is native($XML2) {*}
    method Size(--> int32) is symbol('xmlHashSize') is native($XML2) {*}
    method Copy(xmlHashTable --> xmlHashTable) is native($XML2) is symbol('xmlHashCopy') {*}
    method Free( &deallocator ( Pointer, xmlCharP ) ) is symbol('xmlHashFree') is native($XML2) {*}
    method Discard() is native($BIND-XML2) is symbol('xml6_hash_discard') {*}
    method keys(CArray[Str]) is native($BIND-XML2) is symbol('xml6_hash_keys') {*}
    method values(CArray[Pointer]) is native($BIND-XML2) is symbol('xml6_hash_values') {*}
    method key-values(CArray[Pointer]) is native($BIND-XML2) is symbol('xml6_hash_key_values') {*}
    method add-pairs(CArray, uint32, &deallocator ( Pointer, xmlCharP ) ) is native($BIND-XML2) is symbol('xml6_hash_add_pairs') {*}

    # build a two dimensional hash mapping element name to attribute names
    # specific to the multi-keyed Dtd attributes hash table
    method BuildDtdAttrDeclTable(--> xmlHashTable) is native($BIND-XML2) is symbol('xml6_hash_build_attr_decls') {*}
}
