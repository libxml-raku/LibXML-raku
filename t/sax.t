use v6;
use Test;
# minimal low-level bootstrapping tests for the sax parser

plan 12;
use NativeCall;
use LibXML;
use LibXML::Native;
my \config = LibXML.config;

my @start-tags;
my @end-tags;
my %atts-seen;

# 1. RAW Native SAX Handler

sub startElement(parserCtxt $ctx, Str $name, CArray[Str] $atts) {
    @start-tags.push: $name;
    my $i = 0;
    loop {
        my $key = $atts[$i++] // last;
        my $val = $atts[$i++] // last;
        %atts-seen{$key} = $val;
    }
    
}

sub endElement(parserCtxt $ctx, Str $name) {
    @end-tags.push: $name;
}

my xmlSAXHandler $sax-handler .= new;

ok $sax-handler.defined, 'sax handler defined';
ok !$sax-handler.startElement.defined, 'startElement initial';
lives-ok {$sax-handler.startElement = &startElement}, 'startElement setter';
ok $sax-handler.startElement.defined, 'startElement updated';

$sax-handler .= new: :&startElement, :&endElement;
ok $sax-handler.startElement.defined, 'startElement initialization';
my Blob $chunk = '<html><body><h1 working="yup">Hello World</h1></body></html>'.encode;

my $ctx = xmlPushParserCtxt.new: :sax($sax-handler), :$chunk;
$ctx.ParseChunk(Blob.new, 0, 1); #terminate

is-deeply @start-tags, ['html', 'body', 'h1'], 'start tags';
is-deeply @end-tags, ['h1', 'body', 'html'], 'end tags';
is-deeply %atts-seen, %( :working<yup> ), 'atts';

# 2. Subclassed LibXML::SAX::Handler

use LibXML::SAX::Handler;
class SaxHandler is LibXML::SAX::Handler {
    use LibXML::SAX::Builder :sax-cb;
    method startElement($name, :%atts) is sax-cb {
        callsame;
        %atts-seen ,= %atts;
        @start-tags.push: $name; 
    }
    method endElement($name) is sax-cb {
        callsame;
        @end-tags.push: $name; 
    }
}

@start-tags = ();
@end-tags = ();
%atts-seen = ();
my xmlSAXHandler $sax = SaxHandler.new.sax;

$ctx .= new: :$sax, :$chunk;
$ctx.ParseChunk(Blob.new, 0, 1); #terminate

is-deeply @start-tags, ['html', 'body', 'h1'], 'start tags';
is-deeply @end-tags, ['h1', 'body', 'html'], 'end tags';
is-deeply %atts-seen, %( :working<yup> ), 'atts';
# 3. Basic use of LibXML::SAX::Builder::XML

use XML::Document;
use LibXML::SAX::Handler::XML;
my $handler = LibXML::SAX::Handler::XML.new;
$sax = $handler.sax;

$ctx .= new: :$sax, :$chunk;
$ctx.ParseChunk(Blob.new, 0, 1); #terminate

my XML::Document:D $doc = $handler.doc;
my $header = '<?xml version="1.0"?>';
is $doc.Str, $header ~ $chunk, 'XML Sax builder sanity';
