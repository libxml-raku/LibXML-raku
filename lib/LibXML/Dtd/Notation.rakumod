use W3C::DOM;

#| LibXML DtD notations
unit class LibXML::Dtd::Notation
    is repr('CPointer')
    does W3C::DOM::Notation;

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

method new(Str:D :$name!, Str :$publicId, Str :$systemId) {
    self.box: xmlNotation.new(:$name, :$publicId, :$systemId);
}
method box(xmlNotation:D $raw --> LibXML::Dtd::Notation) {
    nativecast(self, $raw.Copy);
}
method unique-key returns Str { $.raw.UniqueKey.Str }
method isSame($_) is also<isSameNode> {
    .isa($?CLASS) && self.unique-key eq .unique-key
}

#| return the Public (External) ID
method publicId(--> Str) { $.raw.publicId }

#| Return the System ID
method systemId(--> Str) { $.raw.systemId }

#| Return the entity name
method name(--> Str) { $.raw.name }

method raw handles<Str type> { nativecast(xmlNotation, self) }

# DOM

method nodeName is also<localName> { $.name }
method nodeType { $.type }
method prefix { Str }
method hasAttributes { False }
method cloneNode is also<clone> { self.box: self.raw }

# Inventory of unimplemented DOM methods. Mostly because W3C expects this
# class to be based on a node, but LibXML doesn't.
method nodeValue is also<
    parentNode childNodes firstChild lastChild previousSibling nextSibling
    attributes ownerDocument insertBefore insertAfter replaceChild removeChild
    appendChild hasChildNodes normalize isSupported namespaceURI> {
    die X::NYI.new
}

submethod DESTROY { self.raw.Free; }
