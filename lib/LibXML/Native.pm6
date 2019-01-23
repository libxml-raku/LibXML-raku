use v6;

unit class LibXML::Native;

use NativeCall;

constant LIB = 'xml2';
constant WRAPPER-LIB =  %?RESOURCES<libraries/xml6>;
constant xmlParserVersion is export := cglobal(LIB, 'xmlParserVersion', Str);

# type defs
constant xmlCharP = Str;

# forward declarations
class xmlDoc     is repr('CStruct') is export {...}
class xmlError   is repr('CStruct') is export {...}
class xmlNode    is repr('CStruct') is export {...}
class parserCtxt is repr('CStruct') is export {...}

# Opaque/stubbed structs
constant Stub = 'CPointer';
class xmlAttr is repr(Stub) is export {}
class xmlDict is repr(Stub) is export {}
class xmlDtd is repr(Stub) is export {}
class xmlEntity is repr(Stub) is export {
    sub xmlGetPredefinedEntity(xmlCharP $name) is native(LIB) returns xmlEntity is export { * }
    method new(Str :$name!) {
        xmlGetPredefinedEntity($name);
    }
}
class xmlHashTable is repr(Stub) is export {}
class xmlNs is repr(Stub) is export {}
class xmlParserInputBuffer is repr(Stub) is export {}
class xmlParserInput is repr(Stub) is export {}
class xmlParserNodeInfo is repr(Stub) is export {}
class xmlValidState is repr(Stub) is export {}
class xmlAutomata is repr(Stub) is export {}
class xmlAutomataState is repr(Stub) is export {}

# Defined Structs/Pointers
class xmlSAXHandler is repr('CStruct') is export {

    my role Sax-CB-Att[&setter] {
        #| override standard Attribute method for generating accessors
        method compose(Mu $package) {
            my $name = self.name.subst(/^(\$|\@|\%)'!'/, '');
            my &accessor = sub (\obj) is rw {
                Proxy.new(
                    FETCH => sub ($) { self.get_value(obj) },
                    STORE => sub ($, &cb) {
                        setter(obj,&cb);
                    });
            }
            $package.^add_method( $name, &accessor );
        }
    }

    multi trait_mod:<is>(Attribute $att, :&sax-cb!) {
        $att does Sax-CB-Att[&sax-cb]
    }

    has Pointer   $.internalSubset is sax-cb(
        method xml6_sax_set_internalSubset(&cb (parserCtxt $ctx, Str $name, Str $external-id, Str $system-id) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.isStandalone is sax-cb(
        method xml6_sax_set_isStandalone( &cb (parserCtxt $ctx) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.hasInternalSubset is sax-cb(
        method xml6_sax_set_hasInternalSubset( &cb (parserCtxt $ctx) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.hasExternalSubset is sax-cb(
        method xml6_sax_set_hasExternalSubset( &cb (parserCtxt $ctx) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.resolveEntity is sax-cb(
        method xml6_sax_set_resolveEntity( &cb (parserCtxt $ctx, Str $name, Str $public-id, Str $system-id) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.getEntity is sax-cb(
        method xml6_sax_set_getEntity( &cb (parserCtxt $ctx, Str $name --> xmlEntity) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.entityDecl is sax-cb(
        method xml6_sax_set_entityDecl( &cb (parserCtxt $ctx, Str $name, uint32 $type, Str $public-id, Str $system-id) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.notationDecl is sax-cb(
        method xml6_sax_set_notationDecl( &cb (parserCtxt $ctx, Str $name, Str $public-id, Str $system-id) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.attributeDecl is sax-cb(
        # todo xmlEnumeration $tree
        method xml6_sax_set_attributeDecl( &cb (parserCtxt $ctx, Str $elem, Str $fullname, uint32 $type, uint32 $def, Str $default-value, Pointer $tree) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.elementDecl is sax-cb(
        # todo xmlElementContent $content
        method xml6_sax_set_elementDecl( &cb (parserCtxt $ctx, Str $name, uint32 $type, Pointer $content) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.unparsedEntityDecl is sax-cb(
        method xml6_sax_set_unparsedEntityDecl( &cb (parserCtxt $ctx, Str $name, Str $public-id, Str $system-id, Str $notation-name) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.setDocumentLocator is sax-cb(
        # todo xmlSAXLocator $loc
        method xml6_sax_set_setDocumentLocator( &cb (parserCtxt $ctx, Pointer $loc) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.startDocument is sax-cb(
        method xml6_sax_set_startDocument( &cb (parserCtxt $ctx) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.endDocument is sax-cb(
        method xml6_sax_set_endDocument( &cb (parserCtxt $ctx) ) is native(WRAPPER-LIB) {*}
    );

    has Pointer   $!startElement is sax-cb(
        method xml6_sax_set_startElement( &cb (parserCtxt $ctx, Str $name, CArray[Str] $atts) ) is native(WRAPPER-LIB) {*}
    );
    
    has Pointer   $!endElement is sax-cb(
        method xml6_sax_set_endElement( &cb (parserCtxt $ctx, Str $name) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.reference is sax-cb(
        method xml6_sax_set_reference( &cb (parserCtxt $ctx, Str $name) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.characters is sax-cb(
        method xml6_sax_set_characters( &cb (parserCtxt $ctx, CArray[byte] $chars, int32 $len) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.ignorableWhitespace is sax-cb(
        method xml6_sax_set_ignorableWhitespace( &cb (parserCtxt $ctx, Str $name, int32 $len) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.processingInstruction is sax-cb(
        method xml6_sax_processingInstruction( &cb (parserCtxt $ctx, Str $target, Str $data) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.comment is sax-cb(
        method xml6_sax_set_comment( &cb (parserCtxt $ctx, Str $value) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.warning is sax-cb(
        method xml6_sax_set_warning( &cb (parserCtxt $ctx, Str $msg) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.error is sax-cb(
        method xml6_sax_set_error( &cb (parserCtxt $ctx, Str $msg) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.fatalError is sax-cb(
        method xml6_sax_set_fatalError( &cb (parserCtxt $ctx, Str $msg) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.getParameterEntity is sax-cb(
        method xml6_sax_set_getParameterEntity( &cb (parserCtxt $ctx, Str $name) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.cdataBlock is sax-cb(
        method xml6_sax_set_cdataBlock( &cb (parserCtxt $ctx, Str $name, int32 $len) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.externalSubset is sax-cb(
        method xml6_sax_set_externalSubset( &cb (parserCtxt $ctx, Str $name, Str $external-id, Str $system-id) ) is native(WRAPPER-LIB) {*}
    );
    has uint32    $.initialized;
    has Pointer   $._private;
    has Pointer   $.startElementNs is sax-cb(
        method xml6_sax_set_startElementNs( &cb (parserCtxt $ctx, Str $local-name, Str $prefix, Str $uri, int32 $nb-namespaces, CArray[Str] $namespaces, int32 $nb-attributes, int32 $nb-defaulted, CArray[Str] $attributes) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.endElementNs is sax-cb(
        method xml6_sax_set_endElementNs( &cb (parserCtxt $ctx, Str $local-name, Str $prefix, Str $uri) ) is native(WRAPPER-LIB) {*}
    );
    has Pointer   $.serror is sax-cb(
        method xml6_sax_set_serror( &cb (parserCtxt $ctx, xmlError $serror) ) is native(WRAPPER-LIB) {*}
    );

    submethod TWEAK(*%callbacks) {
        for %callbacks.pairs.sort {
            self."{.key}"() = .value;
        }
    }

    method ParseDoc(Str, int32) is native(LIB) is symbol('xmlSAXParseDoc') returns xmlDoc {*};

}

class xmlBuffer is repr(Stub) is export {
    method Create is native(LIB) is symbol('xmlBufferCreate') returns xmlBuffer {*}
    method xmlNodeDump(xmlDoc $doc, xmlNode $cur, int32 $level, int32 $format) is native(LIB) returns int32 is export { * }
    method Content is symbol('xmlBufferContent') is native(LIB) returns Str is export { * }
    method Free is symbol('xmlBufferFree') is native(LIB) is export { * }
}

# C structs

class _NodeCommon is repr('CStruct') {
    has Pointer               $._private;    # application data
    has int32                 $.type;        # type number, must be second !
    has xmlCharP              $.name;        # the name of the node, or the entity
    has xmlNode               $.children;    # parent->childs link
    has xmlNode               $.last;        # last child link
    has xmlNode               $.parent;      # child->parent link
    has xmlNode               $.next;        # next sibling link
    has xmlNode               $.prev;        # previous sibling link
    has xmlDoc                $.doc;         # the containing document
    # End of common part

    method GetBase(xmlDoc) is native(LIB) is symbol('xmlNodeGetBase') returns xmlCharP {*}
    method SetBase(xmlCharP) is native(LIB) is symbol('xmlNodeSetBase') {*}

    sub siblings($cur) is rw {
        my class Siblings does Iterable does Iterator {
            has xmlNode $.cur;
            method iterator { self }
            method pull-one {
                my xmlNode $this = $!cur;
                $_ = .next with $!cur;
                $this // IterationEnd;
            }
        }.new( :$cur );
    }

    method child-nodes {
        siblings($!children);
    }
  }

class xmlNode is _NodeCommon is export {
    has xmlNs                 $.ns;          # pointer to the associated namespace
    has xmlCharP              $.content;     # the content
    has xmlAttr               $.properties;  # properties list
    has xmlNs                 $.nsDef;       # namespace definitions on this node
    has Pointer               $.psvi;        # for type/PSVI informations
    has uint16                $.line;        # line number
    has uint16                $.extra;       # extra data for XPath/XSLT

    method Str(Bool() :$format = False) {
        nextsame without self;
        my xmlBuffer $buf .= Create;
        $buf.xmlNodeDump($.doc, self, 0, +$format);
        my str $content = $buf.Content;
        $buf.Free;
        $content;
    }
}

class xmlDoc is _NodeCommon is export {
    has int32                 $.compression; # level of zlib compression
    has int32                 $.standalone;  # standalone document (no external refs)
                                             # 1 if standalone="yes"
                                             # 0 if standalone="no"
                                             # -1 if there is no XML declaration
                                             # -2 if there is an XML declaration, but no
                                             #    standalone attribute was specified
    has xmlDtd                $.intSubset;   # the document internal subset
    has xmlDtd                $.extSubset;   # the document external subset
    has xmlNs                 $.oldNs;       # Global namespace, the old way
    has xmlCharP              $.version;     # the XML version string
    has xmlCharP              $.encoding;    # external initial encoding, if any
    has Pointer               $.ids;         # Hash table for ID attributes if any
    has Pointer               $.refs;        # Hash table for IDREFs attributes if any
    has xmlCharP              $.URL;         # The URI for that document
    has int32                 $.charset;     # Internal flag for charset handling,
                                             # actually an xmlCharEncoding 
    has xmlDict               $.dict;        # dict used to allocate names or NULL
    has Pointer               $.psvi;        # for type/PSVI informations
    has int32                 $.parseFlags;  # set of xmlParserOption used to parse the
                                             # document
    has int32                 $.properties;  # set of xmlDocProperties for this document
                                             # set at the end of parsing

    method DumpFormatMemoryEnc(Pointer[uint8] $ is rw, int32 $ is rw, Str, int32 ) is symbol('xmlDocDumpFormatMemoryEnc') is native(LIB) {*}
    method xmlCopyDoc(int32) is native(LIB)  returns xmlDoc {*}
    method GetRootElement is symbol('xmlDocGetRootElement') is native(LIB) returns xmlNode is export { * }
    method internal-dtd is native(LIB) is symbol('xmlGetIntSubset') {*}
    method copy(Bool :$recursive = True) { $.xmlCopyDoc(+$recursive) }
    method Free is native(LIB) is symbol('xmlFreeDoc') {*}
    method Str(Bool() :$format = False) {
        nextsame without self;
        my Pointer[uint8] $p .= new;
        $.DumpFormatMemoryEnc($p, my int32 $, 'UTF-8', +$format);
        nativecast(str, $p);
    }
}

class xmlParserNodeInfoSeq is repr('CStruct') is export {
    has ulong                  $.maximum;
    has ulong                  $.length;
    has xmlParserNodeInfo      $.buffer;
}

class xmlValidCtxt is repr('CStruct') is export {
    has Pointer                $.userData;  # user specific data block
    has Pointer                $.error;     # the callback in case of errors
    has Pointer                $.warning;   # the callback in case of warning

    # Node analysis stack used when validating within entities
    has xmlNode                $.node;      # Current parsed Node
    has int32                  $.nodeNr;    # Depth of the parsing stack
    has int32                  $.nodeMax;   # Max depth of the parsing stack
    has Pointer[xmlNode]       $.nodeTab;   # array of nodes

    has uint32                 $.finishDtd; # finished validating the Dtd ?
    has xmlDoc                 $.doc;       # the document
    has int32                  $.valid;     # temporary validity check result

    # state state used for non-determinist content validation
    has xmlValidState          $.vstate;    # current state
    has int32                  $.vstateNr;  # Depth of the validation stack
    has int32                  $.vstateMax; # Max depth of the validation stack
    has Pointer[xmlValidState] $.vstateTab; # array of validation state

    # Regex preocessing
    has xmlAutomata            $.am;        # the automata
    has xmlAutomataState       $.state;     # used to build the automata
}

class xmlError is export {
    has int32                  $.domain;    # What part of the library raised this error
    has int32                  $.code;      # The error code, e.g. an xmlParserError
    has Str                    $.message;   # human-readable informative error message
    has int32                  $.level;     # how consequent is the error
    has Str                    $.file;      # the filename
    has int32                  $.line;      # the line number if available
    has Str                    $.str1;      # extra string information
    has Str                    $.str2;      # extra string information
    has Str                    $.str3;      # extra string information
    has int32                  $.int1;      # extra number information
    has int32                  $.int2;      # error column # or 0 if N/A
    has parserCtxt             $.ctxt;      # the parser context if available
    has xmlNode                $.node;      # the node in the tree
}

class parserCtxt is export {
    has xmlSAXHandler          $.sax;          # The SAX handler
    has Pointer                $.userData;     # For SAX interface only, used by DOM build
    has xmlDoc                 $.myDoc;        # the document being built
    has int32                  $.wellFormed;   # is the document well formed
    has int32                  $.replaceEntities;     # shall we replace entities ?
    has xmlCharP               $.version;      #  the XML version string
    has xmlCharP               $.encoding;     # the declared encoding, if any
    has int32                  $.standalone;   # standalone document
    has int32                  $.html;         # an HTML(1)/Docbook(2) document
                                               # 3 is HTML after <head>
                                               # 10 is HTML after <body>
    # Input stream stack
    has xmlParserInput         $.input;        # Current input stream
    has int32                  $.inputNr;      # Number of current input streams
    has int32                  $.inputMax;     # Max number of input streams
    has Pointer[xmlParserInput]       $.inputTab;     # stack of inputs

    # Node analysis stack only used for DOM building
    has xmlNode                $.node;         # Current parsed Node
    has int32                  $.nodeNr;       # Depth of the parsing stack
    has int32                  $.nodeMax;      # Max depth of the parsing stack
    has Pointer[xmlNode]       $.nodeTab;      # array of nodes
    
    has int32                  $.record_info;  # Whether node info should be kept
    HAS xmlParserNodeInfoSeq   $.node_seq;     # info about each node parsed

    has int32                  $.errNo;        # error code

    has int32                  $.hasExternalSubset;     # reference and external subset
    has int32                  $.hasPErefs;    # the internal subset has PE refs
    has int32                  $.external;     # are we parsing an external entity
    has int32                  $.valid;        # is the document valid
    has int32                  $.validate;     # shall we try to validate ?
    HAS xmlValidCtxt           $.vctxt;        #  The validity context

    has int32                  $.instate;      # current type of input
    has int32                  $.token;        # next char look-ahead

    has Str                    $.directory;    # the data directory

    # Node name stack
    has xmlCharP               $.name;         # Current parsed Node
    has int32                  $.nameNr;       # Depth of the parsing stack
    has int32                  $.nameMax;      # Max depth of the parsing stack
    has Pointer[xmlCharP]      $.nameTab;      # array of nodes

    has long                   $.nbChars;      # number of xmlChar processed
    has long                   $.checkIndex;   # used by progressive parsing lookup
    has int32                  $.keepBlanks;   # ugly but ...
    has int32                  $.disableSAX;   #  SAX callbacks are disabled
    has int32                  $.inSubset;     #  Parsing is in int 1/ext 2 subset
    has xmlCharP               $.intSubName;   # name of subset
    has xmlCharP               $.extSubURI;    # URI of external subset
    has xmlCharP               $.extSubSystem; # SYSTEM ID of external subset

    # xml:space values
    has Pointer[int32]         $.space;        # Should the parser preserve spaces
    has int32                  $.spaceNr;      # Depth of the parsing stack
    has int32                  $.spaceMax;     # Max depth of the parsing stack
    has Pointer[int32]         $.spaceTab;     # array of space infos

    has int32                  $.depth;        # to prevent entity substitution loops
    has xmlParserInput         $.entity;       # used to check entities boundaries
    has int32                  $.charset;      # encoding of the in-memory content
                                               # actually an xmlCharEncoding
    has int32                  $.nodelen;      # Those two fields are there to
    has int32                  $.nodemem;      # Speed up large node parsing
    has int32                  $.pedantic;     # signal pedantic warnings
    has Pointer                $._private;     # For user data, libxml won't touch it

    has int32                  $.loadsubset;   # should the external subset be loaded
    has int32                  $.linenumbers is rw;     # set line number in element content
    has Pointer                $.catalogs;     # document's own catalog
    has int32                  $.recovery;     # run in recovery mode
    has int32                  $.progressive;  # is this a progressive parsing
    has xmlDict                $.dict;         # dictionary for the parser 
    has Pointer[xmlCharP]      $.atts;         # array for the attributes callbacks
    has int32                  $.maxatts;      # the size of the array
    has int32                  $.docdict;      # use strings from dict to build tree

    # pre-interned strings
    has xmlCharP               $.str_xml;
    has xmlCharP               $.str_xmlns;
    has xmlCharP               $.str_xml_ns;

    # Everything below is used only by the new SAX mode
    has int32                  $.sax2;         # operating in the new SAX mode
    has int32                  $.nsNr;         # the number of inherited namespaces
    has int32                  $.nsMax;        # the size of the arrays
    has Pointer[xmlCharP]      $.nsTab;        # the array of prefix/namespace name
    has Pointer[int32]         $.attallocs;    #  which attribute were allocated
    has Pointer[Pointer]       $.pushTab;      # array of data for push
    has xmlHashTable           $.attsDefault;  # defaulted attributes if any
    has xmlHashTable           $.attsSpecial;  # non-CDATA attributes if any
    has int32                  $.nsWellFormed; # is the document XML Namespace okay
    has int32                  $.options;      # Extra options

    # These fields are needed only for streaming parsing so far
    has int32                  $.dictNames;    # Use dictionary names for the tree
    has int32                  $.freeElemsNr;  # number of freed element nodes
    has xmlNode                $.freeElems;    # List of freed element nodes
    has int32                  $.freeAttrsNr;  # number of freed attributes nodes
    has xmlAttr                $.freeAttrs;    # List of freed attributes nodes

    # the complete error informations for the last error.
    HAS xmlError               $.lastError;
    has int32                  $.parseMode;    # the parser mode
    has ulong                  $.nbentities;   # number of entities references
    has ulong                  $.sizeentities; # size of parsed entities

    # for use by HTML non-recursive parser
    has xmlParserNodeInfo      $.nodeInfo;     # Current NodeInfo
    has int32                  $.nodeInfoNr;   # Depth of the parsing stack
    has int32                  $.nodeInfoMax;  # Max depth of the parsing stack
    has xmlParserNodeInfo      $.nodeInfoTab;  # array of nodeInfos

    has int32                  $.input_id;     #  we need to label inputs
    has ulong                  $.sizeentcopy;  # volume of entity copy

    method xmlSetGenericErrorFunc( &error-func (parserCtxt $, Str $fmt)) is native(LIB) {*};
    method xmlSetStructuredErrorFunc( &error-func (parserCtxt $, xmlError $)) is native(LIB) {*};
    method GetLastError is native(LIB) is symbol('xmlCtxtGetLastError') returns xmlError is native('xml2') {*}
    method Free is native(LIB) is symbol('xmlFreeParserCtxt') { * }


    # SAX2 Handler callbacks
    method xmlSAX2StartElement(Str $name, CArray $atts) is native(LIB) {*};
    method xmlSAX2EndElement(Str $name) is native(LIB) {*};
    method xmlSAX2Characters(Blob $chars, int32 $len) is native(LIB) {*};
    method xmlSAX2GetEntity(Str $name) is native(LIB) {*};
}

#| a vanilla XML parser context - can be used to read files or strings
class xmlParserCtxt is parserCtxt is repr('CStruct') is export {

    sub xmlNewParserCtxt is native(LIB) returns xmlParserCtxt {*};
    method new { xmlNewParserCtxt() }
    method ReadDoc(Str $xml, Str $uri, Str $enc, int32 $flags) is native(LIB) is symbol('xmlCtxtReadDoc') returns xmlDoc {*};
    method ReadFile(Str $xml, Str $enc, int32 $flags) is native(LIB) is symbol('xmlCtxtReadFile') returns xmlDoc {*};
    method UseOptions(int32) is native(LIB) is symbol('xmlCtxtUseOptions') returns int32 { * }

};

# XML file parser context
class xmlFileParserCtxt is parserCtxt is repr('CStruct') is export {

    sub xmlCreateFileParserCtxt(Str $file) is native(LIB) returns xmlFileParserCtxt {*};
    method ParseDocument is native(LIB) is symbol('xmlParseDocument') returns int32 {*}
    method UseOptions(int32) is native(LIB) is symbol('xmlCtxtUseOptions') returns int32 { * }
    method new(Str() :$file!) { xmlCreateFileParserCtxt($file) }
}

# XML file parser context
class xmlXIncludeCtxt is parserCtxt is repr('CStruct') is export {

    sub xmlXIncludeNewContext(xmlDoc) is native(LIB) returns xmlXIncludeCtxt {*};
    method ProcessNode(xmlNode) is native(LIB) is symbol('xmlXIncludeProcessNode') returns int32 {*}
    method Free is native(LIB) is symbol('xmlXIncludeFreeContext') {*}
    method UseOptions(int32) is native(LIB) is symbol('xmlXIncludeSetFlags') returns int32 { * }
    method new(xmlDoc :$doc!) { xmlXIncludeNewContext($doc) }
}

#| an incremental XML push parser context. Determines encoding and reads data in binary chunks
class xmlPushParserCtxt is parserCtxt is repr('CStruct') is export {

    sub xmlCreatePushParserCtxt(xmlSAXHandler $sax, Pointer $user-data, Blob $chunk, int32 $size, Str $path) is native(LIB) returns xmlPushParserCtxt {*};
    method new(Blob :$chunk!, :$size = +$chunk, xmlSAXHandler :$sax, Pointer :$user-data, Str :$path) { xmlCreatePushParserCtxt($sax, $user-data, $chunk, $size, $path) }
    method ParseChunk(Blob $chunk, int32 $size, int32 $terminate) is native(LIB) is symbol('xmlParseChunk') returns int32 {*};
    method UseOptions(int32) is native(LIB) is symbol('xmlCtxtUseOptions') returns int32 { * }
};

#| a vanilla HTML parser context - can be used to read files or strings
class htmlParserCtxt is parserCtxt is repr('CStruct') is export {

    sub htmlNewParserCtxt is native(LIB) returns htmlParserCtxt {*};
    method new { htmlNewParserCtxt() }
    method UseOptions(int32) is native(LIB) is symbol('htmlCtxtUseOptions') returns int32 { * }
    method ReadDoc(Str $xml, Str $uri, Str $enc, int32 $flags) is native(LIB) is symbol('htmlCtxtReadDoc') returns xmlDoc {*};
    method ReadFile(Str $xml, Str $uri, Str $enc, int32 $flags) is native(LIB) is symbol('htmlCtxtReadFile') returns xmlDoc {*};
};

# HTML file parser context
class htmlFileParserCtxt is parserCtxt is repr('CStruct') is export {

    sub htmlCreateFileParserCtxt(Str $file) is native(LIB) returns htmlFileParserCtxt {*};
    method ParseDocument is native(LIB) is symbol('htmlParseDocument') returns int32 {*}
    method UseOptions(int32) is native(LIB) is symbol('htmlCtxtUseOptions') returns int32 { * }
    method new(Str() :$file!) { htmlCreateFileParserCtxt($file) }
}

#| an incremental HTMLpush parser context. Determines encoding and reads data in binary chunks
class htmlPushParserCtxt is parserCtxt is repr('CStruct') is export {

    sub htmlCreatePushParserCtxt(xmlSAXHandler $sax, Pointer $user-data, Blob $chunk, int32 $size, Str $path) is native(LIB) returns htmlPushParserCtxt {*};
    method new(Blob :$chunk!, :$size = +$chunk, xmlSAXHandler :$sax, Pointer :$user-data, Str :$path) { htmlCreatePushParserCtxt($sax, $user-data, $chunk, $size, $path) }
    method ParseChunk(Blob $chunk, int32 $size, int32 $terminate) is native(LIB) is symbol('htmlParseChunk') returns int32 { *};
    method UseOptions(int32) is native(LIB) is symbol('htmlCtxtUseOptions') returns int32 { * }
};

sub xmlGetLastError returns xmlError is native('xml2') { * }

multi method GetLastError(parserCtxt $ctx) { $ctx.GetLastError() // $.GetLastError()  }
multi method GetLastError { xmlGetLastError()  }

method KeepBlanksDefault is rw {
    constant value = cglobal(LIB, "xmlKeepBlanksDefaultValue", int32);
    sub xmlKeepBlanksDefault(int32 $v) is native(LIB) returns int32 is export { * }

    Proxy.new(
        FETCH => sub ($) { ? value },
        STORE => sub ($, Bool() $_) {
            xmlKeepBlanksDefault($_);
        },
    );
}
