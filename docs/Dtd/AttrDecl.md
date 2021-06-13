[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [Dtd](https://libxml-raku.github.io/LibXML-raku/Dtd)
 :: [AttrDecl](https://libxml-raku.github.io/LibXML-raku/Dtd/AttrDecl)

class LibXML::Dtd::AttrDecl
---------------------------

LibXML DtD Element attribute declaration introspection (experimental)

### Example

    use LibXML::Document;
    use LibXML::Dtd;
    use LibXML::Dtd::AttrDecl;
    use LibXML::Dtd::ElementDecl;
    my LibXML::Document $doc .= parse: :file<example/dtd.xml>;
    my LibXML::Dtd:D $dtd = $doc.getInternalSubset;
    my LibXML::Dtd::AttrDecl $doc-foo:attr-decl = $dtd.attribute-declarations<doc><foo>;
    # Element that contains the attribute declaration
    my LibXML::Dtd::ElementDecl $doc:elem-decl =  $doc-foo:attr-decl.getElementDecl;
    say xmlAttributeType($foo.attrType);
    say xmlAttributeDefault($foo.defaultMode);
    say $foo.elemName;
    say $foo.defaultValue;

Methods
-------

### AttrType

Returns the attribute, type. One of: `XML_ATTRIBUTE_CDATA`, `XML_ATTRIBUTE_ID`, `XML_ATTRIBUTE_IDREF`, `XML_ATTRIBUTE_IDREFS`, `XML_ATTRIBUTE_ENTITY`, `XML_ATTRIBUTE_ENTITIES`, `XML_ATTRIBUTE_NMTOKEN`, `XML_ATTRIBUTE_NMTOKENS`, `XML_ATTRIBUTE_ENUMERATION`, or `XML_ATTRIBUTE_NOTATION`.

### defaultMode

Returns the default mode, of of: `XML_ATTRIBUTE_NONE`, `XML_ATTRIBUTE_REQUIRED`, `XML_ATTRIBUTE_IMPLIED`, or `XML_ATTRIBUTE_FIXED`.

### defaultValue returns Str

Returns the default value, if any.

### enum

    method values returns Array
    say $attr-decl.values; # [a b c]

Returns an array of possible values, or Array:U , if there is no enumerations.

This method is applicable to enumerated attributes (AttrType `XML_ATTRIBUTE_ENUMERATION`).

### elemName

Returns the element holding the attribute.

### prefix

Returns the namespace prefix, if any.

