class LibXML::PushParser {
    use LibXML::Native;
    use LibXML::ErrorHandler;
    use LibXML::Document;

    has Bool $.html;
    has @!errors;
    has parserCtxt $!ctx;
    has LibXML::ErrorHandler $!errors;
    has Int $.err = 0;

    multi submethod TWEAK(Str :chunk($str), |c) {
        my $chunk = $str.encode;
        self.TWEAK(:$chunk, |c);
    }

    multi submethod TWEAK(Blob :$chunk!, Str :$path, :$sax-handler, xmlCharEncoding :$enc, |c) {
        my \ctx-class = $!html ?? htmlPushParserCtxt !! xmlPushParserCtxt;
        my xmlSAXHandler $sax = .unbox with $sax-handler;
        $!ctx = ctx-class.new: :$chunk, :$path, :$sax, :$enc;
        $!ctx.add-reference;
        $!errors .= new: :$!ctx, |c;
    }

    method !parse-chunk(Blob $chunk = Blob.new, UInt :$size = +$chunk, Bool :$terminate = False) {
        with $!ctx {
            .ParseChunk($chunk, $size, +$terminate);
        }
        else {
            die "parser has been finished";
        }
    }

    multi method push(Str $chunk) {
        self!parse-chunk($chunk.encode);
    }

    multi method push(Blob $chunk) is default {
        self!parse-chunk($chunk);
    }

    method finish-push(Str :$URI, Bool :$recover = False) {
        $!errors.try: :$recover, {
            self!parse-chunk: :terminate;
        }
        $!errors = Nil;
	die "XML not well-formed in xmlParseChunk"
            unless $recover || $!ctx.wellFormed;
        LibXML::Document.new( :$!ctx, :$URI);
    }

    submethod DESTROY {
        given $!ctx {
            .Free if .remove-reference;
        }
    }
}

