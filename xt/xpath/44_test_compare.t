use v6.c;

use Test;
use LibXML;

plan 6;

my $x = LibXML.parse(string => q:to/ENDXML/);
<root att="root_att">
   <daughter att="3"/>
   <daughter att="4"/>
   <daughter att="5"/>
</root>
ENDXML

# my %results= ( '/root/daughter[@att<"4"]' => 'daughter[3]',
#                '/root/daughter[@att<4]'   => 'daughter[3]',
#                '//daughter[@att<4]'       => 'daughter[3]',
#                '/root/daughter[@att>4]'   => 'daughter[5]',
#                '/root/daughter[@att>5]'   => '',
#                '/root/daughter[@att<3]'   => '',
#              );
is $x.find('/root/daughter[@att<"4"]')[0].attribs<att> , 3;
is $x.find('/root/daughter[@att<4]')[0].attribs<att> , 3;
is $x.find('//daughter[@att<4]')[0].attribs<att> , 3;
is $x.find('/root/daughter[@att>4]')[0].attribs<att> , 5;

is $x.find('/root/daughter[@att>5]'), '';
is $x.find('/root/daughter[@att<3]'), '';

done-testing;
