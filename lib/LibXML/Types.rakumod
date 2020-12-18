unit module LibXML::Types;

my token pident {
    <.ident> [ '-' [ \d+ <.ident>? || <.ident> ]* % '-' ]?
}

my token name {
    ^ <pident> [ ':' <pident> ]? $
}

subset NCName of Str is export(:NCName) where !.so || /^<pident>$/;
subset QName of Str is export(:QName) where !.defined || $_ ~~ &name;
subset NameVal of Pair is export(:NameVal) where .key ~~ QName:D && .value ~~ Str:D;
