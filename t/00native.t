use Test;
use LibXML::Raw;
use LibXML::Enums;
use LibXML::Raw::Defs :$BIND-XML2;
use NativeCall;

sub node-size(int32 $type --> int32) is symbol('xml6_node_get_size') is native($BIND-XML2) {*}

my @ClassMap := @LibXML::Raw::ClassMap;

plan +@ClassMap;

isa-ok anyNode.new, Failure, 'anyNode.new fails';

for 1 ..^ @ClassMap -> $type {
    my $class := @ClassMap[$type];
    if $class ~~ anyNode|xmlNs {
       todo "has known size changes between libxml2 versions"
           if $type == XML_ENTITY_DECL;
       is node-size($type), nativesizeof($class), 'size of ' ~ $class.raku;
    }
    else {
        skip "class $type";
    }
}