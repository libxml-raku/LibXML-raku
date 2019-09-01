NAME
====

LibXML::Native - bindings to the libxml2 library

SYNOPSIS
========

    do {
        # Create a document from scratch
        use LibXML::Native;
        my xmlDoc:D $doc .= new;
        my xmlElem:D $root = $doc.new-node: :name<Hello>, :content<World!>;
        .Reference for $doc, $root;
        $doc.SetRootElement($root);
        say $doc.Str; # .. <Hello>World!</Hello>
        # unreference/destroy before we go out of scope
        .Unreference for $root, $doc;
    }

DESCRIPTION
===========

The LibXML::Native module contains class definitions for native and bindings to the LibXML2 library.

Low level native access
-----------------------

Other high level classes, by convention, have a `native()` accessor, which can be used, if needed, to gain access to native objects from this module.

Some care needs to be taken in keeping persistant references to native structures.

The following is unsafe:

    my LibXML::Element $elem .= new: :name<Test>;
    my xmlElem:D $native = $elem.native;
    $elem = Nil;
    say $native.Str; # could have been destroyed along with $elem

If the native object supports the `Reference` and `Unreference` methods, the object can be reference counted:

    my LibXML::Element $elem .= new: :name<Test>;
    my xmlElem:D $native = $elem.native;
    $native.Reference; # add a reference tot he object
    $elem = Nil;
    say $native.Str; # now safe
    with $native {
        .Unreference; # unreference, free if no more references
        $_ = Nil;
    }

    Otherwise, the object can usually be copied. That copy then needs to be free, to avoid

memory leaks:

    my LibXML::Namespace $ns .= new: :prefix<foo>, :URI<http://foo.org>;
    my xmlNs:D $native = $ns.native;
     $native .= Copy;
     $ns = Nil;
     say $native.Str; # safe
     with $native {
         .Free; # free the copy
         $_ = Nil;
     }

class LibXML::Native::xmlAutomata
---------------------------------

A libxml automata description, It can be compiled into a regexp

class LibXML::Native::xmlAutomataState
--------------------------------------

A state int the automata description,

class LibXML::Native::xmlBuffer32
---------------------------------

old buffer struct limited to 32bit signed addressing (2Gb). Please use xmlBuf

class LibXML::Native::xmlBuf
----------------------------

New buffer structure, introduced in libxml 2.09.00, the actual structure internals are not public

class LibXML::Native::xmlEnumeration
------------------------------------

List structure used when there is an enumeration in DTDs.

class LibXML::Native::xmlElementContent
---------------------------------------

An XML Element content as stored after parsing an element definition in a DTD.

class LibXML::Native::xmlLocationSet
------------------------------------

A Location Set

class LibXML::Native::xmlParserInputDeallocate
----------------------------------------------

Callback for freeing some parser input allocations.

class LibXML::Native::xmlParserNodeInfo
---------------------------------------

The parser can be asked to collect Node informations, i.e. at what place in the file they were detected.

class LibXML::Native::xmlXPathCompExpr
--------------------------------------

The structure of a compiled expression form is not public.

class LibXML::Native::xmlPattern
--------------------------------

A compiled (XPath based) pattern to select nodes

class LibXML::Native::xmlRegexp
-------------------------------

A libxml regular expression, they can actually be far more complex thank the POSIX regex expressions.

class LibXML::Native::xmlXIncludeCtxt
-------------------------------------

An XInclude context

class LibXML::Native::xmlXPathAxis
----------------------------------

A mapping of name to axis function

class LibXML::Native::xmlXPathType
----------------------------------

A mapping of name to conversion function

class LibXML::Native::xmlValidState
-----------------------------------

Each xmlValidState represent the validation state associated to the set of nodes currently open from the document root to the current element.

### method compose

```perl6
method compose(
    Mu $package
) returns Mu
```

override standard Attribute method for generating accessors

class LibXML::Native::xmlParserInput
------------------------------------

Each entity parsed is associated an xmlParserInput (except the few predefined ones).

class LibXML::Native::xmlNs
---------------------------

An XML namespace. Note that prefix == NULL is valid, it defines the default namespace within the subtree (until overridden).

class LibXML::Native::xmlSAXLocator
-----------------------------------

A SAX Locator.

class LibXML::Native::xmlSAXHandler
-----------------------------------

A SAX handler is bunch of callbacks called by the parser when processing of the input generate data or structure informations.

class LibXML::Native::xmlError
------------------------------

An XML Error instance.

class LibXML::Native::xmlXPathContext
-------------------------------------

Expression evaluation occurs with respect to a context. the context consists of: - a node (the context node) - a node list (the context node list) - a set of variable bindings - a function library - the set of namespace declarations in scope for the expression

class LibXML::Native::xmlXPathParserContext
-------------------------------------------

An XPath parser context. It contains pure parsing informations, an xmlXPathContext, and the stack of objects.

class LibXML::Native::xmlNode
-----------------------------

A node in an XML tree.

class LibXML::Native::xmlElem
-----------------------------

xmlNode of type: XML_ELEMENT_NODE

class LibXML::Native::xmlTextNode
---------------------------------

xmlNode of type: XML_TEXT_NODE

class LibXML::Native::xmlCommentNode
------------------------------------

xmlNode of type: XML_COMMENT_NODE

class LibXML::Native::xmlCDataNode
----------------------------------

xmlNode of type: XML_CDATA_SECTION_NODE

class LibXML::Native::xmlPINode
-------------------------------

xmlNode of type: XML_PI_NODE

class LibXML::Native::xmlEntityRefNode
--------------------------------------

xmlNode of type: XML_ENTITY_REF_NODE

class LibXML::Native::xmlAttr
-----------------------------

An attribute on an XML node (type: XML_ATTRIBUTE_NODE)

class LibXML::Native::xmlDoc
----------------------------

An XML document (type: XML_DOCUMENT_NODE)

class LibXML::Native::htmlDoc
-----------------------------

xmlDoc of type: XML_HTML_DOCUMENT_NODE

class LibXML::Native::xmlDocFrag
--------------------------------

xmlNode of type: XML_DOCUMENT_FRAG_NODE

class LibXML::Native::xmlDtd
----------------------------

An XML DTD, as defined by <!DOCTYPE ... There is actually one for the internal subset and for the external subset (type: XML_DTD_NODE).

class LibXML::Native::xmlAttrDecl
---------------------------------

An Attribute declaration in a DTD (type: XML_ATTRIBUTE_DECL).

class LibXML::Native::xmlEntity
-------------------------------

An unit of storage for an entity, contains the string, the value and the data needed for the linking in the hash table (type: XML_ENTITY_DECL).

class LibXML::Native::xmlElementDecl
------------------------------------

An XML Element declaration from a DTD (type: XML_ELEMENT_DECL).

class LibXML::Native::xmlNodeSet
--------------------------------

A node-set (an unordered collection of nodes without duplicates)

class LibXML::Native::xmlValidCtxt
----------------------------------

An xmlValidCtxt is used for error reporting when validating.

class LibXML::Native::xmlParserCtxt
-----------------------------------

The parser context.

class LibXML::Native::xmlFileParserCtxt
---------------------------------------

XML file parser context

class LibXML::Native::xmlPushParserCtxt
---------------------------------------

an incremental XML push parser context. Determines encoding and reads data in binary chunks

class LibXML::Native::htmlParserCtxt
------------------------------------

a vanilla HTML parser context - can be used to read files or strings

class LibXML::Native::htmlFileParserCtxt
----------------------------------------

HTML file parser context

class LibXML::Native::htmlPushParserCtxt
----------------------------------------

an incremental HTMLpush parser context. Determines encoding and reads data in binary chunks

class LibXML::Native::xmlMemoryParserCtxt
-----------------------------------------

a parser context for an XML in-memory document.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

