unit class LibXML::SAX;

use LibXML::Parser;
also is LibXML::Parser;

use LibXML::SAX::Handler::SAX2;

submethod TWEAK {
    self.sax-handler //= LibXML::SAX::Handler::SAX2;
}

