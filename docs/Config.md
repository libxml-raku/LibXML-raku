[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [Config](https://libxml-raku.github.io/LibXML-raku/Config)

class LibXML::Config
--------------------

LibXML Global configuration

Synopsis
--------

```raku
use LibXML::Config;
if  LibXML::Config.have-compression { ... }
```

Configuration Methods
---------------------

### method version

```perl6
method version() returns Version
```

Returns the run-time version of the `libxml2` library.

### method config-version

```perl6
method config-version() returns Mu
```

Returns the version of the `libxml2` library that the LibXML module was built against

### method have-reader

```perl6
method have-reader() returns Bool
```

Returns True if the `libxml2` library supports XML Reader (LibXML::Reader) functionality.

### method have-schemas

```perl6
method have-schemas() returns Bool
```

Returns True if the `libxml2` library supports XML Schema (LibXML::Schema) functionality.

### method have-threads

```perl6
method have-threads() returns Bool
```

Returns True if the `libxml2` library supports threads

### method have-compression

```perl6
method have-compression() returns Bool
```

Returns True if the `libxml2` library supports compression

Serialization Default Options
-----------------------------

### method skip-xml-declaration

```perl6
method skip-xml-declaration() returns Bool
```

Whether to omit '<?xml ...>' preamble (default Fallse)

### method skip-dtd

```perl6
method skip-dtd() returns Bool
```

Whether to omit internal DTDs (default False)

### method tag-expansion

```perl6
method tag-expansion() returns Mu
```

Whether to output empty tags as '<a></a>' rather than '<a/>' (default False)

Parsing Default Options
-----------------------

### method keep-blanks

```perl6
method keep-blanks() returns Bool
```

Keep blank nodes (Default True)

### method parser-flags

```perl6
method parser-flags() returns UInt
```

Low-level default parser flags (Read-only)

### method external-entity-loader

```perl6
method external-entity-loader() returns Callable
```

External entity handler to be used when parser expand-entities is set.

The routine provided is called whenever the parser needs to retrieve the content of an external entity. It is called with two arguments: the system ID (URI) and the public ID. The value returned by the subroutine is parsed as the content of the entity. 

This method can be used to completely disable entity loading, e.g. to prevent exploits of the type described at ([http://searchsecuritychannel.techtarget.com/generic/0,295582,sid97_gci1304703,00.html](http://searchsecuritychannel.techtarget.com/generic/0,295582,sid97_gci1304703,00.html)), where a service is tricked to expose its private data by letting it parse a remote file (RSS feed) that contains an entity reference to a local file (e.g. `/etc/fstab`). 

A more granular solution to this problem, however, is provided by custom URL resolvers, as in 

```raku
my LibXML::InputCallback $cb .= new;
sub match($uri) {   # accept file:/ URIs except for XML catalogs in /etc/xml/
  my ($uri) = @_;
  ? ($uri ~~ m|^'file:/'}
     and $uri !~~ m|^'file:///etc/xml/'|)
}
sub deny(|c) { }
$cb.register-callbacks(&match, &deny, &deny, &deny);
$parser.input-callbacks($cb);
```

### method input-callbacks

```perl6
method input-callbacks() returns Mu
```

Default input callback handlers

See [LibXML::InputCallback](https://libxml-raku.github.io/LibXML-raku/InputCallback)

Query Handler
-------------

### method query-handler

```perl6
method query-handler() returns LibXML::Config::QueryHandler
```

Default query handler to service querySelector() and querySelectorAll() methods

See [LibXML::XPath::Context](https://libxml-raku.github.io/LibXML-raku/XPath/Context)

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

