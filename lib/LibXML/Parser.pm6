class LibXML::Parser {

    use LibXML::Config;
    use LibXML::Native;
    use LibXML::Enums;
    use LibXML::Document;
    use LibXML::PushParser;
    use LibXML::Parser::Context;
    use Method::Also;

    constant config = LibXML::Config;

    has Bool $.html;
    has Bool $.line-numbers is rw = False;
    has UInt $.flags is rw = XML_PARSE_NODICT +| XML_PARSE_DTDLOAD;
    has Str $.baseURI is rw;
    has $.sax-handler is rw;
    has $.input-callbacks is rw = config.input-callbacks;
    multi method input-callbacks is rw { $!input-callbacks }
    multi method input-callbacks($!input-callbacks) {}

    use LibXML::_Options;
    also does LibXML::_Options[
        %(
            :clean-namespaces(XML_PARSE_NSCLEAN),
            :complete-attributes(XML_PARSE_DTDATTR),
            :dtd(XML_PARSE_DTDLOAD +| XML_PARSE_DTDVALID
                 +| XML_PARSE_DTDATTR +| XML_PARSE_NOENT),
            :expand-entities(XML_PARSE_NOENT),
            :expand-xinclude(XML_PARSE_XINCLUDE),
            :huge(XML_PARSE_HUGE),
            :load-ext-dtd(XML_PARSE_DTDLOAD),
            :no-base-fix(XML_PARSE_NOBASEFIX),
            :no-blanks(XML_PARSE_NOBLANKS),
            :no-keep-blanks(XML_PARSE_NOBLANKS),
            :no-cdata(XML_PARSE_NOCDATA),
            :no-def-dtd(HTML_PARSE_NODEFDTD),
            :no-network(XML_PARSE_NONET),
            :no-xinclude-nodes(XML_PARSE_NOXINCNODE),
            :old10(XML_PARSE_OLD10),
            :oldsax(XML_PARSE_OLDSAX),
            :pedantic-parser(XML_PARSE_PEDANTIC),
            :recover(XML_PARSE_RECOVER),
            :recover-silently(XML_PARSE_RECOVER +| XML_PARSE_NOERROR),
            :suppress-errors(XML_PARSE_NOERROR),
            :suppress-warnings(XML_PARSE_NOWARNING),
            :validation(XML_PARSE_DTDVALID),
            :xinclude(XML_PARSE_XINCLUDE),
        )];

    # Perl 5 compat
    multi method set-option('recover', 2) {
        $.set-option('recover-silently', True);
    }
    multi method get-option('recover') {
        my $recover = $.get-flag($!flags, 'recover');
        $recover && $.get-option('suppress-errors') ?? 2 !! $recover;
    }

    multi method get-option(Str:D $key) is default { $.get-flag($!flags, $key); }
    multi method set-option(Str:D $key, $_) is default { $.set-flag($!flags, $key, $_); }
    multi method set-option(*%opt) is also<set-options> {
        my $rv := $.set-option(.key, .value) for %opt.sort;
        $rv;
    }

    method options(:$html, *%opts) {
        my UInt $flags = $!flags;
        $.set-flag($flags, 'load-ext-dtd', False)
            if $html;
        $.set-flags($flags, %opts);

        $.set-flag($flags, 'dtd', False)
            unless $html || $flags +& XML_PARSE_DTDLOAD;

        $flags;
    }

    method !make-handler(parserCtxt :$native, *%flags) {
        my UInt $flags = self.options(|%flags);
        LibXML::Parser::Context.new: :$native, :$flags, :$!line-numbers, :$!input-callbacks, :$.sax-handler;
    }

    method !publish(:$URI, LibXML::Parser::Context :$handler!, xmlDoc :$native = $handler.native.myDoc) {
        my LibXML::Document:D $doc .= new: :ctx($handler), :$native;
        $doc.baseURI = $_ with $URI;
        self.processXIncludes($doc, :$handler)
            if $.expand-xinclude;
        $doc;
    }

    method processXIncludes(
        LibXML::Document $_,
        LibXML::Parser::Context:D :$handler = self!make-handler(:native(xmlParserCtxt.new)),
        *%opts --> Int) is also<process-xinclude> {
        my xmlDoc $doc = .native;
        my $flags = self.options(|%opts);
        $handler.try: { $doc.XIncludeProcessFlags($flags) }
    }

    method load(|c) {
        my $obj = do with self { .clone } else { .new };
        $obj.parse(|c);
    }

    multi method parse(Str:D() :$string!,
                       Bool() :$html = $!html,
                       Str() :$URI = $!baseURI,
                       xmlEncodingStr :$enc = 'UTF-8',
                       *%flags 
                      ) {

        # gives better diagnositics

        my LibXML::Parser::Context $handler = self!make-handler: :$html, |%flags;

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

        my LibXML::Parser::Context $handler = self!make-handler: :native($ctx), :$html, |%flags;
        $handler.try: { $ctx.ParseDocument };
        self!publish: :$handler;
    }

    multi method parse(IO() :$file!,
                       Bool() :$html = $!html,
                       xmlEncodingStr :$enc,
                       Str :$URI = $!baseURI,
                       *%flags,
                      ) {
        my LibXML::Parser::Context $handler = self!make-handler: :$html, |%flags;

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

    multi method parse(UInt :$fd!,
                       Str :$URI = $!baseURI,
                       Bool() :$html = $!html,
                       xmlEncodingStr :$enc,
                       *%flags,
                      ) {

        my LibXML::Parser::Context $handler = self!make-handler: :$html, |%flags;
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

    multi method parse(Str() :location($file)!, |c) {
        $.parse(:$file, |c);
    }

    # parse from a Miscellaneous source
    multi method parse(Any:D $src, |c) is default {
        my Pair $in = do with $src {
            when UInt       { :fd($_) }
            when IO::Handle
            |    IO::Path   { :io($_) }
            when Blob       { :buf($_) }
            when Str  { m:i:s/^ '<'/ ?? :string($_) !! :file($_) }
            default { fail "Unrecognised parser input: {.perl}"; }
        }
        $.parse( |$in, |c );
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
