unit class LibXML::Writer::Buffer;

use LibXML::Writer;
also is LibXML::Writer;

use LibXML::Raw;

has xmlBuffer32 $.buf .= new;

method Str { $!buf.Content; }

submethod TWEAK {
    self.raw .= new: :$!buf;
}

submethod DESTROY {
    .Free with $!buf;
}
