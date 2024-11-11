use v6;
use Test;

plan 11;

use LibXML;
use LibXML::Document;
use LibXML::InputCallback;
use LibXML::Config;

LibXML::Config.parser-locking = True;

use lib 't';
use Counter;

use LibXML;

my $string = q:to<EOF>;
<x xmlns:xinclude="http://www.w3.org/2001/XInclude"><xml>test<xinclude:include href="/samples/test2.xml"/></xml></x>
EOF

my Counter $match_file_counter .= new(
    gen-cb => -> &inc-cb {

        -> $uri {
            if $uri ~~ /^'/samples/'/ {
                &inc-cb();
                1;
            }
            else { 0 };
        }
    }
);

my Counter $open_file_counter .= new(
    gen-cb => -> &inc-cb {

        -> $uri {
            my $file = ('.' ~ $uri).IO.open(:r);
            &inc-cb();
            $file;
        }
    }
);

my Counter $read_file_counter .= new(
    gen-cb => -> &inc-cb {

        -> $fh, $n {
            &inc-cb();
            $fh.read( $n );
        }
    }
);

my Counter $close_file_counter .= new(
    gen-cb => -> &inc-cb {

        -> $fh {
            &inc-cb();
            +$fh.close();
        };
    }
);

my Counter $match_hash_counter .= new(
    gen-cb => -> &inc-cb {

        -> $uri {
            if $uri ~~ /^'/samples/'/ {
                &inc-cb();
                1;
            }
            else { 0 };
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

my Counter $close_hash_counter .= new(
    gen-cb => -> &inc-cb {

        -> $h is rw {
            $h = Nil;
            &inc-cb();

            1;
        }
    }
);

my Counter $read_hash_counter .= new(
    gen-cb => -> &inc-cb {

        -> $h, $n {

            my $id = $h<line>;
            $h<line> += 1;
            my $str = $h<lines>[$id];

            $str //= "";

            &inc-cb();

            $str.encode;
        }
    }
);

my LibXML::InputCallback:D $icb .= new: :callbacks{
    match => $match_file_counter.cb(),
    open => $open_file_counter.cb(),
    read => $read_file_counter.cb(),
    close => $close_file_counter.cb() };


my LibXML:D $parser .= new;
$parser.expand-xinclude = True;
$parser.input-callbacks = $icb;
my LibXML::Document:D $doc = $parser.parse: :$string;

$match_file_counter.test(1, 'match_file matched once.');

$open_file_counter.test(1, 'open_file called once.');

$read_file_counter.test(2, 'read_file called twice.');

$close_file_counter.test(1, 'close_file called once.');

is $doc.string-value(), "test..", 'string-value';

my LibXML::InputCallback:D $icb2  .= new: :callbacks{
    match =>  $match_hash_counter.cb(),
    open  => $open_hash_counter.cb(),
    read  => $read_hash_counter.cb(),
    close => $close_hash_counter.cb()};

$parser.input-callbacks = $icb2;
$doc = $parser.parse: :$string;

$match_hash_counter.test(1, 'match_hash matched once.');

$open_hash_counter.test(1, 'open_hash called once.');

$read_hash_counter.test(6, 'read_hash called six times.');

$close_hash_counter.test(1, 'close_hash called once.');

ok $doc.defined, 'doc defined';

is $doc.string-value(), "testbar..", 'string-value';
