use v6.c;

use Test;
use LibXML;

my $x   = LibXML.parse(string => '<a>link desc<bar/>yada yada<bar/></a>');
my $lnk = $x.first('//a',);
my @t   := $x.find('//text()', $lnk);

is @t.elems, 2, 'found two elements';
is @t[0].text, 'link desc', 'found link desc';
is @t[1].text, 'yada yada', 'found yada yada';

done-testing;

