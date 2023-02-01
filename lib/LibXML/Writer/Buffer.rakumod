unit class LibXML::Writer::Buffer;

use LibXML::Writer;
also is LibXML::Writer;

use LibXML::Raw;

has xmlBuffer32 $!buf handles <Blob Str> .= new;

submethod TWEAK is hidden-from-backtrace {
    self.raw .= new(:$!buf)
        // die X::LibXML::OpFail.new(:what<Write>, :op<NewMem>);
}
