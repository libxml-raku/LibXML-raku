[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [SAX](https://libxml-raku.github.io/LibXML-raku/SAX)
 :: [Handler](https://libxml-raku.github.io/LibXML-raku/SAX/Handler)
 :: [SAX2](https://libxml-raku.github.io/LibXML-raku/SAX/Handler/SAX2)

class LibXML::SAX::Handler::SAX2
--------------------------------

a base class that provides a full set of SAX2 callbacks

Description
-----------

SAX2 is at the very heart of LibXML DOM construction. The standard SAX2 callbacks are what are used to constructed a DOM.

[LibXML::SAX::Handler::SAX2](https://libxml-raku.github.io/LibXML-raku/SAX/Handler/SAX2) is a base class that provides access to LibXML's standard SAX2 callbacks. You may want to inherit from it if you wish to modify or intercept LibXML's standard callbacks, but do not want to completely replace them.

If the handler is acting as a filter, it should at some point redispatch via 'callsame()', 'nextsame()', etc, if the parsed item is to be retained.

### Available SAX Callbacks

#### method startDocument

    method startDocument(
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Called when the document starts being processed.

#### method endDocument

    method endDocument(
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Called when the document end has been detected.

#### method internalSubset

    method internalSubset(
        Str $name,                # the root element name
        Str :$external-id         # the external ID
        Str :$system-id           # the system ID (e.g. filename or URL)
    )

Callback on internal subset declaration

#### method externalSubset

    method externalSubset(
        Str $name,                # the root element name
        Str :$external-id         # the external ID
        Str :$system-id           # the system ID (e.g. filename or URL)
    )

Callback on external subset declaration

#### method attributeDecl

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

#### method elementDecl

    method elementDecl(
        Str $name,	            # the element name
        xmlElementContent $content, # description of allowed content
        UInt :$type, 	            # the element type
    )

A DTD element definition has been parsed.

#### method entityDecl

    method entityDecl(
        Str $name,                # the entity name
        Str $content,             # the entity value
        UInt :$type,              # the entity type
        Str :$public-id           # the external ID
        Str :$system-id           # the system ID (e.g. filename or URL)
    )

A DTD entity definition has been parsed

#### method notationDecl

    method notationDecl(
        Str $name,                # the notation name
        Str :$public-id         # the external ID
        Str :$system-id           # the system ID (e.g. filename or URL)
    )

A DTD notation definition has been parsed

#### method startElement

    method startElement(
        Str $name,                # the element name
        :%attribs,                # cooked attributes
        CArray[Str] :$atts-raw,   # raw attributes as name-value pairs (null terminated)
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Called when an opening tag has been processed.

#### method endElement

    method endElement(
        Str $name,                # the element name
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Called when the end of an element has been detected.

#### method startElementNs

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

  * `name`

  * `prefix`

  * `key` - `name` or `name`:`prefix`

  * `URI`

  * value

#### method endElementNs

    method endElementNs(
        Str $local-name,          # the element name
        Str :$prefix,             # the element namespace prefix, if available
        Str :$uri,                # the element namespace name, if available
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Called when the end of an element has been detected. It provides the namespace information.

#### method characters

    method characters(
        Str $chars,               # the element name
        Str :$uri,                # the element namespace name, if available
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Receive some characters from the parser.

#### method cdataBlock

    method cdataBlock(
        Str $chars,               # the element name
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Receive a CDATA block from the parser.

#### method getEntity

    method getEntity(
        Str $name,                # the element name
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Get an entity's data

#### method processingInstruction

    method processingInstruction(
        Str $target,              # the target name
        Str $data,                # the PI data
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Get a processing instruction

#### method serror

    method serror(
        X::LibXML $error,         # the element name
    )

Handle a structured error from the parser.

#### method warning(Str $message)

    method warn(
        Str $message,
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Handle a warning message.

#### method error(Str $message)

    method error(
        Str $message,
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Handle an error message.

#### method fatalError(Str $message)

    method fatalError(
        Str $message,
        xmlParserCtxt :$ctx,      # the raw user data (XML parser context)
    )

Handle a fatal error message.

#### method publish

    method publish(
        LibXML::Document $doc
    ) returns Any:D

*Not part of the standard SAX interface*.

As well as the standard SAX2 callbacks (as described in [LibXML::SAX::Builder](https://libxml-raku.github.io/LibXML-raku/SAX/Builder)). There is a `publish()` method that returns the completed LibXML document.

The `publish()` can also be overridden to perform final document construction and possibly return non-LibXML document. See [LibXML::SAX::Handler::XML](https://libxml-raku.github.io/LibXML-raku/SAX/Handler/XML) for an example which uses SAX parsing but produces a pure Raku [XML](https://github.com/raku-community-modules/XML) document.

