use v6;
use Test;
# minimal low-level bootstrapping tests for the sax parser

plan 7;
use NativeCall;
use LibXML;
use LibXML::Config;
use LibXML::Native;
constant config = LibXML::Config;

my @tags;
my %atts;

sub start-element-cb(parserCtxt $ctx, Str $name, CArray[Str] $atts) {
    @tags.push: $name;
    my $i = 0;
    loop {
        my $key = $atts[$i++] // last;
        my $val = $atts[$i++] // last;
        %atts{$key} = $val;
    }
    
}

my xmlSAXHandler $sax-handler .= new;

ok $sax-handler.defined, 'sax handler defined';
ok !$sax-handler.startElement.defined, 'startElement initial';
lives-ok {$sax-handler.startElement = &start-element-cb}, 'startElement setter';
ok $sax-handler.startElement.defined, 'startElement updated';

$sax-handler .= new: :startElement(&start-element-cb);
ok $sax-handler.startElement.defined, 'startElement initialization';
my Blob $chunk = '<html><body><h1 working="yup">Test</h1></body></html>'.encode;

my $ctx = xmlPushParserCtxt.new: :sax($sax-handler), :$chunk;
$ctx.ParseChunk(Blob.new, 0, 1); #terminate

is-deeply @tags, ['html', 'body', 'h1'], 'tags';
is-deeply %atts, %( :working<yup> ), 'atts';

