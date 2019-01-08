class X::XML::LibXML::Parser is Exception {
    use XML::LibXML::Native;
    use XML::LibXML::Enums;

    has xmlError $.error;
    has Str $.file;
    
    method message {
        my $msg = "Error while parsing {$!file // 'XML document'}\n"
        ~ "XML::LibXML::Parser error";
        with $!error {
            $msg ~= ": $_" with .message;
        }
        $msg;
    }
}

class XML::LibXML::Parser {

    use XML::LibXML::Native;
    use XML::LibXML::Enums;
    use XML::LibXML::Document;

    has parserCtxt $!parser-ctx;
    has Bool $.html;
    has Bool $.line-numbers = False;
    has Str $.dir;
    has UInt $!flags;

    submethod TWEAK(:$!flags = ($!html ?? (HTML_PARSE_RECOVER + HTML_PARSE_NOBLANKS) !! 0)) {
    }

    method !flag-accessor($flag) is rw {
        Proxy.new(
            FETCH => sub ($) { $!flags +& $flag },
            STORE => sub ($, Bool() $_) {
                if .so {
                    $!flags +|= $flag;
                }
                else {
                    $!flags -= $flag
                        if $!flags +& $flag
                }
            }
        );
    }

    method keep-blanks is rw { self!flag-accessor(XML_PARSE_NOBLANKS); }
    method expand-entities is rw { self!flag-accessor(XML_PARSE_NOENT); }
    method pedantic-parser is rw { self!flag-accessor(XML_PARSE_PEDANTIC); }

    method !init-parser(parserCtxt $ctx) {
        die "unable to initialize parser" unless $ctx;

        unless $!flags +& XML_PARSE_DTDLOAD {
            for (XML_PARSE_DTDVALID, XML_PARSE_DTDATTR, XML_PARSE_NOENT ) {
                $!flags -= $_ if $!flags +& $_
            }
        }
        $ctx.use-options($!flags);     # Note: sets ctxt.linenumbers = 1
        $ctx.linenumbers = +$!line-numbers;
        $ctx;
    }

    multi method parse(Str:D() :$string!,
                       Str :$uri,
                       Str :$enc) {

        my parserCtxt $ctx = $!html
           ?? htmlParserCtxt.new
           !! xmlParserCtxt.new;

        self!init-parser($ctx);

        with $ctx.read-doc($string, $uri, $enc, $!flags) {
            $ctx.free;
            XML::LibXML::Document.new: :struct($_);
        }
        else {
            given XML::LibXML::Native.last-error($ctx) -> $error {
                die X::XML::LibXML::Parser.new: :$error;
            }
        }
    }

    multi method parse(Str:D :$file!,
                       Str :$uri,
                       Str :$enc) {

        my parserCtxt $ctx = $!html
           ?? htmlParserCtxt.new
           !! xmlParserCtxt.new;

        self!init-parser($ctx);

        with $ctx.read-file($file, $uri, $enc, $!flags) {
            $ctx.free;
            XML::LibXML::Document.new: :struct($_);
        }
        else {
            given XML::LibXML::Native.last-error($ctx) -> $error {
                die X::XML::LibXML::Parser.new: :$error;
            }
        }
    }

    multi method parse(IO::Handle :$io!,
                       Str   :$uri,
                       Str   :$enc,
                       UInt :$chunk-size = 4096,
                      ) {

        # read initial block to determine encoding
        my Str $path = $io.path.path;
        my Blob $chunk = $io.read($chunk-size);

        my \ctx-class = $!html ?? htmlPushParserCtxt !! xmlPushParserCtxt;
        my parserCtxt $ctx = ctx-class.new: :$chunk, :$path;

        self!init-parser($ctx);
        my Bool $more = ?$chunk;

        while $more {
            $chunk = $io.read($chunk-size);
            $more = ?$chunk;
            $ctx.parse-chunk($chunk, +$chunk, 0)
                if $more;
        }
        $ctx.parse-chunk($chunk, 0, 1); # terminate
        my xmlDoc:D $struct = $ctx.myDoc;
        my xmlDoc $struct = $ctx.myDoc.copy;
        $ctx.free;
        XML::LibXML::Document.new: :$struct;
    }

    multi method parse(IO() :io($path)!, |c) {
        my IO::Handle $io = $path.open(:bin, :r);
        $.parse(:$io, |c);
    }

}
