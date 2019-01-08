unit class XML::LibXML::Config;

use XML::LibXML::Native;

our $skipXMLDeclaration;
our $skipDTD;

method skip-xml-declaration is rw { $skipXMLDeclaration }
method skip-dtd is rw { $skipDTD }

method indent-tree-output is rw { $xmlIndentTreeOutput }
method keep-blanks-default is rw {
    XML::LibXML::Native.xmlKeepBlanksDefault;
}

method set-tags-compression { $xmlSaveNoEmptyTags }

