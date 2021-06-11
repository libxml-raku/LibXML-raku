#| DtD element content declration (experimental)
unit class LibXML::Dtd::ElementContent;

use LibXML::Raw;
use LibXML::Enums;
use LibXML::Item :&box-class;
use NativeCall;

has $!decl; # element declaration (keep this alive)
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
subset ElementDeclRef of  LibXML::Dtd::ElementContent where .type == XML_ELEMENT_CONTENT_ELEMENT;
method getElementDecl(ElementDeclRef:D:) {
    my $elem-decl-class = box-class(XML_ELEMENT_DECL);
    with  $!decl.raw.parent {
        # xmlElementDecl nodes should always have the Dtd as immediate parent
        my xmlDtd:D $dtd = .delegate;
        $elem-decl-class.box: $dtd.getElementDecl($.name);
    }
    else {
        $elem-decl-class;
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

