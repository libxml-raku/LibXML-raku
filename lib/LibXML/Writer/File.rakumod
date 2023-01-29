unit class LibXML::Writer::File;

use LibXML::Writer;
also is LibXML::Writer;

use LibXML::Raw;

has Str:D $.file is required;

submethod TWEAK is hidden-from-backtrace {
    self.raw .= new(:$!file)
        // die X::LibXML::OpFail.new(:what<Write>, :op<NewFile>);
}

