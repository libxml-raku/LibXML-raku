unit module LibXML::Types;

my token pident {
    <.ident> [ '-' [ \d+ <.ident>? || <.ident> ]* % '-' ]?
}

my token qname {
    ^ <pident> [ ':' <pident> ]? $
}

subset NCName of Str is export(:NCName) where !.so || /^<pident>$/;
subset QName of Str is export(:QName) where !.defined || $_ ~~ &qname;
subset NameVal of Pair is export(:NameVal) where .key ~~ QName:D && .value ~~ Str:D;

# XPathish is just a marker role for classes matching XPathRange
role XPathish {}
subset XPathRange is export(:XPathRange) where Bool|Numeric|Str|XPathish;

# Another marker role to know that a class is LibXML::Item descendant
role Itemish { }

{
    my $resolution-cache = {};
    our sub resolve-package(Str:D $pkg) is export(:resolve-package) is raw {
        (my $cache := ⚛$resolution-cache){$pkg}:exists
            ?? $cache{$pkg}
            !! resolve-package-slow-path($pkg)
    }

    sub add-to-cache(Str:D $pkg, Mu \result --> Mu) is raw {
        loop {
            # Another thread has already added this package, do nothing
            return result if (my $old-cache := ⚛$resolution-cache){$pkg}:exists;
            my $new-cache = $old-cache.clone;
            $new-cache{$pkg} := result;
            return result if cas($resolution-cache, $old-cache, $new-cache) === $old-cache;
        }
    }

    my &resolve-package-slow-path = $*RAKU.compiler.version >= v2022.04.74.g.1.c.4680544
        ?? anon sub resolve-package-slow-path(Str:D $pkg) is raw {
            my \found = do require ::($pkg);
            add-to-cache($pkg, found)
        }
        !! do {
            my $resolve-lock = Lock.new;
            anon sub resolve-package-slow-path(Str:D $pkg) is raw {
                my \found = $resolve-lock.protect: { do require ::($pkg) }
                add-to-cache($pkg, found)
            }
        }
}

