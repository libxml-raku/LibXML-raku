constant DocRoot = "https://libxml-raku.github.io";

sub resolve-class(Str() $class) {
    my @path = $class.split('::');
    @path[0] ~= '-raku';
    @path.unshift: DocRoot;
    @path.join: '/';
}

s:g:s/ '](' (LibX[ML|SLT]['::'*%%<ident>]) ')'/{'](' ~ resolve-class($0) ~ ')'}/;
