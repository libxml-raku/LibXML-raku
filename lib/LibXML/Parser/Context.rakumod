unit class LibXML::Parser::Context;

use NativeCall;
use LibXML::Config;
use LibXML::Enums;
use LibXML::ErrorHandling :&structured-error-cb;
use LibXML::Raw;
use LibXML::_Options;

has xmlParserCtxt $!raw handles <wellFormed valid>;
has uint32 $.flags = LibXML::Config.parser-flags;
multi method flags(LibXML::Parser::Context:D:) is default is rw { $!flags }
multi method flags { LibXML::Config.parser-flags }
has Bool $.input-compressed;
has Bool $.line-numbers;
has $.input-callbacks;
has $.sax-handler;

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

also does LibXML::_Options[%Opts];
also does LibXML::ErrorHandling;

method raw { $!raw }
method close {
    $!input-compressed = ? .Close()
        with $!raw;
}

method set-raw(xmlParserCtxt $raw) {
    .Reference with $raw;
    .Unreference with $!raw;

    with $raw {
        .UseOptions($!flags);     # Note: sets ctxt.linenumbers = 1
        .linenumbers = +?$!line-numbers;
        $!raw = $_;
        $!raw.sax = .raw with $!sax-handler;
    }
}

submethod TWEAK(xmlParserCtxt :$raw, *%opts) {
    self.set-raw($_) with $raw;
    self.set-flags($!flags, :lax, |%opts);
}

submethod DESTROY {
    with $!raw {
        .sax = Nil;
        .Unreference;
    }
}

method try(&action, Bool :$recover = $.recover, Bool :$check-valid) is hidden-from-backtrace {

    my $rv;
    my $*XML-CONTEXT = self;
    $_ = .new: :raw(xmlParserCtxt.new)
        without $*XML-CONTEXT;

    my @input-contexts = .activate()
        with $*XML-CONTEXT.input-callbacks;

    given xml6_gbl_save_error_handlers() {
        $*XML-CONTEXT.raw.SetStructuredErrorFunc: &structured-error-cb;

        &*chdir(~$*CWD);

        $rv := action();

        .deactivate
            with $*XML-CONTEXT.input-callbacks;

        xml6_gbl_restore_error_handlers($_);
    }

    .flush-errors for @input-contexts;
    $rv := $*XML-CONTEXT.is-valid if $check-valid;
    $*XML-CONTEXT.flush-errors: :$recover;

    $rv;
}

method FALLBACK($key, |c) is rw {
    $.option-exists($key)
        ?? $.option($key, |c)
        !! die X::Method::NotFound.new( :method($key), :typename(self.^name) );
}

