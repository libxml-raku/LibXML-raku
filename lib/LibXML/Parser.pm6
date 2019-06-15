class LibXML::Parser {

    use LibXML::Config;
    use LibXML::Native;
    use LibXML::Enums;
    use LibXML::Document;
    use LibXML::PushParser;
    use LibXML::ParserContext;
    use Method::Also;

    constant config = LibXML::Config;

    has Bool $.html;
    has Bool $.line-numbers is rw = False;
    has UInt $.flags is rw = XML_PARSE_NODICT +| XML_PARSE_DTDLOAD;
    has Str $.baseURI is rw;
    has $.sax-handler is rw;
    has $.input-callbacks is rw = config.input-callbacks;

    use LibXML::_Options;
    also does LibXML::_Options[
        %(
            :recover(XML_PARSE_RECOVER),
            :expand-entities(XML_PARSE_NOENT),
            :load-ext-dtd(XML_PARSE_DTDLOAD),
            :complete-attributes(XML_PARSE_DTDATTR),
            :validation(XML_PARSE_DTDVALID),
            :suppress-errors(XML_PARSE_NOERROR),
            :suppress-warnings(XML_PARSE_NOWARNING),
            :pedantic-parser(XML_PARSE_PEDANTIC),
            :no-blanks(XML_PARSE_NOBLANKS),
            :expand-xinclude(XML_PARSE_XINCLUDE),
            :xinclude(XML_PARSE_XINCLUDE),
            :no-network(XML_PARSE_NONET),
            :clean-namespaces(XML_PARSE_NSCLEAN),
            :no-cdata(XML_PARSE_NOCDATA),
            :no-xinclude-nodes(XML_PARSE_NOXINCNODE),
            :old10(XML_PARSE_OLD10),
            :no-base-fix(XML_PARSE_NOBASEFIX),
            :huge(XML_PARSE_HUGE),
            :oldsax(XML_PARSE_OLDSAX),
            :no-def-dtd(HTML_PARSE_NODEFDTD),
        )];

    method get-option(Str:D $key) { $.get-flag($!flags, $key); }
    multi method set-option(Str:D $key, Bool() $_) { $.set-flag($!flags, $key, $_); }
    multi method set-option(*%opt) {
        my $rv := $.set-option(.key, .value) for %opt.sort;
        $rv;
    }

    method options(:$html, *%opts) {
        my UInt $flags = $!flags;
        $.set-flag($flags, 'load-ext-dtd', False)
            if $html;
        $.set-flags($flags, %opts);

        unless $html || $flags +& XML_PARSE_DTDLOAD {

            for (XML_PARSE_DTDVALID, XML_PARSE_DTDATTR, XML_PARSE_NOENT ) {
                $flags -= $_ if $flags +& $_
            }
        }

        $flags;
    }

    method keep-blanks(|c) is rw { $.blanks(|c) }

    method !make-handler(parserCtxt :$native, *%flags) {
        my UInt $flags = self.options(|%flags);
        LibXML::ParserContext.new: :$native, :$flags, :$!line-numbers, :$!input-callbacks, :$.sax-handler;
    }

    method !publish(:$URI, LibXML::ParserContext :$handler!, xmlDoc :$native = $handler.native.myDoc) {
        my LibXML::Document:D $doc .= new: :ctx($handler), :$native;
        $doc.baseURI = $_ with $URI;
        self.processXIncludes($doc, :$handler)
            if $.expand-xinclude;
        $doc;
    }

    method processXIncludes(
        LibXML::Document $_,
        LibXML::ParserContext:D :$handler = self!make-handler(:native(xmlParserCtxt.new)),
        *%opts --> Int) is also<process-xinclude> {
        my xmlDoc $doc = .native;
        my $flags = self.options(|%opts);
        $handler.try: { $doc.XIncludeProcessFlags($flags) }
    }

    method load(|c) { self.new.parse(|c) }

    multi method parse(Str:D() :$string!,
                       Bool() :$html = $!html,
                       Str() :$URI = $!baseURI,
                       xmlEncodingStr :$enc = 'UTF-8',
                       *%flags,
                      ) {

        # gives better diagnositics

        my LibXML::ParserContext $handler = self!make-handler: :$html, |%flags;

        $handler.try: {
            my parserCtxt:D $ctx = $html
            ?? htmlMemoryParserCtxt.new: :$string, :$enc
            !! xmlMemoryParserCtxt.new: :$string;

            $ctx.input.filename = $_ with $URI;
            $handler.native = $ctx;
            $ctx.ParseDocument;
        };
        self!publish: :$handler;
    }

    multi method parse(Blob:D :$buf!,
                       Bool() :$html = $!html,
                       Str() :$URI = $!baseURI,
                       xmlEncodingStr :$enc = 'UTF-8',
                       *%flags,
                      ) {

        my parserCtxt:D $ctx = $html
           ?? htmlMemoryParserCtxt.new(:$buf, :$enc)
           !! xmlMemoryParserCtxt.new(:$buf, :$enc);

        $ctx.input.filename = $_ with $URI;

        my LibXML::ParserContext $handler = self!make-handler: :native($ctx), :$html, |%flags;
        $handler.try: { $ctx.ParseDocument };
        self!publish: :$handler;
    }

    multi method parse(IO() :$file!,
                       Bool() :$html = $!html,
                       xmlEncodingStr :$enc,
                       Str :$URI = $!baseURI,
                       *%flags,
                      ) {
        my LibXML::ParserContext $handler = self!make-handler: :$html, |%flags;

        $handler.try: {
            my parserCtxt $ctx = $html
               ?? htmlFileParserCtxt.new(:$file, :$enc)
               !! xmlFileParserCtxt.new(:$file);
            die "unable to load file: $file"
                without $ctx;
            $handler.native = $ctx;
            $ctx.ParseDocument;
        };

        self!publish: :$URI, :$handler;
    }

    multi method parse(Int :$fd!,
                       Str :$URI = $!baseURI,
                       Bool() :$html = $!html,
                       xmlEncodingStr :$enc,
                       *%flags,
                      ) {

        my LibXML::ParserContext $handler = self!make-handler: :$html, |%flags;
        my UInt $flags = self.options(|%flags, :$html);
        my xmlDoc $native;

        $handler.try: {
            my parserCtxt $ctx = $html
               ?? htmlParserCtxt.new
               !! xmlParserCtxt.new;
            $handler.native = $ctx;
            $native = $ctx.ReadFd($fd, $URI, $enc, $flags);
        };

        self!publish: :$handler, :$native;
    }

    multi method parse(IO::Handle :$io!,
                       Str :$URI = $io.path.path,
                       |c) {
        my UInt:D $fd = $io.native-descriptor;
        self.parse( :$fd, :$URI, |c);
    }

    multi method parse(IO() :io($path)!, |c) {
        my IO::Handle $io = $path.open(:bin, :r);
        $.parse(:$io, |c);
    }

    has LibXML::PushParser $!push-parser;
    method init-push { $!push-parser = Nil }
    method push($chunk) {
        with $!push-parser {
            .push($chunk)
        }
        else {
            $_ .= new: :$chunk, :$!html, :$!flags, :$!line-numbers, :$.sax-handler;
        }
    }
    method parse-chunk($chunk?, :$terminate) {
        $.push($_) with $chunk;
        $.finish-push
            if $terminate;
    }
    method finish-push (
        Str :$URI = $!baseURI,
        Bool :$recover = $.recover,
    )
    {
        with $!push-parser {
            my $doc := .finish-push(:$URI, :$recover);
            $_ = Nil;
            $doc;
        }
        else {
            die "no active push parser";
        }
    }

    method parse-balanced(Str() :$string!, LibXML::Document :$doc) {
        use LibXML::DocumentFragment;
        my LibXML::DocumentFragment $frag .= new: :$doc;
        my UInt $ret = $frag.parse: :balanced, :$string, :$.sax-handler, :$.keep-blanks;
        $frag;
    }

    method load-catalog(Str:D $filename) {
        xmlLoadCatalog($filename);
    }

    submethod TWEAK(Str :$catalog, :html($), :line-numbers($), :flags($), :URI($), :sax-handler($), :build-sax-handler($), :input-callbacks($), *%opts) {
        self.load-catalog($_) with $catalog;
        self.set-flags($!flags, %opts);
    }

    method FALLBACK($key, |c) is rw {
        $.option-exists($key)
            ?? $.option($key, |c)
            !! die X::Method::NotFound.new( :method($key), :typename(self.^name) );
    }

}
