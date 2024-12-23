unit class LibXML::Parser::Context;

use NativeCall;
use LibXML::_Configurable;
use LibXML::Config :&protected;
use LibXML::Enums;
use LibXML::ErrorHandling :&structured-error-cb;
use LibXML::Item;
use LibXML::Raw;
use LibXML::_Options;

our constant %Opts = %(
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
    :recover-quietly(XML_PARSE_RECOVER +| XML_PARSE_NOWARNING),
    :recover-silently(XML_PARSE_RECOVER +| XML_PARSE_NOERROR),
    :suppress-errors(XML_PARSE_NOERROR),
    :suppress-warnings(XML_PARSE_NOWARNING),
    :validation(XML_PARSE_DTDVALID),
    :xinclude(XML_PARSE_XINCLUDE),
);

also does LibXML::_Configurable;
also does LibXML::_Options[%Opts];
also does LibXML::ErrorHandling;

has xmlParserCtxt $!raw handles <wellFormed valid SetStructuredErrorFunc>;
has uint32 $.flags = self.config.parser-flags;
multi method flags(::?CLASS:D:) is rw { $!flags }
multi method flags(::?CLASS:U:) { self.config.parser-flags }
has Bool $.input-compressed;
has Bool $.line-numbers;
has $.input-callbacks;
has $.sax-handler;
has $!published;
has Bool $.local-errors = self.config.version >= v2.13.00;

method raw { $!raw }
method close {
    $!input-compressed //= ? .Close()
        with $!raw;
}

method set-raw(xmlParserCtxt $_) {
    my $old = $!raw;
    $!raw = $_;
    with $!raw {
        .Reference;
        .UseOptions($!flags);     # Note: sets ctxt.linenumbers = 1
        .linenumbers = +?$!line-numbers;
        $!raw.sax = .raw with $!sax-handler;
        self.init-local-error-handling
            if $!local-errors;
    }
    with $old {
        unless $!published {
            with .myDoc {
                .Free  unless .is-referenced;
            }
        }
        .sax = Nil;
        .Unreference;
    }
    $!published = False;
}

method publish {
    my xmlDoc $doc = .myDoc with $!raw;
    $.close() without $!input-compressed;
    $!published = True;
    self.reset();
    $doc;
}

submethod TWEAK(xmlParserCtxt :$raw, *%opts) {
    self.set-flags($!flags, :lax, |%opts);
    self.set-raw($_) with $raw;
}

method reset { self.set-raw(xmlParserCtxt); }

submethod DESTROY { self.reset }

method stop-parser {
    with $!raw {
        .StopParser unless self.recover;
    }
}

method try(|c) is hidden-from-backtrace is DEPRECATED<do> { self.do: |c }

proto method do(|) {*}
multi method do(::?CLASS:D $ctx: &action, Bool :$recover = $.recover, Bool :$check-valid) is hidden-from-backtrace {

    my $rv;

    protected sub () is hidden-from-backtrace {
        my @input-contexts = .activate with $ctx.input-callbacks;

        die "LibXML::Config.parser-locking needs to be enabled to allow parser-level input-callbacks"
            if @input-contexts && !LibXML::Config.parser-locking;

        my $handlers;
        if $ctx.global-error-handling {
            $handlers := xml6_gbl::save-error-handlers();
            $ctx.SetStructuredErrorFunc: &structured-error-cb;
        }
        &*chdir(~$*CWD);
        my @prev = $ctx.config.setup();

        my $*XML-CONTEXT := $ctx;
        $rv := action();

        .flush-errors for @input-contexts;
        $rv := $ctx.is-valid if $check-valid;
        $ctx.flush-errors: :$recover;

        LEAVE {
            self.config.restore(@prev);

            .deactivate with $ctx.input-callbacks;

            xml6_gbl::restore-error-handlers($_)
                with $handlers;
        }
    }
    $rv;
}

multi method do(::?CLASS:U: |c) is hidden-from-backtrace {
    my xmlParserCtxt $raw .= new;
    self.new(:$raw).do: |c;
}

method FALLBACK($key, |c) is rw is hidden-from-backtrace {
    $.option-exists($key)
        ?? $.option($key, |c)
        !! die X::Method::NotFound.new( :method($key), :typename(self.^name) );
}

