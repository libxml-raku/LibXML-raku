#| LibXML DtD Element declaration introspection (experimental)
unit class LibXML::Dtd::ElementDecl;

use LibXML::Node;
use LibXML::Raw;
use LibXML::_Rawish;

also is LibXML::Node;
also does LibXML::_Rawish[xmlElementDecl, <etype prefix>];

use LibXML::Dtd::AttrDecl;
use LibXML::Dtd::ElementContent;
use LibXML::Enums;
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

proto method box(|) {*}
multi method box(anyNode $_) {
    !.defined || .delegate.etype == XML_ELEMENT_TYPE_UNDEFINED
        ?? self.WHAT
        !! nextsame();
}
multi method box($, anyNode) { nextsame }

#| return the parsed content expression for this element declaration
method content(LibXML::Dtd::ElementDecl:D: --> LibXML::Dtd::ElementContent) {
    self.create: LibXML::Dtd::ElementContent, :decl(self), :raw($.raw.content)
}

#| return a read-only list of attribute declarations
method properties returns Array[LibXML::Dtd::AttrDecl] {
    my xmlAttrDecl $att = $.raw.attributes;
    my LibXML::Dtd::AttrDecl @props;
    while $att.defined {
        @props.push: self.box(LibXML::Node, $att);
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

method keys {
    my @props = @.properties.map: { '@' ~ .nodeName };
    @props.append: $.content.potential-children;
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
