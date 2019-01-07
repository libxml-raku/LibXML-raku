use v6;

unit class XML::LibXML::Native;

use NativeCall;

# gptrixie-mined/handcrafted definitions to go here

constant LIB = 'xml2';
constant xmlParserVersion is export := cglobal(LIB, 'xmlParserVersion', Str);

# Opaque/stubbed structs
constant Stub = 'CPointer';
class xmlAttr is repr(Stub) is export {}
constant xmlChar = uint8;
constant xmlCharP = Pointer[xmlChar];
class xmlDict is repr(Stub) is export {}
class xmlDoc is repr(Stub) is export {}
class xmlHashTable is repr(Stub) is export {}
class xmlNode is repr(Stub) is export {}
class xmlParserInputBuffer is repr(Stub) is export {}
class xmlParserInput is repr(Stub) is export {}
class xmlParserNodeInfo is repr(Stub) is export {}
class xmlValidState is repr(Stub) is export {}
class xmlAutomata is repr(Stub) is export {}
class xmlAutomataState is repr(Stub) is export {}
class xmlSAXHandler is repr(Stub) is export {}

class xmlParserNodeInfoSeq is repr('CStruct') is export {
	has ulong                  $.maximum; # long unsigned int maximum
	has ulong                  $.length; # long unsigned int length
	has xmlParserNodeInfo      $.buffer; # Typedef<xmlParserNodeInfo>->«_xmlParserNodeInfo»* buffer
}

class xmlValidCtxt is repr('CStruct') is export {
	has Pointer                $.userData; # void* userData
	has Pointer                $.error; # Typedef<xmlValidityErrorFunc>->«F:void ( )*» error
	has Pointer                $.warning; # Typedef<xmlValidityWarningFunc>->«F:void ( )*» warning
	has xmlNode                $.node; # Typedef<xmlNodePtr>->«Typedef<xmlNode>->«_xmlNode»*» node
	has int32                  $.nodeNr; # int nodeNr
	has int32                  $.nodeMax; # int nodeMax
	has Pointer[xmlNode]       $.nodeTab; # Typedef<xmlNodePtr>->«Typedef<xmlNode>->«_xmlNode»*»* nodeTab
	has uint32                 $.finishDtd; # unsigned int finishDtd
	has xmlDoc                 $.doc; # Typedef<xmlDocPtr>->«Typedef<xmlDoc>->«_xmlDoc»*» doc
	has int32                  $.valid; # int valid
	has xmlValidState          $.vstate; # Typedef<xmlValidState>->«_xmlValidState»* vstate
	has int32                  $.vstateNr; # int vstateNr
	has int32                  $.vstateMax; # int vstateMax
	has Pointer[xmlValidState] $.vstateTab; # Typedef<xmlValidState>->«_xmlValidState»* vstateTab
	has xmlAutomata            $.am; # Typedef<xmlAutomataPtr>->«Typedef<xmlAutomata>->«_xmlAutomata»*» am
	has xmlAutomataState       $.state; # Typedef<xmlAutomataStatePtr>->«Typedef<xmlAutomataState>->«_xmlAutomataState»*» state
}

class xmlError is repr('CStruct') is export {
    has int32                 $.domain;  # What part of the library raised this error
    has int32                 $.code;    # The error code, e.g. an xmlParserError
    has Str                   $.message; # human-readable informative error message
    has int32                 $.level;   # how consequent is the error
    has Str                   $.file;    # the filename
    has int32                 $.line;    # the line number if available
    has Str                   $.str1;    # extra string information
    has Str                   $.str2;    # extra string information
    has Str                   $.str3;    # extra string information
    has int32                 $.int1;    # extra number information
    has int32                 $.int2;    # error column # or 0 if N/A
    has Pointer               $.ctxt;    # the parser context if available
    has Pointer               $.node;    # the node in the tree
}

class parserCtxt is repr('CStruct') is export {
    has xmlSAXHandler           $.sax;          # The SAX handler
    has Pointer                 $.userData;     # For SAX interface only, used by DOM build
    has xmlDoc                  $.myDoc;        # the document being built
    has int32                   $.wellFormed;   # is the document well formed
    has int32                   $.replaceEntities;     # shall we replace entities ?
    has xmlCharP                $.version;      #  the XML version string
    has xmlCharP                $.encoding;     # the declared encoding, if any
    has int32                   $.standalone;   # standalone document
    has int32                   $.html;         # an HTML(1)/Docbook(2) document
                                                # 3 is HTML after <head>
                                                # 10 is HTML after <body>
    # Input stream stack
    has xmlParserInput          $.input;        # Current input stream
    has int32                   $.inputNr;      # Number of current input streams
    has int32                   $.inputMax;     # Max number of input streams
    has Pointer[xmlParserInput]        $.inputTab;     # stack of inputs

    # Node analysis stack only used for DOM building
    has xmlNode                 $.node;         # Current parsed Node
    has int32                   $.nodeNr;       # Depth of the parsing stack
    has int32                   $.nodeMax;      # Max depth of the parsing stack
    has Pointer[xmlNode]        $.nodeTab;      # array of nodes
    
    has int32                   $.record_info;  # Whether node info should be kept
    HAS xmlParserNodeInfoSeq    $.node_seq;     # info about each node parsed

    has int32                   $.errNo;        # error code

    has int32                   $.hasExternalSubset;     # reference and external subset
    has int32                   $.hasPErefs;    # the internal subset has PE refs
    has int32                   $.external;     # are we parsing an external entity
    has int32                   $.valid;        # is the document valid
    has int32                   $.validate;     # shall we try to validate ?
    HAS xmlValidCtxt            $.vctxt;        #  The validity context

    has int32                   $.instate;      # current type of input
    has int32                   $.token;        # next char look-ahead

    has Str                     $.directory;    # the data directory

    # Node name stack
    has xmlCharP                $.name;         # Current parsed Node
    has int32                   $.nameNr;       # Depth of the parsing stack
    has int32                   $.nameMax;      # Max depth of the parsing stack
    has Pointer[xmlCharP]       $.nameTab;      # array of nodes

    has long                    $.nbChars;      # number of xmlChar processed
    has long                    $.checkIndex;   # used by progressive parsing lookup
    has int32                   $.keepBlanks;   # ugly but ...
    has int32                   $.disableSAX;   #  SAX callbacks are disabled
    has int32                   $.inSubset;     #  Parsing is in int 1/ext 2 subset
    has xmlCharP                $.intSubName;   # name of subset
    has xmlCharP                $.extSubURI;    # URI of external subset
    has xmlCharP                $.extSubSystem; # SYSTEM ID of external subset

    # xml:space values
    has Pointer[int32]          $.space;        # Should the parser preserve spaces
    has int32                   $.spaceNr;      # Depth of the parsing stack
    has int32                   $.spaceMax;     # Max depth of the parsing stack
    has Pointer[int32]          $.spaceTab;     # array of space infos

    has int32                   $.depth;        # to prevent entity substitution loops
    has xmlParserInput          $.entity;       # used to check entities boundaries
    has int32                   $.charset;      # encoding of the in-memory content
				                # actually an xmlCharEncoding
    has int32                   $.nodelen;      # Those two fields are there to
    has int32                   $.nodemem;      # Speed up large node parsing
    has int32                   $.pedantic;     # signal pedantic warnings
    has Pointer                 $._private;     # For user data, libxml won't touch it

    has int32                   $.loadsubset;   # should the external subset be loaded
    has int32                   $.linenumbers is rw;     # set line number in element content
    has Pointer                 $.catalogs;     # document's own catalog
    has int32                   $.recovery;     # run in recovery mode
    has int32                   $.progressive;  # is this a progressive parsing
    has xmlDict                 $.dict;         # dictionary for the parser 
    has Pointer[xmlCharP]       $.atts;         # array for the attributes callbacks
    has int32                   $.maxatts;      # the size of the array
    has int32                   $.docdict;      # use strings from dict to build tree

    # pre-interned strings
    has xmlCharP                $.str_xml;
    has xmlCharP                $.str_xmlns;
    has xmlCharP                $.str_xml_ns;

    # Everything below is used only by the new SAX mode
    has int32                   $.sax2;         # operating in the new SAX mode
    has int32                   $.nsNr;         # the number of inherited namespaces
    has int32                   $.nsMax;        # the size of the arrays
    has Pointer[xmlCharP]       $.nsTab;        # the array of prefix/namespace name
    has Pointer[int32]          $.attallocs;    #  which attribute were allocated
    has Pointer[Pointer]        $.pushTab;      # array of data for push
    has xmlHashTable            $.attsDefault;  # defaulted attributes if any
    has xmlHashTable            $.attsSpecial;  # non-CDATA attributes if any
    has int32                   $.nsWellFormed; # is the document XML Namespace okay
    has int32                   $.options;      # Extra options

    # These fields are needed only for streaming parsing so far
    has int32                   $.dictNames;    # Use dictionary names for the tree
    has int32                   $.freeElemsNr;  # number of freed element nodes
    has xmlNode                 $.freeElems;    # List of freed element nodes
    has int32                   $.freeAttrsNr;  # number of freed attributes nodes
    has xmlAttr                 $.freeAttrs;    # List of freed attributes nodes

    # the complete error informations for the last error.
    has xmlError                $.lastError;
    has int32                   $.parseMode;    # the parser mode
    has ulong                   $.nbentities;   # number of entities references
    has ulong                   $.sizeentities; # size of parsed entities

    # for use by HTML non-recursive parser
    has xmlParserNodeInfo       $.nodeInfo;     # Current NodeInfo
    has int32                   $.nodeInfoNr;   # Depth of the parsing stack
    has int32                   $.nodeInfoMax;  # Max depth of the parsing stack
    has xmlParserNodeInfo       $.nodeInfoTab;  # array of nodeInfos

    has int32                   $.input_id;     #  we need to label inputs
    has ulong                   $.sizeentcopy;  # volume of entity copy

    method last-error is native(LIB) is symbol('xmlCtxtGetLastError') returns xmlError is native('xml2') {*}
    method free is native(LIB) is symbol('xmlFreeParserCtxt') { * }
}

class xmlParserCtxt is parserCtxt is repr('CStruct') is export {

    sub xmlNewParserCtxt is native(LIB) returns xmlParserCtxt {*};
    method new { xmlNewParserCtxt() }
    method init is native(LIB) is symbol('xmlCtxtUseOptions') returns int32 { * }
    method read-doc(Str $xml, Str $uri, Str $enc, int32 $flags) is native(LIB) is symbol('xmlCtxtReadDoc') returns xmlDoc {*};
    method read-file(Str $xml, Str $uri, Str $enc, int32 $flags) is native(LIB) is symbol('xmlCtxtReadFile') returns xmlDoc {*};
    method use-options(int32) is native(LIB) is symbol('xmlCtxtUseOptions') returns int32 { * }
};

class htmlParserCtxt is parserCtxt is repr('CStruct') is export {

    sub htmlNewParserCtxt is native(LIB) returns htmlParserCtxt {*};
    method new { htmlNewParserCtxt() }
    method use-options(int32) is native(LIB) is symbol('htmlCtxtUseOptions') returns int32 { * }
    method read-doc(Str $xml, Str $uri, Str $enc, int32 $flags) is native(LIB) is symbol('htmlCtxtReadDoc') returns xmlDoc {*};
    method read-file(Str $xml, Str $uri, Str $enc, int32 $flags) is native(LIB) is symbol('htmlCtxtReadFile') returns xmlDoc {*};
};

sub xmlGetLastError returns xmlError is native('xml2') { * }

multi method last-error(parserCtxt $ctx) { $ctx.last-error() // $.last-error()  }
multi method last-error { xmlGetLastError()  }

our $xmlKeepBlanksDefaultValue is export := cglobal(LIB, "xmlKeepBlanksDefaultValue", int32);
sub xmlKeepBlanksDefault(int32 $v) is native(LIB) returns int32 is export { * }

method keep-blanks-default is rw {
    Proxy.new(
        FETCH => sub ($) { ? $xmlKeepBlanksDefaultValue },
        STORE => sub ($, Bool() $_) {
            xmlKeepBlanksDefault($_);
        },
    );
}
