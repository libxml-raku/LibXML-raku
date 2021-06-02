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
```

