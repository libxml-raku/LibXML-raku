[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [EntityRef](https://libxml-raku.github.io/LibXML-raku/EntityRef)

class LibXML::EntityRef
-----------------------

Entity Reference nodes

Synopsis
--------

```raku
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
```

Description
-----------

[LibXML::EntityRef](https://libxml-raku.github.io/LibXML-raku/EntityRef) objects represent entities in a document. These may be either a predefined entity such as `&lt;` or `&gt`, or a reference to an entity defined in an internal or external Dtd.

In the latter case, the entity may contain one child node, which is a link back to the entity declaration in the Dtd, of type [LibXML::Dtd::Entity](https://libxml-raku.github.io/LibXML-raku/Dtd/Entity).

