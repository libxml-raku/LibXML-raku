NAME
====

LibXML::Config - LibXML Global configuration

SYNOPSIS
========

```raku
use LibXML::Config;
```

METHODS
=======

  * version

    Returns the version of the `libxml2` library.

  * have-reader

    Returns True if the `libxml2` library supports XML Reader (LibXML::Reader) functionality.

  * have-schemas

    Returns True if the `libxml2` library supports XML Schema (LibXML::Schema) functionality.

  * external-entity-loader

    Provide a custom external entity handler to be used when parser expand-entities is set to True. Possible value is a subroutine reference. 

    The routine provided is called whenever the parser needs to retrieve the content of an external entity. It is called with two arguments: the system ID (URI) and the public ID. The value returned by the subroutine is parsed as the content of the entity. 

    This method can be used to completely disable entity loading, e.g. to prevent exploits of the type described at ([http://searchsecuritychannel.techtarget.com/generic/0,295582,sid97_gci1304703,00.html ](http://searchsecuritychannel.techtarget.com/generic/0,295582,sid97_gci1304703,00.html )), where a service is tricked to expose its private data by letting it parse a remote file (RSS feed) that contains an entity reference to a local file (e.g. `/etc/fstab `). 

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

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

