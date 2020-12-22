[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [SAX](https://libxml-raku.github.io/LibXML-raku/SAX)
 :: [Handler](https://libxml-raku.github.io/LibXML-raku/SAX/Handler)
 :: [XML](https://libxml-raku.github.io/LibXML-raku/SAX/Handler/XML)

class LibXML::SAX::Handler::XML
-------------------------------

Build pure Raku XML documents using LibXML's SAX parser

Synopsis
--------

    use LibXML;
    use LibXML::SAX::Handler::XML;
    use XML::Document;

    my LibXML::SAX::Handler::XML $sax-handler .= new;
    my XML::Document $doc = LibXML.parse: :file</tmp/ee.xml>, :$sax-handler;

Description
-----------

[LibXML::SAX::Handler::XML](https://libxml-raku.github.io/LibXML-raku/SAX/Handler/XML) is a SAX handler that produce a pure Raku [XML::Document](https://github.com/raku-community-modules/XML) object using the LIBXML SAX interface to parse the document.

This class is an example of implementing a custom parser using the LibXML SAX interface, [LibXML::SAX::Builder](https://libxml-raku.github.io/LibXML-raku/SAX/Builder) and [LibXML::SAX::Handler::SAX2](https://libxml-raku.github.io/LibXML-raku/SAX/Handler/SAX2).

