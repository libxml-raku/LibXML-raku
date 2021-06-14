[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [Dtd](https://libxml-raku.github.io/LibXML-raku/Dtd)
 :: [Entity](https://libxml-raku.github.io/LibXML-raku/Dtd/Entity)

class LibXML::Dtd::Entity
-------------------------

DtD entity definitions

Example
-------

```raku
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
```

### method publicId

```raku
method publicId() returns Str
```

return the Public (External) ID

### method systemId

```raku
method systemId() returns Str
```

Return the System ID

### method name

```raku
method name() returns Str
```

Return the entity name

### method notationName

```raku
method notationName() returns Mu
```

return the name of any notation associated with this entity

### method notation

```raku
method notation() returns LibXML::Dtd::Notation
```

return any notation associated with this entity

### method entityType

```raku
method entityType() returns Mu
```

return the entity type

One of: `XML_EXTERNAL_GENERAL_PARSED_ENTITY`, `XML_EXTERNAL_GENERAL_UNPARSED_ENTITY`, `XML_EXTERNAL_PARAMETER_ENTITY`, `XML_INTERNAL_GENERAL_ENTITY`, `XML_INTERNAL_PARAMETER_ENTITY`, or `XML_INTERNAL_PREDEFINED_ENTITY`

