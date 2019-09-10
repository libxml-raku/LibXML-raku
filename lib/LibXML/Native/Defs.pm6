unit module LibXML::Native::Defs;

constant XML2 is export(:XML2) = 'xml2';
constant BIND-XML2 is export(:BIND-XML2) = %?RESOURCES<libraries/xml6>;
constant CLIB is export(:CLIB) = Rakudo::Internals.IS-WIN ?? 'msvcrt' !! Str;

constant Opaque is export(:Opaque) = 'CPointer';
constant xmlCharP is export(:xmlCharP) = Str;
my constant XML_XMLNS_NS is export(:XML_XMLNS_NS) = 'http://www.w3.org/2000/xmlns/';
my constant XML_XML_NS is export(:XML_XML_NS) = 'http://www.w3.org/XML/1998/namespace';
