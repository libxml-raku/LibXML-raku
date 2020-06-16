class LibXML::Raw
-----------------

Bindings to the libxml2 library

Synopsis
--------

    do {
        # Create a document from scratch
        use LibXML::Raw;
        my xmlDoc:D $doc .= new;
        my xmlElem:D $root = $doc.new-node: :name<Hello>, :content<World!>;
        .Reference for $doc, $root;
        $doc.SetRootElement($root);
        say $doc.Str; # .. <Hello>World!</Hello>
        # unreference/destroy before we go out of scope
        .Unreference for $root, $doc;
    }

Description
-----------

The LibXML::Raw module contains class definitions for native and bindings to the LibXML2 library.

### Low level native access

Other high level classes, by convention, have a `raw()` accessor, which can be used, if needed, to gain access to native objects from this module.

Some care needs to be taken in keeping persistant references to raw structures.

The following is unsafe:

    my LibXML::Element $elem .= new: :name<Test>;
    my xmlElem:D $raw = $elem.raw;
    $elem = Nil;
    say $raw.Str; # could have been destroyed along with $elem

If the raw object supports the `Reference` and `Unreference` methods, the object can be reference counted and uncounted:

    my LibXML::Element $elem .= new: :name<Test>;
    my xmlElem:D $raw = $elem.raw;
    $raw.Reference; # add a reference to the object
    $elem = Nil;
    say $raw.Str; # now safe
    with $raw {
        .Unreference; # unreference, free if no more references
        $_ = Nil;
    }

Otherwise, the object can usually be copied. That copy then needs to be freed, to avoid memory leaks:

    my LibXML::Namespace $ns .= new: :prefix<foo>, :URI<http://foo.org>;
    my xmlNs:D $raw = $ns.raw;
    $raw .= Copy;
    $ns = Nil;
    say $raw.Str; # safe
    with $raw {
        .Free; # free the copy
        $_ = Nil;
    }

class LibXML::Raw::xmlAutomata
------------------------------

A libxml automata description, It can be compiled into a regexp

class LibXML::Raw::xmlAutomataState
-----------------------------------

A state int the automata description,

class LibXML::Raw::xmlBuffer32
------------------------------

old buffer struct limited to 32bit signed addressing (2Gb). xmlBuf is preferred, where available

class LibXML::Raw::xmlBuf
-------------------------

New buffer structure, introduced in libxml 2.09.00, the actual structure internals are not public

class LibXML::Raw::xmlEnumeration
---------------------------------

List structure used when there is an enumeration in DTDs.

class LibXML::Raw::xmlElementContent
------------------------------------

An XML Element content as stored after parsing an element definition in a DTD.

class LibXML::Raw::xmlLocationSet
---------------------------------

A Location Set

class LibXML::Raw::xmlParserInputDeallocate
-------------------------------------------

Callback for freeing some parser input allocations.

class LibXML::Raw::xmlParserNodeInfo
------------------------------------

The parser can be asked to collect Node informations, i.e. at what place in the file they were detected.

class LibXML::Raw::xmlXPathCompExpr
-----------------------------------

The structure of a compiled expression form is not public.

class LibXML::Raw::xmlPattern
-----------------------------

A compiled (XPath based) pattern to select nodes

class LibXML::Raw::xmlRegexp
----------------------------

A libxml regular expression, they can actually be far more complex thank the POSIX regex expressions.

class LibXML::Raw::xmlXIncludeCtxt
----------------------------------

An XInclude context

class LibXML::Raw::xmlXPathAxis
-------------------------------

A mapping of name to axis function

class LibXML::Raw::xmlXPathType
-------------------------------

A mapping of name to conversion function

class LibXML::Raw::xmlValidState
--------------------------------

Each xmlValidState represent the validation state associated to the set of nodes currently open from the document root to the current element.

class LibXML::Raw::xmlParserInput
---------------------------------

Each entity parsed is associated an xmlParserInput (except the few predefined ones).

class LibXML::Raw::xmlNs
------------------------

An XML namespace. Note that prefix == NULL is valid, it defines the default namespace within the subtree (until overridden).

class LibXML::Raw::xmlSAXLocator
--------------------------------

A SAX Locator.

class LibXML::Raw::xmlSAXHandler
--------------------------------

A SAX handler is bunch of callbacks called by the parser when processing of the input generate data or structure informations.

class LibXML::Raw::xmlError
---------------------------

An XML Error instance.

class LibXML::Raw::xmlXPathContext
----------------------------------

Expression evaluation occurs with respect to a context. the context consists of: - a node (the context node) - a node list (the context node list) - a set of variable bindings - a function library - the set of namespace declarations in scope for the expression

class LibXML::Raw::xmlXPathParserContext
----------------------------------------

An XPath parser context. It contains pure parsing informations, an xmlXPathContext, and the stack of objects.

class LibXML::Raw::xmlNode
--------------------------

A node in an XML tree.

class LibXML::Raw::xmlElem
--------------------------

xmlNode of type: XML_ELEMENT_NODE

class LibXML::Raw::xmlTextNode
------------------------------

xmlNode of type: XML_TEXT_NODE

class LibXML::Raw::xmlCommentNode
---------------------------------

xmlNode of type: XML_COMMENT_NODE

class LibXML::Raw::xmlCDataNode
-------------------------------

xmlNode of type: XML_CDATA_SECTION_NODE

class LibXML::Raw::xmlPINode
----------------------------

xmlNode of type: XML_PI_NODE

class LibXML::Raw::xmlEntityRefNode
-----------------------------------

xmlNode of type: XML_ENTITY_REF_NODE

class LibXML::Raw::xmlAttr
--------------------------

An attribute on an XML node (type: XML_ATTRIBUTE_NODE)

class LibXML::Raw::xmlDoc
-------------------------

An XML document (type: XML_DOCUMENT_NODE)

class LibXML::Raw::htmlDoc
--------------------------

xmlDoc of type: XML_HTML_DOCUMENT_NODE

class LibXML::Raw::xmlDocFrag
-----------------------------

xmlNode of type: XML_DOCUMENT_FRAG_NODE

class LibXML::Raw::xmlDtd
-------------------------

An XML DTD, as defined by <!DOCTYPE ... There is actually one for the internal subset and for the external subset (type: XML_DTD_NODE).

class LibXML::Raw::xmlAttrDecl
------------------------------

An Attribute declaration in a DTD (type: XML_ATTRIBUTE_DECL).

class LibXML::Raw::xmlEntity
----------------------------

An unit of storage for an entity, contains the string, the value and the data needed for the linking in the hash table (type: XML_ENTITY_DECL).

class LibXML::Raw::xmlElementDecl
---------------------------------

An XML Element declaration from a DTD (type: XML_ELEMENT_DECL).

class LibXML::Raw::xmlNodeSet
-----------------------------

A node-set (an unordered collection of nodes without duplicates)

class LibXML::Raw::xmlValidCtxt
-------------------------------

An xmlValidCtxt is used for error reporting when validating.

class LibXML::Raw::xmlParserCtxt
--------------------------------

The parser context.

class LibXML::Raw::xmlFileParserCtxt
------------------------------------

XML file parser context

class LibXML::Raw::xmlPushParserCtxt
------------------------------------

an incremental XML push parser context. Determines encoding and reads data in binary chunks

class LibXML::Raw::htmlParserCtxt
---------------------------------

a vanilla HTML parser context - can be used to read files or strings

class LibXML::Raw::htmlFileParserCtxt
-------------------------------------

HTML file parser context

class LibXML::Raw::htmlPushParserCtxt
-------------------------------------

an incremental HTMLpush parser context. Determines encoding and reads data in binary chunks

class LibXML::Raw::xmlMemoryParserCtxt
--------------------------------------

a parser context for an XML in-memory document.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

