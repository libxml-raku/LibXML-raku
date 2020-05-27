class LibXML::SAX::Builder
--------------------------

Build DOM trees from SAX events.

Description
-----------

This module provides mappings from native SAX callbacks to Raku. It is usually used in conjunction with a [LibXML::SAX::Handler](https://libxml-raku.github.io/LibXML-raku/SAX/Handler) base-class.

Example
-------

The following example builds a modified DOM tree with all tags and attributes converted to uppercase.

    use LibXML::Document;
    use LibXML::SAX::Builder;
    use LibXML::SAX::Handler::SAX2;

    class SAXShouter is LibXML::SAX::Handler::SAX2 {
        use LibXML::SAX::Builder :sax-cb;
        method startElement($name, |c) is sax-cb {
            nextwith($name.uc, |c);
        }
        method endElement($name, |c) is sax-cb {
            nextwith($name.uc, |c);
        }
        method characters($chars, |c) is sax-cb {
            nextwith($chars.uc, |c);
        }
    }

    my SAXShouter $sax-handler .= new();
    my $string = '<html><body><h1>Hello World</h1></body></html>'
    my LibXML::Document $doc .= parse: :$sax-hander;
    say $doc.Str;  # <HTML><BODY><H1>HELLO WORLD</H1></BODY></HTML>'

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

