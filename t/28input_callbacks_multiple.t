use v6;
use Test;

plan 56;

use LibXML;
use LibXML::InputCallback;
use LibXML::Config;

LibXML::Config.parser-locking = True;
LibXML.config.skip-xml-declaration = True;

use lib './t/lib';
use Counter;
use Stacker;

use LibXML;

my Counter $read_hash_counter .= new(
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
my Counter $read_file_counter .= new(
    gen-cb => -> &inc-cb {
        -> $h, $n {
            &inc-cb();

            $h.read( $n );
        }
    }
);

my Counter $close_file_counter .= new(
    gen-cb => -> &inc-cb {
        -> $h {
            &inc-cb();
            $h.close();

            1;
        }
    }
);

my Counter $close_xml_counter .= new(
    gen-cb => -> &inc-cb {
        -> $dom is rw {
            $dom = Nil;
            &inc-cb();

            1;
        }
    }
);

my Counter $open_xml_counter .= new(
    gen-cb => -> &inc-cb {
        -> $uri {
            my $dom = LibXML.parse: :string(q{<?xml version="1.0"?><foo><tmp/>barbar</foo>});

            with ($dom)
            {
                &inc-cb();
            }

            $dom;
        }
    }
);

my Counter $close_hash_counter .= new(
    gen-cb => -> &inc-cb {
        -> $h is rw {
            $h = Nil;

            &inc-cb();

            1;
        }
    }
);

my Counter $open_hash_counter .= new(
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

my Stacker $open_file_stacker .= new(
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

my Stacker $match_hash_stacker .= new(
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

my Stacker $match_file_stacker .= new(
    gen-cb => -> &push-cb {
        -> $uri {

            my $verdict = (( $uri ~~ /^'/samples/'/ ) ?? 1 !! 0);
            if ($verdict)
            {
                &push-cb({ verdict => $verdict, uri => $uri, });
            }

            $verdict;
        };
    }
);

my Stacker $match_hash2_stacker .= new(
    gen-cb => -> &push-cb {
        -> $uri {
            if ( $uri ~~ /^'/samples/'/ ) {
                &push-cb({ verdict => 1, uri => $uri, });
                1;
            }
            else {
                0;
            }
        };
    }
);

my Stacker $match_xml_stacker .= new(
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

my Stacker $read_xml_stacker .= new(
    gen-cb => -> &push-cb {
        -> $dom, $buflen {
            my $tmp = $dom.documentElement.first('tmp');
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
    <xinclude:include href="/samples/test2.xml"/>
    <xinclude:include href="/libxml/test2.xml"/>
    <xinclude:include href="/xmldom/test2.xml"/></xml>
    </x>
    EOF

    my LibXML::InputCallback $icb .= new;

    $icb.register-callbacks(
        match => $match_file_stacker.cb,
        open  => $open_file_stacker.cb,
        read  => $read_file_counter.cb,
        close => $close_file_counter.cb );

    $icb.register-callbacks(
        match => $match_hash_stacker.cb, open => $open_hash_counter.cb,
        read => $read_hash_counter.cb, close => $close_hash_counter.cb );

    $icb.register-callbacks( $match_xml_stacker.cb, $open_xml_counter.cb,
                             $read_xml_stacker.cb, $close_xml_counter.cb );

    ok($icb, 'LibXML::InputCallback was initialized');

    my LibXML $parser .= new();
    $parser.expand-xinclude = True ;
    $parser.input-callbacks = $icb;;
    my $doc = $parser.parse: :$string; # read_hash - 1,1,1,1,1

    my $test_counters = sub {
        $read_hash_counter.test(6, "read_hash() count for multiple tests");

        $read_file_counter.test(2, 'read_file() called twice.');

        $close_file_counter.test(1, 'close_file() called once.');

        $open_file_stacker.test(
            [
                '/samples/test2.xml',
            ],
            'open_file() for URLs.',
        );

        $match_hash_stacker.test(
            [
                { verdict => 1, uri => '/libxml/test2.xml',},
            ],
            'match_hash() for URLs.',
        );

        $read_xml_stacker.test(
            [
                buf8.new(qq{<foo><tmp/>barbar</foo>\n}.encode),
                buf8.new,
            ],
            'read_xml() for multiple callbacks',
        );

        $match_xml_stacker.test(
            [
                { verdict => 1, uri => '/xmldom/test2.xml', },
            ],
            'match_xml() one.',
        );

        $match_file_stacker.test(
            [
                { verdict => 1, uri => '/samples/test2.xml',},
            ],
                'match_file() for multiple_tests',
        );

        $open_hash_counter.test(1, 'open_hash() : called 1 times');
        $open_xml_counter.test(1, 'open_xml() : parse: :string() successful.',);
        $close_xml_counter.test(1, "close_xml() called once.");
        $close_hash_counter.test(1, "close_hash() called once.");
    };


    $test_counters.();

    # This is a Perl regression test for:
    # https://rt.cpan.org/Ticket/Display.html?id=51086
    my $doc2 = $parser.parse: :$string;

    $test_counters.();

    ok($doc, 'parse: :string() returns a doc.');
    is($doc.string-value(),
       "\ntest\n..\nbar..\nbarbar\n",
       '.string-value()',
      );

    ok($doc2, 'second parse: :string() returns a doc.');
    is($doc2.string-value(),
       "\ntest\n..\nbar..\nbarbar\n",
       q{Second parse: :string()'s .string-value()},
    );
}

{
    my $string = q:to<EOF>;
    <x xmlns:xinclude="http://www.w3.org/2001/XInclude">
    <xml>test
    <xinclude:include href="/samples/test2.xml"/>
    <xinclude:include href="/samples/test3.xml"/></xml>
    </x>
    EOF

    my LibXML::InputCallback $icb .= new();

    $icb.register-callbacks( $match_file_stacker.cb, $open_file_stacker.cb(),
                                $read_file_counter.cb(), $close_file_counter.cb() );

    my &hash2-stacker := $match_hash2_stacker.cb;
    $icb.register-callbacks( &hash2-stacker, $open_hash_counter.cb,
                                $read_hash_counter.cb(), $close_hash_counter.cb() );


    my LibXML $parser .= new();
    $parser.expand-xinclude = True;
    $parser.input-callbacks = $icb;
    my $doc = $parser.parse: :$string;

    $read_hash_counter.test(12, "read_hash() count for multiple register_callbacks");

    $open_file_stacker.test(
        [
        ],
        'open_file() for URLs.',
    );

    $match_hash2_stacker.test(
        [
            { verdict => 1, uri => '/samples/test2.xml',},
            { verdict => 1, uri => '/samples/test3.xml',},
        ],
        'match_hash2() input callbacks' ,
    );

    $match_file_stacker.test(
        [
        ],
        'match_file() input callbacks' ,
    );

    is($doc.string-value(), "\ntest\nbar..\nbar..\n",
        'string-value returns fine',);

    $open_hash_counter.test(2, 'open_hash() : called 2 times');
    $close_hash_counter.test(
        2, "close_hash() called twice on two xincludes."
    );

    $icb.unregister-callbacks( match => &hash2-stacker );
    $doc = $parser.parse: :$string;

    $read_file_counter.test(4, 'read_file() called 4 times.');


    $close_file_counter.test(2, 'close_file() called twice.');

    $open_file_stacker.test(
        [
            '/samples/test2.xml',
            '/samples/test3.xml',
        ],
        'open_file() for URLs.',
    );

    $match_hash2_stacker.test(
        [
        ],
        'match_hash2() does not match after being unregistered.' ,
    );

    $match_file_stacker.test(
        [
            { verdict => 1, uri => '/samples/test2.xml',},
            { verdict => 1, uri => '/samples/test3.xml',},
        ],
        'match_file() input callbacks' ,
    );


    is($doc.string-value(),
       "\ntest\n..\n\n         \n   \n",
       'string-value() after unregister callbacks',
    );
}

{
    my $string = q:to<EOF>;
    <x xmlns:xinclude="http://www.w3.org/2001/XInclude">
    <xml>test
    <xinclude:include href="/samples/test2.xml"/>
    <xinclude:include href="/xmldom/test2.xml"/></xml>
    </x>
    EOF
    my $string2 = q:to<EOF>;
    <x xmlns:xinclude="http://www.w3.org/2001/XInclude">
    <tmp/><xml>foo..<xinclude:include href="/samples/test2.xml"/>bar</xml>
    </x>
    EOF

    my LibXML::InputCallback $icb .= new();
    ok ($icb, 'LibXML::InputCallback was initialized (No. 2)');

    my $open_xml2 = -> $uri {
            my LibXML $parser .= new;
            $parser.expand-xinclude = True;
            $parser.input-callbacks = $icb;

            my $dom = $parser.parse: :string($string2);
            ok ($dom, 'parse: :string() inside open_xml2');

            $dom;
    };

    $icb.register-callbacks( $match_xml_stacker.cb, $open_xml2,
                                $read_xml_stacker.cb, $close_xml_counter.cb );

    $icb.register-callbacks( $match_hash2_stacker.cb, $open_hash_counter.cb,
                                $read_hash_counter.cb(), $close_hash_counter.cb );

    my LibXML $parser .= new();
    $parser.expand-xinclude = True;

    $parser.input-callbacks = LibXML::InputCallback.new: :callbacks{
        match => $match_file_stacker.cb,
        open => $open_file_stacker.cb,
        read => $read_file_counter.cb,
        close => $close_file_counter.cb, 
   };

    $parser.input-callbacks.prepend($icb);

    my $doc = $parser.parse: :$string;

    $read_hash_counter.test(6, "read_hash() count for stuff.");

    $read_file_counter.test(2, 'read_file() called twice.');

    $close_file_counter.test(1, 'close_file() called once.');

    $open_file_stacker.test(
        [
            '/samples/test2.xml',
        ],
        'open_file() for URLs.',
    );

    $match_hash2_stacker.test(
        [
            { verdict => 1, uri => '/samples/test2.xml',},
        ],
        'match_hash2() input callbacks' ,
    );

    $read_xml_stacker.test(
        [
            buf8.new(qq{<x xmlns:xinclude="http://www.w3.org/2001/XInclude">\n<tmp/><xml>foo..<foo xml:base="/samples/test2.xml">bar<xsl/>..</foo>bar</xml>\n</x>\n}.encode),
            buf8.new,
        ],
        'read_xml() No. 2',
    );
    $match_xml_stacker.test(
        [
            { verdict => 1, uri => '/xmldom/test2.xml', },
        ],
        'match_xml() No. 2.',
    );

    $match_file_stacker.test(
        [
            { verdict => 1, uri => '/samples/test2.xml',},
        ],
        'match_file() for inner callback.',
    );

    $open_hash_counter.test(1, 'open_hash() : called 1 times');

    $close_xml_counter.test(1, "close_xml() called once.");

    $close_hash_counter.test(1, "close_hash() called once.");

    is($doc.string-value(), "\ntest\n..\n\nfoo..bar..bar\n\n",
        'string-value()',);
}
