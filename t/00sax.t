use v6;
use Test;
# minimal low-level bootstrapping tests for the sax parser

plan 13;
use NativeCall;
use LibXML;
use LibXML::Raw;
use LibXML::Parser;
my \config = LibXML.config;

my @start-tags;
my @end-tags;
my %atts-seen;

# 1. RAW Native SAX Handler

sub startElement(xmlParserCtxt $ctx, Str $name, CArray[Str] $atts) {
    @start-tags.push: $name;
    my $i = 0;
    loop {
        my $key = $atts[$i++] // last;
        my $val = $atts[$i++] // last;
        %atts-seen{$key} = $val;
    }
    
}

sub endElement(xmlParserCtxt $ctx, Str $name) {
    @end-tags.push: $name;
}

my xmlSAXHandler $sax-handler .= new;

ok $sax-handler.defined, 'sax handler defined';
ok !$sax-handler.startElement.defined, 'startElement initial';
lives-ok {$sax-handler.startElement = &startElement}, 'startElement setter';
ok $sax-handler.startElement.defined, 'startElement updated';

$sax-handler .= new: :&startElement, :&endElement;
ok $sax-handler.startElement.defined, 'startElement initialization';
my $string = '<html><body><h1 working="yup">Hello World</h1></body></html>';
my Blob $chunk = $string.encode;

my $ctx = xmlPushParserCtxt.new: :$sax-handler, :$chunk;
$ctx.ParseChunk(Blob.new, 0, 1); #terminate

is-deeply @start-tags, ['html', 'body', 'h1'], 'start tags';
is-deeply @end-tags, ['h1', 'body', 'html'], 'end tags';
is-deeply %atts-seen, %( :working<yup> ), 'atts';

# 2. Subclassed LibXML::SAX::Handler

use LibXML::SAX::Handler;

class SaxHandler is LibXML::SAX::Handler {
    use LibXML::SAX::Builder :sax-cb;
    method startElement($name, :%attribs) is sax-cb {
        %atts-seen ,= %attribs;
        @start-tags.push: $name; 
    }
    method endElement($name) is sax-cb {
        @end-tags.push: $name; 
    }
}

# low-level tests on native sax handlers
@start-tags = ();
@end-tags = ();
%atts-seen = ();
$sax-handler = SaxHandler.new.raw;

$ctx .= new: :$sax-handler, :$chunk;
$ctx.ParseChunk(Blob.new, 0, 1); #terminate

is-deeply @start-tags, ['html', 'body', 'h1'], 'start tags';
is-deeply @end-tags, ['h1', 'body', 'html'], 'end tags';
is-deeply %atts-seen, %( :working<yup> ), 'atts';

# 3. Basic use of LibXML::SAX::Builder::XML

use XML::Document;
use LibXML::SAX::Handler::XML;
my $handler = LibXML::SAX::Handler::XML.new;
$sax-handler = $handler.raw;

$ctx .= new: :$sax-handler, :$chunk;
$ctx.ParseChunk(Blob.new, 0, 1); #terminate

my XML::Document:D $doc = $handler.doc;
my $header = '<?xml version="1.0"?>';
is $doc.Str, $header ~ $chunk, 'XML Sax builder sanity';

class SAXShouter is LibXML::SAX::Handler::SAX2 {
    use LibXML::SAX::Builder :sax-cb;
    method startElement($name, |c) is sax-cb {
        nextwith($name.uc, |c);
    }
    method endElement($name, |c) is sax-cb {
        nextwith($name.uc, |c);
    }
    method characters($chars, |c) is sax-cb {
        nextwith($chars.uc, |c);
    }
}

$sax-handler = SAXShouter.new.raw;

$ctx .= new: :$sax-handler, :$chunk;
$ctx.ParseChunk(Blob.new, 0, 1); #terminate

is $ctx.myDoc.Str.lines.tail, '<HTML><BODY><H1 working="yup">HELLO WORLD</H1></BODY></HTML>', 'Simple transform';
