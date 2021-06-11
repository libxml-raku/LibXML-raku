[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [Dtd](https://libxml-raku.github.io/LibXML-raku/Dtd)
 :: [ElementDecl](https://libxml-raku.github.io/LibXML-raku/Dtd/ElementDecl)

class LibXML::Dtd::ElementDecl
------------------------------

LibXML DtD Element declaration introspection (experimental)

Synopsis
--------

```raku
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
```

### method properties

```raku
method properties() returns Mu
```

return a read-only list of attribute declarations

for example:

```raku
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
```

Produces:

    <!ATTLIST A foo CDATA #IMPLIED>
    <!ATTLIST A bar CDATA #IMPLIED>

### method attributes

```raku
method attributes() returns Mu
```

return a read-only hash of attribute declarations

