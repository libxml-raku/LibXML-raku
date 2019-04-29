use v6;
use Test;

# bootstrapping tests for Input callbacks

use LibXML;
use LibXML::InputCallback;

plan 6;

my $fh;
my %seen;

my LibXML::InputCallback $input-callbacks .= new: :callbacks{
        :match(sub ($f) {%seen<match>++; return 1}),
        :open(sub ($f)  {%seen<open>++; $f.IO.open(:r) }),
        :read(sub ($fh, $bytes) {%seen<read>++; $fh.read($bytes)}),
        :close(sub ($fh) {%seen<close>++; $fh.close;}),
    };

my $parser = LibXML.new: :$input-callbacks;
# TEST

$parser.expand-xinclude = True;

my $dom;
lives-ok {$dom = $parser.parse: :file("example/test.xml")}, 'file parse';
ok %seen<match>, 'match callback called';
ok %seen<open>, 'open callback called';
ok %seen<read>, 'read callback called';
ok %seen<close>, 'close callback called';
is $dom.documentElement.firstChild.name, '#text', 'DOM sanity';

done-testing;

