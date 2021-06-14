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
use LibXML::Dtd::Entity;
use LibXML::Enums;

my $string = q:to<END>;
<!ENTITY foo "Fooo">
END

my LibXML::Dtd $dtd .= parse: :$string;
my LibXML::Dtd::Entity $ent = $dtd.entities<foo>;

note $ent.name; # foo
note $ent.value; # Fooo
say xmlEntityType($ent.entityType); # XML_INTERNAL_GENERAL_ENTITY
note $ent.Str; # <!ENTITY foo "Foo ">
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

