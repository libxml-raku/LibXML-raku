class LibXML::SAX::Handler::SAX2::Locator {
    use LibXML::Raw;
    use Method::Also;
    has xmlSAXLocator $.native .= default();

    method getPublicId(xmlParserCtxt $ctx --> Str) {
        $!native.getPublicId($ctx);
    }

    method getSystemId(xmlParserCtxt $ctx --> Str) {
        $!native.getSystemId($ctx);
    }

    method getLineNumber(xmlParserCtxt $ctx --> UInt) is also<line-number> {
        $!native.getLineNumber($ctx);
    }

    method getColumnNumber(xmlParserCtxt $ctx --> UInt) is also<column-number> {
        $!native.getColumnNumber($ctx);
    }
}
