use LibXML::Node;
use LibXML::_ParentNode;
use W3C::DOM;

#| LibXML DOM Document Class
unit class LibXML::Document
    is LibXML::Node
    does LibXML::_ParentNode
    does W3C::DOM::Document;

use LibXML::Attr;
use LibXML::CDATA;
use LibXML::Config;
use LibXML::Comment;
use LibXML::DocumentFragment;
use LibXML::Dtd;
use LibXML::Dtd::Entity;
use LibXML::Element;
use LibXML::EntityRef;
use LibXML::Enums;
use LibXML::Item :dom-boxed;
use LibXML::Node :&output-options;
use LibXML::Raw;
use LibXML::PI;
use LibXML::Text;
use LibXML::Types :QName, :NCName, :NameVal;
use Method::Also;
use NativeCall;

=begin pod
    =head2 Synopsis

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
        my Str $html-tidy = $doc.Str: :$format, :$html;
        my Str $xml-c14n = $doc.Str: :C14N, :$comments, :$xpath, :$exclusive, :$selector;
        my Str $xml-tidy = $doc.serialize: :$format;
        my Int $state = $doc.write: :$file, :$format;
        $state = $doc.save: :io($fh), :$format;
        my Str $html = $doc.Str: :html;
        $html = $doc.serialize-html();
        try { $doc.validate(); }
        if $doc.is-valid() { ... }
        if $doc.is-valid($elem) { ... }

        my LibXML::Element $root = $doc.documentElement();
        $dom.documentElement = $root;
        my LibXML::Element $element = $doc.createElement( $nodename );
        $element = $doc.createElementNS( $namespaceURI, $nodename );
        my LibXML::Text $text = $doc.createTextNode( $content_text );
        my LibXML::Comment $comment = $doc.createComment( $comment_text );
        my LibXML::Attr $attr = $doc.createAttribute($name [,$value]);
        $attr = $doc.createAttributeNS( namespaceURI, $name [,$value] );
        my LibXML::DocumentFragment $fragment = $doc.createDocumentFragment();
        my LibXML::CDATA $cdata = $doc.createCDATASection( $cdata_content );
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

    =head2 Description

    The Document Class is in most cases the result of a parsing process. But
    sometimes it is necessary to create a Document from scratch. The DOM Document
    Class provides functions that conform to the DOM Core naming style.

    It inherits all functions from L<LibXML::Node> as specified in the DOM specification. This enables access to the nodes besides
    the root element on document level - a C<DTD> for example. The support for these nodes is limited at the moment.

=end pod

=begin pod  
    =head2 Exports

    =head3 XML

    A subset of LibXML::Document that have node-type C<XML_DOCUMENT_NODE>. General characteristics include:
    =item element and attribute names are case sensitive
    =item opening and closing tags must always be paired

    =head3 HTML

    A subset of LibXML::Document that have node-type C<XML_HTML_DOCUMENT_NODE>. General characteristics include:
    =item HTML Parsing converts element and attribute names to lowercase. Closing tags can usually be omitted.

    =head3 DOCB

    A subset of LibXML::Document that have node-type C<XML_DOCB_DOCUMENT_NODE>. XML documents of type DocBook
=end pod

subset XML  is export(:XML)  of LibXML::Document:D where .nodeType == XML_DOCUMENT_NODE;
subset HTML is export(:HTML) of LibXML::Document:D where .nodeType == XML_HTML_DOCUMENT_NODE;
subset DOCB is export(:DOCB) of LibXML::Document:D where .nodeType == XML_DOCB_DOCUMENT_NODE;

constant config = LibXML::Config;
constant InputCompressed = 1;

=begin pod
    =head2 Methods

    Many functions listed here are extensively documented in the DOM Level 3 specification (L<http://www.w3.org/TR/DOM-Level-3-Core/>). Please refer to the specification for extensive documentation.
=end pod

has xmlDoc $.raw;
method new(
    Str  :$version,
    xmlEncodingStr :$enc,
    Str  :$URI,
    Bool :$html,
    Int  :$compression,
    Bool :$input-compressed,
    xmlDoc :$raw = ($html ?? htmlDoc !! xmlDoc).new,
    # obselete
    :$ctx,
    :$native, # obselete,
    |c
) {
    die 'new(:$native) option is obselete. Please use :$raw'
        with $native;
    die 'new(:$ctx) option is obselete.' with $ctx;
    $raw.version = $_ with $version;
    $raw.encoding = $_ with $enc;
    $raw.URI = $_ with $URI;
    $raw.setCompression($_) with $compression;
    $raw.Reference;
    $raw.set-flags(InputCompressed)
        if $input-compressed;

    self.bless(:$raw, |c);
}
=begin pod
    =head3 method new

        method new(
          xmlDoc :$native,
          Str :$version,
          xmlEncodingStr :$enc, # e.g. 'utf-8', 'utf-16'
          Str :$URI,
          Bool :$html,
          Int :$compression
        ) returns LibXML::Document

=end pod

method implementation returns W3C::DOM::Implementation {
    require ::('LibXML');
}

# Perl compatibility
multi method createDocument(Str:D() $version where /^\d'.'\d$/, xmlEncodingStr $enc) {
    self.new: :$version, :$enc;
}

# DOM compatibility
multi method createDocument(Str $URI? is copy, QName $name?, W3C::DOM::DocumentType $dtd?, Str :URI($uri), *%opt) {
    $URI //= $uri;

    with $dtd {
        %opt<html> //= .is-XHTML;
    }
    my $doc = self.new: :$URI, |%opt;
    with $name {
        my LibXML::Node:D $elem = $doc.createElementNS($URI, $_);
        $doc.setDocumentElement($elem);
    }
    $doc.setInternalSubset($_) with $dtd;
    $doc;
}

=begin pod
    =head3 method createDocument

        multi method createDocument(Str() $version, xmlEncodingStr $enc
        ) returns LibXML::Document
        multi method createDocument(
             Str $URI?, QName $name?, Str $doc-type?
        )

    Raku or DOM-style constructors for the document class. As parameters it takes the version
    string and (optionally) the encoding string. Simply calling I<createDocument>() will create the document:
        =begin code :lang<xml>
        <?xml version="your version" encoding="your encoding"?>
        =end code
    Both parameters are optional. The default value for I<$version> is C<1.0>, of course. If the I<$encoding> parameter is not set, the encoding will be left unset, which means UTF-8 is
implied.

    The call of I<createDocument>() without any parameter will result the following code:
        =begin code :lang<xml>
        <?xml version="1.0"?>
        =end code
=end pod

method raw handles <encoding setCompression getCompression standalone URI wellFormed set-flags> {
    $!raw; # xmlDoc htmlDoc
}
=begin pod
    =head3 method URI

        my Str $URI = $doc.URI();
        $doc.URI = $URI;

    Gets or sets the URI (or filename) of the original document. For documents obtained
    by parsing a string of a FH without using the URI parsing argument of the
    corresponding C<parse_*> function, the result is a generated string unknown-XYZ where XYZ is some
    number; for documents created with the constructor C<new>, the URI is undefined.

    =head3 method encoding

        my Str $enc = $doc.encoding();
        $doc.encoding = $new-encoding;

    Gets or sets the encoding of the document.

    =item The `.Str` method treats the encoding as a subset. Any characters that fall outside the encoding set are encoded as entities (e.g. `&nbsp;`)
    =item The `.Blob` method will fully render the XML document in as a Blob with the specified encoding.

        my $doc = LibXML.createDocument( "1.0", "ISO-8859-15" );
        print $doc.encoding; # prints ISO-8859-15
        my $xml-with-entities = $doc.Str;
        'encoded.xml'.IO.spurt( $doc.Blob, :bin);

=end pod

method doc { self }

#| Returns the encoding in which the XML will be output by $doc.Blob() or $doc.write.
method actualEncoding returns xmlEncodingStr { $.encoding || 'UTF-8' }
=begin pod
    =para
    This is usually the original encoding of the document as declared in the XML
    declaration and returned by $doc.encoding. If the original encoding is not
    known (e.g. if created in memory or parsed from a XML without a declared
    encoding), 'UTF-8' is returned.

        my $doc = LibXML.createDocument( "1.0", "ISO-8859-15" );
        print $doc.encoding; # prints ISO-8859-15

=end pod

#| Gets or sets the version of the document
method version is rw returns Version {
    Proxy.new(
        FETCH => { Version.new($.raw.version) },
        STORE => -> $, Str() $_ {
            $.raw.version = Version.new($_).Str;
    });
}

enum XmlStandalone is export(:XmlStandalone) (
    XmlStandaloneYes => 1,
    XmlStandaloneNo => 0,
    XmlStandaloneMu => -1,
);

# standalone() is handled by native() method
=begin pod
    =head3 method standalone

        use LibXML::Document :XmlStandalone;
        if $doc.standalone == XmlStandaloneYes { ... }

    Gets or sets the Numerical value of a documents XML declarations
    standalone attribute.

    It returns
    =item I<1 (XmlStandaloneYes)> if standalone="yes" was found,
    =item I<0 (XmlStandaloneNo)> if standalone="no" was found and
    =item I<-1 (XmlStandaloneMu)> if standalone was not specified (default on creation).
=end pod

#| Alter the value of a documents standalone attribute.
method setStandalone(Numeric $_) {
    $.raw.standalone = .defined
        ?? $_
        !! XmlStandaloneMu
}
=begin pod

        use LibXML::Document :XmlStandalone;
        $doc.setStandalone(XmlStandaloneYes);

    =para Set it to
    =item I<1 (XmlStandaloneYes)> to set standalone="yes",
    =item to I<0 (XmlStandaloneNo)> to set standalone="no" or
    =item to I<-1 (XmlStandaloneMu)> to remove the standalone attribute from the XML declaration.
=end pod

#| Gets or sets output compression
method compression is rw returns Int {
    Proxy.new(
        FETCH => { $.getCompression },
        STORE => -> $, UInt() $_ { $.setCompression($_) }
    );
}

#| Detect whether input was compressed
method input-compressed returns Bool {
   ? ($.raw.get-flags +& InputCompressed);
}
=begin pod
    =begin code :lang<raku>
    my LibXML::Document $doc .= parse<mydoc.xml.gz>;
    if $doc.input-compressed {
        my $zip-level = 5;
        $doc.compression = $zip-level;
        $doc.write: :file<test.xml.gz>;
    }
    else {
        $doc.write: :file<test.xml>;
    }
    =end code
    =para libxml2 allows reading of documents directly from gzipped files. The input-compressed method returns True if the input file was compressed.

    If one intends to write the document directly to a file, it is possible to set
    the compression level for a given document. This level can be in the range from
    0 to 8. If LibXML should not try to compress use I<-1> (default).

    Note that this feature will I<only> work if libxml2 is compiled with zlib support (`LibXML.have-compression` is True) ``and `.parse: :file(...)` is used for input and `.write` is used for output.
=end pod

method Str(
    LibXML::Document:D $doc is copy:
    Bool :$skip-dtd = config.skip-dtd,
    Bool :$html = $.raw.isa(htmlDoc),
    Bool :$C14N,
    |c --> Str) {

    if $skip-dtd && $doc.getInternalSubset.defined {
        $doc .= cloneNode: :deep;
        $doc.getInternalSubset.unbindNode;
    }

    when $C14N { $doc.canonicalize(|c) }
    when $html { $doc.serialize-html(|c) }
    default { $doc.raw.Str: options => output-options(|c); }
}
=begin pod
    =head3 method Str

    =head4 multi `method Str(Bool :$skip-dtd, Bool :$html, Bool :$format)`;

    I<Str> is a serializing function, so the DOM Tree is serialized into an XML
    string, ready for output.

        $file.IO.spurt: $doc.Str;

    regardless of the actual encoding of the document.

    The optional I<$format> flag sets the indenting of the output.

    If $format is False, or omitted, the document is dumped as it was originally parsed

    If $format is True, libxml2 will add ignorable white spaces, so the nodes content
    is easier to read. Existing text nodes will not be altered

    libxml2 uses a hard-coded indentation of 2 space characters per indentation
    level. This value can not be altered on run-time.

    =head4 `multi method Str: :C14N($!)!, |c`

      my Str $xml-c14   = $doc.Str: :C14N, :$comment, :$xpath;
      my Str $xml-ec14n = $doc.Str: :C14N, :exclusive $xpath, :@prefix;

   C14N Normalisation. See the documentation in L<LibXML::Node>.

    =head4 `multi method Str: :$html!, |c`

      my Str $html = $document.Str: :html;

    I<.Str: :html> serializes the tree to a string as HTML. With this
    method indenting is automatic and managed by libxml2 internally.

    =head3 method serialize

        my Str $xml-formatted = $doc.serialize(:$format);

    Similar to Str(), but doesn't interpret `:skip-dtd`, `:html` or `:C14N` options. This function was name added to be more consistent
    with libxml2.
=end pod

#| Serialize to HTML.
method serialize-html(Bool :$format = True --> Str) {
    my buf8 $buf;

    given self.raw -> xmlDoc:D $_ {
        my htmlDoc:D $html-doc = nativecast(htmlDoc, $_);
        $html-doc.dump(:$format);
    }
}
=begin pod
    =para Equivalent to: .Str: :html, but doesn't allow `:skip-dtd` option.
=end pod

    method Blob(
        LibXML::Document:D $doc is copy:
        Bool() :$skip-xml-declaration is copy = config.skip-xml-declaration,
        Bool() :$skip-dtd = config.skip-dtd,
        xmlEncodingStr:D :$enc = self.encoding // 'UTF-8',
        Bool :$force,
        |c  --> Blob) {

    if $skip-xml-declaration {
        # losing the declaration that includes the encoding scheme; we need
        # to switch to UTF-8 (default encoding) to stay conformant.
        unless $force || $enc eq 'UTF-8' {
            warn "please use :force to allow :skip-xml-declaration for non-UTF-8 encoding '$enc'";
            $skip-xml-declaration = False;
        }
    }

    if $skip-dtd && $doc.getInternalSubset.defined {
        $doc .= cloneNode: :deep;
        $doc.getInternalSubset.unbindNode;
    }

    my $options = output-options(:$skip-xml-declaration, |c);
    $doc.raw.Blob: :$enc, :$options;
}
=begin pod
    =head3 method Blob() returns Blob

        method Blob(
            xmlEncodingStr :$enc = self.encoding // 'UTF-8',
            Bool :$format,
            Bool :$tag-expansion
            Bool :$skip-dtd,
            Bool :$skip-xml-declaration,
            Bool :$force,
        ) returns Blob;

    =para
    Returns a binary representation  of the XML
    document and it decendants encoded as `:$enc`.

    The option `:force` is needed to really allow the combination of
    a non-UTF8 encoding and :skip-xml-declaration.
=end pod

#| Write to a name file
method write(Str() :$file!, Bool :$format = False --> UInt) {
    my UInt $n = self.raw.write($file, :$format);
    fail "unable to save as xml: $file" if $n < 0;
    $n;
}

#| Write to a name file (equivalent to $.write: :$file)
method save-as(Str() $file --> UInt) { $.write(:$file) }

method is-valid(|c --> Bool) { $.validate(|c, :check); }
=begin pod
=head3 is-valid
=begin code :lang<raku>
multi method is-valid(LibXML::Dtd $dtd? --> Bool)
multi method is-valid(LibXML::Element $elem --> Bool)
multi method is-valid(LibXML::Element $elem, LibXML::Attr $attr)
=end code

Checks that the document, or a an element in the document, is valid. Returns either True or False.

Optionally accepts an element to check. The element may be at any level in the document, and is checked as a sub-tree in isolation.

You may also pass in a L<LibXML::Dtd> object, to validate the document against an external DTD:

    =begin code :lang<raku>
    unless $doc.is-valid(:$dtd) {
        warn("document is not valid!");
    }
    =end code

=end pod

#| Whether the document was valid when it was parsed
method was-valid returns Bool {
    ? ($.raw.properties +& XML_DOC_DTDVALID)
}
method valid is DEPRECATED<was-valid> { $.was-valid }

=head3 method validate
=begin code :lang<raku>
multi method validate(LibXML::Dtd $dtd?)
multi method validate(LibXML::Element $elem)
multi method validate(LibXML::Element $elem, LibXML::Attr $attr)
=end code
multi method validate($doc: Bool :$check --> Bool) is hidden-from-backtrace {
    my LibXML::Dtd::ValidContext $valid-ctx .= new;
    $valid-ctx.validate($doc, :$check);
}
multi method validate($doc: LibXML::Dtd $dtd, Bool :$check --> Bool) is hidden-from-backtrace {
    my LibXML::Dtd::ValidContext $valid-ctx .= new;
    $valid-ctx.validate($doc, :$dtd, :$check);
}
multi method validate($doc: LibXML::Element:D $elem, LibXML::Attr $attr?, Bool :$check --> Bool) is hidden-from-backtrace {
    my LibXML::Dtd::ValidContext $valid-ctx .= new;
    $valid-ctx.validate($elem, $attr, :$doc, :$check);
}

=begin pod
    =para Validates, either the entire document, or an individual element.
    =para
    This is an exception throwing equivalent of is-valid. If the document is not
    valid it will throw an exception containing the error.

    It is also possible to write: `$elem.validate` as a shortcut for `$elem.ownerDocument.validate($elem)` and `$elem.is-valid` as a shortcut for `$elem.ownerDocument.is-valid($elem)`
=end pod


#| Gets or sets the root element of the Document.
method documentElement is rw is also<root> returns LibXML::Element {
    Proxy.new(
        FETCH => sub ($) {
            self.getDocumentElement;
        },
        STORE => sub ($, LibXML::Node $elem) {
            self.setDocumentElement($elem);
        }
    );
}
=begin pod
    =para
    A document can have just one root element to contain the documents data.
    If the document resides in a different document tree, it is automatically imported.
=end pod

#| Creates a new Element Node bound to the DOM with the given tag (name), Optionally bound to a given name-space;
method createElement(QName $name, Str :$href --> LibXML::Element) {
    $href
    ?? $.createElementNS($href, $name)
    !! &?ROUTINE.returns.box: $.raw.createElement($name);
}

#| equivalent to .createElement($name, :$href)
method createElementNS(Str $href, QName:D $name --> LibXML::Element) {
    &?ROUTINE.returns.box: $.raw.createElementNS($href, $name);
}

method !check-new-node($node, |) {
   if $node ~~ LibXML::Element {
       die "Document already has a root element"
           with $.documentElement;
   }
}

multi method createAttribute(NameVal $_!, |c) {
    $.createAttribute(.key, .value, |c);
}

#| Creates a new Attribute node
multi method createAttribute(
    QName:D $qname,
    Str $value = '',
    Str :$href,
    --> LibXML::Attr
) {
    with $href {
        $.createAttributeNS($_, $qname, $value);
    }
    else {
        &?ROUTINE.returns.box: $.raw.createAttribute($qname, $value);
    }
}

multi method createAttributeNS(Str $href, NameVal $_!, |c) {
    $.createAttributeNS($href, .key, .value, |c);
}
#| Creates an Attribute bound to a name-space.
multi method createAttributeNS(Str $href,
                         QName:D $qname,
                         Str $value = '',
                         --> LibXML::Attr
                        ) {
    &?ROUTINE.returns.box: $.raw.createAttributeNS($href, $qname, $value);
}

#| Creates a Document Fragment
method createDocumentFragment($doc: --> LibXML::DocumentFragment) {
    &?ROUTINE.returns.new: :$doc;
}

#| Creates a Text Node bound to the DOM.
method createTextNode($doc: Str $content --> LibXML::Text) {
    &?ROUTINE.returns.new: :$doc, :$content;
}

#| Create a Comment Node bound to the DOM
method createComment($doc: Str $content --> LibXML::Comment) {
    &?ROUTINE.returns.new: :$doc, :$content;
}

#| Create a CData Section bound to the DOM
method createCDATASection($doc: Str $content --> LibXML::CDATA) {
    &?ROUTINE.returns.new: :$doc, :$content;
}

#| Creates an Entity Reference
method createEntityReference($doc: Str $name --> LibXML::EntityRef) {
    &?ROUTINE.returns.new: :$doc, :$name;
}
=begin pod
    =para
    If a document has a DTD specified, one can create entity references by using
    this function. If one wants to add a entity reference to the document, this
    reference has to be created by this function.

    An entity reference is unique to a document and cannot be passed to other
    documents as other nodes can be passed.

    I<NOTE:> A text content containing something that looks like an entity reference, will
    not be expanded to a real entity reference unless it is a predefined entity

        my Str $text = '&foo;';
        $some_element.appendText( $text );
        print $some_element.textContent; # prints "&amp;foo;"

=end pod

# (or createProcessingInstruction) create a processing instruction node.
proto method createPI(|) is also<createProcessingInstruction> {*}
multi method createPI(NameVal $_!, |c) {
    $.createPI(.key, .value, |c);
}
multi method createPI($doc: NCName $name, Str $content? --> LibXML::PI) {
    &?ROUTINE.returns.new: :$doc, :$name, :$content;
}

#| Creates a new external subset
method createExternalSubset($doc: Str $name, Str $external-id, Str $system-id --> LibXML::Dtd) {
    &?ROUTINE.returns.new: :$doc, :type<external>, :$name, :$external-id, :$system-id;
}
=para This function is similar to C<createInternalSubset()> but this DTD is considered to be external and is therefore not added to the
  document itself. Nevertheless it can be used for validation purposes.

#| Creates a new Internal Subset
method createInternalSubset($doc: Str $name, Str $external-id, Str $system-id --> LibXML::Dtd) {
    &?ROUTINE.returns.new: :$doc, :type<internal>, :$name, :$external-id, :$system-id;
}
=begin pod
    =head3 method createInternalSubset

        my LibXML::Dtd
        $dtd = $doc.createInternalSubset( $rootnode, $public, $system);

    This function creates and adds an internal subset to the given document.
    Because the function automatically adds the DTD to the document there is no
    need to add the created node explicitly to the document.

        my LibXML::Document $doc = LibXML::Document.new();
        my LibXML::Dtd $dtd = $doc.createInternalSubset( "foo", undef, "foo.dtd" );

    will result in the following XML document:
        =begin code :lang<xml>
        <?xml version="1.0"?>
        <!DOCTYPE foo SYSTEM "foo.dtd">
        =end code
    By setting the public parameter it is possible to set PUBLIC DTDs to a given
    document. So

        my LibXML::Document $doc = LibXML::Document.new();
        my LibXML::Dtd $dtd = $doc.createInternalSubset( "foo", "-//FOO//DTD FOO 0.1//EN", undef );

    will cause the following declaration to be created on the document:
        =begin code :lang<xml>
        <?xml version="1.0"?>
        <!DOCTYPE foo PUBLIC "-//FOO//DTD FOO 0.1//EN">
        =end code
=end pod

#| Create a new external DTD
method createDTD(Str $name, Str $external-id, Str $system-id --> LibXML::Dtd) {
    &?ROUTINE.returns.new: :$name, :$external-id, :$system-id, :type<external>;
}

#| Lookup an entity in the document
method getEntity(Str $name --> LibXML::Dtd::Entity) {
    &?ROUTINE.returns.box: $.raw.GetEntity($name);
}
=para Searches any internal subset, external subset, and predefined entities

# don't allow more than one element in the document root
method appendChild(LibXML::Node:D $node)    { self!check-new-node($node); nextsame; }
method addChild(LibXML::Node:D $node)       { self!check-new-node($node); nextsame; }
method insertBefore(LibXML::Node:D $node, LibXML::Node $) { self!check-new-node($node); nextsame; }
method insertAfter(LibXML::Node:D $node, LibXML::Node $)  { self!check-new-node($node); nextsame; }

#| Imports a node from another DOM
proto method importNode(LibXML::Node:D $node --> LibXML::Node) {*}
multi method importNode(LibXML::Document $) { fail "Can't import Document nodes" }
multi method importNode(LibXML::Node:D $node --> LibXML::Node) {
    &?ROUTINE.returns.box: $.raw.importNode($node.raw);
}
=para If a node is not part of a document, it can be imported to another document. As
    specified in DOM Level 2 Specification the Node will not be altered or removed
    from its original document (C<$node.cloneNode(:deep)> will get called implicitly).

#| Adopts a node from another DOM
proto method adoptNode(LibXML::Node:D $node --> LibXML::Node) {*}
multi method adoptNode(LibXML::Document $) { fail "Can't adopt Document nodes" }
multi method adoptNode(LibXML::Node:D $node --> LibXML::Node)  {
    $node.keep: $.raw.adoptNode($node.raw);
}
=para If a node is not part of a document, it can be adopted by another document. As
    specified in DOM Level 3 Specification the Node will not be altered but it will
    removed from its original document.
=para After a document adopted a node, the node, its attributes and all its
    descendants belong to the new document. Because the node does not belong to the
    old document, it will be unlinked from its old location first.
=para I<NOTE:> Don't try to use importNode() or adoptNode() to import sub-trees that contain entity references -
    even if the entity reference is the root node of the sub-tree. This will cause
    serious problems to your program. This is a limitation of libxml2 and not of
    LibXML itself.

#| DOM compatible method to get the document element
method getDocumentElement returns LibXML::Element {
        &?ROUTINE.returns.box:  $.raw.getDocumentElement
}

#| DOM compatible method to set the document element
method setDocumentElement($doc: LibXML::Element:D $elem --> LibXML::Element) {
    # Preempt libxml which unlinks, but doesn't free any current root element
    LibXML::Node.box($_).unbindNode
        with $.raw.getDocumentElement;

    $elem.setOwnerDocument($doc);
    self.raw.setDocumentElement($elem.raw);
    $elem;
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

method getInternalSubset(--> LibXML::Dtd) is dom-boxed is also<doctype> {...}

#|This method sets a DTD node as an internal subset of the given document.
method setInternalSubset(LibXML::Dtd:D $dtd is copy --> LibXML::Dtd) {
    with $dtd.raw.doc {
        $dtd .= clone unless .isSameNode($.raw);
    }
    $dtd.keep: self.raw.setInternalSubset: $dtd.raw;
}
=para Inserts a copy of the Dtd node into the document as its internal subset
    =begin code :lang<raku>
    my $new-dtd = $doc.setInternalSubset: $other-doc.getInternalSubset;
    =end code
=para Note: At this stage, only the `name`, `publicId` and `systemId` are copied.

=para This method is currently most useful for setting the document-type of an XML or HTML document:

=begin code :lang<raku>
use LibXML;
use LibXML::Dtd;
use LibXML::Document;
my $htmlPublic = "-//W3C//DTD XHTML 1.0 Transitional//EN";
my $htmlSystem = "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd";

my LibXML::Dtd:D $dtd = LibXML.createDocumentType('xhtml', $htmlPublic, $htmlSystem);
my Bool $html = $dtd.is-XHTML;
my LibXML::Document $doc .= new: :$html;
$doc.setInternalSubset: $dtd;
$doc.setDocumentElement: $doc.createElement('xhtml');
say $doc.Str;
# <!DOCTYPE xhtml PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
# <xhtml></xhtml>

=end code

#| This method removes an external, if defined, from the document
method removeInternalSubset(--> LibXML::Dtd) is dom-boxed {...}
=para If a document has an internal subset defined it can be removed from the
    document by using this function. The removed dtd node will be returned.

method setURI(Str $uri) { self.URI = $_ }
method setEncoding(xmlEncodingStr $enc) { $.encoding = $enc }

#| Gets or sets the internal DTD for the document.
method internalSubset is rw returns LibXML::Dtd {
    Proxy.new( FETCH => sub ($) { self.getInternalSubset },
               STORE => sub ($, LibXML::Dtd $dtd) {
                     self.setInternalSubset($dtd);
                 }
             );
}
=para I<NOTE> Dtd nodes are no ordinary nodes in libxml2. The support for these nodes in
    LibXML is still limited. In particular one may not want to use common node
    function on doctype declaration nodes!

method getExternalSubset(--> LibXML::Dtd) is dom-boxed {...}

#| This method sets a DTD node as an external subset of the given document.
method setExternalSubset(LibXML::Dtd $dtd is copy, Bool :$validate --> LibXML::Dtd) {
    with $dtd.raw.doc {
        $dtd .= clone unless .isSameNode($.raw);
    }

    if $validate && $dtd.defined {
        $dtd.validate(self);
    }
    $dtd.keep: self.raw.setExternalSubset: $dtd.raw;
}
=para I<EXPERIMENTAL!>
=para If the :validate option is passed, the document is first validated against the DTD.

#| This method removes any external subset from the document
method removeExternalSubset(--> LibXML::Dtd) is dom-boxed {...}
=para If a document has an external subset defined it can be removed from the
    document by using this function. The removed dtd node will be returned.

#| Gets or sets the external DTD for a document.
method externalSubset is rw returns LibXML::Dtd {
    Proxy.new( FETCH => sub ($) { self.getExternalSubset },
               STORE => sub ($, LibXML::Dtd $dtd) {
                     self.setExternalSubset($dtd);
                 }
             );
}
=para I<NOTE> Dtd nodes are no ordinary nodes in libxml2. The support for these nodes in
    LibXML is still limited. In particular one may not want use common node
    function on doctype declaration nodes!

method parser handles<parse> { require ::('LibXML::Parser'); }
=begin pod
    =head3 method parse

        my LibXML::Document $doc .= parse($string, |%opts);

    Calling C<LibXML::Document.parse(|c)> is equivalent to calling C<LibXML.parse(|c)>; See the parse method in L<LibXML>.
=end pod

#| Expand XInclude flags
method processXIncludes(|c) is also<process-xincludes> {
    self.parser.new.processXIncludes(self, |c);
}

=begin pod
    =head3 method getElementsByTagName

        my LibXML::Element @nodes = $doc.getElementsByTagName($tagname);
        my LibXML::Node::Set $nodes = $doc.getElementsByTagName($tagname);

    Implements the DOM Level 2 function

    =head3 method getElementsByTagNameNS

        my LibXML::Element @nodes = $doc.getElementsByTagNameNS($nsURI,$tagname);
        my LibXML::Node::Set $nodes = $doc.getElementsByTagNameNS($nsURI,$tagname);

    Implements the DOM Level 2 function

    =head3 method getElementsByLocalName

        my LibXML::Element @nodes = $doc.getElementsByLocalName($localname);
        my LibXML::Node::Set $nodes = $doc.getElementsByLocalName($localname);

    This allows the fetching of all nodes from a given document with the given
    Localname.
=end pod

#| Returns the element that has an ID attribute with the given value. If no such element exists, this returns LibXML::Element:U.
method getElementById(Str:D $id --> LibXML::Element) is also<getElementsById> {
   &?ROUTINE.returns.box: $.raw.getElementById($id);
}
=para Note: the ID of an element may change while manipulating the document. For
    documents with a DTD, the information about ID attributes is only available if
    DTD loading/validation has been requested. For HTML documents parsed with the
    HTML parser ID detection is done automatically. In XML documents, all "xml:id"
    attributes are considered to be of type ID. You can test ID-ness of an
    attribute node with $attr.isId().

#| Index elements for faster XPath searching
method indexElements returns Int { $.raw.IndexElements }
=para This function causes libxml2 to stamp all elements in a document with their
    document position index which considerably speeds up XPath queries for large
    documents. It should only be used with static documents that won't be further
    changed by any DOM methods, because once a document is indexed, XPath will
    always prefer the index to other methods of determining the document order of
    nodes. XPath could therefore return improperly ordered node-lists when applied
    on a document that has been changed after being indexed. It is of course
    possible to use this method to re-index a modified document before using it
    with XPath again. This function is not a part of the DOM specification.

=para This function returns the number of elements indexed, -1 if error occurred, or -2
    if this feature is not available in the running libxml2.


=begin pod
=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
