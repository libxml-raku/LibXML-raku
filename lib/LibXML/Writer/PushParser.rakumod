unit class LibXML::Writer::PushParser;

use LibXML::Writer;
also is LibXML::Writer;

use LibXML::Raw;
use LibXML::PushParser;

has LibXML::PushParser $!push-parser handles<push finish-push>;

submethod TWEAK(:$chunk = '', |c) is hidden-from-backtrace {
    $!push-parser .= new: :$chunk, |c;
    my xmlParserCtxt:D $ctxt = $!push-parser.ctxt.raw;
    self.raw .= new(:$ctxt)
        // die X::LibXML::OpFail.new(:what<Write>, :op<NewPushParser>);
}

method close {
    with $!push-parser {
        .ctxt.raw = Nil; # avoid double free
        $_ = Nil;
        callsame();
    }
}
