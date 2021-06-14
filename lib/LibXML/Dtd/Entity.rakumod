use LibXML::Node;
use W3C::DOM;

#| DtD entity definitions
unit class LibXML::Dtd::Entity
    is repr('CPointer')
    is LibXML::Node
    does W3C::DOM::Entity;

use LibXML::Raw;
use LibXML::Enums;
use NativeCall;
use LibXML::Dtd::Notation;

method new(Str:D :$name!, Str:D :$content!, Str :$external-id, Str :$internal-id, LibXML::Item :$doc) {
    my xmlEntity:D $native .= create: :$name, :$content, :$external-id, :$internal-id;
    self.box($native, :$doc);
}

=begin pod
=head2 Example

=begin code :lang<raku>
use LibXML::Document;
use LibXML::Element;
use LibXML::EntityRef;
use LibXML::Dtd::Entity;
use LibXML::Enums;

my $string = q:to<END>;
<!DOCTYPE doc [
<!ENTITY foo "Foo ">
<!ENTITY bar " Bar">
]>
<doc>&foo;example</doc>
END

my LibXML::Document $doc .= parse: :$string;
my LibXML::Element $root = $doc.root;
my LibXML::EntityRef $foo-ref = $root.firstChild;
my LibXML::EntityRef $bar-ref =  $doc.createEntityReference('bar');

# Reference to entity defined in DtD
say xmlEntityType($bar-ref.firstChild.entityType); # XML_INTERNAL_GENERAL_ENTITY

# Reference to unknown entity
my LibXML::EntityRef $baz-ref =  $doc.createEntityReference('baz');
say $baz-ref.firstChild.defined; # False

# Reference to predefined entity
my LibXML::EntityRef $gt-ref =  $doc.createEntityReference('gt');
say xmlEntityType($gt-ref.firstChild.entityType); # XML_INTERNAL_PREDEFINED_ENTITY

$root.appendChild: $bar-ref;
$root.appendChild: $baz-ref;
$root.appendChild: $gt-ref;

note $root.Str; # <doc>&foo;example&bar;&baz;&gt;</doc>
=end code
=end pod

#| return the Public (External) ID
method publicId(--> Str) { $.raw.ExternalID }

#| Return the System ID
method systemId(--> Str) { $.raw.SystemID }

#| Return the entity name
method name(--> Str) { $.raw.name }

#| return the name of any notation associated with this entity
method notationName {
    self.raw.etype == XML_INTERNAL_PREDEFINED_ENTITY
    ?? Str
    !! $.raw.content;
}

#| return any notation associated with this entity
method notation(--> LibXML::Dtd::Notation) {
    do with $.notationName {
        with $.raw.parent -> $dtd {
            LibXML::Dtd::Notation.box: $dtd.delegate.getNotation($_);
        }
    } // LibXML::Dtd::Notation;
}

#| return the entity type
method entityType { $.raw.etype }
=para One of: `XML_EXTERNAL_GENERAL_PARSED_ENTITY`,
    `XML_EXTERNAL_GENERAL_UNPARSED_ENTITY`,
    `XML_EXTERNAL_PARAMETER_ENTITY`,
    `XML_INTERNAL_GENERAL_ENTITY`,
    `XML_INTERNAL_PARAMETER_ENTITY`,
    or `XML_INTERNAL_PREDEFINED_ENTITY`

method raw { nativecast(xmlEntity, self) }

method Str {
    self.defined && self.raw.etype == XML_INTERNAL_PREDEFINED_ENTITY
        ?? $.raw.content
        !! nextsame;
}
