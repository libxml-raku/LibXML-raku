use v6;
use Test;
plan 55;

use LibXML;
use LibXML::SAX;
#use LibXML::SAX::Parser;
use LibXML::SAX::Builder;
use LibXML::SAX::Handler::SAX2;
use LibXML::Node;
use LibXML::Element;

use lib 't/lib';
use Collector;
use Counter;
use Stacker;

class SAXTester { ... }

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

my $SAXTester_start_document_counter = _create_simple_counter();
my $SAXTester_end_document_counter = _create_simple_counter();

my $SAXTester_start_element_stacker = Stacker.new(
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

my $SAXNSTester_start_element_stacker = Stacker.new(
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

my $SAXNS2Tester_start_element_stacker = Stacker.new(
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

temp $XML::SAX::ParserPackage = 'LibXML::SAX::Parser';

my $parser;
{
    my $sax = SAXTester.new;
    # TEST
    ok($sax, ' TODO : Add test name');

    my $str = "example/dromeds.xml".IO.slurp;
    my $doc = LibXML.new.parse: :string($str);
    # TEST
    ok($doc, ' TODO : Add test name');

    my $generator = LibXML::SAX.new(sax-handler => $sax);
    # TEST
    ok($generator, ' TODO : Add test name');

    $generator.reparse($doc); # start_element*10

    # TEST
    $SAXTester_start_element_stacker.test(
        ['true' xx 10],
        'start_element was successful 10 times.',
    );

    # TEST
    $SAXTester_start_document_counter.test(1, 'start_document called once.');
    # TEST
    $SAXTester_end_document_counter.test(1, 'end_document called once.');

    my $builder = LibXML::SAX::Builder.new();
    # TEST
    ok($builder, ' TODO : Add test name');
    my $gen2 = LibXML::SAX.new(sax-builder => $builder);
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
    $parser.parse: :file("example/dromeds.xml"); # start_element*10

    # TEST
    $SAXTester_start_element_stacker.test(
        ['true' xx 10],
        'parse: file(): start_element was successful 10 times.',
    );
    # TEST
    $SAXTester_start_document_counter.test(1, 'start_document called once.');
    # TEST
    $SAXTester_end_document_counter.test(1, 'end_document called once.');

    $parser.parse: :string(q:to<EOT>); # start_element*1
<?xml version='1.0' encoding="US-ASCII"?>
<dromedaries one="1" />
EOT
    # TEST
    $SAXTester_start_element_stacker.test(
        ['true'],
        'parse: :string() : start_element was successful 1 times.',
    );
    # TEST
    $SAXTester_start_document_counter.test(1, 'start_document called once.');
    # TEST
    $SAXTester_end_document_counter.test(1, 'end_document called once.');
}

{
}; skip("todo: port remaining tests", 38);
=begin TODO
    my $sax = SAXNSTester.new;

    # TEST
    ok($sax, ' TODO : Add test name');

    $parser.set_handler($sax);

    $parser.parse_uri("example/ns.xml");

    # TEST
    $SAXNSTester_start_element_stacker.test(
        [
            qw(true true true)
        ],
        'Three successful SAXNSTester elements.',
    );
    # TEST
    $SAXNSTester_start_prefix_mapping_stacker.test(
        [
            qw(true true true)
        ],
        'Three successful SAXNSTester start_prefix_mapping.',
    );
    # TEST
    $SAXNSTester_end_prefix_mapping_stacker.test(
        [
            qw(true true true)
        ],
        'Three successful SAXNSTester end_prefix_mapping.',
    );
}

{
    local $XML::SAX::ParserPackage = 'LibXML::SAX';

    my @stack;
    my $sax = SAXLocatorTester.new( sub {
        my ($self, $method, @args) = @_;
        push( @stack, $method => [
            $self.{locator}.{LineNumber},
            $self.{locator}.{ColumnNumber}
        ] );
    } );

    # TEST
    ok($sax, 'Created SAX handler with document locator');

    my $parser = XML::SAX::ParserFactory.parser(Handler => $sax);

    $parser.parse_string(<<EOT);
<?xml version="1.0" encoding="UTF-8"?>
<root>
1
<!-- comment -.
<![CDATA[ a < b ]]>
</root>
EOT

    my $expecting = [
        start_document => [ 2, 1  ],
        start_element  => [ 2, 6  ],
        characters     => [ 4, 1  ],
        comment        => [ 4, 17 ],
        characters     => [ 5, 1  ],
        start_cdata    => [ 5, 20 ],
        characters     => [ 5, 20 ],
        end_cdata      => [ 5, 20 ],
        characters     => [ 6, 1  ],
        end_element    => [ 6, 8  ],
        end_document   => [ 6, 8  ],
    ];

    # TEST
    is_deeply( \@stack, $expecting, "Check locator positions" );
}


########### Namespace test ( empty namespaces ) ########

{
    my $h = "SAXNS2Tester";
    my $xml = "<a xmlns='xml://A'><b/></a>";
    my @tests = (
sub {
    LibXML::SAX        .new( Handler => $h ).parse_string( $xml );
    # TEST
    $SAXNS2Tester_start_element_stacker.test([qw(true)], 'LibXML::SAX');
},

sub {
    LibXML::SAX::Parser.new( Handler => $h ).parse_string( $xml );
    # TEST
    $SAXNS2Tester_start_element_stacker.test([qw(true)], 'LibXML::SAX::Parser');
},
);

    $_.() for @tests;


}


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
  my $builder = LibXML::SAX::Builder.new( Encoding => 'UTF-8' );
  my $parser = LibXML::SAX.new( Handler => $builder );
  $parser.start_document();
  $builder.start_element({Name=>'foo'});
  $parser.parse_chunk($chunk);
  $parser.parse_chunk($chunk);
  $builder.end_element({Name=>'foo'});
  $parser.end_document();
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
  sub start_element {
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
  eval { $parser.parse_string( <<'EOF' ) };
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

    method startDocument(parserCtxt :$ctx!, |) is sax-cb {
        callsame;
        $SAXTester_start_document_counter.cb.()
    }

    method endDocument(parserCtxt :$ctx!, |) is sax-cb {
        callsame;
        $SAXTester_end_document_counter.cb.()
    }

    method startElement(parserCtxt :$ctx!, |) is sax-cb {
        callsame;
        with $ctx.node {
            my LibXML::Node $node .= box($_);
            $SAXTester_start_element_stacker.cb.($node);
        }
    }
    method endElement(parserCtxt :$ctx!, |) is sax-cb {
        callsame;
    }
}

=begin TODO2

package SAXNSTester;
use Test::More;

sub new {
    bless {}, shift;
}

sub start_element {
    my ($self, $node) = @_;

    $SAXNSTester_start_element_stacker.cb().($node);

    return;
}

sub end_element {
    my ($self, $node) = @_;
    # warn("end_element: $node.{Name}\n");
}

sub start_prefix_mapping {
    my ($self, $node) = @_;

    $SAXNSTester_start_prefix_mapping_stacker.cb().($node);

    return;
}

sub end_prefix_mapping {
    my ($self, $node) = @_;

    $SAXNSTester_end_prefix_mapping_stacker.cb().($node);

    return;
}

1;

package SAXNS2Tester;
use Test::More;

#sub new {
#    my $class = shift;
#    return bless {}, $class;
#}

sub start_element {
    my $self = shift;
    my ( $elt ) = @_;

    $SAXNS2Tester_start_element_stacker.cb().($elt);

    return;
}


package SAXLocatorTester;
use Test::More;

sub new {
    my ($class, $cb) = @_;
    my $self = bless {}, $class;

    for my $method ( qw(
        start_document end_document
        start_element end_element
        start_cdata end_cdata
        start_dtd end_dtd
        characters
        comment
    ) ) {
        no strict 'refs';
        *$method = sub { $cb.( $_[0], $method, @_[1..$#_]) };
    }

    return $self;
}

sub set_document_locator {
    my ($self, $locator) = @_;
    $self.{locator} = $locator;
}

1;

package SAXErrorTester;
use Test::More;

sub new {
    bless {}, shift;
}

sub end_document {
    print "End doc: @_\n";
    return 1; # Shouldn't be reached
}

package SAXErrorCallbackTester;
use Test::More;

sub fatal_error {
    $_[0].{fatal_called} = 1;
}

sub start_element {
    # test if we can do other stuff
    LibXML.new.parse_string("<foo/>");
    return;
}
sub new {
    bless {}, shift;
}

sub end_document {
    print "End doc: @_\n";
    return 1; # Shouldn't be reached
}
=end TODO2
