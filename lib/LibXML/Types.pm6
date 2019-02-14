unit module LibXML::Types;

use XML::Grammar;

subset NCName of Str is export(:NCName) where {!.defined || $_ ~~ /^<XML::Grammar::pident>$/}
subset QName of Str is export(:QName) where {!.defined || $_ ~~ /^<XML::Grammar::name>$/}
