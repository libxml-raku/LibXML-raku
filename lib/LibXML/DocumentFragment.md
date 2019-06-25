### method keep

```perl6
method keep(
    |c is raw
) returns Mu
```

The native DOM returns the document fragment content as a nodelist; rather than the fragment itself

NAME
====

LibXML::DocumentFragment - LibXML's DOM L2 Document Fragment Implementation

SYNOPSIS
========

    use LibXML::Document;
    use LibXML::DocumentFragment;
    my LibXML::Document $dom .= new;
    my LibXML::DocumentFragment $frag = $dom.createDocumentFragment;
    $frag.appendChild: $dom.createElement('foo');
    $frag.appendChild: $dom.createElement('bar');
    say $frag.Str # '<foo/><bar/>'

DESCRIPTION
===========

This class is a helper class as described in the DOM Level 2 Specification. It is implemented as a node without name. All adding, inserting or replacing functions are aware of document fragments.

As well *all * unbound nodes (all nodes that do not belong to any document sub-tree) are implicit members of document fragments.

AUTHORS
=======

Matt Sergeant, Christian Glahn, Petr Pajas

VERSION
=======

2.0132

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

cut
===



LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

