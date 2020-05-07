unit module LibXML::Types;

use XML::Grammar;

subset NCName of Str is export(:NCName) where {!$_ || $_ ~~ /^<XML::Grammar::pident>$/}
subset QName of Str is export(:QName) where Str:U|/^<XML::Grammar::name>$/;
subset NameVal of Pair is export(:NameVal) where .key ~~ QName:D && .value ~~ Str:D;

