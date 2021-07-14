use LibXML::Node;

#| LibXML DtD Element declaration introspection (experimental)
unit class LibXML::Dtd::ElementDecl
    is repr('CPointer')
    is LibXML::Node;

use LibXML::Dtd::AttrDecl;
use LibXML::Dtd::ElementContent;
use LibXML::Enums;
use LibXML::Raw;
use NativeCall;
use Method::Also;

=begin pod
=head2 Example

=begin code :lang<raku>

use LibXML::Document;
use LibXML::Dtd;
use LibXML::HashMap;
use LibXML::Dtd::ElementDecl;

my $string = q:to<END>;
<!ELEMENT note (to,from,heading,body)>
<!ATTLIST note id CDATA #IMPLIED>
<!ELEMENT to (#PCDATA)>
<!ELEMENT from (#PCDATA)>
<!ELEMENT heading (#PCDATA)>
<!ELEMENT body (#PCDATA)>
END

my LibXML::Dtd $dtd .= parse: :$string;
my LibXML::HashMap[LibXML::Dtd::ElementDecl] $elements = $dtd.element-decls;

my LibXML::Dtd::ElementDecl $note-decl = $elements<note>;
note $note-decl.Str; # <!ELEMENT note (to,from,heading,body)>
note $note-decl.content.potential-children; # [to from heading body]
note $node-decl.attributes<id>.Str; # <!ATTLIST note id #IMPLIED>
=end code

=head2 Methods

=end pod

method box(anyNode $_) {
    !.defined || .delegate.etype == XML_ELEMENT_TYPE_UNDEFINED
        ?? self.WHAT
        !! nextsame();
}

#| return the parsed content expression for this element declaration
method content(LibXML::Dtd::ElementDecl:D $decl: --> LibXML::Dtd::ElementContent) {
    my xmlElementContent $raw = $decl.raw.content;
    LibXML::Dtd::ElementContent.new: :$decl, :$raw;
}

#| return a read-only list of attribute declarations
method properties returns Array[LibXML::Dtd::AttrDecl] {
    my xmlAttrDecl $att = $.raw.attributes;
    my LibXML::Dtd::AttrDecl @props;
    while $att.defined {
        @props.push: LibXML::Node.box($att);
        $att .= nexth;
    }
    @props;
}
=para for example:
=begin code :lang<raku>
use LibXML::Dtd;
my LibXML::Dtd $dtd .= parse: :string(q:to<END>);
  <!ELEMENT A ANY>
  <!ATTLIST A
    foo CDATA #IMPLIED
    bar CDATA #IMPLIED
  >
  END

my $A:decl = $dtd.element-declarations<A>;

for $A:decl.properties {
    print .Str;
}
=end code
=para Produces:
=begin code
<!ATTLIST A foo CDATA #IMPLIED>
<!ATTLIST A bar CDATA #IMPLIED>
=end code

#| return a read-only hash of attribute declarations
method attributes is also<attribs attr> {
    my % = @.properties.map: { .nodeName => $_ };
}
method new(|) { fail }
method raw handles <etype prefix> { nativecast(xmlElementDecl, self) }

method keys {
    my @k = @.properties.map: { '@' ~ .nodeName };
    @k.append: $.content.potential-children;
}
method values {
    my $dtd := self.parent;
    my @v := @.properties;
    @v.push: $dtd.getElementDeclaration($_)
        for $.content.potential-children;
    @v;
}
method pairs {
    my $dtd := self.parent;
    my @p = @.properties.map: { '@' ~ .nodeName => $_ };
    @p.push: ($_ => $dtd.getElementDeclaration($_))
        for $.content.potential-children;
    @p;
}
method Hash handles<AT-KEY> {
    my % = @.pairs
}

=begin pod
=head3 method prefix
=para Returns a namespace prefix, if any.
=end pod
