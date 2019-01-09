unit class LibXML::Config;

use LibXML::Native;

our $skipXMLDeclaration;
our $skipDTD;

method skip-xml-declaration is rw { $skipXMLDeclaration }
method skip-dtd is rw { $skipDTD }

method keep-blanks-default is rw {
    LibXML::Native.xmlKeepBlanksDefault;
}


