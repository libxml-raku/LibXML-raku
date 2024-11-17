[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [Dtd](https://libxml-raku.github.io/LibXML-raku/Dtd)
 :: [Notation](https://libxml-raku.github.io/LibXML-raku/Dtd/Notation)

class LibXML::Dtd::Notation
---------------------------

LibXML DtD notations

### Example

```raku
use LibXML::Dtd;
use LibXML::Dtd::Notation;

my $string = q:to<END>;
<!NOTATION jpeg SYSTEM "image/jpeg">
<!NOTATION png SYSTEM "image/png">
<!ENTITY camelia-logo
         SYSTEM "https://www.raku.org/camelia-logo.png"
         NDATA png>
END

my LibXML::Dtd $dtd .= parse: :$string;
my LibXML::Dtd::Notation $notation = $dtd.notations<jpeg>;
$notation = $dtd.entities<camelia-logo>.notation;

say $notation.name;     # png
say $notation.systemId; # image/png
say $notation.Str;      # <!NOTATION png SYSTEM "image/png" >
```

### Description

Notation declarations are an older mechanism that is sometimes used in a DTD to qualify the data contained within an external entity (non-xml) file.

### method publicId

```raku
method publicId() returns Str
```

Return the Public (External) ID

### method systemId

```raku
method systemId() returns Str
```

Return the System ID

### method nodeName

```raku
method nodeName() returns Str
```

Return the entity name

