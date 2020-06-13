
class LibXML::SAX::Handler {
    use LibXML::SAX::Builder;

    use LibXML::Raw;
    has xmlSAXHandler $!raw;
    method raw { $!raw }
    method native is DEPRECATED<raw> { $.raw }

    has &.serror-cb is rw;      # structured errors
    has &.warning-cb is rw;     # unstructured warnings
    has &.error-cb is rw;       # unstructured errors
    has &.fatalError-cb is rw;  # unstructured fatal errors

    has $.sax-builder = LibXML::SAX::Builder;

    submethod TWEAK {
        $!raw .= new;
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

}

