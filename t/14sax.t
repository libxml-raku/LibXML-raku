use v6;
use Test;
plan 34;

use LibXML;
use LibXML::SAX;
use LibXML::SAX::Builder;
use LibXML::SAX::Handler::SAX2;
use LibXML::Document;
use LibXML::Node;
use LibXML::Element;

use lib 't/lib';
use Collector;
use Counter;
use Stacker;

class SAXTester { ... }
class SAXNSTester { ... }
class SAXNS2Tester { ... }
class SAXLocatorTester { ... }
class SAXErrorTester { ... }
class SAXInternalParseTester { ... }

sub _create_simple_counter {
    Counter.new(
        gen-cb => -> &inc-cb {
            sub {
                inc-cb();
            }
        }
    );
}

my $SAXTester_startDocument_counter = _create_simple_counter();
my $SAXTester_endDocument_counter = _create_simple_counter();

my Stacker $SAXTester_startElement_stacker .= new(
    gen-cb => -> &push-cb {

        -> LibXML::Element $el {

            &push-cb(
                ($el.localname ~~ m{^^[dromedaries|species|humps|disposition|legs]$$})
                    ?? 'true'
                    !! 'false'
                   );
        };
    }
);

my Stacker $SAXNSTester_startElement_stacker .= new(
    gen-cb => -> &push-cb {

        ->  LibXML::Node $node {

            &push-cb(
                $node.namespaceURI ~~ /^urn:/
                    ?? 'true'
                    !! 'false'
                   );

        };
    }
);

my Stacker $SAXNS2Tester_startElement_stacker .= new(
    gen-cb => -> &push-cb {
        -> LibXML::Element $elt {

            if ($elt.name eq "b")
                {
                    &push-cb(
                        ($elt.namespaceURI eq "xml://A") ?? 'true' !! 'false'
                       );
                }
            };
    }
);


sub _create_urn_stacker
{
    Stacker.new(
        gen-cb => -> &push-cb {
            -> LibXML::Node $node {

                &push-cb(
                    ($node.namespaceURI ~~ /^^'urn:'[camels|mammals|a]$$/)
                        ?? 'true'
                        !! 'false'
                       );
            };
        }
    );
}

my $SAXNSTester_start_prefix_mapping_stacker = _create_urn_stacker();
my $SAXNSTester_end_prefix_mapping_stacker = _create_urn_stacker();

my LibXML::SAX $parser;
subtest 'callback basic', {

    my $str = "samples/dromeds.xml".IO.slurp;
    my LibXML::Document:D $doc = LibXML.parse: :string($str);
    my SAXTester:D $sax = $doc.create: SAXTester;

    my LibXML::SAX:D $generator = $doc.create: LibXML::SAX, sax-handler => $sax;

    $generator.reparse($doc); # startElement*10

    $SAXTester_startElement_stacker.test(
        ['true' xx 10],
        'startElement was successful 10 times.',
    );

    $SAXTester_startDocument_counter.test(1, 'startDocument called once.');
    $SAXTester_endDocument_counter.test(1, 'endDocument called once.');

    my LibXML::SAX $gen2 = $doc.create: LibXML::SAX;
    my LibXML::Document:D $dom2 = $gen2.reparse($doc);

    is $dom2.Str, $str;
    # warn($dom2.toString);

    ########### XML::SAX Replacement Tests ###########
    $parser = LibXML::SAX.new(sax-handler => $sax);
    ok $parser.defined;
    $parser.parse: :file("samples/dromeds.xml"); # startElement*10

    $SAXTester_startElement_stacker.test(
        ['true' xx 10],
        'parse: file(): startElement was successful 10 times.',
    );
    $SAXTester_startDocument_counter.test(1, 'startDocument called once.');
    $SAXTester_endDocument_counter.test(1, 'endDocument called once.');

    $parser.parse: :string(q:to<EOT>); # startElement*1
<?xml version='1.0' encoding="US-ASCII"?>
<dromedaries one="1" />
EOT
    $SAXTester_startElement_stacker.test(
        ['true'],
        'parse: :string() : startElement was successful 1 times.',
    );
    $SAXTester_startDocument_counter.test(1, 'startDocument called once.');
    $SAXTester_endDocument_counter.test(1, 'endDocument called once.');
}

subtest 'Ns callbacks', {
    my SAXNSTester:D $sax = $parser.create: SAXNSTester;

    $parser.sax-handler = $sax;
    $parser.parse: :file("samples/ns.xml");

    $SAXNSTester_startElement_stacker.test(
        [
            'true' xx 3
        ],
        'Three successful SAXNSTester elements.',
    );
    $SAXNSTester_start_prefix_mapping_stacker.test(
        [
            'true' xx 3
        ],
        'Three successful SAXNSTester start_prefix_mapping.',
    );
    $SAXNSTester_end_prefix_mapping_stacker.test(
        [
            'true' xx 3
        ],
        'Three successful SAXNSTester end_prefix_mapping.',
    );
}

subtest 'callback metrics', {
    my @stack;
    my sub cb($sax, $name, :$ctx, |c) {
        push( @stack, $name => [
            $sax.line-number($ctx),
            $sax.column-number($ctx),
        ]);
    };
    my SAXLocatorTester:D $sax .= new( :&cb );

    my LibXML::SAX:D $parser .= new(sax-handler => $sax);

    $parser.parse: :string(q:to<EOT>.chomp);
    <?xml version="1.0" encoding="UTF-8"?>
    <root>
    1
    <!-- comment -->
    <![CDATA[ a < b ]]>
    </root>
    EOT

    my $expecting = [
        startDocument => [ 2, 1  ],
        startElement  => [ 2, 6  ],
        characters    => [ 4, 1  ],
        comment       => [ 4, 17 ],
        characters    => [ 5, 1  ],
        cdataBlock    => [ 5, 20 ],
        characters    => [ 6, 1  ],
        endElement    => [ 6, 8  ],
        endDocument   => [ 6, 8  ],
    ];

    is-deeply @stack, $expecting, "Check locator positions";
}


subtest 'namespaces, empty', {
    use LibXML::Config;
    my SAXNS2Tester $sax .= new: config => LibXML::Config.new;
    my $xml = "<a xmlns='xml://A'><b/></a>";
    my @tests = (
        sub {
            LibXML::SAX.new(sax-handler => $sax).parse: :string( $xml );
            $SAXNS2Tester_startElement_stacker.test(['true'], 'LibXML::SAX');
        },
    );

    .() for @tests;

}

subtest 'error handling', {
    my $bad-xml = '<foo><bar/><a>Text</b></foo>';
    my $good-xml = '<foo><bar/><a>Text</a></foo>';

    my SAXErrorTester $sax .= new;
    do {
        try {
            LibXML::SAX.new(sax-handler => $sax).parse: :string($bad-xml);
        };
        ok $!, 'we got an error';
    }
    ok $sax.errors, 'error handler called';

    my SAXInternalParseTester $sax2 .= new;
    do {
        try { LibXML::SAX.new(sax-handler => $sax2 ).parse: :string($bad-xml) };
        ok $!, 'we got another error';
    }
    ok $sax2.errors, 'error handler called';

    $sax2 .= new;
    do {
        try { LibXML::SAX.new(sax-handler => $sax2 ).parse: :string($good-xml) };
        nok $!, 'no errors';
    }
    ok $sax2.start-element-called, 'startElement called';
    ok $sax2.start-element-completed, 'startElement completed';
    nok $sax2.errors, 'no internal errors';

    $sax2 .= new: :pre-xml($bad-xml);
    do {
        try { LibXML::SAX.new(sax-handler => $sax2 ).parse: :string($good-xml) };
        todo "issue #80";
        ok $!, 'we got another error';
    }
    ok $sax2.start-element-called, 'startElement called';
    nok $sax2.start-element-completed, 'startElement not completed';
    nok $sax2.errors, 'error handler not called for internal errors';
}

 ########### LibXML::SAX::parse-chunk test ###########

skip("todo: port remaining tests", 29);
=begin TODO


{
    my $chunk = '<app>LOGOUT</app><bar/>';
    my LibXML::SAX::Handler::SAX2 $sax .= new();
    my LibXML::SAX $parser .= new(sax-handler => $sax );
    $parser.startDocument();
    $sax.startElement('foo');
    $parser.parse-chunk($chunk);
    $parser.parse-chunk($chunk);
    $builder.endElement('foo');
    $parser.endDocument();
    is($builder.publish().documentElement.toString(), '<foo>'.$chunk.$chunk.'</foo>', ' TODO : Add test name');
}

{

    package MySAXHandler;
    use strict;
    use warnings;
    use parent 'XML::SAX::Base';
    use Carp;
    sub startElement {
        my( $self, $elm) = @_;
        if ( $elm.{LocalName} eq 'TVChannel' ) {
            die bless({ Message => "My exception"},"MySAXException");
        }
    }
}
{
    use strict;
    use warnings;
    my LibXML::SAX $parser .= new( Handler => MySAXHandler.new( )) ;
    eval { $parser.parse_string(q:to<EOF> ) };
    <TVChannel TVChannelID="71" TVChannelName="ARD">
            <Moin>Moin</Moin>
    </TVChannel>
    EOF
    is(ref($@), 'MySAXException', ' TODO : Add test name');
    is(ref($@) && $@.{Message}, "My exception", ' TODO : Add test name');
}

=end TODO

########### Helper class #############

use LibXML::SAX::Handler::SAX2;
use LibXML::Raw;
use LibXML::_Configurable;

class SAXTester {
    also is LibXML::SAX::Handler::SAX2;
    also does LibXML::_Configurable;

    use NativeCall;
    use LibXML::SAX::Builder :sax-cb;

    method startDocument(xmlParserCtxt :$ctx!, |) is sax-cb {
        callsame;
        $SAXTester_startDocument_counter.cb.()
    }

    method endDocument(xmlParserCtxt :$ctx!, |) is sax-cb {
        callsame;
        $SAXTester_endDocument_counter.cb.()
    }

    method startElement(xmlParserCtxt :$ctx!, |) is sax-cb {
        callsame;
        with $ctx.node {
            my LibXML::Node $node = self.box(LibXML::Node, $_);
            $SAXTester_startElement_stacker.cb.($node);
        }
    }

    method endElement(xmlParserCtxt :$ctx!, |) is sax-cb {
        callsame;
    }
}


class SAXNSTester {
    also is LibXML::SAX::Handler::SAX2;
    also does LibXML::_Configurable;

    use LibXML::SAX::Builder :sax-cb, :atts2Hash;
    has Hash @!ns;
    has LibXML::Node @!nodes;

    method startElementNs($name, xmlParserCtxt :$ctx!, :$num-namespaces, :$namespaces) is sax-cb {
        callsame;
        @!ns.push: ${ :num-namespaces, :$namespaces };
        given $ctx.node {
            my LibXML::Node $node = self.box(LibXML::Node, $_);
            @!nodes.push: $node;
            for ^$num-namespaces {
                $SAXNSTester_start_prefix_mapping_stacker.cb().($node)
            }
            $SAXNSTester_startElement_stacker.cb.($node);
        }
    }

    method endElementNs(xmlParserCtxt :$ctx!, |) is sax-cb {
        callsame;
        my %ns = @!ns.pop;
        my LibXML::Node $node = @!nodes.pop;

        for ^%ns<num-namespaces> {
            $SAXNSTester_end_prefix_mapping_stacker.cb().($node)
        }
   }

}

class SAXNS2Tester {
    also is LibXML::SAX::Handler::SAX2;
    also does LibXML::_Configurable;
    use LibXML::SAX::Builder :sax-cb;

    method startElement(:$ctx!, |) is sax-cb {
        callsame;
        with $ctx.node {
            my LibXML::Node $node = self.box(LibXML::Node, $_);
            $SAXNS2Tester_startElement_stacker.cb.($node);
        }
    }
    method endElement(|) is sax-cb { callsame; }
}

class SAXLocatorTester
    is LibXML::SAX::Handler::SAX2 {

    use LibXML::SAX::Builder :sax-cb, :is-sax-cb;

    has &.cb;

    BEGIN {
        for <
            startDocument endDocument
            startElement endElement
            cdataBlock
            characters comment> -> $name {
            my &meth = method (|c) {
                &!cb(self, $name, |c);
            }
            $?CLASS.^add_method($name, &meth does is-sax-cb[$name]);
        }
    }

}

class SAXErrorTester
    is LibXML::SAX::Handler::SAX2 {
    use LibXML::SAX::Builder :sax-cb, :is-sax-cb;
    has $.start-doc-calls = 0;
    has $.end-doc-calls = 0;
    has @.errors;

    method startDocument(|c) is sax-cb { $!start-doc-calls++; }
    method endDocument(|c) is sax-cb { $!end-doc-calls++; }
    method warning($_) is sax-cb { @!errors.push: 'warning' => $_ }
    method error($_) is sax-cb { @!errors.push: 'error' => $_; }
    method fatalError($_) is sax-cb { @!errors.push: 'fatal' => $_; }
}

class SAXInternalParseTester
    is SAXErrorTester { # check inheritance

    has $.pre-xml = "<foo/>";
    has $.post-xml = "<bar/>";

    use LibXML::SAX::Builder :sax-cb, :is-sax-cb;
    has Bool $.start-element-called;
    has Bool $.start-element-completed;
    method startElement(|) is sax-cb {
        $!start-element-called = True;
        # test if we can do other stuff
        LibXML.parse: :string($!pre-xml);
        callsame;
        LibXML.parse: :string($!post-xml);
        $!start-element-completed = True;
    }
    method endElement(|) is sax-cb { callsame }
}

