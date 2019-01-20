use v6;
use Test;
# minimal low-level bootstrapping tests for the sax parser

plan 11;
use NativeCall;
use LibXML;
use LibXML::Config;
use LibXML::Native;
constant config = LibXML::Config;

my @start-tags;
my @end-tags;
my %atts-seen;

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
my Blob $chunk = '<html><body><h1 working="yup">Test</h1></body></html>'.encode;

my $ctx = xmlPushParserCtxt.new: :sax($sax-handler), :$chunk;
$ctx.ParseChunk(Blob.new, 0, 1); #terminate

is-deeply @start-tags, ['html', 'body', 'h1'], 'start tags';
is-deeply @end-tags, ['h1', 'body', 'html'], 'end tags';
is-deeply %atts-seen, %( :working<yup> ), 'atts';

use LibXML::SAX;
class SaxHandler is LibXML::SAX {
    method startElement($name, :%atts) {
        %atts-seen ,= %atts;
        @start-tags.push: $name; 
    }
    method endElement($name) {
        @end-tags.push: $name; 
    }
}

@start-tags = ();
@end-tags = ();
%atts-seen = ();
my SaxHandler $sh .= new;
my xmlSAXHandler $sax = $sh.sax;

$ctx .= new: :$sax, :$chunk;
$ctx.ParseChunk(Blob.new, 0, 1); #terminate

is-deeply @start-tags, ['html', 'body', 'h1'], 'start tags';
is-deeply @end-tags, ['h1', 'body', 'html'], 'end tags';
is-deeply %atts-seen, %( :working<yup> ), 'atts';
