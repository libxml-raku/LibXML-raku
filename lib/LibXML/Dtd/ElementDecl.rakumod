use LibXML::Node :&iterate-list;

#| LibXML DtD Element declaration introspection (experimental)
unit class LibXML::Dtd::ElementDecl
    is repr('CPointer')
    is LibXML::Node;

use LibXML::Dtd::AttrDecl;
use LibXML::Enums;
use LibXML::Raw;
use NativeCall;

class Content {
    has LibXML::Dtd::ElementDecl $!decl; # keep this alive
    submethod TWEAK(Any:D :$!decl) {}
    has xmlElementContent $.raw is required handles<type arity name prefix Str>;
    method !visit(xmlElementContent $raw) {
        if $raw.defined {
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
    method gist { $.Str }
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

method new(|) { fail }
method raw handles <etype prefix> { nativecast(xmlElementDecl, self) }

=begin pod
=head2 Synopsis

=begin code :lang<raku>

use LibXML::Document;
use LibXML::Dtd;
use LibXML::HashMap;
use LibXML::Dtd::ElementDecl;

my $string = q:to<END>;
<?xml version="1.0"?>
<!DOCTYPE note [
<!ELEMENT note (to,from,heading,body)>
<!ELEMENT to (#PCDATA)>
<!ELEMENT from (#PCDATA)>
<!ELEMENT heading (#PCDATA)>
<!ELEMENT body (#PCDATA)>
]>
<note>
  <to>Tove</to>
  <from>Jani</from>
  <heading>Reminder</heading>
  <body>Don't forget me this weekend!</body>
</note>
END

my LibXML::Document $doc .= parse: :$string;
my LibXML::Dtd $dtd = $doc.getInternalSubset;
my LibXML::HashMap[LibXML::Dtd::ElementDecl] $elements = $dtd.element-decls;

my LibXML::Dtd::ElementDecl $note-decl = $elements<note>;
note $note-decl.Str; # <!ELEMENT note (to,from,heading,body)>
note $note-decl.potential-children; # [to from heading body]

=head2 Methods

=head3 potential-children(UInt :$max = 255)

=para Returns an array (up to size `$max`) of possible immediate child elements names, or '#PCDATA' if the element may have Text or CDATA content.

=end code
=end pod
