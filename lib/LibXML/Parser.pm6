class LibXML::Parser {

    use LibXML::Native;
    use LibXML::Enums;
    use LibXML::Document;
    use LibXML::PushParser;
    use LibXML::ErrorHandler;

    has Bool $.html;
    has Bool $.line-numbers is rw = False;
    has Bool $.recover is rw;
    has uint32 $.flags is rw = XML_PARSE_NODICT +| XML_PARSE_DTDLOAD;
    has Str $.baseURI is rw;
    has $.sax-handler;

    constant %FLAGS = %(
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
    );

    method keep-blanks is rw {
        Proxy.new(FETCH => sub ($) { ! self.no-blanks },
                  STORE => sub ($, Bool() $kb) {
                         self.no-blanks = ! $kb
                     })
    }

    method !error-handler(parserCtxt:D :$ctx!) {
        $ctx.sax = .unbox with $.sax-handler;
        LibXML::ErrorHandler.new: :$ctx, :$!flags, :$!line-numbers, :$!recover;
    }

    method !publish(:$ctx!, :$URI, LibXML::ErrorHandler :$errors!, ) {
        my LibXML::Document:D $doc .= new: :$ctx;
        $doc.baseURI = $_ with $URI;
        self.processXIncludes($doc, :$errors)
            if $.expand-xinclude;
        $doc;
    }

    proto method processXIncludes(LibXML::Document $_, LibXML::ErrorHandler :$errors) {*}

    multi method processXIncludes(LibXML::Document $_, LibXML::ErrorHandler:D :$errors! --> UInt) {
        my xmlDoc $doc = .unbox;
        $errors.try: { $doc.XIncludeProcessFlags($!flags); }
    }
    multi method processXIncludes(LibXML::Document $_) is default {
        my xmlDoc:D $doc = .unbox;
        my xmlParserCtxt:D $ctx .= new;
        $ctx.sax = .unbox with $.sax-handler;
        my LibXML::ErrorHandler $error-handler = self!error-handler: :$ctx;
        $error-handler.try: { 
            $doc.XIncludeProcessFlags($!flags);
        }
    }

    method load(|c) { self.new.parse(|c) }

    multi method parse(Str:D() :$string!,
                       Bool() :$html = $!html,
                       Str() :$URI = $!baseURI,
                      ) {

        # gives better diagnositics
        my parserCtxt:D $ctx = $html
           ?? htmlMemoryParserCtxt.new: :$string
           !! xmlMemoryParserCtxt.new: :$string;

        $ctx.input.filename = $_ with $URI;

        my LibXML::ErrorHandler $errors = self!error-handler: :$ctx;
        $errors.try: { $ctx.ParseDocument };
        self!publish: :$ctx, :$errors;
    }

    multi method parse(Blob :$buf!,
                       Bool() :$html = $!html,
                       Str() :$URI = $!baseURI,
                       xmlCharEncoding :$enc = 'UTF-8',
                      ) {

        # gives better diagnositics
        my parserCtxt:D $ctx = $html
           ?? htmlMemoryParserCtxt.new(:$buf, :$enc)
           !! xmlMemoryParserCtxt.new(:$buf, :$enc);

        $ctx.input.filename = $_ with $URI;

        my LibXML::ErrorHandler $errors = self!error-handler: :$ctx;
        $errors.try: { $ctx.ParseDocument };
        self!publish: :$ctx, :$errors;
    }

    multi method parse(IO() :$file!,
                       Bool() :$html = $!html,
                       xmlCharEncoding :$enc,
                       Str :$URI = $!baseURI) {

        die "file not found: $file"
            unless $file.IO.e;
        my parserCtxt $ctx = $html
           ?? htmlFileParserCtxt.new(:$file, :$enc)
           !! xmlFileParserCtxt.new(:$file);

        my LibXML::ErrorHandler $errors = self!error-handler: :$ctx;
        $errors.try: { $ctx.ParseDocument };
        self!publish: :$ctx, :$URI, :$errors;
    }

    multi method parse(IO::Handle :$io!,
                       Str :$URI = $!baseURI,
                       Bool() :$html = $!html,
                       UInt :$chunk-size = 4096,
                       xmlCharEncoding :$enc,
                      ) {

        # read initial block to determine encoding
        my Str $path = $io.path.path;
        my Blob $chunk = $io.read($chunk-size);
        my LibXML::PushParser $push-parser .= new: :$chunk, :$html, :$path, :$!flags, :$!line-numbers, :$.sax-handler, :$enc;

        my Bool $more = ?$chunk;

        while $more && !$push-parser.err {
            $chunk = $io.read($chunk-size);
            $more = ?$chunk;
            $push-parser.push($chunk)
                if $more;
        }

        $push-parser.finish-push: :$URI;
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
    method finish-push(
        Str :$URI = $!baseURI,
        Bool :$recover = $!recover,
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

    method parse-balanced(Str() :$string!, Bool() :$recover = False, LibXML::Document :$doc) {
        use LibXML::DocumentFragment;
        my LibXML::DocumentFragment $frag .= new: :$doc;
        my UInt $ret = $frag.parse: :balanced, :$string, :$.sax-handler;
        $frag;
    }

    method !flag-accessor(uint32 $flag) is rw {
        Proxy.new(
            FETCH => sub ($) { ? ($!flags +& $flag) },
            STORE => sub ($, Bool() $_) {
                if .so {
                    $!flags +|= $flag;
                }
                else {
                    my uint32 $mask = 0xffffffff +^ $flag;
                    $!flags +&= $mask;
                }
            });
    }

    submethod TWEAK(:html($), :line-numbers($), :flags($), :URI($), :sax-handler($), *%flags) {
        for %flags.pairs.sort -> $f {
            with %FLAGS{$f.key} {
                self!flag-accessor($_) = $f.value;
            }
            else {
                warn "ignoring option: {$f.key}";
            }
        }
    }

    method FALLBACK($method, |c) is rw {
        # set up flag accessors;
        with %FLAGS{$method} {
            self!flag-accessor($_,|c);
        }
        else {
            die X::Method::NotFound.new( :$method, :typename(self.^name) )
        }
    }

}
