unit class XML::LibXML::Config;

use XML::LibXML::Native;

our $skipXMLDeclaration;
our $skipDTD;

method skip-xml-declaration is rw { $skipXMLDeclaration }
method skip-dtd is rw { $skipDTD }

method keep-blanks-default is rw {
    XML::LibXML::Native.xmlKeepBlanksDefault;
}


