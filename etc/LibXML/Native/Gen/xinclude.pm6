use v6;
#  -- DO NOT EDIT --
# generated by: etc/generator.p6 

unit module LibXML::Native::Gen::xinclude;
# implementation of XInclude:
#    API to handle XInclude processing, implements the World Wide Web Consortium Last Call Working Draft 10 November 2003
use LibXML::Native::Defs :$lib, :xmlCharP;

class xmlXIncludeCtxt is repr('CPointer') {
    method FreeContext() is native(XML2) is symbol('xmlXIncludeFreeContext') {*};
    method ProcessNode(xmlNode $node --> int32) is native(XML2) is symbol('xmlXIncludeProcessNode') {*};
    method SetFlags(int32 $flags --> int32) is native(XML2) is symbol('xmlXIncludeSetFlags') {*};
}
