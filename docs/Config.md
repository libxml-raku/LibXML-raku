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

These may be parsed to objects that perform the `LibXML::_Configurable` role, including [LibXML](https://libxml-raku.github.io/LibXML-raku), [LibXML::Parser](https://libxml-raku.github.io/LibXML-raku/Parser), [LibXML::_Reader](https://libxml-raku.github.io/LibXML-raku/_Reader).

DOM objects, generally aren't configurable, although some methods that invoke a configurable object allow a `:$config` option.

[LibXML::Document](https://libxml-raku.github.io/LibXML-raku/Document) methods that support the `:$config` option include: `processXIncludes`, `validate`, `Str`, `Blob`, and `parse`.

The `:$config`, option is also applicable to [LibXML::Element](https://libxml-raku.github.io/LibXML-raku/Element) `appendWellBalancedChunk` method and [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node) `ast` and `xpath-class` methods.

Configuration Methods
---------------------

### method version

```raku
method version() returns Version
```

Returns the run-time version of the `libxml2` library.

### method config-version

```raku
method config-version() returns Mu
```

Returns the version of the `libxml2` library that the LibXML module was built against

### method have-reader

```raku
method have-reader() returns Bool
```

Returns True if the `libxml2` library supports XML Reader (LibXML::Reader) functionality.

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

### method tag-expansion

```raku
method tag-expansion() returns Bool
```

Whether to output empty tags as '<a></a>' rather than '<a/>' (default False)

### method max-errors

```raku
method max-errors() is rw returns Int:D
```

Maximum errors before throwing a fatal X::LibXML::TooManyErrors

Parsing Default Options
-----------------------

### method keep-blanks

```raku
method keep-blanks() returns Bool
```

Keep blank nodes (Default True)

### method parser-flags

```raku
method parser-flags() returns UInt
```

Low-level default parser flags (Read-only)

### method external-entity-loader

```raku
method external-entity-loader() returns Callable
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
$parser.input-callbacks($cb);
```

### method input-callbacks

```raku
method input-callbacks is rw returns LibXML::InputCallback
```

Default input callback handlers

Input callbacks are not thread-safe and `parser-locking` should also be set to disable concurrent parsing when using per-parser input-callbacks (see below).

See [LibXML::InputCallback](https://libxml-raku.github.io/LibXML-raku/InputCallback)

### parser-locking

This configuration setting will lock the parsing of documents to disable concurrent parsing. It need to be set to allow per-parser input-callbacks, which are not currently thread safe.

Query Handler
-------------

### method query-handler

```raku
method query-handler() is rw returns LibXML::Config::QueryHandler
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

