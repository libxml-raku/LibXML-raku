#| LibXML DtD notations
unit class LibXML::Dtd::Notation;

use W3C::DOM;

also does W3C::DOM::Notation;

use LibXML::Raw;
use NativeCall;
use Method::Also;

=begin pod

=head3 Example

=begin code :lang<raku>
use LibXML::Dtd;
use LibXML::Dtd::Notation;

my $string = q:to<END>;
<!NOTATION jpeg SYSTEM "image/jpeg">
<!NOTATION png SYSTEM "image/png">
<!ENTITY camelia-logo
         SYSTEM "https://www.raku.org/camelia-logo.png"
         NDATA png>
END

my LibXML::Dtd $dtd .= parse: :$string;
my LibXML::Dtd::Notation $notation = $dtd.notations<jpeg>;
$notation = $dtd.entities<camelia-logo>.notation;

say $notation.name;     # png
say $notation.systemId; # image/png
say $notation.Str;      # <!NOTATION png SYSTEM "image/png" >
=end code

=head3 Description

Notation declarations are an older mechanism that is sometimes used in a DTD to qualify the data contained within an external entity (non-xml) file.

=end pod

has xmlNotation:D $.raw handles<Str type publicId systemId> is required;

method new(Str:D :$name!, Str :$publicId, Str :$systemId, *%c) {
    self.bless(raw => xmlNotation.new(:$name, :$publicId, :$systemId), |%c)
}
method box(xmlNotation:D $raw, |c --> LibXML::Dtd::Notation) {
    self.bless: :raw(nativecast(xmlNotation, $raw.Copy)), |c
}
method unique-key returns Str { $.raw.UniqueKey.Str }
method isSame($_) is also<isSameNode> {
    .isa($?CLASS) && self.unique-key eq .unique-key
}

=head3 method publicId

=for code :lang<raku>
method publicId() returns Str

=para Return the Public (External) ID

=head3 method systemId

=for code :lang<raku>
method systemId() returns Str

=para Return the System ID

# DOM

#| Return the entity name
method nodeName(--> Str) is also<name localName> { $!raw.name }
method nodeType { $.type }
method prefix { Str }
method hasAttributes { False }
method cloneNode is also<clone> { self.box: $!raw }

# Inventory of unimplemented DOM methods. Mostly because W3C expects this
# class to be based on a node, but LibXML doesn't.
method nodeValue is also<
    parentNode childNodes firstChild lastChild previousSibling nextSibling
    attributes ownerDocument insertBefore insertAfter replaceChild removeChild
    appendChild hasChildNodes normalize isSupported namespaceURI> {
    die X::NYI.new
}

submethod DESTROY { $!raw.Free; }
