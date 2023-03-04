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

# change global default for maximum errors
LibXML::Config.max-errors = 42;

# create a parser with its own configuration
my LibXML::Config:D $config .= new: :max-errors(100);
my LibXML::Parser:D $parser .= new: :$config;
my LibXML::Document:D $doc = $parser.parse: :html, :file<messy.html>;
```

Description
-----------

This class holds configuration settings. Some of which are read-only. Others are writeable, as listed below.

In the simple case, the global configuration can be updated to suit the application.

Objects of type [LibXML::Config](https://libxml-raku.github.io/LibXML-raku/Config) may be created to enable configuration to localised and more explicit.

Note however that the `input-callbacks` and `external-entity-loader` are global in the `libxml` library and need to be configured globally:

```raku
LibXML::Config.input-callbacks = @input-callbacks;
LibXML::Config.external-entity-loader = &external-entity-loader;
```

...or `parser-locking` needs to be set, which allows multiple local configurations, but disables multi-threaded parsing:

```raku
LibXML::Config.parser-locking = True;
my LibXML::Config $config .= new: :@input-callbacks, :&external-entity-loader;
```

Configuration instance objects may be passed to objects that perform the `LibXML::_Configurable` role, including [LibXML](https://libxml-raku.github.io/LibXML-raku), [LibXML::Parser](https://libxml-raku.github.io/LibXML-raku/Parser), [LibXML::_Reader](https://libxml-raku.github.io/LibXML-raku/_Reader).

```raku
    my $doc = LibXML.parse: :file<doc.xml>, :$config;
```

DOM objects, generally aren't configurable, although some particular methods do support a `:$config` option.

- [LibXML::Document](https://libxml-raku.github.io/LibXML-raku/Document) methods: `processXIncludes`, `validate`, `Str`, `Blob`, and `parse`. - [LibXML::Element](https://libxml-raku.github.io/LibXML-raku/Element) method: `appendWellBalancedChunk`. - [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node) methods: `ast` and `xpath-class`.

Configuration Methods
---------------------

### method version

```raku
method version() returns Version:D
```

Returns the run-time version of the `libxml2` library.

### method config-version

```raku
method config-version() returns Version:D
```

Returns the version of the `libxml2` library that the LibXML module was built against

### method have-reader

```raku
method have-reader() returns Bool
```

Returns True if the `libxml2` library supports XML Reader (LibXML::Reader) functionality.

### method have-writer

```raku
method have-writer() returns Bool
```

Returns True if the `libxml2` library supports XML Writer (LibXML::Writer) functionality.

Note: LibXML::Writer is available as a separate module.

### method have-schemas

```raku
method have-schemas() returns Bool
```

Returns True if the `libxml2` library supports XML Schema (LibXML::Schema) functionality.

### method have-threads

```raku
method have-threads() returns Bool
```

Returns True if the `libxml2` library supports threads

### method have-compression

```raku
method have-compression() returns Bool
```

Returns True if the `libxml2` library supports compression

### method have-iconv

```raku
method have-iconv() returns Bool
```

Returns True if the `libxml2` library supports iconv (unicode encoding)

Serialization Default Options
-----------------------------

### method skip-xml-declaration

```raku
method skip-xml-declaration() is rw returns Bool
```

Whether to omit '<?xml ...>' preamble (default False)

### method skip-dtd

```raku
method skip-dtd() is rw returns Bool
```

Whether to omit internal DTDs (default False)

### has Bool:D(Any) $!tag-expansion

Whether to output empty tags as '<a></a>' rather than '<a/>' (default False)

### method max-errors

```raku
method max-errors() is rw returns Int:D
```

Maximum errors before throwing a fatal X::LibXML::TooManyErrors

Parsing Default Options
-----------------------

### method parser-flags

```raku
method parser-flags() returns UInt:D
```

Low-level default parser flags (Read-only)

### sub set-external-entity-loader

```raku
sub set-external-entity-loader(
    &loader
) returns Mu
```

External entity handler to be used when parser expand-entities is set.

The routine provided is called whenever the parser needs to retrieve the content of an external entity. It is called with two arguments: the system ID (URI) and the public ID. The value returned by the subroutine is parsed as the content of the entity. 

This method can be used to completely disable entity loading, e.g. to prevent exploits of the type described at ([http://searchsecuritychannel.techtarget.com/generic/0,295582,sid97_gci1304703,00.html](http://searchsecuritychannel.techtarget.com/generic/0,295582,sid97_gci1304703,00.html)), where a service is tricked to expose its private data by letting it parse a remote file (RSS feed) that contains an entity reference to a local file (e.g. `/etc/fstab`).

This method acts globally across all parser instances and threads.

A more granular and localised solution to this problem, however, is provided by custom URL resolvers, as in

```raku
my LibXML::InputCallback $cb .= new;
sub match($uri) {   # accept file:/ URIs except for XML catalogs in /etc/xml/
  my ($uri) = @_;
  ? ($uri ~~ m|^'file:/'}
     and $uri !~~ m|^'file:///etc/xml/'|)
}
sub deny(|c) { }
$cb.register-callbacks(&match, &deny, &deny, &deny);
$parser.input-callbacks($cb)
```

### method input-callbacks

```raku
method input-callbacks is rw returns LibXML::InputCallback
```

Default input callback handlers.

The LibXML::Config:U `input-callbacks` method sets and enables a set of input callbacks for the entire process.

The LibXML::Config:U `input-callbacks` sets up a localised set of input callbacks. Concurrent use of multiple input callbacks is NOT thread-safe and `parser-locking` also needs to be set to disable concurrent parsing (see below).

See [LibXML::InputCallback](https://libxml-raku.github.io/LibXML-raku/InputCallback)

### parser-locking

This configuration setting will lock the parsing of documents to disable concurrent parsing. It needs to be set to allow per-parser input-callbacks, which are not currently thread safe.

Note: `parser-locking` defaults to `True` on Windows, as some platforms have thread-safety issues.

Query Handler
-------------

### method query-handler

```raku
method query-handler() is rw returns LibXML::Config::QueryHandler
```

Default query handler to service querySelector() and querySelectorAll() methods

See [LibXML::XPath::Context](https://libxml-raku.github.io/LibXML-raku/XPath/Context)

### has Bool:D $.with-cache

Enable object re-use per XML node.

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

