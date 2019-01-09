class X::LibXML::Parser is Exception {
    use LibXML::Native;
    use LibXML::Enums;

    has xmlError $.error;
    has Str $.file;
    
    method message {
        my $msg = "Error while parsing {$!file // 'XML document'}\n"
        ~ "LibXML::Parser error";
        with $!error {
            $msg ~= ": $_" with .message;
        }
        $msg;
    }
}

class LibXML::Parser {

    use LibXML::Native;
    use LibXML::Enums;
    use LibXML::Document;

    has parserCtxt $!parser-ctx;
    has Bool $.html;
    has Bool $.line-numbers = False;
    has Str $.dir;
    has uint32 $.flags is rw = XML_PARSE_NODICT +| XML_PARSE_DTDLOAD;

    submethod TWEAK {
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
            }
        );
    }

    method keep-blanks is rw { self!flag-accessor(XML_PARSE_NOBLANKS); }
    method expand-entities is rw { self!flag-accessor(XML_PARSE_NOENT) }
    method pedantic-parser is rw { self!flag-accessor(XML_PARSE_PEDANTIC); }

    method !init-parser(parserCtxt $ctx) {
        die "unable to initialize parser" unless $ctx;

        unless $!flags +& XML_PARSE_DTDLOAD {
            for (XML_PARSE_DTDVALID, XML_PARSE_DTDATTR, XML_PARSE_NOENT ) {
                $!flags -= $_ if $!flags +& $_
            }
        }
        $ctx.UseOptions($!flags);     # Note: sets ctxt.linenumbers = 1
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

        with $ctx.ReadDoc($string, $uri, $enc, $!flags) {
            $ctx.Free;
            LibXML::Document.new: :struct($_);
        }
        else {
            given $ctx.GetLastError -> $error {
                die X::LibXML::Parser.new: :$error;
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

        with $ctx.ReadFile($file, $enc, $!flags) {
            $ctx.Free;
            LibXML::Document.new: :struct($_);
        }
        else {
            given $ctx.GetLastError -> $error {
                die X::LibXML::Parser.new: :$error;
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
            fail X::LibXML::Parser.new: :$error;
        }
        else {
            warn "untrapped error $err" if $err;
            my xmlDoc:D $struct = $ctx.myDoc;
            LibXML::Document.new: :$ctx, :$struct;
        }
    }

    multi method parse(IO() :io($path)!, |c) {
        my IO::Handle $io = $path.open(:bin, :r);
        $.parse(:$io, |c);
    }

}
