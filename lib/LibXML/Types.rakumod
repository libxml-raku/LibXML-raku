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

{
    my $resolution-cache := {};
    our sub resolve-package(Str:D $pkg) is export(:resolve-package) is raw {
        my \found = $resolution-cache{$pkg};
        found !=== Any ?? found !! resolve-package-slow-path($pkg);
    }

    sub add-to-cache(Str:D $pkg, \result --> Nil) {
        my $new-cache = $resolution-cache.clone;
        $new-cache{$pkg} := result;
        $resolution-cache := $new-cache;
    }

    my &resolve-package-slow-path = $*RAKU.compiler.version >= v2022.04.74.g.1.c.4680544
        ??  anon sub resolve-package-slow-path(Str:D $pkg) is raw {
                my \found = do require ::($pkg);
                add-to-cache($pkg, found);
                found
            }
        !!  do {
                my $resolve-lock = Lock.new;
                anon sub resolve-package-slow-path(Str:D $pkg) is raw {
                    my \found = $resolve-lock.protect: { require ::($pkg) }
                    add-to-cache($pkg, found);
                    found
                }
            }
}

