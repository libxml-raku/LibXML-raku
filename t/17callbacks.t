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
                if (my $fh = $fn.IO.open(:r, :bin) )
                {
                    cond-cb();
                    $fh;
                }
                else
                {
                    return Nil;
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
                $fn.IO.e;
            };
        },
    );

my ($close1_non_global_counter, $close1_global_counter) =
    _create_counter_pair(
        -> &cond-cb {
            -> $fh {
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
    ok($parser, 'Parser was initted.');

    $parser.expand-xinclude = True;

    my $dom = $parser.parse: :file("example/test.xml");

    $read1_non_global_counter.test(2, 'read1 for expand_include called twice.');
    # I think the second close gets called when the parser context is freed
    $close1_non_global_counter.test(2, 'close1 for expand_include called.');
    $match1_non_global_counter.test(2, 'match1 for expand_include called twice.');

    $open1_non_global_counter.test(2, 'expand_include open1 worked.');

    ok($dom, 'DOM was returned.');
    # warn $dom.toString();

    my $root = $dom.getDocumentElement();

    my @nodes = $root.findnodes( 'xml/xsl' );
    ok( +@nodes, 'Found nodes.' );
}

{
    # test per parser callbacks. These tests must not fail!

    my $parser = LibXML.new();
    my $parser2 = LibXML.new();

    ok($parser, '$parser was init.');
    ok($parser2, '$parser2 was init.');

    my LibXML::InputCallback $input-callbacks .= new: :callbacks{
        :match($match1_non_global_counter.cb.() ),
        :read( $read1_non_global_counter.cb.() ),
        :open( $open1_non_global_counter.cb.() ),
        :close( $close1_non_global_counter.cb.() ),
    };

    $parser.input-callbacks = $input-callbacks;
    $parser.expand-xinclude = True;

    my LibXML::InputCallback $input-callbacks2 .= new: :callbacks{
        :match(&match2),
        :read(&read2),
        :open($open2_counter.cb),
        :close(&close ),
    };

    $parser2.input-callbacks = $input-callbacks2;
    $parser2.expand-xinclude = True;

    my $dom1 = $parser.parse: :file( "example/test.xml");
    my $dom2 = $parser2.parse: :file("example/test.xml");

    $read1_non_global_counter.test(2, 'read1 for $parser out of ($parser,$parser2)');
    $close1_non_global_counter.test(2, 'close1 for $parser out of ($parser,$parser2)');

    $match1_non_global_counter.test(2, 'match1 for $parser out of ($parser,$parser2)');
    $open1_non_global_counter.test(2, 'expand_include for $parser out of ($parser,$parser2)');
    $open2_counter.test(2, 'expand_include for $parser2 out of ($parser,$parser2)');
    ok($dom1, '$dom1 was returned');
    ok($dom2, '$dom2 was returned');

    my $val1  = ( $dom1.first( "/x/xml/text()") ).string-value();
    my $val2  = ( $dom2.first( "/x/xml/text()") ).string-value();

    $val1 .= trim;
    $val2 .= trim;


    is( $val1, "test", ' TODO : Add test name' );
    is( $val2, "test 4", ' TODO : Add test name' );
}

chdir("example/complex");

my $str = 'complex.xml'.IO.slurp;

{
    # tests if callbacks are called correctly within DTDs
    my $parser2 = LibXML.new();
    $parser2.expand-xinclude = True;
    my $dom = $parser2.parse: :string($str);
    ok($dom, '$dom was init.');
}

my $input-callbacks = LibXML::InputCallback.new: :callbacks{
        :match($match1_global_counter.cb.() ),
        :read( $read1_global_counter.cb.() ),
        :open( $open1_global_counter.cb.() ),
        :close( $close1_global_counter.cb.() ),
};

{
    # tests if global callbacks are working
    my $parser = LibXML.new: :$input-callbacks;
    $parser.dtd = True;
    ok($parser, '$parser was init');

    ok($parser.parse(:string($str)), 'parse: :string returns a true value.');

    $open1_global_counter.test(3, 'open1 for global counter.');

    $match1_global_counter.test(3, 'match1 for global callback.');

    $close1_global_counter.test(3, 'close1 for global callback.');

    $read1_global_counter.test(3, 'read1 for global counter.');
}

sub match2($) {
    return 1;
}

sub close2($fh) {
    .close with $fh;
}

sub read2($fh, $n) {
    .read($n) with $fh;
}

