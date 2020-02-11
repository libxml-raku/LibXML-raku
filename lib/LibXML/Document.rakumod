use v6;
use LibXML::Node :output-options;
use LibXML::_DOMNode;

unit class LibXML::Document
    is LibXML::Node
    does LibXML::_DOMNode;

use LibXML::Attr;
use LibXML::Config;
use LibXML::Dtd;
use LibXML::Element;
use LibXML::EntityRef;
use LibXML::Enums;
use LibXML::Item :ast-to-xml, :item-class;
use LibXML::Native;
use LibXML::Parser::Context;
use LibXML::PI;
use LibXML::Types :QName, :NCName;
use Method::Also;
use NativeCall;

subset XML  is export(:XML)  of LibXML::Document:D where .nodeType == XML_DOCUMENT_NODE;
subset HTML is export(:HTML) of LibXML::Document:D where .nodeType == XML_HTML_DOCUMENT_NODE;
subset DOCB is export(:DOCB) of LibXML::Document:D where .nodeType == XML_DOCB_DOCUMENT_NODE;

enum XmlStandalone is export(:XmlStandalone) (
    XmlStandaloneYes => 1,
    XmlStandaloneNo => 0,
    XmlStandaloneMu => -1,
);

constant config = LibXML::Config;
has LibXML::Parser::Context $.ctx handles <wellFormed valid>;
has LibXML::Element $!docElem;

method native handles <encoding setCompression getCompression standalone URI> {
    callsame() // xmlDoc
}
method doc { self }
method input-compressed {
    with self.?ctx.native.?input.?buf.compressed {
        $_ != 0
    } else {
        Mu
    };
}
submethod TWEAK(
                Str  :$version,
                xmlEncodingStr :$enc,
                Str  :$URI,
                Bool :$html,
                Int  :$compression,
) {
    my xmlDoc:D $struct = self.native
        // self.set-native: ($html ?? htmlDoc !! xmlDoc).new;

    $struct.version = $_ with $version;
    $struct.encoding = $_ with $enc;
    $struct.URI = $_ with $URI;
    $struct.setCompression($_) with $compression;
}

method version is rw {
    Proxy.new(
        FETCH => { Version.new($.native.version) },
        STORE => -> $, Str() $_ {
            $.native.version = Version.new($_).Str;
    });
}

method compression is rw {
    Proxy.new(
        FETCH => { $.getCompression },
        STORE => -> $, UInt() $_ { $.setCompression($_) }
    );
}

# DOM Methods

multi method createElement(QName $name, Str:D :$href!) {
    $.createElementNS($href, $name);
}
multi method createElement(QName $name) {
    LibXML::Element.box: $.native.createElement($name);
}
method createElementNS(Str:D $href, QName:D $name) {
    LibXML::Element.box: $.native.createElementNS($href, $name);
}

method !check-new-node($node, |) {
   if $node ~~ LibXML::Element {
       die "Document already has a root element"
           with $.documentElement;
   }
}

# don't allow more than one element in the document root
method appendChild(LibXML::Node:D $node)    { self!check-new-node($node); nextsame; }
method addChild(LibXML::Node:D $node)       { self!check-new-node($node); nextsame; }
method insertBefore(LibXML::Node:D $node, LibXML::Node $) { self!check-new-node($node); nextsame; }
method insertAfter(LibXML::Node:D $node, LibXML::Node $)  { self!check-new-node($node); nextsame; }

method importNode(LibXML::Node:D $node) {
    given $.native.importNode($node.native) {
        LibXML::Node.box($_, :doc(self));
    }
}
method adoptNode(LibXML::Node:D $node)  {
    given $.native.adoptNode($node.native) {
        LibXML::Node.box($_, :doc(self));
    }
}

method getDocumentElement {
    with $.native.getDocumentElement {
        $!docElem = LibXML::Element.box($_)
             unless $!docElem.defined && $!docElem.native.isSameNode($_);
    }
    else {
        $!docElem = LibXML::Element;
    }
    $!docElem;
}
method setDocumentElement(LibXML::Element $!docElem) {
    $!docElem.setOwnerDocument(self);
    self.native.setDocumentElement($!docElem.native);
    $!docElem;
}
method documentElement is rw is also<root> {
    Proxy.new(
        FETCH => sub ($) {
            self.getDocumentElement;
        },
        STORE => sub ($, LibXML::Node $elem) {
            self.setDocumentElement($elem);
        }
    );
}

method from-ast($_) {
    my $node = ast-to-xml($_);
    $node .= root if $node ~~ LibXML::Document;
    self.setDocumentElement($node);
}

my subset NameVal of Pair where .key ~~ QName:D && .value ~~ Str:D;
multi method createAttribute(NameVal $_!, |c) {
    $.createAttribute(.key, .value, |c);
}

multi method createAttribute(QName:D $name,
                       Str $value = '',
                       Str :$href,
                      ) {
    with $href {
        $.createAttributeNS($_, $name, $value);
    }
    else {
        LibXML::Attr.box: $.native.createAttribute($name, $value);
    }
}

multi method createAttributeNS(Str $href, NameVal $_!, |c) {
    $.createAttributeNS($href, .key, .value, |c);
}
multi method createAttributeNS(Str $href,
                         QName:D $name,
                         Str $value = '',
                        ) {
    LibXML::Attr.box: $.native.createAttributeNS($href, $name, $value);
}

multi method createDocument(Str() $version, xmlEncodingStr $enc) {
    self.new: :$version, :$enc;
}
multi method createDocument(Str $URI? is copy, QName $name?, Str $doc-type?, Str :URI($uri), *%opt) {
    $URI //= $uri;
    my $doc = self.new: :$URI, |%opt;
    with $name {
        my LibXML::Node:D $elem = $doc.createElementNS($URI, $_);
        $doc.setDocumentElement($elem);
    }
    $doc.setExternalSubset($_) with $doc-type;
    $doc;
}

method createDocumentFragment() {
    item-class('LibXML::DocumentFragment').new: :doc(self);
}

method createTextNode(Str $content) {
    item-class('LibXML::Text').new: :doc(self), :$content;
}

method createComment(Str $content) {
    item-class('LibXML::Comment').new: :doc(self), :$content;
}

method createCDATASection(Str $content) {
    item-class('LibXML::CDATA').new: :doc(self), :$content;
}

method createEntityReference(Str $name) {
    item-class('LibXML::EntityRef').new: :doc(self), :$name;
}

proto method createPI(|) is also<createProcessingInstruction> {*}
multi method createPI(NameVal $_!, |c) {
    $.createPI(.key, .value, |c);
}
multi method createPI(NCName $name, Str $content?) {
    LibXML::PI.new: :doc(self), :$name, :$content;
}

method insertProcessingInstruction(|c) {
    my LibXML::PI:D $pi = $.createPI(|c);
    with $.documentElement -> $root {
        # this is actually not correct, but i guess it's what the user
        # intends
        $.insertBefore( $pi, $root );
    }
    else {
        # if no documentElement was found we just append the PI
        $.appendChild( $pi );
    }

}

method createExternalSubset(Str $name, Str $external-id, Str $system-id) {
    LibXML::Dtd.new: :doc(self), :type<external>, :$name, :$external-id, :$system-id;
}

method createInternalSubset(Str $name, Str $external-id, Str $system-id) {
    LibXML::Dtd.new: :doc(self), :type<internal>, :$name, :$external-id, :$system-id;
}

method createDTD(Str $name, Str $external-id, Str $system-id) {
    LibXML::Dtd.new: :$name, :$external-id, :$system-id, :type<external>;
}

method getInternalSubset {
    LibXML::Dtd.box: self.native.getInternalSubset;
}

method setInternalSubset(LibXML::Dtd $dtd) {
    self.native.setInternalSubset: $dtd.native;
}

method removeInternalSubset {
    LibXML::Dtd.box: self.native.removeInternalSubset;
}

method indexElements { $.native.IndexElements }

method setURI(Str $uri) { self.URI = $_ }
method actualEncoding { $.encoding || 'UTF-8' }
method setEncoding(xmlEncodingStr $enc) { $.encoding = $enc }
method setStandalone(Numeric $_) {
    $.native.standalone = .defined
        ?? ($_ == 0 ?? XmlStandaloneYes !!  XmlStandaloneNo)
        !! XmlStandaloneMu
}

method internalSubset is rw {
    Proxy.new( FETCH => sub ($) { self.getInternalSubset },
               STORE => sub ($, LibXML::Dtd $dtd) {
                     self.setInternalSubset($dtd);
                 }
             );
}

method getExternalSubset {
    LibXML::Dtd.box: self.native.getExternalSubset;
}

method setExternalSubset(LibXML::Dtd $dtd) {
    self.native.setExternalSubset: $dtd.native;
}

method removeExternalSubset {
    LibXML::Dtd.box: self.native.removeExternalSubset;
}

method externalSubset is rw {
    Proxy.new( FETCH => sub ($) { self.getExternalSubset },
               STORE => sub ($, LibXML::Dtd $dtd) {
                     self.setExternalSubset($dtd);
                 }
             );
}

method getElementById(Str:D $id --> LibXML::Node) is also< getElementsById> {
    LibXML::Node.box: self.native.getElementById($id);
}

method validate(LibXML::Dtd $dtd?, Bool :$check --> Bool) {
    my LibXML::Dtd::ValidContext $valid-ctx .= new;
    $valid-ctx.validate(:doc(self), :$dtd, :$check);
}
method is-valid(|c) { $.validate(:check, |c); }

method parser handles<parse> { require ::('LibXML::Parser'); }

method processXIncludes(|c) is also<process-xincludes> {
    self.parser.new.processXIncludes(self, :$!ctx, |c);
}

method serialize-html(Bool :$format = True) {
    my buf8 $buf;

    given self.native -> xmlDoc:D $_ {
        my htmlDoc:D $html-doc = nativecast(htmlDoc, $_);
        $html-doc.dump(:$format);
    }
}

method Str(Bool :$skip-dtd = config.skip-dtd, Bool :$html = $.native.isa(htmlDoc), |c --> Str) {
    my Str $rv;

    with self.native -> xmlDoc:D $doc {

        my $skipped-dtd = $doc.getInternalSubset
            if $skip-dtd;

        with $skipped-dtd {
            $doc.lock;
            .Unlink;
        }

        $rv := $html
            ?? self.serialize-html(|c)
            !! callwith(|c);

        with $skipped-dtd {
            $doc.setInternalSubset($_);
            $doc.unlock;
        }
    }

    $rv;
}

method Blob(Bool() :$skip-decl = config.skip-xml-declaration,
            Bool() :$skip-dtd =  config.skip-dtd,
            xmlEncodingStr:D :$enc is copy = self.encoding // 'UTF-8',
            |c  --> Blob) {

    my Blob $rv;

    if $skip-decl {
        # losing the declaration that encludes the encoding scheme; we need
        # to switch to UTF-8 (default encoding) to stay conformant.
        $enc = 'UTF-8';
    }

    with self.native -> xmlDoc:D $doc {

        my $skipped-dtd = $doc.getInternalSubset
            if $skip-dtd;

        with $skipped-dtd {
            $doc.lock;
            .Unlink;
        }

        $rv := callwith(:$enc, :$skip-decl, |c);

        with $skipped-dtd {
            $doc.setInternalSubset($_);
            $doc.unlock;
        }
    }

    $rv;
}

method write(Str() :$file!, Bool :$format = False) {
    my UInt $n = self.native.write($file, :$format);
    fail "unable to save as xml: $file" if $n < 0;
    $n;
}

method save-as(Str() $file) { $.write(:$file) }

=begin pod
=head1 NAME

LibXML::Document - LibXML DOM Document Class

=head1 SYNOPSIS



  use LibXML::Document;
  # Only methods specific to Document nodes are listed here,
  # see the LibXML::Node documentation for other methods

  my LibXML::Document $doc  .= new: :$version, :$enc;
  $doc .= createDocument($version, $enc);
  $doc .= parse($string);

  my Str $URI = $doc.URI();
  $doc.setURI($URI);
  my Str $enc = $doc.encoding();
  $enc = $doc.actualEncoding();
  $doc.encoding = $new-encoding;
  my Version $doc-version = $doc.version();
  use LibXML::Document :XmlStandalone;
  if $doc.standalone == XmlStandaloneYes {...}
  $doc.standalone = XmlStandaloneNo;
  my Bool $is-compressed = $doc.input-compressed;
  my Int $zip-level = 5; # zip-level (0..9), or -1 for no compression
  $doc.compression = $zip-level;
  my Str $html-tidy = $dom.Str(:$format, :$html);
  my Str $xml-c14n = $doc.Str: :C14N, :$comments, :$xpath, :$exclusive, :$selector;
  my Str $xml-tidy = $doc.serialize(:$format);
  my Int $state = $doc.write: :$file, :$format;
  $state = $doc.save: :io($fh), :$format;
  my Str $html = $doc.Str(:html);
  $html = $doc.serialize-html();
  try { $dom.validate(); }
  if $dom.is-valid() { ... }

  my LibXML::Element $root = $dom.documentElement();
  $dom.documentElement = $root;
  my LibXML::Element $element = $dom.createElement( $nodename );
  $element = $dom.createElementNS( $namespaceURI, $nodename );
  my LibXML::Text $text = $dom.createTextNode( $content_text );
  my LibXML::Comment $comment = $dom.createComment( $comment_text );
  my LibXML::Attr $attr = $doc.createAttribute($name [,$value]);
  $attr = $doc.createAttributeNS( namespaceURI, $name [,$value] );
  my LibXML::DocumentFragment $fragment = $doc.createDocumentFragment();
  my LibXML::CDATA $cdata = $dom.createCDATASection( $cdata_content );
  my LibXML::PI $pi = $doc.createProcessingInstruction( $target, $data );
  my LibXML::EntityRef $entref = $doc.createEntityReference($refname);
  my LibXML::Dtd $dtd = $doc.createInternalSubset( $rootnode, $public, $system);
  $dtd = $doc.createExternalSubset( $rootnode_name, $publicId, $systemId);
  $doc.importNode( $node );
  $doc.adoptNode( $node );
  $dtd = $doc.externalSubset;
  $dtd = $doc.internalSubset;
  $doc.externalSubset = $dtd;
  $doc.internalSubset = $dtd;
  $dtd = $doc.removeExternalSubset();
  $dtd = $doc.removeInternalSubset();
  my LibXML::Element @found = $doc.getElementsByTagName($tagname);
  @found = $doc.getElementsByTagNameNS($nsURI,$tagname);
  @found = $doc.getElementsByLocalName($localname);
  my LibXML::Element $node = $doc.getElementById($id);
  $doc.indexElements();

=head1 DESCRIPTION

The Document Class is in most cases the result of a parsing process. But
sometimes it is necessary to create a Document from scratch. The DOM Document
Class provides functions that conform to the DOM Core naming style.

It inherits all functions from L<<<<<< LibXML::Node >>>>>> as specified in the DOM specification. This enables access to the nodes besides
the root element on document level - a C<<<<<< DTD >>>>>> for example. The support for these nodes is limited at the moment.

=head1 METHODS

Many functions listed here are extensively documented in the DOM Level 3 specification (L<<<<<< http://www.w3.org/TR/DOM-Level-3-Core/ >>>>>>). Please refer to the specification for extensive documentation.

=begin item
new

  my LibXML::Document $dom .= new;

=end item

=begin item
createDocument

  my LibXML::Document $dom .= createDocument( $version, $encoding );

DOM-style constructor for the document class. As parameters it takes the version
string and (optionally) the encoding string. Simply calling I<<<<<< createDocument >>>>>>() will create the document:



  <?xml version="your version" encoding="your encoding"?>

Both parameters are optional. The default value for I<<<<<< $version >>>>>> is C<<<<<< 1.0 >>>>>>, of course. If the I<<<<<< $encoding >>>>>> parameter is not set, the encoding will be left unset, which means UTF-8 is
implied.

The call of I<<<<<< createDocument >>>>>>() without any parameter will result the following code:



  <?xml version="1.0"?>

Alternatively one can call this constructor directly from the LibXML class
level, to avoid some typing. This will not have any effect on the class
instance, which is always LibXML::Document.



  my LibXML::Document $document = LibXML.createDocument( "1.0", "UTF-8" );

is therefore equivalent to:



  my LibXML::Document $document .= createDocument( "1.0", "UTF-8" );
=end item

=begin item
parse

   my LibXML::Document $doc .= parse($string, |%opts);

   Calling C<LibXML::Document.parse(|c)> is equivalent to calling C<LibXML.parse(|c)>; See the parse method in L<LibXML>.

=end item

=begin item
URI

  my Str $URI = $doc.URI();
  $doc.URI = $URI;

Gets or sets the URI (or filename) of the original document. For documents obtained
by parsing a string of a FH without using the URI parsing argument of the
corresponding C<<<<<< parse_* >>>>>> function, the result is a generated string unknown-XYZ where XYZ is some
number; for documents created with the constructor C<<<<<< new >>>>>>, the URI is undefined.

=end item

=begin item
encoding

    my Str $enc = $doc.encoding();
    $doc.encoding = $new-encoding;

Gets or sets the encoding of the document.

=item The `.Str` method treats the encoding as a subset. Any characters that fall outside the encoding set are encoded as entities (e.g. `&nbsp;`)
=item The `.Blob` method will fully render the XML document in as a Blob with the specified encoding.
  =begin code
  my $doc = LibXML.createDocument( "1.0", "ISO-8859-15" );
  print $doc.encoding; # prints ISO-8859-15
  my $xml-with-entities = $doc.Str;
  'encoded.xml'.IO.spurt( $doc.Blob, :bin);
  =end code
=end item


=begin item
  actualEncoding

  my Str $enc = $doc.actualEncoding();

returns the encoding in which the XML will be output by $doc.Blob() or $doc.write.
This is usually the original encoding of the document as declared in the XML
declaration and returned by $doc.encoding. If the original encoding is not
known (e.g. if created in memory or parsed from a XML without a declared
encoding), 'UTF-8' is returned.


  my $doc = LibXML.createDocument( "1.0", "ISO-8859-15" );
  print $doc.encoding; # prints ISO-8859-15

=end item


=begin item
version

  my Version $v = $doc.version();

returns the version of the document

I<<<<<< getVersion() >>>>>> is an alternative getter function.

=end item


=begin item
standalone

  use LibXML::Document :XmlStandalone;
  if $doc.standalone == XmlStandaloneYes { ... }

This function returns the Numerical value of a documents XML declarations
standalone attribute. It returns I<<<<<< 1 (XmlStandaloneYes) >>>>>> if standalone="yes" was found, I<<<<<< 0 (XmlStandaloneNo) >>>>>> if standalone="no" was found and I<<<<<< -1 (XmlStandaloneMu) >>>>>> if standalone was not specified (default on creation).
=end item



=begin item
setStandalone

  use LibXML::Document :XmlStandalone;
  $doc.setStandalone(XmlStandaloneYes);

Through this method it is possible to alter the value of a documents standalone
attribute. Set it to I<<<<<< 1 (XmlStandaloneYes) >>>>>> to set standalone="yes", to I<<<<<< 0 (XmlStandaloneNo) >>>>>> to set standalone="no" or set it to I<<<<<< -1 (XmlStandaloneMu) >>>>>> to remove the standalone attribute from the XML declaration.
=end item

=begin item
compression

  # input
  my LibXML::Document $doc .= :parse<mydoc.xml.gz>;
  my Bool $compressed = $doc.input-compressed;
  # output
  if LibXML.have-compression {
      $doc.compression = $zip-level;
      $doc.write: :file<test.xml.gz>;
  }
  else {
      $doc.write: :file<test.xml>;
  }

libxml2 allows reading of documents directly from gzipped files. The input-compressed
method returns True if the inpout file was compressed.

If one intends to write the document directly to a file, it is possible to set
the compression level for a given document. This level can be in the range from
0 to 8. If LibXML should not try to compress use I<<<<<< -1 >>>>>> (default).

Note that this feature will I<<<<<< only >>>>>> work if libxml2 is compiled with zlib support (`LibXML.have-compression` is True) ``and `.parse: :file(..._)` is used for input and `.write` is used for output.
=end item


=begin item
Str

  my Str $xml = $dom.Str(:$format);

I<<<<<< Str >>>>>> is a serializing function, so the DOM Tree is serialized into an XML
string, ready for output.


  $file.IO.spurt: $doc.Str;

regardless of the actual encoding of the document.

The optional I<<<<<< $format >>>>>> flage sets the indenting of the output.

If $format is False, or ommitted, the document is dumped as it was originally parsed

If $format is True, libxml2 will add ignorable white spaces, so the nodes content
is easier to read. Existing text nodes will not be altered

libxml2 uses a hard-coded indentation of 2 space characters per indentation
level. This value can not be altered on run-time.
=end item


=begin item
Str: :C14N

  my Str $xml-c14   = $doc.Str: :C14N, :$comment, :$xpath;
  my Str $xml-ec14n = $doc.Str: :C14N, :exclusive $xpath, :@prefix;

C14N Normalisation. See the documentation in L<<<<<< LibXML::Node >>>>>>.
=end item

=begin item
serialize

  my Str $xml-formatted = $doc.serialize(:$format);

An alias for Str(). This function was name added to be more consistent
with libxml2.
=end item


=begin item
write

  my Int $state = $doc.write: :$file, :$format;

This function is similar to Str(), but it writes the document directly
into a filesystem. This function is very useful, if one needs to store large
documents.

The format parameter has the same behaviour as in Str().
=end item


=begin item
Str: :html

  my Str $html = $document.Str: :html;

I<<<<<< .Str: :html >>>>>> serializes the tree to a byte string in the document encoding as HTML. With this
method indenting is automatic and managed by libxml2 internally.
=end item


=begin item
serialize-html

  my Str $html = $document.serialize-html();

Equilavent to: .Str: :html.
=end item


=begin item
is-valid

  my Bool $valid = $dom.is-valid();

Returns either True or False depending on whether the DOM Tree is a valid
Document or not.

You may also pass in a L<<<<<< LibXML::Dtd >>>>>> object, to validate against an external DTD:
=end item



  unless $dom.is-valid(:$dtd) {
       warn("document is not valid!");
   }


=begin item
validate

  $dom.validate();

This is an exception throwing equivalent of is_valid. If the document is not
valid it will throw an exception containing the error. This allows you much
better error reporting than simply is_valid or not.

Again, you may pass in a DTD object
=end item


=begin item
documentElement

  my LibXML::Element $root = $dom.documentElement();
  $dom.documentElement = $root;

Returns the root element of the Document. A document can have just one root
element to contain the documents data.

This function also enables you to set the root element for a document. The function
supports the import of a node from a different document tree, but does not
support a document fragment as $root.
=end item


=begin item
createElement

  my LibXML::Element $element = $dom.createElement( $nodename );

This function creates a new Element Node bound to the DOM with the name C<<<<<< $nodename >>>>>>.
=end item


=begin item
createElementNS

  my LibXML::Element $element = $dom.createElementNS( $namespaceURI, $nodename );

This function creates a new Element Node bound to the DOM with the name C<<<<<< $nodename >>>>>> and placed in the given namespace.
=end item


=begin item
createTextNode

  my LibXML::Text $text = $dom.createTextNode( $content_text );

As an equivalent of I<<<<<< createElement >>>>>>, but it creates a I<<<<<< Text Node >>>>>> bound to the DOM.
=end item

=begin item
createComment

  my LibXML::Comment $comment = $dom.createComment( $comment_text );

As an equivalent of I<<<<<< createElement >>>>>>, but it creates a I<<<<<< Comment Node >>>>>> bound to the DOM.
=end item


=begin item
createAttribute

  my LibXML::Attr $attrnode = $doc.createAttribute($name [,$value]);

Creates a new Attribute node.
=end item


=begin item
createAttributeNS

  my LibXML::Attr $attrnode = $doc.createAttributeNS( namespaceURI, $name [,$value] );

Creates an Attribute bound to a namespace.
=end item


=begin item
createDocumentFragment

  my LibXML::DocumentFragment $fragment = $doc.createDocumentFragment();

This function creates a DocumentFragment.
=end item


=begin item
createCDATASection

  my LibXML::CDATA $cdata = $dom.createCDATASection( $cdata_content );

Similar to createTextNode and createComment, this function creates a
CDataSection bound to the current DOM.
=end item


=begin item
createProcessingInstruction

  my LibXML::PI $pi = $doc.createProcessingInstruction( $target, $data );

create a processing instruction node.

Since this method is quite long one may use its short form I<<<<<< createPI() >>>>>>.
=end item


=begin item
createEntityReference

  my LibXML::EntityRef $entref = $doc.createEntityReference($refname);

If a document has a DTD specified, one can create entity references by using
this function. If one wants to add a entity reference to the document, this
reference has to be created by this function.

An entity reference is unique to a document and cannot be passed to other
documents as other nodes can be passed.

I<<<<<< NOTE: >>>>>> A text content containing something that looks like an entity reference, will
not be expanded to a real entity reference unless it is a predefined entity



  my Str $text = '&foo;';
  $some_element.appendText( $text );
  print $some_element.textContent; # prints "&amp;foo;"
=end item


=begin item
createInternalSubset

  my LibXML::Dtd
  $dtd = $doc.createInternalSubset( $rootnode, $public, $system);

This function creates and adds an internal subset to the given document.
Because the function automatically adds the DTD to the document there is no
need to add the created node explicitly to the document.



  my LibXML::Document $doc = LibXML::Document.new();
  my LibXML::Dtd $dtd = $doc.createInternalSubset( "foo", undef, "foo.dtd" );

will result in the following XML document:



  <?xml version="1.0"?>
   <!DOCTYPE foo SYSTEM "foo.dtd">

By setting the public parameter it is possible to set PUBLIC DTDs to a given
document. So



  my LibXML::Document $doc = LibXML::Document.new();
  my LibXML::Dtd $dtd = $doc.createInternalSubset( "foo", "-//FOO//DTD FOO 0.1//EN", undef );

will cause the following declaration to be created on the document:



  <?xml version="1.0"?>
  <!DOCTYPE foo PUBLIC "-//FOO//DTD FOO 0.1//EN">
=end item


=begin item
createExternalSubset

  $dtd = $doc.createExternalSubset( $rootnode_name, $publicId, $systemId);

This function is similar to C<<<<<< createInternalSubset() >>>>>> but this DTD is considered to be external and is therefore not added to the
document itself. Nevertheless it can be used for validation purposes.
=end item


=begin item
importNode

  $document.importNode( $node );

If a node is not part of a document, it can be imported to another document. As
specified in DOM Level 2 Specification the Node will not be altered or removed
from its original document (C<<<<<< $node.cloneNode(1) >>>>>> will get called implicitly).

I<<<<<< NOTE: >>>>>> Don't try to use importNode() to import sub-trees that contain an entity
reference - even if the entity reference is the root node of the sub-tree. This
will cause serious problems to your program. This is a limitation of libxml2
and not of LibXML itself.
=end item


=begin item
adoptNode

  $document.adoptNode( $node );

If a node is not part of a document, it can be imported to another document. As
specified in DOM Level 3 Specification the Node will not be altered but it will
removed from its original document.

After a document adopted a node, the node, its attributes and all its
descendants belong to the new document. Because the node does not belong to the
old document, it will be unlinked from its old location first.

I<<<<<< NOTE: >>>>>> Don't try to adoptNode() to import sub-trees that contain entity references -
even if the entity reference is the root node of the sub-tree. This will cause
serious problems to your program. This is a limitation of libxml2 and not of
LibXML itself.
=end item


=begin item
externalSubset

  my LibXML::Dtd $dtd = $doc.externalSubset;

If a document has an external subset defined it will be returned by this
function.

I<<<<<< NOTE >>>>>> Dtd nodes are no ordinary nodes in libxml2. The support for these nodes in
LibXML is still limited. In particular one may not want use common node
function on doctype declaration nodes!
=end item


=begin item
internalSubset

  my LibXML::Dtd $dtd = $doc.internalSubset;

If a document has an internal subset defined it will be returned by this
function.

I<<<<<< NOTE >>>>>> Dtd nodes are no ordinary nodes in libxml2. The support for these nodes in
LibXML is still limited. In particular one may not want use common node
function on doctype declaration nodes!
=end item


=begin item
setExternalSubset

  $doc.setExternalSubset($dtd);

I<<<<<< EXPERIMENTAL! >>>>>>

This method sets a DTD node as an external subset of the given document.
=end item


=begin item
setInternalSubset

  $doc.setInternalSubset($dtd);

I<<<<<< EXPERIMENTAL! >>>>>>

This method sets a DTD node as an internal subset of the given document.
=end item


=begin item
removeExternalSubset

  my $dtd = $doc.removeExternalSubset();

I<<<<<< EXPERIMENTAL! >>>>>>

If a document has an external subset defined it can be removed from the
document by using this function. The removed dtd node will be returned.
=end item


=begin item
removeInternalSubset

  my $dtd = $doc.removeInternalSubset();

I<<<<<< EXPERIMENTAL! >>>>>>

If a document has an internal subset defined it can be removed from the
document by using this function. The removed dtd node will be returned.
=end item


=begin item
getElementsByTagName

  my LibXML::Element @nodes = $doc.getElementsByTagName($tagname);
  my LibXML::Node::Set $nodes = $doc.getElementsByTagName($tagname);

Implements the DOM Level 2 function

=end item


=begin item
getElementsByTagNameNS

  my LibXML::Element @nodes = $doc.getElementsByTagNameNS($nsURI,$tagname);
  my LibXML::Node::Set $nodes = $doc.getElementsByTagNameNS($nsURI,$tagname);

Implements the DOM Level 2 function

=end item


=begin item
getElementsByLocalName

  my LibXML::Element @nodes = $doc.getElementsByLocalName($localname);
  my LibXML::Node::Set $nodes = $doc.getElementsByLocalName($localname);

This allows the fetching of all nodes from a given document with the given
Localname.

=end item


=begin item
getElementById

  my $node = $doc.getElementById($id);

Returns the element that has an ID attribute with the given value. If no such
element exists, this returns undef.

Note: the ID of an element may change while manipulating the document. For
documents with a DTD, the information about ID attributes is only available if
DTD loading/validation has been requested. For HTML documents parsed with the
HTML parser ID detection is done automatically. In XML documents, all "xml:id"
attributes are considered to be of type ID. You can test ID-ness of an
attribute node with $attr.isId().

In versions 1.59 and earlier this method was called getElementsById() (plural)
by mistake. Starting from 1.60 this name is maintained as an alias only for
backward compatibility.
=end item


=begin item
indexElements

  $dom.indexElements();

This function causes libxml2 to stamp all elements in a document with their
document position index which considerably speeds up XPath queries for large
documents. It should only be used with static documents that won't be further
changed by any DOM methods, because once a document is indexed, XPath will
always prefer the index to other methods of determining the document order of
nodes. XPath could therefore return improperly ordered node-lists when applied
on a document that has been changed after being indexed. It is of course
possible to use this method to re-index a modified document before using it
with XPath again. This function is not a part of the DOM specification.

This function returns number of elements indexed, -1 if error occurred, or -2
if this feature is not available in the running libxml2.
=end item


=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.


=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
