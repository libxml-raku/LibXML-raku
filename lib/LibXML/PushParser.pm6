class LibXML::PushParser {
    use LibXML::Native;
    use LibXML::Parser::Context;
    use LibXML::Document;

    has Bool $.html;
    has @!errors;
    has LibXML::Parser::Context $!ctx;
    has Int $.err = 0;

    multi submethod TWEAK(Str :chunk($str), |c) {
        my $chunk = $str.encode;
        self.TWEAK(:$chunk, |c);
    }

    multi submethod TWEAK(Blob :$chunk!, Str :$path, :$sax-handler, xmlEncodingStr :$enc, |c) {
        my \ctx-class = $!html ?? htmlPushParserCtxt !! xmlPushParserCtxt;
        my xmlSAXHandler $sax = .native with $sax-handler;
        my xmlParserCtxt:D $native = ctx-class.new: :$chunk, :$path, :$sax, :$enc;
        $!ctx .= new: :$native, |c;
    }

    method !parse-chunk(Blob $chunk = Blob.new, UInt :$size = +$chunk, Bool :$terminate = False) {
        with $!ctx.native {
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
        $!ctx.try: :$recover, {
            self!parse-chunk: :terminate;
        }
	die "XML not well-formed in xmlParseChunk"
            unless $recover || $!ctx.wellFormed;
        my xmlDoc $native = $!ctx.native.myDoc;
        my $rv := LibXML::Document.new( :$native, :$!ctx, :$URI);
        $!ctx = Nil;
        $rv;
    }

}

