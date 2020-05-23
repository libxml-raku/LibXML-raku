class LibXML::Comment
---------------------

LibXML Comment nodes

Synopsis
--------

```raku
use LibXML::Comment;
# Only methods specific to Comment nodes are listed here,
# see the LibXML::Node documentation for other methods
my LibXML::Comment $comment .= new( :$content );

$comment.data ~~ s/xxx/yyy/; # Stringy Interface - see LibXML::Text
```

Description
-----------

This class provides all functions of [LibXML::Text](https://libxml-raku.github.io/LibXML-raku/Text), but for comment nodes. This can be done, since only the output of the node types is different, but not the data structure. :-)

Methods
-------

The class inherits from [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node). The documentation for Inherited methods is not listed here.

Many functions listed here are extensively documented in the DOM Level 3 specification ([http://www.w3.org/TR/DOM-Level-3-Core/](http://www.w3.org/TR/DOM-Level-3-Core/)). Please refer to the specification for extensive documentation.

### method new

```raku
method new( Str :$content ) returns LibXML::Comment
```

The constructor is the only provided function for this package. It is required, because *libxml2* treats text nodes and comment nodes slightly differently.

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

