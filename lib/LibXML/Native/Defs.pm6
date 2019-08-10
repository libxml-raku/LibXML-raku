unit module LibXML::Native::Defs;

constant LIB is export(:LIB) = 'xml2';
constant BIND-LIB is export(:BIND-LIB) =  %?RESOURCES<libraries/xml6>;
constant Stub is export(:Stub) = 'CPointer';
constant xmlCharP is export(:xmlCharP) = Str;
my constant XML_XMLNS_NS is export(:XML_XMLNS_NS) = 'http://www.w3.org/2000/xmlns/';
my constant XML_XML_NS is export(:XML_XML_NS) = 'http://www.w3.org/XML/1998/namespace';
