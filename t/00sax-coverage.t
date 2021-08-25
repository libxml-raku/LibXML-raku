use LibXML::Document;
use LibXML::SAX::Handler::SAX2;
use Test;

class SAXCoverage is LibXML::SAX::Handler::SAX2 {

    our %cov;
    our %ext-dtd;
    our %entity-decl;
    our %element-decl;
    multi trait_mod:<is>(Method $m, :%metered!) {
        $m.wrap: method (|) {
            %metered{$m.name}++;
            callsame()
        }
    }

    use LibXML::SAX::Builder :sax-cb;
    method setDocumentLocator($) is sax-cb is metered(%cov) {
        callsame();
    }
    method entityDecl($name, $content, :ctx($), *%etc) is sax-cb is metered(%cov) {
        %entity-decl{$name} = %(%etc, %( :$content ));
        callsame();
    }
    method elementDecl($name, $content, :ctx($), *%etc) is sax-cb is metered(%cov) {
        %element-decl{$name} = %(%etc, %( :$content ));
        callsame();
    }
    method attributeDecl(|) is sax-cb is metered(%cov) {
        callsame();
    }
    method notationDecl(|c) is sax-cb is metered(%cov) {
        callsame();
    }
    method internalSubset($name, :ctx($), *%etc) is sax-cb is metered(%cov) {
        %ext-dtd{$name} = %etc;
        callsame();
    }
    method getEntity($name) is sax-cb {
        callsame;
    }
    method startDocument() is sax-cb is metered(%cov) {
        callsame();
    }
    method endDocument() is sax-cb is metered(%cov) {
        callsame();
    }
    method startElement($name,) is sax-cb is metered(%cov) {
        callsame();
    }
    method endElement($name,) is sax-cb is metered(%cov) {
        callsame();
    }
    method characters($chars) is sax-cb is metered(%cov) {
        callsame();
    }
    method cdataBlock($chars) is sax-cb is metered(%cov) {
        callsame();
    }
    method reference($text) is sax-cb is metered(%cov) {
        callsame();
    }
    method processingInstruction(|c) is sax-cb is metered(%cov) {
        callsame();
    }
    method comment(|c) is sax-cb is metered(%cov) {
        callsame();
    }
    method unparsedEntityDecl(|c) is sax-cb is metered(%cov) {
        callsame();
    }
}

my SAXCoverage $sax-handler .= new;
my LibXML::Document $doc1 .= parse: :file<samples/dtd.xml>;
my LibXML::Document $doc2 .= parse: :file<samples/dtd.xml>, :$sax-handler;
is $doc2.Str, $doc1.Str, 'document integrity';

$doc1 .= parse: :file<samples/cdata.xml>;
$doc2 .= parse: :file<samples/cdata.xml>, :$sax-handler;
is $doc2.Str, $doc1.Str, 'document integrity';

is-deeply %SAXCoverage::cov.keys.sort.List, qw<
    attributeDecl cdataBlock characters comment elementDecl endDocument
    endElement entityDecl internalSubset notationDecl processingInstruction
    reference setDocumentLocator startDocument startElement unparsedEntityDecl>, 'sax coverage';
is-deeply %SAXCoverage::ext-dtd<doc>, %( :external-id(Str), :system-id(Str), ), 'external subset';
is-deeply %SAXCoverage::entity-decl<foo>, %(:public-id(Str), :system-id(Str), :type(1), :content(" test ") ), 'entity declaration';
done-testing;
