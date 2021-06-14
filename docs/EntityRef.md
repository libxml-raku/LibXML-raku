[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [EntityRef](https://libxml-raku.github.io/LibXML-raku/EntityRef)

class LibXML::EntityRef
-----------------------

Entity Reference nodes

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

Description
-----------

[LibXML::EntityRef](https://libxml-raku.github.io/LibXML-raku/EntityRef) objects represent entities in a document. These may be either a predefined entity such as `&lt;` or `&gt`, or a reference to an entity defined in an internal or external Dtd.

In the latter case, the entity may contain one child node, which is a link back to the entity declaration in the Dtd, of type [LibXML::Dtd::Entity](https://libxml-raku.github.io/LibXML-raku/Dtd/Entity).

