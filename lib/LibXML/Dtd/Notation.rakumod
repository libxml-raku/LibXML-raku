use W3C::DOM;

#| LibXML DtD notations
unit class LibXML::Dtd::Notation
    is repr('CPointer')
    does W3C::DOM::Notation;

use LibXML::Raw;
use NativeCall;
use Method::Also;

method new(Str:D :$name!, Str :$publicId, Str :$systemId) {
    self.box: xmlNotation.new(:$name, :$publicId, :$systemId);
}
method box(xmlNotation:D $raw --> LibXML::Dtd::Notation) {
    nativecast(self, $raw.Copy);
}
method unique-key returns Str { $.raw.UniqueKey }
method isSame($_) is also<isSameNode> {
    .isa($?CLASS) && self.unique-key eq .unique-key
}

#| return the Public (External) ID
method publicId(--> Str) { $.raw.publicId }

#| Return the System ID
method systemId(--> Str) { $.raw.systemID }

#| Return the entity name
method name(--> Str) { $.raw.name }

method raw handles<Str> { nativecast(xmlNotation, self) }

# DOM

method nodeName is also<localName> { $.name }
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
