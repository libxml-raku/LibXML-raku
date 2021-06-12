[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [Dtd](https://libxml-raku.github.io/LibXML-raku/Dtd)
 :: [ElementContent](https://libxml-raku.github.io/LibXML-raku/Dtd/ElementContent)

class LibXML::Dtd::ElementContent
---------------------------------

DtD element content declaration (experimental)

Example
-------

```raku
use LibXML::Dtd;
use LibXML::Dtd::ElementContent;
use LibXML::Dtd::ElementDecl;
use LibXML::Enums;

my $string = "example/ProductCatalog.dtd".IO.slurp;
my LibXML::Dtd $dtd .= parse: :$string;

my LibXML::Dtd::ElementContent:D $product = .content
    given $dtd.element-declarations<Product>;

say $product.Str; # (Specifications+ , Options? , Price+ , Notes?)
say xmlElementContentType($product.type);   # XML_ELEMENT_CONTENT_SEQ
say xmlElementContentOccur($product.occurs); # XML_ELEMENT_CONTENT_ONCE
say $product.potential-children; # [Specifications Options Price Notes]

my $specs = $product.firstChild;
say $specs.Str; # Specifications+
say xmlElementContentType($specs.type);   # XML_ELEMENT_CONTENT_ELEMENT
say xmlElementContentOccur($specs.occurs); # XML_ELEMENT_CONTENT_PLUS
my LibXML::Dtd::ElementDecl:D $specs-decl = $specs.getElementDecl;
say $specs-decl.Str;          # <!ELEMENT Specifications (#PCDATA)>
say $specs-decl.content.Str;  # #PCDATA

my $rest = $product.secondChild;
say $rest.Str; # (Options? , Price+ , Notes?)
say xmlElementContentType($rest.type);   # XML_ELEMENT_CONTENT_SEQ
say xmlElementContentOccur($rest.occurs); # XML_ELEMENT_CONTENT_ONE
```

Description
-----------

This class describes element declaration content as a sub-tree.

Methods
-------

### type

Returns `XML_ELEMENT_TYPE_EMPTY`, `XML_ELEMENT_TYPE_ANY`, `XML_ELEMENT_TYPE_MIXED`, or `XML_ELEMENT_TYPE_ELEMENT`.

### occurs

Returns `XML_ELEMENT_CONTENT_ONCE`, `XML_ELEMENT_CONTENT_OPT`(`?`), `XML_ELEMENT_CONTENT_MULT`(`*`), or `XML_ELEMENT_CONTENT_PLUS`(`+`).

### firstChild, secondChild

```raku
method firstChild returns LibXML::Dtd::ElementContent
method secondChild returns LibXML::Dtd::ElementContent
```

Returns the first and second children for a *sequence*(`,`) or *or*(`|`) expression.

Applicable to content types `XML_ELEMENT_CONTENT_SEQ`, and `XML_ELEMENT_CONTENT_OR`.

### getElementDecl

```raku
method getElementDecl returns LibXML::Dtd::ElementDecl
```

Returns the element declaration for a node of type `XML_ELEMENT_CONTENT_ELEMENT`.

### content

```raku
method content returns LibXML::Dtd::ElementContent
```

Returns child content for a node of type `XML_ELEMENT_CONTENT_ELEMENT`.

`$obj.content` is a shortcut for `$obj.getElementDecl.content`.

### potential-children(

```raku
method potential-children(UInt :$max = 255) returns Array
```

Returns an array (up to size `$max`) of names, summarizing possible content for the nodes and its immediate children.

