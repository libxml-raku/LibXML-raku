
class LibXML::SAX::Handler {
    use LibXML::SAX::Builder;
    use LibXML::Document;
    use LibXML::DocumentFragment;

    use LibXML::Raw;
    has xmlSAXHandler $.raw .= new;
    method native is DEPRECATED<raw> { $.raw }

    has &.serror-cb is rw;      # structured errors
    has &.warning-cb is rw;     # unstructured warnings
    has &.error-cb is rw;       # unstructured errors
    has &.fatalError-cb is rw;  # unstructured fatal errors

    has LibXML::SAX::Builder $.sax-builder;

    submethod TWEAK {
        $!sax-builder.build-sax-handler(self);
    }

    # Error Handling:
    # ---------------
    # The following are not directly dispatched via SAX. Rather they are
    # called from a LibXML::ErrorHandling installed SAX callback.
    multi method set-sax-callback('serror', &!serror-cb) {}
    multi method set-sax-callback('warning', &!warning-cb) {}
    multi method set-sax-callback('error', &!error-cb) {}
    multi method set-sax-callback('fatalError', &!fatalError-cb) {}

    # SAX Callbacks
    # -------------
    # Remaining calls are all handled directly via a native SAX handler
    multi method set-sax-callback($name, &cb) is default {
        $!raw."$name"() = &cb;
    }

    multi method publish(LibXML::Document $doc!) {
        $doc;
    }
    multi method publish(LibXML::DocumentFragment $doc!) {
        $doc;
    }

}

