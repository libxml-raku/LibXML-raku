# a base class that provides a full set of SAX2 callbacks
use LibXML::SAX::Handler;

my role SAX2BaseClass {
    # implement methods that call LibXML2's default SAX2 handlers,
    # so that callsame(), etc will invoke them
    use LibXML::Types :QName, :NCName;
    use LibXML::Raw;
    use NativeCall;

    my constant Ctx = xmlParserCtxt;

    method setDocumentLocator(xmlSAXLocator $locator, Ctx :$ctx!) returns Bool {
        ? $ctx.xmlSAX2SetDocumentLocator($locator);
    }

    method isStandalone(Ctx :$ctx!) returns Bool {
        ? $ctx.xmlSAX2IsStandalone;
    }

    method startDocument(Ctx :$ctx!) {
        $ctx.xmlSAX2StartDocument;
    }

    method endDocument(Ctx :$ctx!) {
        $ctx.xmlSAX2EndDocument;
    }

    method startElement(QName:D $name, CArray :$atts-raw!, Ctx :$ctx!) {
        $ctx.xmlSAX2StartElement($name, $atts-raw);
    }

    method endElement(QName:D $name, Ctx :$ctx!) {
        $ctx.xmlSAX2EndElement($name);
    }

    method externalSubset(Str:D $name, Ctx :$ctx!, Str :$external-id, Str :$system-id) {
        $ctx.xmlSAX2ExternalSubset($name, $external-id, $system-id);
    }

    method internalSubset(Str:D $name, Ctx :$ctx!, Str :$external-id, Str :$system-id) {
        $ctx.xmlSAX2InternalSubset($name, $external-id, $system-id);
    }

    method startElementNs($local-name, Str :$prefix!, Str :$uri!, UInt :$num-namespaces!, CArray :$namespaces!, UInt :$num-atts!, UInt :$num-defaulted!, CArray :$atts-raw!, Ctx :$ctx!) {
        $ctx.xmlSAX2StartElementNs($local-name, $prefix, $uri, $num-namespaces, $namespaces, $num-atts, $num-defaulted, $atts-raw);
    }

    method endElementNs($local-name, Str :$prefix, Str :$uri, Ctx :$ctx!) {
        $ctx.xmlSAX2EndElementNs($local-name, $prefix, $uri);
    }

    method characters(Str $chars, Ctx :$ctx!) {
        my Blob $buf = $chars.encode;
        $ctx.xmlSAX2Characters($buf, +$buf);
    }

    method processingInstruction(Str $target, Str $data, Ctx :$ctx!) {
        $ctx.xmlSAX2ProcessingInstruction($target, $data);
    }

    method cdataBlock(Str $chars, Ctx :$ctx!) {
        my Blob $buf = $chars.encode;
        $ctx.xmlSAX2CDataBlock($buf, +$buf);
    }

    method getEntity(Str $name, Ctx :$ctx!) {
        $ctx.xmlSAX2GetEntity($name);
    }

    method entityDecl(Str $name, Str $content, Ctx :$ctx!, Int :$type, Str :$public-id, Str :$system-id) {
        $ctx.xmlSAX2EntityDecl($name, $type, $public-id, $system-id, $content);
    }

    method elementDecl(Str $name, xmlElementContent $content, Ctx :$ctx!, Int :$type) {
        $ctx.xmlSAX2ElementDecl($name, $type, $content);
    }

    method reference(Str:D $text, Ctx :$ctx! ) {
        $ctx.xmlSAX2Reference($text);
    }

    method attributeDecl($elem, $fullname, :$ctx!, :$type, :$def, :$default-value, :$tree) {
        $ctx.xmlSAX2AttributeDecl($elem, $fullname, $type, $def, $default-value, $tree);
    }

    method unparsedEntityDecl($name, :$ctx!, :$public-id, :$system-id, :$notation-name) {
        $ctx.xmlSAX2UnparsedEntityDecl($name, $public-id, $system-id, $notation-name);
    }

    method notationDecl($name, :$ctx!, :$public-id, :$system-id) {
        $ctx.xmlSAX2NotationDecl($name, $public-id, $system-id);
    }

    method comment(Str:D $text, Ctx :$ctx! ) {
        $ctx.xmlSAX2Comment($text);
    }

    # unimplmented callbacks
    method error(|) {die &?BLOCK.name ~ " SAX callback nyi"}
    method fatalError(|) {die &?BLOCK.name ~ " SAX callback nyi"}
    method getParameterEntity(|) {die &?BLOCK.name ~ " SAX callback nyi"}
    method hasExternalSubset(|) {die &?BLOCK.name ~ " SAX callback nyi"}
    method hasInternalSubset(|) {die &?BLOCK.name ~ " SAX callback nyi"}
    method ignorableWhitespace(|) {die &?BLOCK.name ~ " SAX callback nyi"}
    method warning(|) {die &?BLOCK.name ~ " SAX callback nyi"}
}

class LibXML::SAX::Handler::SAX2
    is LibXML::SAX::Handler
    does SAX2BaseClass {
    use LibXML::SAX::Handler::SAX2::Locator;
    has LibXML::SAX::Handler::SAX2::Locator $.locator handles<line-number column-number> .= new;

    use LibXML::Document;
    use LibXML::DocumentFragment;

    multi method publish(LibXML::Document $doc!) {
        $doc;
    }
    multi method publish(LibXML::DocumentFragment $doc!) {
        $doc;
    }

}

=begin pod

=head2 Description

SAX2 is at the very heart of LibXML DOM construction. The standard SAX2 callbacks are what are used to constructed a DOM.

L<LibXML::SAX::Handler::SAX2> is a base class that provides access to LibXML's standard SAX2 callbacks. You may want to inherit from it if you wish to modify or intercept LibXML's standard callbacks, but do not want to completely replace them.

If the handler is acting as a filter, it should at some point redispatch via 'callsame()', 'nextsame()', etc, if the parsed item is to be retained.

=head3 Available SAX Callbacks

=head4 method startDocument

  method startDocument(
      xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
  )

Called when the document starts being processed.

=head4 method endDocument

    method endDocument(
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Called when the document end has been detected.

=head4 method internalSubset

    method internalSubset(
        Str $name,                # the root element name
        Str :$external-id         # the external ID
        Str :$system-id           # the system ID (e.g. filename or URL)
    )

Callback on internal subset declaration

=head4 method externalSubset

    method externalSubset(
        Str $name,                # the root element name
        Str :$external-id         # the external ID
        Str :$system-id           # the system ID (e.g. filename or URL)
    )

Callback on external subset declaration

=head4 method attributeDecl

    method attributeDecl(
        Str $elem,                # the name of the element
        Str $name,	          # the attribute name
        UInt :$type,              # the attribute type
        UInt :$def, 	          # the type of default value
        Str  :$default-value,     # the attribute default value
        Uint :$tree,              # the tree of enumerated value set
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

A DTD attribute definition has been parsed.

=head4 method elementDecl

    method elementDecl(
        Str $name,	            # the element name
        xmlElementContent $content, # description of allowed content
        UInt :$type, 	            # the element type
    )

A DTD element definition has been parsed.

=head4 method entityDecl

    method entityDecl(
        Str $name,                # the entity name
        Str $content,             # the entity value
        UInt :$type,              # the entity type
        Str :$public-id           # the external ID
        Str :$system-id           # the system ID (e.g. filename or URL)
    )

A DTD entity definition has been parsed

=head4 method notationDecl

    method notationDecl(
        Str $name,                # the notation name
        Str :$public-id         # the external ID
        Str :$system-id           # the system ID (e.g. filename or URL)
    )

A DTD notation definition has been parsed

=head4 method startElement

    method startElement(
        Str $name,                # the element name
        :%attribs,                # cooked attributes
        CArray[Str] :$atts-raw,   # raw attributes as name-value pairs (null terminated)
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Called when an opening tag has been processed.

=head4 method endElement

    method endElement(
        Str $name,                # the element name
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Called when the end of an element has been detected.

=head4 method startElementNs

    use LibXML::SAX::Builder :NsAtt;
    method startElementNs(
        Str $local-name,          # the local name of the element
        Str :$prefix,             # the element namespace prefix, if available
        NsAtt :%attribs,          # cooked attributes
        Str :$uri,                # the element namespace name, if available
        UInt :$num-namespaces,    # number of namespace definitions on that node
        CArray[Str] :$namespaces, # raw namespaces as name-value pairs
        CArray[Str] :$atts-raw,   # raw attributes as name-value pairs
        UInt :$num-attributes,    # the number of attributes on that node
        UInt :$num-defaulted,     # the number of defaulted attributes. These are at the end of the array
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

SAX2 callback when an element start has been detected by the parser. It provides the namespace informations for the element, as well as the new namespace declarations on the element.

`:%attribs` values are of type `NsAtt` which has the following accessors:

=item `name`
=item `prefix`
=item `key` - `name` or `name`:`prefix`
=item `URI`
=item value

=head4 method endElementNs

    method endElementNs(
        Str $local-name,          # the element name
        Str :$prefix,             # the element namespace prefix, if available
        Str :$uri,                # the element namespace name, if available
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Called when the end of an element has been detected. It provides the namespace information.

=head4 method characters

    method characters(
        Str $chars,               # the element name
        Str :$uri,                # the element namespace name, if available
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Receive some characters from the parser.

=head4 method cdataBlock

    method cdataBlock(
        Str $chars,               # the element name
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Receive a CDATA block from the parser.

=head4 method getEntity

    method getEntity(
        Str $name,                # the element name
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Get an entity's data

=head4 method processingInstruction

  method processingInstruction(
      Str $target,              # the target name
      Str $data,                # the PI data
      xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
  )

Get a processing instruction

=head4 method serror

    method serror(
        X::LibXML $error,         # the element name
    )

Handle a structured error from the parser.

=head4 method warning(Str $message)

    method warn(
        Str $message,
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Handle a warning message.

=head4 method error(Str $message)

    method error(
        Str $message,
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Handle an error message.

=head4 method fatalError(Str $message)

    method fatalError(
        Str $message,
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Handle a fatal error message.

=head4 method publish

    method publish(
        LibXML::Document $doc
    ) returns Any:D

I<Not part of the standard SAX interface>.

As well as the standard SAX2 callbacks (as described in L<LibXML::SAX::Builder>). There is a `publish()` method that returns the completed LibXML document.

The `publish()` can also be overridden to perform final document construction and possibly return non-LibXML document. See L<LibXML::SAX::Handler::XML> for an example which uses SAX parsing but produces a pure Raku L<XML> document.

=end pod
