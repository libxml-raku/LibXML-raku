class X::LibXML::Parser is Exception {
    use LibXML::Native;
    use LibXML::Enums;

    has Str $.text;
    has Str $.file;
    
    method message {
        my $msg = "Error while parsing {$!file // 'XML document'}";
        $msg ~= ":\n" ~ $_ with $!text;
        chomp $msg;
    }
}

class LibXML::Parser {

    use LibXML::Native;
    use LibXML::Enums;
    use LibXML::Document;

    has parserCtxt $!parser-ctx;
    has Bool $.html;
    has Bool $.line-numbers = False;
    has uint32 $.flags is rw = XML_PARSE_NODICT +| XML_PARSE_DTDLOAD;
    has Str $.base-uri is rw;
    has @.errors;

    constant %FLAGS = %(
        :recover(XML_PARSE_RECOVER),
        :expand-entities(XML_PARSE_NOENT),
        :load-ext-dtd(XML_PARSE_DTDLOAD),
        :complete-attributes(XML_PARSE_DTDATTR),
        :validation(XML_PARSE_DTDVALID),
        :suppress-errors(XML_PARSE_NOERROR),
        :suppress-warnings(XML_PARSE_NOWARNING),
        :pedantic-parser(XML_PARSE_PEDANTIC),
        :keep-blanks(XML_PARSE_NOBLANKS),
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

    method !init-parser(parserCtxt $ctx) {
        die "unable to initialize parser" unless $ctx;

        unless $!flags +& XML_PARSE_DTDLOAD {
            for (XML_PARSE_DTDVALID, XML_PARSE_DTDATTR, XML_PARSE_NOENT ) {
                $!flags -= $_ if $!flags +& $_
            }
        }

        $ctx.UseOptions($!flags);     # Note: sets ctxt.linenumbers = 1
        $ctx.linenumbers = +$!line-numbers;

        # error handling
        @!errors = ();
        sub structured-err-func(parserCtxt $, xmlError $_) {
            my Int $level = .level;
            my Str $msg = .message;
            if .line && .file && !.file.ends-with('/') {
                $msg = (.file, .line, $msg).join: ':';
            }
            @!errors.push: %( :$level, :$msg);
        }

        $ctx.xmlSetGenericErrorFunc( sub (parserCtxt $, Str $msg) { @!errors.push: %( :level(XML_ERR_FATAL), :$msg ) });
        $ctx.xmlSetStructuredErrorFunc( &structured-err-func );

        $ctx;
    }

    method !flush-errors {
        if @!errors {
            my Str $text = @!errors.map(*<msg>).join;
            my $fatal = @!errors.first: { .<level> >= XML_ERR_FATAL };
            my X::LibXML::Parser $err .= new: :$text;
            if $fatal {
                die $err;
            }
            else {
                warn $err;
            }
       }
       @!errors = ();
    }

    method !finish(LibXML::Document $doc, :$uri) {
        self!flush-errors;
        $doc.uri = $_ with $uri;
        self.process-xincludes($doc)
            if $.expand-xinclude;
        $doc;
    }

    multi method parse(Str:D() :$string!,
                       Str :$uri = $!base-uri,
                       Str :$enc) {

        my parserCtxt $ctx = $!html
           ?? htmlParserCtxt.new
           !! xmlParserCtxt.new;

        self!init-parser($ctx);

        with $ctx.ReadDoc($string, $uri, $enc, $!flags) -> $doc {
            self!finish: LibXML::Document.new( :$ctx, :$doc);
        }
        else {
            given $ctx.GetLastError -> $error {
                my $text = $error.message;
                die X::LibXML::Parser.new: :$text;
            }
        }
    }

    multi method parse(Str:D :$file!,
                       Str :$uri = $!base-uri) {

        my parserCtxt $ctx = $!html
           ?? htmlFileParserCtxt.new(:$file)
           !! xmlFileParserCtxt.new(:$file);

        self!init-parser($ctx);

        if $ctx.ParseDocument == 0 {
            self!finish: LibXML::Document.new(:$ctx), :$uri;
        }
        else {
            given $ctx.GetLastError -> $error {
                my $text = $error.message;
                die X::LibXML::Parser.new: :$text;
            }
        }
    }

    multi method parse(IO::Handle :$io!,
                       Str :$uri = $!base-uri,
                       UInt :$chunk-size = 4096,
                      ) {

        # read initial block to determine encoding
        my Str $path = $io.path.path;
        my Blob $chunk = $io.read($chunk-size);

        my \ctx-class = $!html ?? htmlPushParserCtxt !! xmlPushParserCtxt;
        my parserCtxt $ctx = ctx-class.new: :$chunk, :$path;

        self!init-parser($ctx);
        my Bool $more = ?$ctx && ?$chunk;
        my $err = 0;

        while $more && !$err {
            $chunk = $io.read($chunk-size);
            $more = ?$chunk;
            $err = $ctx.ParseChunk($chunk, +$chunk, 0)
                if $more;
        }

        given $ctx.ParseChunk($chunk, 0, 1) { # terminate
            $err ||= $_
        }

        with $ctx.GetLastError -> $error {
            my $text = $error.message;
            fail X::LibXML::Parser.new: :$text;
        }
        else {
            self!finish: LibXML::Document.new( :$ctx ), :$uri;
        }
    }

    multi method parse(IO() :io($path)!, |c) {
        my IO::Handle $io = $path.open(:bin, :r);
        $.parse(:$io, |c);
    }

    multi method process-xincludes( LibXML::Document $doc) {
        my xmlDoc $xml-doc = $doc.doc;
        my xmlXIncludeCtxt $ctx .= new( :doc($xml-doc) );
        self!init-parser($ctx);
        my xmlNode $root = $xml-doc.GetRootElement;
        my $n = $ctx.ProcessNode($root);
        self!flush-errors;
        $ctx.Free;
        $n;
    }

    method !flag-accessor(uint32 $flag) is rw {
        Proxy.new(
            FETCH => sub ($) { $!flags +& $flag },
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

    submethod TWEAK(:html($), :line-numbers($), :flags($), :uri($), *%flags) {
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
