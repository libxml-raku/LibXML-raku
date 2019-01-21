class LibXML::PushParser {
    use LibXML::Native;
    use LibXML::ParserContext;
    use LibXML::Document;

    has Bool $.html;
    has @!errors;
    has parserCtxt $!ctx;
    has LibXML::ParserContext $!pc;
    has Int $.err = 0;
    method ctx { $!ctx }

    multi submethod TWEAK(Str :chunk($str), |c) {
        my $chunk = $str.encode;
        self.TWEAK(:$chunk, |c);
    }

    multi submethod TWEAK(Blob :$chunk!, Str :$path, xmlSAXHandler :$sax, |c) {
        my \ctx-class = $!html ?? htmlPushParserCtxt !! xmlPushParserCtxt;
        $!ctx = ctx-class.new: :$chunk, :$path, :$sax;
        $!pc .= new: :$!ctx, |c;
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

    method finish-push(Str :$uri, Bool :$recover = False) {
        self!parse-chunk: :terminate;
	$!pc.flush-errors: :$recover;
	die "XML not well-formed in xmlParseChunk"
            unless $recover || $!ctx.wellFormed;
        my $doc := LibXML::Document.new( :$!ctx, :$uri);
        $!ctx = Nil;
        $doc;
    }
}

