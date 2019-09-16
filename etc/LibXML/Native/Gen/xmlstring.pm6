use v6;
#  -- DO NOT EDIT --
# generated by: etc/generator.p6 

unit module LibXML::Native::Gen::xmlstring;
# set of routines to process strings:
#    type and interfaces needed for the internal string handling of the library, especially UTF8 processing. 
use LibXML::Native::Defs :$lib, :xmlCharP;

sub xmlCharStrdup(Str $cur --> xmlCharP) is native(XML2) is export {*};
sub xmlCharStrndup(Str $cur, int32 $len --> xmlCharP) is native(XML2) is export {*};
sub xmlCheckUTF8(const unsigned char * $utf --> int32) is native(XML2) is export {*};
sub xmlGetUTF8Char(const unsigned char * $utf, Pointer[int32] $len --> int32) is native(XML2) is export {*};
sub xmlStrEqual(xmlCharP $str1, xmlCharP $str2 --> int32) is native(XML2) is export {*};
sub xmlStrPrintf(xmlCharP $buf, int32 $len, Str $msg, ... $... --> int32) is native(XML2) is export {*};
sub xmlStrQEqual(xmlCharP $pref, xmlCharP $name, xmlCharP $str --> int32) is native(XML2) is export {*};
sub xmlStrVPrintf(xmlCharP $buf, int32 $len, Str $msg, va_list $ap --> int32) is native(XML2) is export {*};
sub xmlStrcasecmp(xmlCharP $str1, xmlCharP $str2 --> int32) is native(XML2) is export {*};
sub xmlStrcasestr(xmlCharP $str, xmlCharP $val --> xmlCharP) is native(XML2) is export {*};
sub xmlStrcat(xmlCharP $cur, xmlCharP $add --> xmlCharP) is native(XML2) is export {*};
sub xmlStrchr(xmlCharP $str, xmlChar $val --> xmlCharP) is native(XML2) is export {*};
sub xmlStrcmp(xmlCharP $str1, xmlCharP $str2 --> int32) is native(XML2) is export {*};
sub xmlStrdup(xmlCharP $cur --> xmlCharP) is native(XML2) is export {*};
sub xmlStrlen(xmlCharP $str --> int32) is native(XML2) is export {*};
sub xmlStrncasecmp(xmlCharP $str1, xmlCharP $str2, int32 $len --> int32) is native(XML2) is export {*};
sub xmlStrncat(xmlCharP $cur, xmlCharP $add, int32 $len --> xmlCharP) is native(XML2) is export {*};
sub xmlStrncatNew(xmlCharP $str1, xmlCharP $str2, int32 $len --> xmlCharP) is native(XML2) is export {*};
sub xmlStrncmp(xmlCharP $str1, xmlCharP $str2, int32 $len --> int32) is native(XML2) is export {*};
sub xmlStrndup(xmlCharP $cur, int32 $len --> xmlCharP) is native(XML2) is export {*};
sub xmlStrstr(xmlCharP $str, xmlCharP $val --> xmlCharP) is native(XML2) is export {*};
sub xmlStrsub(xmlCharP $str, int32 $start, int32 $len --> xmlCharP) is native(XML2) is export {*};
sub xmlUTF8Charcmp(xmlCharP $utf1, xmlCharP $utf2 --> int32) is native(XML2) is export {*};
sub xmlUTF8Size(xmlCharP $utf --> int32) is native(XML2) is export {*};
sub xmlUTF8Strlen(xmlCharP $utf --> int32) is native(XML2) is export {*};
sub xmlUTF8Strloc(xmlCharP $utf, xmlCharP $utfchar --> int32) is native(XML2) is export {*};
sub xmlUTF8Strndup(xmlCharP $utf, int32 $len --> xmlCharP) is native(XML2) is export {*};
sub xmlUTF8Strpos(xmlCharP $utf, int32 $pos --> xmlCharP) is native(XML2) is export {*};
sub xmlUTF8Strsize(xmlCharP $utf, int32 $len --> int32) is native(XML2) is export {*};
sub xmlUTF8Strsub(xmlCharP $utf, int32 $start, int32 $len --> xmlCharP) is native(XML2) is export {*};
