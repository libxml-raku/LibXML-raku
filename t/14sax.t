use v6;
use Test;
plan 56;

use LibXML;
use LibXML::SAX;
use LibXML::SAX::Builder;
use LibXML::SAX::Handler::SAX2;
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

# TEST
ok(1, 'Loaded');

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

my $SAXTester_startElement_stacker = Stacker.new(
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

my $SAXNSTester_startElement_stacker = Stacker.new(
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

my $SAXNS2Tester_startElement_stacker = Stacker.new(
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

my $parser;
{
    my SAXTester $sax .= new;
    # TEST
    ok($sax, ' TODO : Add test name');

    my $str = "example/dromeds.xml".IO.slurp;
    my $doc = LibXML.parse: :string($str);
    # TEST
    ok($doc, ' TODO : Add test name');

    my $generator = LibXML::SAX.new(sax-handler => $sax);
    # TEST
    ok($generator, ' TODO : Add test name');

    $generator.reparse($doc); # startElement*10

    # TEST
    $SAXTester_startElement_stacker.test(
        ['true' xx 10],
        'startElement was successful 10 times.',
    );

    # TEST
    $SAXTester_startDocument_counter.test(1, 'startDocument called once.');
    # TEST
    $SAXTester_endDocument_counter.test(1, 'endDocument called once.');

    # TEST
    my $gen2 = LibXML::SAX.new;
    my $dom2 = $gen2.reparse($doc);
    # TEST
    ok($dom2, ' TODO : Add test name');

    # TEST
    is($dom2.Str, $str, ' TODO : Add test name');
    # warn($dom2.toString);

########### XML::SAX Replacement Tests ###########
    $parser = LibXML::SAX.new(sax-handler => $sax);
    # TEST
    ok($parser, ' TODO : Add test name');
    $parser.parse: :file("example/dromeds.xml"); # startElement*10

    # TEST
    $SAXTester_startElement_stacker.test(
        ['true' xx 10],
        'parse: file(): startElement was successful 10 times.',
    );
    # TEST
    $SAXTester_startDocument_counter.test(1, 'startDocument called once.');
    # TEST
    $SAXTester_endDocument_counter.test(1, 'endDocument called once.');

    $parser.parse: :string(q:to<EOT>); # startElement*1
<?xml version='1.0' encoding="US-ASCII"?>
<dromedaries one="1" />
EOT
    # TEST
    $SAXTester_startElement_stacker.test(
        ['true'],
        'parse: :string() : startElement was successful 1 times.',
    );
    # TEST
    $SAXTester_startDocument_counter.test(1, 'startDocument called once.');
    # TEST
    $SAXTester_endDocument_counter.test(1, 'endDocument called once.');
}

{
    my $sax = SAXNSTester.new;
    # TEST
    ok($sax, ' TODO : Add test name');

    $parser.sax-handler = $sax;
    $parser.parse: :file("example/ns.xml");

    # TEST
    $SAXNSTester_startElement_stacker.test(
        [
            'true' xx 3
        ],
        'Three successful SAXNSTester elements.',
    );
    # TEST
    $SAXNSTester_start_prefix_mapping_stacker.test(
        [
            'true' xx 3
        ],
        'Three successful SAXNSTester start_prefix_mapping.',
    );
    # TEST
    $SAXNSTester_end_prefix_mapping_stacker.test(
        [
            'true' xx 3
        ],
        'Three successful SAXNSTester end_prefix_mapping.',
    );
}

{
    my @stack;
    my $sax = SAXLocatorTester.new( cb => -> $sax, $name, :$ctx, |c {
        push( @stack, $name => [
            $sax.line-number($ctx),
            $sax.column-number($ctx)
        ] );
    } );

    # TEST
    ok($sax, 'Created SAX handler with document locator');

    my $parser = LibXML::SAX.new(sax-handler => $sax);

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
        characters     => [ 4, 1  ],
        comment        => [ 4, 17 ],
        characters     => [ 5, 1  ],
        cdataBlock    => [ 5, 20 ],
        characters     => [ 6, 1  ],
        endElement    => [ 6, 8  ],
        endDocument   => [ 6, 8  ],
    ];

    # TEST
    is-deeply( @stack, $expecting, "Check locator positions" );
}


########### Namespace test ( empty namespaces ) ########

{
    my SAXNS2Tester $sax .= new;
    my $xml = "<a xmlns='xml://A'><b/></a>";
    my @tests = (
        sub {
            LibXML::SAX.new(sax-handler => $sax).parse: :string( $xml );
            # TEST
            $SAXNS2Tester_startElement_stacker.test(['true'], 'LibXML::SAX');
        },
    );

    $_.() for @tests;

}

skip("todo: port remaining tests", 33);
=begin TODO

########### Error Handling ###########
{
  my $xml = '<foo><bar/><a>Text</b></foo>';

  my $handler = SAXErrorTester.new;

  foreach my $pkg (qw(LibXML::SAX::Parser LibXML::SAX)) {
    undef $@;
    eval {
      $pkg.new(Handler => $handler).parse_string($xml);
    };
    # TEST*2
    ok($@, ' TODO : Add test name'); # We got an error
  }

  $handler = SAXErrorCallbackTester.new;
  eval { LibXML::SAX.new(Handler => $handler ).parse_string($xml) };
  # TEST
  ok($@, ' TODO : Add test name'); # We got an error
  # TEST
  ok( $handler.{fatal_called}, ' TODO : Add test name' );

}

########### LibXML::SAX::parse_chunk test ###########

{
  my $chunk = '<app>LOGOUT</app><bar/>';
  my $builder = LibXML::SAX::Builder.new();
  my $parser = LibXML::SAX.new( Handler => $builder );
  $parser.startDocument();
  $builder.startElement({Name=>'foo'});
  $parser.parse_chunk($chunk);
  $parser.parse_chunk($chunk);
  $builder.endElement({Name=>'foo'});
  $parser.endDocument();
  # TEST
  is($builder.result().documentElement.toString(), '<foo>'.$chunk.$chunk.'</foo>', ' TODO : Add test name');
}


######## TEST error exceptions ##############
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
  my $parser = LibXML::SAX.new( Handler => MySAXHandler.new( )) ;
  eval { $parser.parse_string(q:to<EOF> ) };
<TVChannel TVChannelID="71" TVChannelName="ARD">
        <Moin>Moin</Moin>
</TVChannel>
EOF
  # TEST
  is(ref($@), 'MySAXException', ' TODO : Add test name');
  # TEST
  is(ref($@) && $@.{Message}, "My exception", ' TODO : Add test name');
}
########### Helper class #############
=end TODO

use LibXML::SAX::Handler::SAX2;
use LibXML::Native;

class SAXTester
    is LibXML::SAX::Handler::SAX2 {

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
            my LibXML::Node $node .= box($_);
            $SAXTester_startElement_stacker.cb.($node);
        }
    }

    method endElement(xmlParserCtxt :$ctx!, |) is sax-cb {
        callsame;
    }
}


class SAXNSTester
    is LibXML::SAX::Handler::SAX2 {

    use LibXML::SAX::Builder :sax-cb, :atts2Hash;
    has Hash @!ns;
    has LibXML::Node @!nodes;

    method startElementNs($name, xmlParserCtxt :$ctx!, :$num-namespaces, :$namespaces) is sax-cb {
        callsame;
        @!ns.push: ${ :num-namespaces, :$namespaces };
        given $ctx.node {
            my LibXML::Node $node .= box($_);
            @!nodes.push: $node;
            for 0 ..^ $num-namespaces {
                $SAXNSTester_start_prefix_mapping_stacker.cb().($node)
            }
            $SAXNSTester_startElement_stacker.cb.($node);
        }
    }

    method endElementNs(xmlParserCtxt :$ctx!, |) is sax-cb {
        callsame;
        my %ns = @!ns.pop;
        my LibXML::Node $node = @!nodes.pop;

        for 0 ..^ %ns<num-namespaces> {
            $SAXNSTester_end_prefix_mapping_stacker.cb().($node)
        }
   }

}

class SAXNS2Tester
    is LibXML::SAX::Handler::SAX2 {
    use LibXML::SAX::Builder :sax-cb;

    method startElement(:$ctx!, |) is sax-cb {
        callsame;
        with $ctx.node {
            my LibXML::Node $node .= box($_);
            warn $node.Str;
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

=begin TODO2

package SAXErrorTester;
use Test::More;

sub new {
    bless {}, shift;
}

sub endDocument {
    print "End doc: @_\n";
    return 1; # Shouldn't be reached
}

package SAXErrorCallbackTester;
use Test::More;

sub fatal_error {
    $_[0].{fatal_called} = 1;
}

sub startElement {
    # test if we can do other stuff
    LibXML.parse_string("<foo/>");
    return;
}
sub new {
    bless {}, shift;
}

sub endDocument {
    print "End doc: @_\n";
    return 1; # Shouldn't be reached
}
=end TODO2
