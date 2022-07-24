#| LibXML DtD Element attribute declaration introspection (experimental)
unit class LibXML::Dtd::AttrDecl;

use LibXML::Node;
use LibXML::Raw;
use LibXML::_Rawish;

also is LibXML::Node;
also does LibXML::_Rawish[xmlAttrDecl, <prefix defaultValue>];

use LibXML::Enums;
use LibXML::Item :&box-class;
use NativeCall;

method new(|) { fail ::?CLASS.^name ~ " cannot be directly instantiated" }

method attrType returns UInt { $.raw.atype }
method defaultMode returns UInt { $.raw.def }
method elemName returns Str { $.raw.elem }

method values {
    with $.raw.values -> $cur is copy {
        my @values;
        while $cur.defined {
            @values.push: $cur.value;
            $cur .= next;
        }
        @values;
    }
    else {
        Array;
    }
}

method getElementDecl(Any:D:) {
    my $elem-decl-class = box-class(XML_ELEMENT_DECL);
    with $.raw.parent {
        # xmlAttrDecl nodes should always have the Dtd as immediate parent
        my xmlDtd:D $dtd = .delegate;
        $elem-decl-class.box: $dtd.getElementDecl($.elemName);
    }
    else {
        $elem-decl-class;
    }
}


=begin pod
=head3 Example
=begin code
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
=end code

=head2 Methods

=head3 AttrType

Returns the attribute, type. One of: `XML_ATTRIBUTE_CDATA`,
    `XML_ATTRIBUTE_ID`,
    `XML_ATTRIBUTE_IDREF`,
    `XML_ATTRIBUTE_IDREFS`,
    `XML_ATTRIBUTE_ENTITY`,
    `XML_ATTRIBUTE_ENTITIES`,
    `XML_ATTRIBUTE_NMTOKEN`,
    `XML_ATTRIBUTE_NMTOKENS`,
    `XML_ATTRIBUTE_ENUMERATION`,
    or `XML_ATTRIBUTE_NOTATION`.

=head3 defaultMode

Returns the default mode, of of: `XML_ATTRIBUTE_NONE`,
    `XML_ATTRIBUTE_REQUIRED`,
    `XML_ATTRIBUTE_IMPLIED`,
    or `XML_ATTRIBUTE_FIXED`.

=head3 defaultValue returns Str

Returns the default value, if any.

=head3 enum
=begin code
method values returns Array
say $attr-decl.values; # [a b c]
=end code
Returns an array of possible values, or Array:U , if there is no enumerations.

This method is applicable to enumerated attributes (AttrType `XML_ATTRIBUTE_ENUMERATION`).

=head3 elemName
=para Returns the name of the element holding the attribute.

=head3 getElementDecl
=begin code :lang<raku>
method getElementDecl() returns LibXML::Dtd::ElementDecl
=end code
=para Returns the element declaration associated with this attribute.

=head3 prefix
=para Returns the namespace prefix, if any.
=end pod
