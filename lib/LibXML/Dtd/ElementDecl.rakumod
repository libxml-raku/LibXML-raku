use LibXML::Node :&iterate-list;

#| LibXML DtD Element declaration introspection (experimental)
unit class LibXML::Dtd::ElementDecl
    is repr('CPointer')
    is LibXML::Node;

use LibXML::Dtd::AttrDecl;
use LibXML::Enums;
use LibXML::Raw;
use NativeCall;

method new(|) { fail }
method raw { nativecast(xmlElementDecl, self) }

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

=end code
=end pod
