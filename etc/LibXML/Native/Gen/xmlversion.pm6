use v6;
#  -- DO NOT EDIT --
# generated by: etc/generator.p6 

unit module LibXML::Native::Gen::xmlversion;
# compile-time version informations:
#    compile-time version informations for the XML library 
use LibXML::Native::Defs :$lib, :xmlCharP;

sub xmlCheckVersion(int32 $version) is native(XML2) is export {*};
