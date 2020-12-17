unit module LibXML::Types;

use XML::Grammar;

subset NCName of Str is export(:NCName) where !.defined || ?XML::Grammar.parse($_, :rule<pident>);
subset QName of Str is export(:QName) where !.defined || ?XML::Grammar.parse($_, :rule<name>);
subset NameVal of Pair is export(:NameVal) where .key ~~ QName:D && .value ~~ Str:D;

