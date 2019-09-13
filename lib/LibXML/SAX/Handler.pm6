
class LibXML::SAX::Handler {
    use LibXML::SAX::Builder;

    use LibXML::Native;
    has xmlSAXHandler $!native;
    method native { $!native }

    has &.serror-cb is rw;      # structured errors
    has &.warning-cb is rw;     # unstructured warnings
    has &.error-cb is rw;       # unstructured errors
    has &.fatalError-cb is rw;  # unstructured fatal errors

    has $.sax-builder = LibXML::SAX::Builder;

    submethod TWEAK {
        $!native .= new;
        $!sax-builder.build-sax-handler(self);
    }

    # Error Handling:
    # ---------------
    # Assume we already have a master error handler in place
    # (such as LibXML::ErrorHandler) to delegate these calls to.
    multi method set-sax-callback('serror', &!serror-cb) {}
    multi method set-sax-callback('warning', &!warning-cb) {}
    multi method set-sax-callback('error', &!error-cb) {}
    multi method set-sax-callback('fatalError', &!fatalError-cb) {}

    # SAX Callbacks
    # -------------
    # Remaining calls are all handled directly via a native SAX handler
    multi method set-sax-callback($name, &cb) is default {
        $!native."$name"() = &cb;
    }

}

