#| DtD element content declaration (experimental)
unit class LibXML::Dtd::ElementContent;

use LibXML::Raw;
use LibXML::Enums;
use LibXML::Item :&box-class;
use NativeCall;

has $!decl; # element declaration (keep this alive to avoid GC)
submethod TWEAK(Any:D :$!decl) {}
has xmlElementContent $.raw is required handles<type occurs name prefix Str>;
method !visit(xmlElementContent $raw) {
    my constant MagicTopLevel = 1; # as set by LibXML on top-level declarations
    if $raw.defined && +nativecast(Pointer, $raw) != MagicTopLevel {
        $?CLASS.new: :$!decl, :$raw;
    }
    else {
        $?CLASS
    }
}
subset ElementDeclRef of  LibXML::Dtd::ElementContent where .type == XML_ELEMENT_CONTENT_ELEMENT;
subset ElementDeclNode of  LibXML::Dtd::ElementContent where .type ~~ XML_ELEMENT_CONTENT_SEQ|XML_ELEMENT_CONTENT_OR;
method getElementDecl(ElementDeclRef:D:) {
    my $elem-decl-class = box-class(XML_ELEMENT_DECL);
    with $!decl.raw.parent {
        # xmlElementDecl nodes should always have the Dtd as immediate parent
        my xmlDtd:D $dtd = .delegate;
        $elem-decl-class.box: $dtd.getElementDecl($.name);
    }
    else {
        $elem-decl-class;
    }
}
method content(ElementDeclRef:D:) {
    use trace;
    with $!decl.raw.parent {
        my xmlDtd:D $dtd = .delegate;
        my xmlElementDecl:D $decl = $dtd.getElementDecl($.name);
        my xmlElementContent:D $raw = $decl.content;
        self.new: :$raw, :$!decl;
    }
}
multi method gist(Any:D:) { $.Str }
method firstChild(ElementDeclNode:D:) {
    self!visit: $!raw.c1;
}
method secondChild(ElementDeclNode:D:) {
    self!visit: $!raw.c2;
}
method parent {
    self!visit: $!raw.parent;
}
method potential-children(UInt:D :$max = 255) {
    my CArray[Str] $buf .= new;
    my int32 $len = 0;
    $buf[$max] = Str;
    $!raw.PotentialChildren($buf, $len, $max);
    my @ = (0 ..^ $len).map: {$buf[$_]}
}

=begin pod

=head2 Example

=begin code :lang<raku>
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
=end code

=head2 Description

This class describes element declaration content as a sub-tree.

=head2 Methods

=head3 type

Returns `XML_ELEMENT_TYPE_EMPTY`, `XML_ELEMENT_TYPE_ANY`,
`XML_ELEMENT_TYPE_MIXED`, or `XML_ELEMENT_TYPE_ELEMENT`.

=head3 occurs

Returns `XML_ELEMENT_CONTENT_ONCE`, `XML_ELEMENT_CONTENT_OPT`(`?`),
`XML_ELEMENT_CONTENT_MULT`(`*`), or `XML_ELEMENT_CONTENT_PLUS`(`+`).

=head3 firstChild, secondChild
=begin code :lang<raku>
method firstChild returns LibXML::Dtd::ElementContent
method secondChild returns LibXML::Dtd::ElementContent
=end code
=para Returns the first and second children for a I<sequence>(`,`) or I<or>(`|`) expression.

=para Applicable to content types `XML_ELEMENT_CONTENT_SEQ`, and `XML_ELEMENT_CONTENT_OR`.

=head3 getElementDecl
=begin code :lang<raku>
method getElementDecl returns LibXML::Dtd::ElementDecl
=end code
Returns the element declaration for a node of type `XML_ELEMENT_CONTENT_ELEMENT`.

=head3 content
=begin code :lang<raku>
method content returns LibXML::Dtd::ElementContent
=end code
Returns child content for a node of type `XML_ELEMENT_CONTENT_ELEMENT`.

`$obj.content` is a shortcut for `$obj.getElementDecl.content`.

=head3 potential-children
=begin code :lang<raku>
method potential-children(UInt :$max = 255) returns Array
=end code
Returns an array (up to size `$max`) of names, summarizing possible content for the nodes and
its immediate children.

=head3 method prefix
=para Returns a namespace prefix, if any.

=end pod
