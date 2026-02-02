use v6;
use Test;

use LibXML::Raw::Defs :$XML2, :$BIND-XML2, :$CLIB;
use NativeCall;

# some sanity checking on our native library configuration.
# Check a few symbols $XML2, $BIND-XML2 and $CLIB libraries.
# Useful test when doing porting work on META6.json, LibXML::Raw::Defs etc

# sanity check our libraries
sub xmlInitParser is native($XML2) {*}
lives-ok {xmlInitParser()}, 'can call xmlInitParser()';

ok $BIND-XML2.IO.s, $BIND-XML2.IO.path ~ ' library has been built';
unless $BIND-XML2.IO.s {
    bail-out "unable to access {$BIND-XML2.IO.basename}, has it been built, (e.g. 'zef build .' or 'raku Build.rakumod'" ~ ('Makefile'.IO.e ?? ", or 'make'" !! '') ~ ')';
}

lives-ok({$BIND-XML2.&cglobal("xml6_config_version", Pointer) }, 'binding lib sanity')
    or note "unable to access 'xml6' binding library; has it been built? (e.g. 'zef build .)";

for <xml6_doc_set_encoding xml6_gbl_os_thread_set_tag_expansion> {
    ok(try {$BIND-XML2.&cglobal($_, Pointer)}, "binding lib $_ symbol")
     or diag "error fetching $_ symbol: $!";
}

for <xmlBufferCreate xmlNewDocNode> {
    ok(try {$XML2.&cglobal($_, Pointer)}, "libxml $_ binding")
     or diag "error fetching $_ symbol: $!";
}

for <malloc memcpy free> {
    ok(try {$CLIB.&cglobal($_, Pointer)}, "clib $_ binding")
     or diag "error fetching $_ symbol: $!";
}

done-testing();
