use v6;
use Test;

plan 4;

use LibXML;
use LibXML::Document;
use LibXML::InputCallback;

use lib './t/lib';
use Counter;
use Stacker;

sub _create_counter_pair(&worker-cb, &predicate-cb = sub { True })
{

    my Counter $non_global_counter .= new(
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

    my Counter $global_counter .= new(
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

my Counter $open2_counter .= new(
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

subtest 'single callback', {
    # first test checks if local callbacks work
    my LibXML::InputCallback $input-callbacks .= new: :callbacks{
        :match($match1_non_global_counter.cb.() ),
        :read( $read1_non_global_counter.cb.() ),
        :open( $open1_non_global_counter.cb.() ),
        :close( $close1_non_global_counter.cb.() ),
    };

    my LibXML:D $parser .= new: :$input-callbacks;

    $parser.expand-xinclude = True;

    my LibXML::Document:D $dom = $parser.parse: :file("samples/test.xml");

    $read1_non_global_counter.test(2, 'read1 for expand_include called twice.');
    $close1_non_global_counter.test(2, 'close1 for expand_include called.');
    $match1_non_global_counter.test(2, 'match1 for expand_include called twice.');

    $open1_non_global_counter.test(2, 'expand_include open1 worked.');

    my $root = $dom.getDocumentElement();

    my @nodes = $root.findnodes( 'xml/xsl' );
    ok +@nodes, 'Found nodes.';
}

subtest 'per parser callbacks', {
    # test per parser callbacks. These tests must not fail!

    my LibXML:D $parser .= new();
    my LibXML:D $parser2 .= new();

    my LibXML::InputCallback:D $input-callbacks .= new: :callbacks{
        :match($match1_non_global_counter.cb.() ),
        :read( $read1_non_global_counter.cb.() ),
        :open( $open1_non_global_counter.cb.() ),
        :close( $close1_non_global_counter.cb.() ),
    };

    $parser.input-callbacks = $input-callbacks;
    $parser.expand-xinclude = True;

    my LibXML::InputCallback:D $input-callbacks2 .= new: :callbacks{
        :match(&match2),
        :read(&read2),
        :open($open2_counter.cb),
        :close(&close ),
    };

    $parser2.input-callbacks = $input-callbacks2;
    $parser2.expand-xinclude = True;

    my LibXML::Document:D $dom1 = $parser.parse: :file( "samples/test.xml");
    my LibXML::Document:D $dom2 = $parser2.parse: :file("samples/test.xml");

    $read1_non_global_counter.test(2, 'read1 for $parser out of ($parser,$parser2)');
    $close1_non_global_counter.test(2, 'close1 for $parser out of ($parser,$parser2)');

    $match1_non_global_counter.test(2, 'match1 for $parser out of ($parser,$parser2)');
    $open1_non_global_counter.test(2, 'expand_include for $parser out of ($parser,$parser2)');
    $open2_counter.test(2, 'expand_include for $parser2 out of ($parser,$parser2)');

    my $val1  = ( $dom1.first( "/x/xml/text()") ).string-value();
    my $val2  = ( $dom2.first( "/x/xml/text()") ).string-value();

    $val1 .= trim;
    $val2 .= trim;

    is $val1, "test", 'first parser result';
    is $val2, "test 4", 'second parser result';
}

chdir("samples/complex");

my $str = 'complex.xml'.IO.slurp;

{
    # tests if callbacks are called correctly within DTDs
    my LibXML $parser2 .= new();
    $parser2.expand-xinclude = True;
    lives-ok {
        my LibXML::Document:D $ = $parser2.parse: :string($str);
    }
}

my LibXML::InputCallback $input-callbacks .= new: :callbacks{
        :match($match1_global_counter.cb.() ),
        :read( $read1_global_counter.cb.() ),
        :open( $open1_global_counter.cb.() ),
        :close( $close1_global_counter.cb.() ),
};

subtest 'global callbacks', {
    my LibXML:D $parser .= new: :$input-callbacks;
    $parser.dtd = True;

    ok $parser.parse(:string($str)), 'parse: :string returns a true value.';

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

