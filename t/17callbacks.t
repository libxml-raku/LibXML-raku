use v6;
use Test;

plan 25;

use LibXML;
use LibXML::InputCallback;

use lib './t/lib';
use Counter;
use Stacker;

sub _create_counter_pair(&worker-cb, &predicate-cb = sub { True })
{

    my $non_global_counter = Counter.new(
        gen-cb => -> &inc-cb {
           sub {
                return &worker-cb(
                    sub {
                        if (&predicate-cb())
                        {
                            &inc-cb()
                        }
                        return;
                    }
                );
            }
        }
    );

    my $global_counter = Counter.new(
        gen-cb => -> &inc-cb {
            sub {
                return &worker-cb(
                    sub {
                        if (&predicate-cb())
                        {
                            &inc-cb()
                        }
                        return;
                    }
                );
            }
        }
    );

    return ($non_global_counter, $global_counter);
}

my ($open1_non_global_counter, $open1_global_counter) =
    _create_counter_pair(
        -> &cond-cb {
            -> $fn {
                ## warn("open: $fn");

                if (my $fh = $fn.IO.open(:r, :bin) )
                {
                    cond-cb();
                    $fh;
                }
                else
                {
                    return 0;
                }
            };
        },
    );

my $open2_counter = Counter.new(
    gen-cb => -> &inc-cb {
        -> Str $fn is copy {
            $fn ~~ s/(<- [0..9]>)(\.xml)$/{$0}4{$1}/; # use a different file
            my ($ret, $verdict);
            if ($verdict = $fn.IO.open(:r, :bin))
            {
                $ret = $verdict;
            }
            else
            {
                $ret = 0;
            }

            inc-cb();

            $ret;
        };
    }
);

my ($match1_non_global_counter, $match1_global_counter) =
    _create_counter_pair(
    -> &cond-cb {
            -> Str $fn {
                cond-cb();
                1;
            };
        },
    );

my ($close1_non_global_counter, $close1_global_counter) =
    _create_counter_pair(
        -> &cond-cb {
            -> $fh {
                # warn("open: $fn\n");

                cond-cb();

                if ($fh)
                {
                    $fh.close();
                }
            };
        },
    );

my ($read1_non_global_counter, $read1_global_counter) =
    _create_counter_pair(
        -> &cond-cb {
            -> $fh, $n {
                ##warn "read!";
                my Blob $buf;

                if ( $fh && $n > 0) {
                    $buf = $fh.read( $n );
                    if $buf
                    {
                        cond-cb();
                    }
                }
                $buf;
            };
        },
    );

{
    # first test checks if local callbacks work
    my LibXML::InputCallback $input-callbacks .= new: :callbacks{
        :match($match1_non_global_counter.cb.() ),
        :read( $read1_non_global_counter.cb.() ),
        :open( $open1_non_global_counter.cb.() ),
        :close( $close1_non_global_counter.cb.() ),
    };

    my $parser = LibXML.new: :$input-callbacks;
    # TEST
    ok($parser, 'Parser was initted.');

    $parser.expand-xinclude = True;

    my $dom = $parser.parse: :file("example/test.xml");

    # TEST
    $read1_non_global_counter.test(2, 'read1 for expand_include called twice.');
    # TEST
    # I think the second close gets called when the parser context is freed
    $close1_non_global_counter.test(1, 'close1 for expand_include called.');
    # TEST
    $match1_non_global_counter.test(2, 'match1 for expand_include called twice.');

    # TEST
    $open1_non_global_counter.test(2, 'expand_include open1 worked.');

    # TEST
    ok($dom, 'DOM was returned.');
    # warn $dom.toString();

    my $root = $dom.getDocumentElement();

    my @nodes = $root.findnodes( 'xml/xsl' );
    # TEST
    ok( +@nodes, 'Found nodes.' );
}

skip "todo port remaing tests", 18;
=begin TODO

{
    # test per parser callbacks. These tests must not fail!

    my $parser = LibXML.new();
    my $parser2 = LibXML.new();

    # TEST
    ok($parser, '$parser was init.');
    # TEST
    ok($parser2, '$parser2 was init.');

    $parser.match_callback( $match1_non_global_counter.cb() );
    $parser.read_callback( $read1_non_global_counter.cb() );
    $parser.open_callback( $open1_non_global_counter.cb() );
    $parser.close_callback( $close1_non_global_counter.cb() );

    $parser.expand_xinclude( 1 );

    $parser2.match_callback( \&match2 );
    $parser2.read_callback( \&read2 );
    $parser2.open_callback( $open2_counter.cb() );
    $parser2.close_callback( \&close2 );

    $parser2.expand_xinclude( 1 );

    my $dom1 = $parser.parse_file( "example/test.xml");
    my $dom2 = $parser2.parse_file("example/test.xml");

    # TEST
    $read1_non_global_counter.test(2, 'read1 for $parser out of ($parser,$parser2)');
    # TEST
    $close1_non_global_counter.test(2, 'close1 for $parser out of ($parser,$parser2)');

    # TEST
    $match1_non_global_counter.test(2, 'match1 for $parser out of ($parser,$parser2)');
    # TEST
    $open1_non_global_counter.test(2, 'expand_include for $parser out of ($parser,$parser2)');
    # TEST
    $open2_counter.test(2, 'expand_include for $parser2 out of ($parser,$parser2)');
    # TEST
    ok($dom1, '$dom1 was returned');
    # TEST
    ok($dom2, '$dom2 was returned');

    my $val1  = ( $dom1.findnodes( "/x/xml/text()") )[0].string_value();
    my $val2  = ( $dom2.findnodes( "/x/xml/text()") )[0].string_value();

    $val1 =~ s/^\s*|\s*$//g;
    $val2 =~ s/^\s*|\s*$//g;

    # TEST

    is( $val1, "test", ' TODO : Add test name' );
    # TEST
    is( $val2, "test 4", ' TODO : Add test name' );
}

chdir("example/complex") || die "chdir: $!";

my $str = slurp('complex.xml');

{
    # tests if callbacks are called correctly within DTDs
    my $parser2 = LibXML.new();
    $parser2.expand_xinclude( 1 );
    my $dom = $parser2.parse_string($str);
    # TEST
    ok($dom, '$dom was init.');
}


$LibXML::match_cb = $match1_global_counter.cb();
$LibXML::open_cb  = $open1_global_counter.cb();
$LibXML::read_cb  = $read1_global_counter.cb();
$LibXML::close_cb = $close1_global_counter.cb();

{
    # tests if global callbacks are working
    my $parser = LibXML.new();
    # TEST
    ok($parser, '$parser was init');

    # TEST
    ok($parser.parse_string($str), 'parse_string returns a true value.');

    # TEST
    $open1_global_counter.test(3, 'open1 for global counter.');

    # TEST
    $match1_global_counter.test(3, 'match1 for global callback.');

    # TEST
    $close1_global_counter.test(3, 'close1 for global callback.');

    # TEST
    $read1_global_counter.test(3, 'read1 for global counter.');
}

sub match2 {
    # warn "match2: $_[0]\n";
    return 1;
}

sub close2 {
    # warn "close2 $_[0]\n";
    if ( $_[0] ) {
        $_[0].close();
    }
    return 1;
}

sub read2 {
    # warn "read2!";
    my $rv = undef;
    my $n = 0;
    if ( $_[0] ) {
        $n = $_[0].read( $rv , $_[1] );
        # warn "read!" if $n > 0;
    }
    return $rv;
}

=end TODO
