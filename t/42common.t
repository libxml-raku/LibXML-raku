use v6;
use Test;
use LibXML::Enums;

plan 2;

pass('Loading');

#########################

is(+XML_ELEMENT_NODE, 1, 'XML_ELEMENT_NODE is 1.' );

