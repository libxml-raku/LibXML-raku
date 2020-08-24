NAME
====

Pod::To::Markdown - Render Pod as Markdown

SYNOPSIS
========

From command line:

    $ perl6 --doc=Markdown lib/To/Class.pm

From Perl6:

```perl6
use Pod::To::Markdown;

=NAME
foobar.pl

=SYNOPSIS
    foobar.pl <options> files ...

print pod2markdown($=pod);
```

EXPORTS
=======

    class Pod::To::Markdown
    sub pod2markdown

DESCRIPTION
===========



### method render

```perl6
method render(
    $pod,
    Bool :$no-fenced-codeblocks
) returns Str
```

Render Pod as Markdown

To render without fenced codeblocks (```` ``` ````), as some markdown engines don't support this, use the :no-fenced-codeblocks option. If you want to have code show up as ```` ```perl6```` to enable syntax highlighting on certain markdown renderers, use:

    =begin code :lang<perl6>

### sub pod2markdown

```perl6
sub pod2markdown(
    $pod,
    Bool :$no-fenced-codeblocks
) returns Str
```

Render Pod as Markdown, see .render()

LICENSE
=======

This is free software; you can redistribute it and/or modify it under the terms of The [Artistic License 2.0](http://www.perlfoundation.org/artistic_license_2_0).
Synopsis
--------

    my LibXML::Dict $dict .= new;
    $dict.see('a');
    $dict.see: <x y z>;
    say $dict.seen('a'); # True
    say $dict.seen('b'); # False
    say $dict<a>:exists; # True
    say $dict<b>:exists; # False
    say $dict.elems; # a x y z

Description
-----------

A LibXML::Dict bins to the xmlDict data structure, which can be used to collate strings.

Please see also [LibXML::HashMap](https://libxml-raku.github.io/LibXML-raku/HashMap), for a more general-purpose associative interface.

