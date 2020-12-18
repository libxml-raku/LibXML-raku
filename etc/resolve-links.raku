constant DocRoot = "https://libxml-raku.github.io";

multi sub resolve-class(@ ('LibXML', *@path)) {
    %( :repo<LibXML-raku>, :@path )
}

multi sub resolve-class(@ ('LibXSLT', *@p)) {
    my @path;
    with @p[1] {
        when 'Stylesheet'|'Security' {
            @path.push: $_;
        }
    }
    %( :repo<LibXSLT-raku>, :@path)
}

sub link-to-url(Str() $class-name) {
    my %info = resolve-class($class-name.split('::'));
    my @path = DocRoot;
    @path.push: %info<repo>;
    @path.append(.list) with %info<path>;
    @path.join: '/';
}

sub breadcrumb(Str $url is copy, @path, UInt $n = +@path, :$top) {
    my $name = $top ?? @path[0 ..^ $n].join('::') !! @path[$n-1];
    $url ~= '/' ~ @path[0 ..^ $n].join('/');
    my $sep = $top ?? '/' !! '::';
    say " $sep [$name]($url)";
}

INIT {
    with %*ENV<TRAIL> {
        # build a simple breadcrumb trail
        my $url = DocRoot;
        say "[[Raku LibXML Project]]({$url})";
        my %info = resolve-class(.split('/'));
        my $repo = %info<repo>;
        $url ~= '/' ~ $repo;

        my @mod = $repo.split('-');
        @mod.pop if @mod.tail ~~ 'raku';
        my $mod = @mod.join: '-';
        say " / [[$mod Module]]({$url})";

        with %info<path> {
            my @path = .list;
            my $n = @path[0..^+@mod] == @mod ?? +@mod !! 2;
            breadcrumb($url, @path, $n, :top);
            breadcrumb($url, @path, $_)
                for $n ^.. @path;
        }
        say '';
    }
}

s:g:s/ '](' (LibX[ML|SLT]['::'*%%<ident>]) ')'/{'](' ~ link-to-url($0) ~ ')'}/;
