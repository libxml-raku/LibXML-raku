use LibXML::Node;
use W3C::DOM;

#| Entity Reference nodes
unit class LibXML::EntityRef
    is repr('CPointer')
    is LibXML::Node
    does W3C::DOM::EntityReference;

=begin pod

=head2 Synopsis

=begin code :lang<raku>
use LibXML::Document;
use LibXML::EntityRef;
use LibXML::Dtd::Entity;

my LibXML::Document $doc .= parse: :string(q:to<E-NUFF!>);
<!DOCTYPE doc [
<!ELEMENT doc (#PCDATA)>
<!ATTLIST doc type CDATA #IMPLIED>
<!ENTITY foo " test ">
]>
<doc>Sample document </doc>
E-NUFF!

# add a referenced to a Dtd entity
my LibXML::EntityRef $foo = $doc.createEntityReference("foo");
my LibXML::Dtd::Entity $foo-decl = $foo.firstChild;
say $foo-decl.Str; # <!ENTITY foo " test ">
my $root = $doc.getDocumentElement;
$root.appendChild: $foo;

# add a predefined entity reference
$root.appendChild: $doc.createEntityReference("gt");

say $root.Str; # <doc>Sample document &foo;&gt;</doc>
=end code

=head2 Description

L<LibXML::EntityRef> objects represent entities in a document.
These may be either a predefined entity such as `&lt;` or `&gt`,
or a reference to an entity defined in an internal or external Dtd.

In the latter case, the entity may contain one child node, which
is a link back to the entity declaration in the Dtd, of type
L<LibXML::Dtd::Entity>.

=end pod

use LibXML::Raw;
use NativeCall;
method raw { nativecast(xmlEntityRefNode, self) }

method new(LibXML::Node :doc($owner), Str :$name!) {
    my xmlDoc:D $doc = .raw with $owner;
    my xmlEntityRefNode:D $raw = $doc.new-ent-ref: :$name;
    self.box($raw);
}
method ast { self.ast-key => [] }
