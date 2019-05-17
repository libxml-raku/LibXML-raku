use v6;
use Test;

plan 56;

use LibXML;
use LibXML::InputCallback;
LibXML.config.skip-xml-declaration = True;

use lib './t/lib';
use Counter;
use Stacker;

use LibXML;

my $read_hash_counter = Counter.new(
    gen-cb => -> &inc-cb {
        -> $h, $n {

            my $id = $h<line>;
            $h<line> += 1;
            my $str = $h<lines>[$id];

            $str //= "";

            &inc-cb();

            $str.encode;

        };
    }
);
my $read_file_counter = Counter.new(
    gen-cb => -> &inc-cb {
        -> $h, $n {
            &inc-cb();

            $h.read( $n );
        }
    }
);

my $close_file_counter = Counter.new(
    gen-cb => -> &inc-cb {
        -> $h {
            &inc-cb();
            $h.close();

            1;
        }
    }
);

my $close_xml_counter = Counter.new(
    gen-cb => -> &inc-cb {
        -> $dom is rw {
            $dom = Nil;
            &inc-cb();

            1;
        }
    }
);

my $open_xml_counter = Counter.new(
    gen-cb => -> &inc-cb {
        -> $uri {
            my $dom = LibXML.new.parse: :string(q{<?xml version="1.0"?><foo><tmp/>barbar</foo>});

            with ($dom)
            {
                &inc-cb();
            }

            $dom;
        }
    }
);

my $close_hash_counter = Counter.new(
    gen-cb => -> &inc-cb {
        -> $h is rw {
            $h = Nil;

            &inc-cb();

            1;
        }
    }
);

my $open_hash_counter = Counter.new(
    gen-cb => -> &inc-cb {
        -> $uri {
            my $hash = { line => 0,
                         lines => [ "<foo>", "bar", "<xsl/>", "..", "</foo>" ],
                       };

            &inc-cb();

            $hash;
        }
    }
);

my $open_file_stacker = Stacker.new(
    gen-cb => -> &push-cb {
        -> $uri {

            with ('.' ~ $uri).IO.open(:r) -> $file
            {
                &push-cb($uri);

                $file;
            }
            else
            {
                die ":-| Could not open file '.$uri'";
            }
        }
    }
);

my $match_hash_stacker = Stacker.new(
    gen-cb => -> &push-cb {
        -> $uri {

            if ( $uri ~~ /^'/libxml/'/ ) {
                &push-cb({ verdict => 1, uri => $uri, });
                1;
            }
            else {
               0;
            }
        };
    }
);

my $match_file_stacker = Stacker.new(
    gen-cb => -> &push-cb {
        -> $uri {

            my $verdict = (( $uri ~~ /^'/example/'/ ) ?? 1 !! 0);
            if ($verdict)
            {
                &push-cb({ verdict => $verdict, uri => $uri, });
            }

            $verdict;
        };
    }
);

my $match_hash2_stacker = Stacker.new(
    gen-cb => -> &push-cb {
        -> $uri {
            if ( $uri ~~ /^'/example/'/ ) {
                &push-cb({ verdict => 1, uri => $uri, });
                1;
            }
            else {
                0;
            }
        };
    }
);

my $match_xml_stacker = Stacker.new(
    gen-cb => -> &push-cb {
        -> $uri {
            if ( $uri ~~ /^'/xmldom/'/ ) {
                &push-cb({ verdict => 1, uri => $uri, });
                1;
            }
            else {
               0;
            }
        };
    }
);

my $read_xml_stacker = Stacker.new(
    gen-cb => -> &push-cb {
        -> $dom, $buflen {
            my $tmp = $dom.documentElement.findnodes('tmp').shift;
            my $rv = $tmp ?? $dom.Blob !! buf8.new;
            .unbindNode with $tmp;

            &push-cb($rv);

            $rv;
        };
    }
);

# --------------------------------------------------------------------- #
# multiple tests
# --------------------------------------------------------------------- #
{
        my $string = q:to<EOF>;
<x xmlns:xinclude="http://www.w3.org/2001/XInclude">
<xml>test
<xinclude:include href="/example/test2.xml"/>
<xinclude:include href="/libxml/test2.xml"/>
<xinclude:include href="/xmldom/test2.xml"/></xml>
</x>
EOF

        my $icb    = LibXML::InputCallback.new;

        $icb.register-callbacks(
            match => $match_file_stacker.cb,
            open  => $open_file_stacker.cb(),
            read  => $read_file_counter.cb(),
            close => $close_file_counter.cb() );

        $icb.register-callbacks(
            match => $match_hash_stacker.cb, open => $open_hash_counter.cb,
            read => $read_hash_counter.cb(), close => $close_hash_counter.cb );

        $icb.register-callbacks( $match_xml_stacker.cb, $open_xml_counter.cb,
                                 $read_xml_stacker.cb, $close_xml_counter.cb );

        ok($icb, 'LibXML::InputCallback was initialized');

        my $parser = LibXML.new();
        $parser.expand-xinclude = True ;
        $parser.input-callbacks = $icb;;
        my $doc = $parser.parse: :$string; # read_hash - 1,1,1,1,1

        # TEST:$c=0;
        my $test_counters = sub {
            # TEST:$c++;
            $read_hash_counter.test(6, "read_hash() count for multiple tests");

            # TEST:$c++;
            $read_file_counter.test(2, 'read_file() called twice.');

            # TEST:$c++;
            $close_file_counter.test(1, 'close_file() called once.');

            # TEST:$c++;
            $open_file_stacker.test(
                [
                    '/example/test2.xml',
                ],
                'open_file() for URLs.',
            );

            # TEST:$c++;
            $match_hash_stacker.test(
                [
                    { verdict => 1, uri => '/libxml/test2.xml',},
                ],
                'match_hash() for URLs.',
            );

            # TEST:$c++;
            $read_xml_stacker.test(
                [
                    buf8.new(qq{<foo><tmp/>barbar</foo>\n}.encode),
                    buf8.new,
                ],
                'read_xml() for multiple callbacks',
            );
            # TEST:$c++;
            $match_xml_stacker.test(
                [
                    { verdict => 1, uri => '/xmldom/test2.xml', },
                ],
                'match_xml() one.',
            );

            # TEST:$c++;
            $match_file_stacker.test(
                [
                    { verdict => 1, uri => '/example/test2.xml',},
                ],
                'match_file() for multiple_tests',
            );

            # TEST:$c++;
            $open_hash_counter.test(1, 'open_hash() : called 1 times');
            # TEST:$c++;
            $open_xml_counter.test(1, 'open_xml() : parse: :string() successful.',);
            # TEST:$c++;
            $close_xml_counter.test(1, "close_xml() called once.");
            # TEST:$c++;
            $close_hash_counter.test(1, "close_hash() called once.");
        };

        # TEST:$test_counters=$c;

        # TEST*$test_counters
        $test_counters.();

        # This is a regression test for:
        # https://rt.cpan.org/Ticket/Display.html?id=51086
        my $doc2 = $parser.parse: :string($string);

        # TEST*$test_counters
        $test_counters.();

        # TEST
        ok($doc, 'parse: :string() returns a doc.');
        # TEST
        is($doc.string-value(),
           "\ntest\n..\nbar..\nbarbar\n",
           '.string-value()',
        );

        # TEST
        ok($doc2, 'second parse: :string() returns a doc.');
        # TEST
        is($doc2.string-value(),
           "\ntest\n..\nbar..\nbarbar\n",
           q{Second parse: :string()'s .string-value()},
        );
}

{
        my $string = q:to<EOF>;
<x xmlns:xinclude="http://www.w3.org/2001/XInclude">
<xml>test
<xinclude:include href="/example/test2.xml"/>
<xinclude:include href="/example/test3.xml"/></xml>
</x>
EOF

        my $icb    = LibXML::InputCallback.new();

        $icb.register-callbacks( $match_file_stacker.cb, $open_file_stacker.cb(),
                                    $read_file_counter.cb(), $close_file_counter.cb(), );

        $icb.register-callbacks( $match_hash2_stacker.cb, $open_hash_counter.cb,
                                    $read_hash_counter.cb(), $close_hash_counter.cb() );


        my $parser = LibXML.new();
        $parser.expand-xinclude = True;
        $parser.input-callbacks = $icb;
        my $doc = $parser.parse: :$string;

        # TEST
        $read_hash_counter.test(12, "read_hash() count for multiple register_callbacks");

        # TEST
        $open_file_stacker.test(
            [
            ],
            'open_file() for URLs.',
        );

        # TEST
        $match_hash2_stacker.test(
            [
                { verdict => 1, uri => '/example/test2.xml',},
                { verdict => 1, uri => '/example/test3.xml',},
            ],
            'match_hash2() input callbacks' ,
        );

        # TEST
        $match_file_stacker.test(
            [
            ],
            'match_file() input callbacks' ,
        );

        # TEST
        is($doc.string-value(), "\ntest\nbar..\nbar..\n",
            'string-value returns fine',);

        # TEST
        $open_hash_counter.test(2, 'open_hash() : called 2 times');
        # TEST
        $close_hash_counter.test(
            2, "close_hash() called twice on two xincludes."
        );

}; skip "port remaining tests", 20;
=begin TODO

        $icb.unregister_callbacks( [ $match_hash2_stacker.cb, \&open_hash,
                                      $read_hash_counter.cb(), $close_hash_counter.cb] );
        $doc = $parser.parse: :$string;

        # TEST
        $read_file_counter.test(4, 'read_file() called 4 times.');

        # TEST
        $close_file_counter.test(2, 'close_file() called twice.');

        # TEST
        $open_file_stacker.test(
            [
                '/example/test2.xml',
                '/example/test3.xml',
            ],
            'open_file() for URLs.',
        );

        # TEST
        $match_hash2_stacker.test(
            [
            ],
            'match_hash2() does not match after being unregistered.' ,
        );

        # TEST
        $match_file_stacker.test(
            [
                { verdict => 1, uri => '/example/test2.xml',},
                { verdict => 1, uri => '/example/test3.xml',},
            ],
            'match_file() input callbacks' ,
        );


        # TEST
        is($doc.string-value(),
           "\ntest\n..\n\n         \n   \n",
           'string-value() after unregister callbacks',
        );
}

{
        my $string = q:to<EOF>;
<x xmlns:xinclude="http://www.w3.org/2001/XInclude">
<xml>test
<xinclude:include href="/example/test2.xml"/>
<xinclude:include href="/xmldom/test2.xml"/></xml>
</x>
EOF
        my $string2 = q:to<EOF>;
<x xmlns:xinclude="http://www.w3.org/2001/XInclude">
<tmp/><xml>foo..<xinclude:include href="/example/test2.xml"/>bar</xml>
</x>
EOF


        my $icb = LibXML::InputCallback.new();
        # TEST
        ok ($icb, 'LibXML::InputCallback was initialized (No. 2)');

        my $open_xml2 = sub {
                my $uri = shift;
                my $parser = LibXML.new;
                $parser.expand_xinclude(1);
                $parser.input_callbacks($icb);

                my $dom = $parser.parse: :string($string2);
                # TEST
                ok ($dom, 'parse: :string() inside open_xml2');

                return $dom;
        };

        $icb.register_callbacks( [ $match_xml_stacker.cb, $open_xml2,
                                    $read_xml_stacker.cb, $close_xml_counter.cb ] );

        $icb.register_callbacks( [ $match_hash2_stacker.cb, $open_hash_counter.cb,
                                    $read_hash_counter.cb(), $close_hash_counter.cb ] );

        my $parser = LibXML.new();
        $parser.expand_xinclude(1);

        $parser.match_callback( $match_file_stacker.cb );
        $parser.open_callback( $open_file_stacker.cb() );
        $parser.read_callback( $read_file_counter.cb() );
        $parser.close_callback( $close_file_counter.cb() );

        $parser.input_callbacks($icb);

        my $doc = $parser.parse: :$string;

        # TEST
        $read_hash_counter.test(6, "read_hash() count for stuff.");

        # TEST
        $read_file_counter.test(2, 'read_file() called twice.');

        # TEST
        $close_file_counter.test(1, 'close_file() called once.');

        # TEST
        $open_file_stacker.test(
            [
                '/example/test2.xml',
            ],
            'open_file() for URLs.',
        );

        # TEST
        $match_hash2_stacker.test(
            [
                { verdict => 1, uri => '/example/test2.xml',},
            ],
            'match_hash2() input callbacks' ,
        );

        # TEST
        $read_xml_stacker.test(
            [
                qq{<?xml version="1.0"?>\n<x xmlns:xinclude="http://www.w3.org/2001/XInclude">\n<tmp/><xml>foo..<foo xml:base="/example/test2.xml">bar<xsl/>..</foo>bar</xml>\n</x>\n},
                '',
            ],
            'read_xml() No. 2',
        );
        # TEST
        $match_xml_stacker.test(
            [
                { verdict => 1, uri => '/xmldom/test2.xml', },
            ],
            'match_xml() No. 2.',
        );

        # TEST
        $match_file_stacker.test(
            [
                { verdict => 1, uri => '/example/test2.xml',},
            ],
            'match_file() for inner callback.',
        );

        # TEST
        $open_hash_counter.test(1, 'open_hash() : called 1 times');

        # TEST
        $close_xml_counter.test(1, "close_xml() called once.");

        # TEST
        $close_hash_counter.test(1, "close_hash() called once.");

        # TEST
        is($doc.string-value(), "\ntest\n..\n\nfoo..bar..bar\n\n",
            'string-value()',);
}

=end TODO
