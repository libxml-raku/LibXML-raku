class LibXML::SAX::Handler::SAX2::Locator {
    use LibXML::Raw;
    use Method::Also;
    has xmlSAXLocator $.raw .= default();

    method getPublicId(xmlParserCtxt $ctx --> Str) {
        $!raw.getPublicId($ctx);
    }

    method getSystemId(xmlParserCtxt $ctx --> Str) {
        $!raw.getSystemId($ctx);
    }

    method getLineNumber(xmlParserCtxt $ctx --> UInt) is also<line-number> {
        $!raw.getLineNumber($ctx);
    }

    method getColumnNumber(xmlParserCtxt $ctx --> UInt) is also<column-number> {
        $!raw.getColumnNumber($ctx);
    }
}
