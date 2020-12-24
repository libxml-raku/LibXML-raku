[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [SAX](https://libxml-raku.github.io/LibXML-raku/SAX)
 :: [Builder](https://libxml-raku.github.io/LibXML-raku/SAX/Builder)

class LibXML::SAX::Builder
--------------------------

Builds SAX callback sets

Description
-----------

This class provides mappings from native SAX2 callbacks to Raku.

It may be used in conjunction with [LibXML::SAX::Handler::SAX2](https://libxml-raku.github.io/LibXML-raku/SAX/Handler/SAX2) base-class.

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
    my LibXML::Document $doc .= parse: :$string, :$sax-handler;
    say $doc.Str;  # <HTML><BODY><H1>HELLO WORLD</H1></BODY></HTML>'

See [LibXML::SAX::Handler::SAX2](https://libxml-raku.github.io/LibXML-raku/SAX/Handler/SAX2) for a description of callbacks

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

