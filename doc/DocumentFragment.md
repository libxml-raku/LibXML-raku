NAME
====

LibXML::DocumentFragment - LibXML's DOM L2 Document Fragment Implementation

SYNOPSIS
========

    use LibXML::Document;
    use LibXML::DocumentFragment;
    my LibXML::Document $doc .= new;
    my LibXML::DocumentFragment $frag .= parse: :balanced, :string('<foo/><bar/>');
    say $frag.Str # '<foo/><bar/>'
    my LibXML::DocumentFragment $frag2 = $doc.createDocumentFragment;
    $frag2.appendChild: $doc.createElement('foo');
    $frag2.appendChild: $doc.createElement('bar');
    say $frag2.Str # '<foo/><bar/>'

DESCRIPTION
===========

This class is a helper class as described in the DOM Level 2 Specification. It is implemented as a node without name. All adding, inserting or replacing functions are aware of document fragments.

As well *all * unbound nodes (all nodes that do not belong to any document sub-tree) are implicit members of document fragments.

AUTHORS
=======

Matt Sergeant, Christian Glahn, Petr Pajas, Shlomi Fish, Tobias Leich, Xliff, David Warring

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

