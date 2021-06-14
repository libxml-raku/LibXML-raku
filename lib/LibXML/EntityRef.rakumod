use LibXML::Node;
use W3C::DOM;

#| Entity Reference nodes
unit class LibXML::EntityRef
    is repr('CPointer')
    is LibXML::Node
    does W3C::DOM::EntityReference;

=begin pod

=begin code
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
my LibXML::EntityRef $bar-ref = $doc.createEntityReference('bar');

# Reference to entity defined in DtD
say xmlEntityType($bar-ref.firstChild.entityType); # XML_INTERNAL_GENERAL_ENTITY

# Create reference to unknown entity
my LibXML::EntityRef $baz-ref =  $doc.createEntityReference('baz');
say $baz-ref.firstChild.defined; # False

# Create reference to predefined entity
my LibXML::EntityRef $gt-ref =  $doc.createEntityReference('gt');
say xmlEntityType($gt-ref.firstChild.entityType); # XML_INTERNAL_PREDEFINED_ENTITY

$root.appendChild: $bar-ref;
$root.appendChild: $baz-ref;
$root.appendChild: $gt-ref;

note $root.Str; # <doc>&foo;example&bar;&baz;&gt;</doc>
=end code

=head2 Description

L<LibXML::EntityRef> objects represent entities in a document.
These may be either a predefined entity such as `&lt;` or `&gt`,
or a reference to an entity defined in an internal or external Dtd.

In the latter case, the entity may contain one child node, which
is a link back to the entity declaration in the Dtd, of type
L<LibXML::Dtd::Entity>.

As a LibXML extension, entity references in attribute nodes may be
examined and manipulated via the attribute's child nodes. For example:

=begin code :lang<raku>
use LibXML::Document;
use LibXML::Attr;
use LibXML::Enums;
my LibXML::Document $doc .= parse: :file<example/dtd.xml>;

my LibXML::Attr $att .= new: :name<att>, :value('xxx');
$att.addChild: $doc.createEntityReference('foo');
note $att.Str; # xxx test
note $att.childNodes[1].WHAT.raku; # LibXML::EntityRef;
$doc.root.setAttributeNode($att);

note $doc.root.Str; # <doc att="xxx&foo;">This is a valid document &foo; !</doc>
=end code

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
