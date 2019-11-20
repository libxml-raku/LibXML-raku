use v6;
use Test;

use LibXML::Native::Defs :$XML2, :$BIND-XML2, :$CLIB;
use NativeCall;

# some sanity checking on our native library configuration.
# Check a few symbols $XML2, $BIND-XML2 and $CLIB libraries.
# Useful test when doing porting work on META6.json, LibXML::Native::Defs etc

for <xml6_doc_set_encoding xml6_gbl_set_tag_expansion> {
    ok(try {cglobal($BIND-XML2, $_, Pointer)}, "$BIND-XML2 $_ symbol")
     or diag "error fetching $_ symbol: $!";
}

for <xmlBufferCreate xmlNewDocNode xmlParserVersion xmlSaveNoEmptyTags> {
    ok(try {cglobal($XML2, $_, Pointer)}, "$XML2 $_ binding")
     or diag "error fetching $_ symbol: $!";
}

for <malloc memcpy free> {
    ok(try {cglobal($CLIB, $_, Pointer)}, "CLIB $_ binding")
     or diag "error fetching $_ symbol: $!";
}

done-testing();
