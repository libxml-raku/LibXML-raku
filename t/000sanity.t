use v6;
use Test;

use LibXML::Raw::Defs :$XML2, :$BIND-XML2, :$CLIB;
use NativeCall;

# some sanity checking on our native library configuration.
# Check a few symbols $XML2, $BIND-XML2 and $CLIB libraries.
# Useful test when doing porting work on META6.json, LibXML::Raw::Defs etc

# sanity check our libraries
lives-ok({ cglobal($XML2, "xmlParserVersion", Pointer) }, 'libxml2 sanity')
   or note "unable to access the libxml2 library; is it installed?";

sub xmlInitParser is native($XML2) {*}
lives-ok {xmlInitParser()}, 'can call xmlInitParser()';

lives-ok({ cglobal($BIND-XML2, "xml6_config_version", Pointer) }, 'binding lib sanity')
    or note "unable to access 'xml6' binding library; has it been built? (e.g. 'zef build .)";

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
