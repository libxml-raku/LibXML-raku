use LibXML::Parser;

class LibXML::SAX
    is LibXML::Parser {
    use LibXML::SAX::Builder;
    has LibXML::SAX::Builder $.handler;
}
