use LibXML::Node;

#| LibXML DtD Element declaration introspection (experimental)
unit class LibXML::Dtd::ElementDecl
    is repr('CPointer')
    is LibXML::Node;

use LibXML::Dtd::AttrDecl;
use LibXML::Enums;
use LibXML::Raw;
use NativeCall;
use Method::Also;

=begin pod
=head2 Synopsis

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
note $note-decl.potential-children; # [to from heading body]
note $node-decl.attributes<id>.Str; # <!ATTLIST note id #IMPLIED>

=head2 Methods

=head3 potential-children(UInt :$max = 255)

=para Returns an array (up to size `$max`) of possible immediate child elements names, or '#PCDATA' if the element may have Text or CDATA content.

=end code
=end pod

class Content {
    has LibXML::Dtd::ElementDecl $!decl; # keep this alive
    submethod TWEAK(Any:D :$!decl) {}
    has xmlElementContent $.raw is required handles<type arity name prefix Str>;
    method !visit(xmlElementContent $raw) {
        my constant MagicTopLevel = 1; # as set by LibXML on top-level declarations
        if $raw.defined && +nativecast(Pointer, $raw) != MagicTopLevel {
            $?CLASS.new: :$!decl, :$raw;
        }
        else {
            $?CLASS
        }
    }
    subset ElementDeclRef of Content where .type == XML_ELEMENT_CONTENT_ELEMENT;
    method getElementDecl(ElementDeclRef:D: --> LibXML::Dtd::ElementDecl) {
        with  $!decl.raw.parent {
            # xmlElementDecl nodes should always have the Dtd as immediate parent
            my xmlDtd:D $dtd = .delegate;
            &?ROUTINE.returns.box: $dtd.getElementDecl($.name);
        }
        else {
            &?ROUTINE.returns;
        }
    }
    multi method gist(Any:D:) { $.Str }
    method firstChild {
        self!visit: $!raw.c1;
    }
    method secondChild {
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
}

method content(LibXML::Dtd::ElementDecl:D $decl:) {
    my xmlElementContent $raw = $decl.raw.content;
    Content.new: :$decl, :$raw;
}

#| return a read-only list of attribute declarations
method properties {
    my anyNode $att = $.raw.attributes;
    my LibXML::Dtd::AttrDecl @props;
    while $att.defined && $att.type == XML_ATTRIBUTE_DECL {
        @props.push: LibXML::Node.box($att);
        $att .= next;
    }
    @props;
}
=para for example:
=begin code :lang<raku>
use LibXML::Dtd;
my LibXML::Dtd $dtd .= parse: :string(q:to<X-X-X>);
  <!ELEMENT A ANY>
  <!ATTLIST A
    foo CDATA #IMPLIED
    bar CDATA #IMPLIED
  >
X-X-X

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

