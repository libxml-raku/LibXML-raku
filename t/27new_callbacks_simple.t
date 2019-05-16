use v6;
use Test;

plan 14;

use LibXML;
use LibXML::InputCallback;

use lib './t/lib';
use Counter;

use LibXML;

# --------------------------------------------------------------------- #
# simple test
# --------------------------------------------------------------------- #
my $string = q:to<EOF>;
<x xmlns:xinclude="http://www.w3.org/2001/XInclude"><xml>test<xinclude:include href="/example/test2.xml"/></xml></x>
EOF

my $match_file_counter = Counter.new(
    gen-cb => -> &inc-cb {

        -> $uri {
            if $uri ~~ /^'/example/'/ {
                &inc-cb();
                1;
            }
            else { 0 };
        }
    }
);

my $open_file_counter = Counter.new(
    gen-cb => -> &inc-cb {

        -> $uri {
            my $file = ('.' ~ $uri).IO.open(:r);
            &inc-cb();
            $file;
        }
    }
);

my $read_file_counter = Counter.new(
    gen-cb => -> &inc-cb {

        -> $fh, $n {
            &inc-cb();
            $fh.read( $n );
        }
    }
);

my $close_file_counter = Counter.new(
    gen-cb => -> &inc-cb {

        -> $fh {
            &inc-cb();
            +$fh.close();
        };
    }
);

my $match_hash_counter = Counter.new(
    gen-cb => -> &inc-cb {

        -> $uri {
            if $uri ~~ /^'/example/'/ {
                &inc-cb();
                1;
            }
            else { 0 };
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

my $close_hash_counter = Counter.new(
    gen-cb => -> &inc-cb {

        -> $fh {
            $fh.keys:delete;
            &inc-cb();

            1;
        }
    }
);

my $read_hash_counter = Counter.new(
    gen-cb => -> &inc-cb {

        -> $fh, $n {

            my $id = $fh<line>;
            $fh<line> += 1;
            my $str = $fh<lines>[$id];

            $str //= "";

            &inc-cb();

            $str.encode;
        }
    }
);

my $icb = LibXML::InputCallback.new: :callbacks{
    match => $match_file_counter.cb(),
    open => $open_file_counter.cb(),
    read => $read_file_counter.cb(),
    close => $close_file_counter.cb() };

    # TEST
ok($icb, ' TODO : Add test name');


my $parser = LibXML.new;
$parser.expand-xinclude = True;
$parser.input-callbacks = $icb;
my $doc = $parser.parse: :$string;

# TEST
$match_file_counter.test(1, 'match_file matched once.');

# TEST
$open_file_counter.test(1, 'open_file called once.');

# TEST
$read_file_counter.test(2, 'read_file called twice.');

# TEST
$close_file_counter.test(1, 'close_file called once.');

# TEST
ok($doc, ' TODO : Add test name');
# TEST

is($doc.string-value(), "test..", ' TODO : Add test name');

my $icb2  = LibXML::InputCallback.new: :callbacks{
    match =>  $match_hash_counter.cb(),
    open  => $open_hash_counter.cb(),
    read  => $read_hash_counter.cb(),
    close => $close_hash_counter.cb()};

# TEST
ok($icb2, ' TODO : Add test name');

$parser.input-callbacks = $icb2;
$doc = $parser.parse: :$string;

# TEST
$match_hash_counter.test(1, 'match_hash matched once.');

# TEST
$open_hash_counter.test(1, 'open_hash called once.');

# TEST
$read_hash_counter.test(6, 'read_hash called six times.');

# TEST
$close_hash_counter.test(1, 'close_hash called once.');

# TEST
ok($doc, ' TODO : Add test name');

# TEST

is($doc.string-value(), "testbar..", ' TODO : Add test name');
