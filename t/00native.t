use Test;
use LibXML::Raw;
use LibXML::Raw::Defs :$BIND-XML2;
use NativeCall;

sub node-size(int32 $type --> int32) is symbol('xml6_node_get_size') is native($BIND-XML2) {*}

my @ClassMap := @LibXML::Raw::ClassMap;

plan +@ClassMap;

isa-ok anyNode.new, Failure, 'anyNode.new fails';

for 1 ..^ @ClassMap -> $type {
    my $class := @ClassMap[$type];
    if $class ~~ anyNode|xmlNs {
       is nativesizeof($class), node-size($type), 'size of ' ~ $class.raku;
    }
    else {
        skip "class $type";
    }
}