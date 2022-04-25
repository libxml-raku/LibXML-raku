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

# XPathish is just a marker role for classes matching XPathRange
role XPathish {}
subset XPathRange is export(:XPathRange) where Bool|Numeric|Str|XPathish;

my $resolve-lock = Lock.new;
sub resolve-package(Str:D $pkg) is export(:resolve-package) is raw {
    $resolve-lock.protect: { ::{$pkg}:exists ?? ::($pkg) !! do require ::($pkg) }
}
