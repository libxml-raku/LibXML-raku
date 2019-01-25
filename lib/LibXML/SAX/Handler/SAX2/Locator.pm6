class LibXML::SAX::Handler::SAX2::Locator {
    use LibXML::Native;

    method getPublicId(:$ctx!) returns Str {
        $ctx.xmlSAX2GetPublicId;
    }

    method getSystemId(:$ctx!) returns Str {
        $ctx.xmlSAX2GetSystemId;

    }

    method getLineNumber(:$ctx!) returns UInt {
        $ctx.xmlSAX2GetLineNumber;
    }

    method getColumnNumber(:$ctx!) returns UInt {
        $ctx.xmlSAX2GetColumnNumber;
    }
}
