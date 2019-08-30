use v6;

unit class LibXML::Native;

use NativeCall;
use LibXML::Enums;
use LibXML::Native::Dict;
use LibXML::Native::HashTable;
use LibXML::Native::DOM::Attr;
use LibXML::Native::DOM::Document;
use LibXML::Native::DOM::Element;
use LibXML::Native::DOM::Node;

use LibXML::Native::Defs :LIB, :BIND-LIB, :Stub, :xmlCharP;

my constant xmlParserVersion is export := cglobal(LIB, 'xmlParserVersion', Str);
sub xml6_gbl_have_threads(-->int32) is native(BIND-LIB) is export {*}
sub xml6_gbl_have_compression(-->int32) is native(BIND-LIB) is export {*}

# type defs
constant xmlCharEncodingHandler = Pointer; # stub

# subsets
sub xmlParseCharEncoding(Str --> int32) is export is native(LIB) {*}
sub xmlFindCharEncodingHandler(Str --> xmlCharEncodingHandler) is export is native(LIB) {*}
my subset xmlEncodingStr of Str is export where {!.defined || xmlFindCharEncodingHandler($_).defined}

# forward declarations
class anyNode        is repr('CStruct') is export {...}
class itemNode       is repr('CStruct') is export {...}
class xmlAttr        is repr('CStruct') is export {...}
class xmlDtd         is repr('CStruct') is export {...}
class xmlDoc         is repr('CStruct') is export {...}
class xmlDocFrag     is repr('CStruct') is export {...}
class xmlElem        is repr('CStruct') is export {...}
class xmlEntity      is repr('CStruct') is export {...}
class xmlError       is repr('CStruct') is export {...}
class xmlNode        is repr('CStruct') is export {...}
class xmlNodeSet     is repr('CStruct') is export {...}

class xmlParserCtxt  is repr('CStruct') is export {...}
class xmlXPathParserContext
                     is repr('CStruct') is export { ...}
class xmlXPathObject is repr('CStruct') is export {...}

# Opaque/stubbed structs
class xmlAutomata is repr(Stub) is export {}
class xmlAutomataState is repr(Stub) is export {}
# old buffer limited to 2Gb. replaced by xmlBuf
class xmlBufOld is repr(Stub) is export {}
class xmlEnumeration is repr(Stub) is export {}
class xmlElementContent is repr(Stub) is export {}
class xmlLocationSet is repr(Stub) is export {}
class xmlParserInputDeallocate is repr(Stub) is export {}
class xmlParserNodeInfo is repr(Stub) is export {}

class xmlXPathCompExpr is repr(Stub) is export {
    sub xmlXPathCompile(xmlCharP:D --> xmlXPathCompExpr) is native(LIB) {*}
    method Free is native(LIB) is symbol('xmlXPathFreeCompExpr') {*}
    method new(Str:D :$expr) {
        xmlXPathCompile($expr);
    }
}
class xmlPattern is repr(Stub) is export {
    method Match(anyNode --> int32) is native(LIB) is symbol('xmlPatternMatch') {*}
    sub xmlPatterncompile(xmlCharP, xmlDict, int32, CArray[xmlCharP] --> xmlPattern) is native(LIB) {*}
    method Free is native(LIB) is symbol('xmlFreePattern') {*}
    method new(Str:D :$pattern!, xmlDict :$dict, UInt :$flags, CArray[xmlCharP] :$ns) {
        xmlPatterncompile($pattern, $dict, $flags, $ns);
    }
}
class xmlRegexp is repr(Stub) is export {
    sub xmlRegexpCompile(xmlCharP --> xmlRegexp) is native(LIB) {*}
    method Match(xmlCharP --> int32) is symbol('xmlRegexpExec') is native(LIB) {*}
    method IsDeterministic(--> int32) is symbol('xmlRegexpIsDeterminist') is native(LIB) {*}
    method Free is native(LIB) is symbol('xmlRegFreeRegexp') {*}
    method new(Str:D :$regexp) {
        xmlRegexpCompile($regexp);
    }
}
class xmlXIncludeCtxt is repr(Stub) is export {}
class xmlXPathAxis is repr(Stub) is export {}
class xmlXPathType is repr(Stub) is export {}
class xmlValidState is repr(Stub) is export {}

sub xmlStrdup(Str --> Pointer) is native(LIB) is export {*};
sub xmlStrndup(Blob, int32 --> Pointer) is native(LIB) is export {*};

multi trait_mod:<is>(Attribute $att, :&rw-ptr!) {

    my role PointerSetter[&setter] {
        #| override standard Attribute method for generating accessors
        method compose(Mu $package) {
            my $name = self.name.subst(/^(\$|\@|\%)'!'/, '');
            my &accessor = sub (\obj) is rw {
                Proxy.new(
                    FETCH => { self.get_value(obj) },
                    STORE => sub ($, $val is raw) {
                        setter(obj, $val);
                    });
            }
            $package.^add_method( $name, &accessor );
        }
    }

    $att does PointerSetter[&rw-ptr]
}

multi trait_mod:<is>(Attribute $att, :&rw-str!) {

    my role StringSetter[&setter] {
        method compose(Mu $package) {
            my $name = self.name.subst(/^(\$|\@|\%)'!'/, '');
            my &accessor = sub (\obj) is rw {
                Proxy.new(
                    FETCH => { self.get_value(obj) },
                    STORE => sub ($, $val) {
                        my $str := do with $val {.Str} else { Str };
                        setter(obj, $str);
                    });
            }
            $package.^add_method( $name, &accessor );
        }
    }

    $att does StringSetter[&rw-str]
}

class xmlBuf is repr('CStruct') is export {
    has xmlCharP      $.content; # The buffer content UTF8
    has uint32     $.compat_use; # for binary compatibility
    has uint32    $.compat_size; # for binary compatibility
    has int32     $.alloc is rw; # The realloc method
    has xmlCharP    $.contentIO; # in IO mode we may have a different base
    has size_t            $.use; # The buffer size used
    has size_t           $.size; # The buffer size
    has xmlBufOld      $.buffer; # wrapper for an old buffer
    has int32           $.error; # an error code if a failure occurred

    sub Create(--> xmlBuf) is native(LIB) is symbol('xmlBufCreate') {*}
    method Write(xmlCharP --> int32) is native(LIB) is symbol('xmlBufCat') {*}
    method WriteQuoted(xmlCharP --> int32) is native(LIB) is symbol('xmlBufWriteQuotedString') {*}
    method NodeDump(xmlDoc $doc, anyNode $cur, int32 $level, int32 $format --> int32) is native(LIB) is symbol('xmlBufNodeDump') is export { * }
    method Content(--> Str) is symbol('xmlBufContent') is native(LIB) is export { * }
    method Free is symbol('xmlBufFree') is native(LIB) is export { * }
    method new(--> xmlBuf:D) { Create() }
}

class xmlParserInputBuffer is repr('CStruct') is export {
    my constant xmlInputReadCallback = Pointer;
    my constant xmlInputWriteCallback = Pointer;
    has Pointer $.context;
    has xmlInputReadCallback $.read-callback;
    has xmlInputWriteCallback $.write-callback;
    has xmlCharEncodingHandler $.encoder;
    has xmlBuf $.buffer;
    has xmlBuf $.raw;
    has int32  $.compressed;
    has int32  $.error;
    has ulong  $.raw-consumed;

    sub xmlAllocParserInputBuffer(int32 $enc --> xmlParserInputBuffer) is native(LIB) {*}
    method new(xmlEncodingStr :$enc, xmlCharP :$string) {
        my Int $encoding = xmlParseCharEncoding($enc);
        given xmlAllocParserInputBuffer($encoding) {
             if $string {
                 my $n := .PushStr($string);
                 die "push to input buffer failed"
                     if $n < 0;
             }
            $_;
        }
    }
    method PushStr(xmlCharP:D --> int32) is native(BIND-LIB) is symbol('xml6_input_buffer_push_str') {*}
}

class xmlParserInput is repr('CStruct') is export {
    has xmlParserInputBuffer           $.buf;  # UTF-8 encoded buffer
    has Str                       $.filename   # The file analyzed, if any
          is rw-str(method xml6_input_set_filename(Str) is native(BIND-LIB) {*});
    has Str                       $.directory; # the directory/base of the file
    has xmlCharP                       $.base; # Base of the array to parse
    has xmlCharP                        $.cur; # Current char being parsed
    has xmlCharP                        $.end; # end of the array to parse
    has int32                        $.length; # length if known
    has int32                          $.line; # Current line
    has int32                           $.col; # Current column
    has ulong                      $.consumed; # How many xmlChars already consumed
    has xmlParserInputDeallocate       $.free; # function to deallocate the base
    has xmlCharP                   $.encoding; # the encoding string for entity
    has xmlCharP                    $.version; # the version string for entity
    has int32                    $.standalone; # Was that entity marked standalone
    has int32                            $.id; # a unique identifier for the entity

    sub xmlNewIOInputStream(xmlParserCtxt, xmlParserInputBuffer, int32 $enc --> xmlParserInput) is native(LIB) is export {*}
    sub xmlNewInputFromFile(xmlParserCtxt, Str --> xmlParserInput) is native(LIB) is export {*}
    method Free is native(LIB) is symbol('xmlFreeInputStream') {*}
}

class xmlNs is export is repr('CStruct') {
    has xmlNs        $.next; # next Ns link for this node
    has int32        $.type; # global or local (enum xmlNsType)
    has xmlCharP     $.href; # URL for the namespace
    has xmlCharP   $.prefix; # prefix for the namespace
    has Pointer  $._private; # application data
    has xmlDoc    $.context; # normally an xmlDoc

    method new(Str:D :$URI!, Str :$prefix, xmlElem :$node) {
        $node.NewNs($URI, $prefix);
    }
    method Free is native(LIB) is symbol('xmlFreeNs') {*}
    method Copy(--> xmlNs) is native(BIND-LIB) is symbol('xml6_ns_copy') {*}
    method copy { $.Copy }
    method Str {
        nextsame without self;
        nextsame if self.prefix ~~ 'xml';
        # approximation of xmlsave.c: xmlNsDumpOutput(...)
        my xmlBuf $buf .= new;

        $buf.Write('xmlns');
        $buf.Write(':' ~ $_)
            with self.prefix;

        with self.href {
            $buf.Write('=');
            $buf.WriteQuoted($_);
        }

        my str $content = $buf.Content;
        $buf.Free;
        $content;
    }
    method ItemNode { nativecast(itemNode, self) }
}

class xmlSAXLocator is repr('CStruct') is export {
    has Pointer  $.getPublicId is rw-ptr(
        method xml6_sax_locator_set_getPublicId( &cb (xmlParserCtxt $ctx --> Str) ) is native(BIND-LIB) {*}
    );

    has Pointer $.getSystemId is rw-ptr(
        method xml6_sax_locator_set_getSystemId( &cb (xmlParserCtxt $ctx --> Str) ) is native(BIND-LIB) {*}
    );

    has Pointer $.getLineNumber is rw-ptr(
        method xml6_sax_locator_set_getLineNumber( &cb (xmlParserCtxt $ctx --> Str) ) is native(BIND-LIB) {*}
    );

    has Pointer $.getColumnNumber is rw-ptr(
        method xml6_sax_locator_set_getColumnNumber( &cb (xmlParserCtxt $ctx --> Str) ) is native(BIND-LIB) {*}
    );

    method init is native(LIB) is symbol('xml6_sax_locator_init') {*}

    submethod BUILD(*%atts) {
        for %atts.pairs.sort {
            self."{.key}"() = .value;
        }
    }
}
class xmlSAXHandler is repr('CStruct') is export {

    submethod BUILD(*%atts) {
        for %atts.pairs.sort {
            self."{.key}"() = .value;
        }
    }
    method native { self } # already native

    has Pointer   $.internalSubset is rw-ptr(
        method xml6_sax_set_internalSubset( &cb (xmlParserCtxt $ctx, Str $name, Str $external-id, Str $system-id) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.isStandalone is rw-ptr(
        method xml6_sax_set_isStandalone( &cb (xmlParserCtxt $ctx --> int32) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.hasInternalSubset is rw-ptr(
        method xml6_sax_set_hasInternalSubset( &cb (xmlParserCtxt $ctx --> int32) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.hasExternalSubset is rw-ptr(
        method xml6_sax_set_hasExternalSubset( &cb (xmlParserCtxt $ctx --> int32) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.resolveEntity is rw-ptr(
        method xml6_sax_set_resolveEntity( &cb (xmlParserCtxt $ctx, Str $name, Str $public-id, Str $system-id --> xmlParserInput) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.getEntity is rw-ptr(
        method xml6_sax_set_getEntity( &cb (xmlParserCtxt $ctx, Str $name --> xmlEntity) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.entityDecl is rw-ptr(
        method xml6_sax_set_entityDecl( &cb (xmlParserCtxt $ctx, Str $name, uint32 $type, Str $public-id, Str $system-id) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.notationDecl is rw-ptr(
        method xml6_sax_set_notationDecl( &cb (xmlParserCtxt $ctx, Str $name, Str $public-id, Str $system-id) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.attributeDecl is rw-ptr(
        # todo xmlEnumeration $tree
        method xml6_sax_set_attributeDecl( &cb (xmlParserCtxt $ctx, Str $elem, Str $fullname, uint32 $type, uint32 $def, Str $default-value, xmlEnumeration $tree) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.elementDecl is rw-ptr(
        method xml6_sax_set_elementDecl( &cb (xmlParserCtxt $ctx, Str $name, uint32 $type, xmlElementContent $content) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.unparsedEntityDecl is rw-ptr(
        method xml6_sax_set_unparsedEntityDecl( &cb (xmlParserCtxt $ctx, Str $name, Str $public-id, Str $system-id, Str $notation-name) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.setDocumentLocator is rw-ptr(
        method xml6_sax_set_setDocumentLocator( &cb (xmlParserCtxt $ctx, xmlSAXLocator $loc) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.startDocument is rw-ptr(
        method xml6_sax_set_startDocument( &cb (xmlParserCtxt $ctx) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.endDocument is rw-ptr(
        method xml6_sax_set_endDocument( &cb (xmlParserCtxt $ctx) ) is native(BIND-LIB) {*}
    );

    has Pointer   $.startElement is rw-ptr(
        method xml6_sax_set_startElement( &cb (xmlParserCtxt $ctx, Str $name, CArray[Str] $atts) ) is native(BIND-LIB) {*}
    );
    
    has Pointer   $.endElement is rw-ptr(
        method xml6_sax_set_endElement( &cb (xmlParserCtxt $ctx, Str $name) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.reference is rw-ptr(
        method xml6_sax_set_reference( &cb (xmlParserCtxt $ctx, Str $name) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.characters is rw-ptr(
        method xml6_sax_set_characters( &cb (xmlParserCtxt $ctx, CArray[byte] $chars, int32 $len) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.ignorableWhitespace is rw-ptr(
        method xml6_sax_set_ignorableWhitespace( &cb (xmlParserCtxt $ctx, CArray[byte] $chars, int32 $len) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.processingInstruction is rw-ptr(
        method xml6_sax_set_processingInstruction( &cb (xmlParserCtxt $ctx, Str $target, Str $data) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.comment is rw-ptr(
        method xml6_sax_set_comment( &cb (xmlParserCtxt $ctx, Str $value) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.warning is rw-ptr(
        method xml6_sax_set_warning( &cb (xmlParserCtxt $ctx, Str $msg) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.error is rw-ptr(
        method xml6_sax_set_error( &cb (xmlParserCtxt $ctx, Str $msg) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.fatalError is rw-ptr(
        method xml6_sax_set_fatalError( &cb (xmlParserCtxt $ctx, Str $msg) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.getParameterEntity is rw-ptr(
        method xml6_sax_set_getParameterEntity( &cb (xmlParserCtxt $ctx, Str $name) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.cdataBlock is rw-ptr(
        method xml6_sax_set_cdataBlock( &cb (xmlParserCtxt $ctx, CArray[byte] $chars, int32 $len) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.externalSubset is rw-ptr(
        method xml6_sax_set_externalSubset( &cb (xmlParserCtxt $ctx, Str $name, Str $external-id, Str $system-id) ) is native(BIND-LIB) {*}
    );
    has uint32    $.initialized;
    has Pointer   $._private;
    has Pointer   $.startElementNs is rw-ptr(
        method xml6_sax_set_startElementNs( &cb (xmlParserCtxt $ctx, Str $local-name, Str $prefix, Str $uri, int32 $num-namespaces, CArray[Str] $namespaces, int32 $num-attributes, int32 $num-defaulted, CArray[Str] $attributes) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.endElementNs is rw-ptr(
        method xml6_sax_set_endElementNs( &cb (xmlParserCtxt $ctx, Str $local-name, Str $prefix, Str $uri) ) is native(BIND-LIB) {*}
    );
    has Pointer   $.serror is rw-ptr(
        method xml6_sax_set_serror( &cb (xmlParserCtxt $ctx, xmlError $error) ) is native(BIND-LIB) {*}
    );

    method xmlSAX2InitDefaultSAXHandler(int32 $warning) is native(LIB) {*}
    method xmlSAX2InitHtmlDefaultSAXHandler is native(LIB) {*}
    method init(Bool :$html, Bool :$warning = True) {
        $html
        ?? $.xmlSAX2InitHtmlDefaultSAXHandler()
        !! $.xmlSAX2InitDefaultSAXHandler( +$warning );
    }
    method ParseDoc(Str, int32 $recovery --> xmlDoc) is native(LIB) is symbol('xmlSAXParseDoc') {*};

}

class xmlError is export {
    has int32           $.domain; # What part of the library raised this error
    has int32             $.code; # The error code, e.g. an xmlParserError
    has Str            $.message; # human-readable informative error message
    has int32            $.level; # how consequent is the error
    has Str               $.file; # the filename
    has int32             $.line; # the line number if available
    has Str               $.str1; # extra string information
    has Str               $.str2; # extra string information
    has Str               $.str3; # extra string information
    has int32             $.int1; # extra number information
    has int32           $.column; # error column # or 0 if N/A
    has xmlParserCtxt     $.ctxt; # the parser context if available
    has anyNode           $.node; # the node in the tree

    method Reset() is native(LIB) is symbol('xmlResetError') {*};
}

class xmlXPathObject is export {
    has int32 $.type;

    has xmlNodeSet $.nodeset is rw;
    has int32       $.bool;
    has num64      $.float;
    has xmlCharP  $.string;

    has Pointer     $.user;
    has int32      $.index;
    has Pointer    $.user2;
    has int32     $.index2;

    sub xmlXPathIsInf(num64 --> int32) is native(LIB) is export {*}
    sub xmlXPathIsNaN(num64 --> int32) is native(LIB) is export {*}
    method add-reference is native(BIND-LIB) is symbol('xml6_xpath_object_add_reference') {*}
    method is-referenced(--> int32) is native(BIND-LIB) is symbol('xml6_xpath_object_is_referenced') {*}
    method remove-reference(--> int32) is native(BIND-LIB) is symbol('xml6_xpath_object_remove_reference') {*}
    method Reference {
        with self {
            .add-reference;
            with .value {
                when xmlNodeSet { .Reference }
            }
        }
    }
    method Unreference {
        with self {
            my $v := .value;
            if .remove-reference {
                .select; # detach value
                .Free;
            }
            $v.Unreference if $v ~~ xmlNodeSet:D;
        }
    }

    method domXPathGetNodeSet(int32 $select --> xmlNodeSet) is native(BIND-LIB) {*}
    method Free is symbol('xmlXPathFreeObject') is native(LIB) {*}

    sub xmlXPathNewString(xmlCharP --> xmlXPathObject) is native(LIB) {*}
    sub xmlXPathNewFloat(num64 --> xmlXPathObject) is native(LIB) {*}
    sub xmlXPathNewBoolean(int32 --> xmlXPathObject) is native(LIB) {*}
    sub xmlXPathNewNodeSet(anyNode:D --> xmlXPathObject) is native(LIB) {*}
    sub xmlXPathWrapNodeSet(xmlNodeSet --> xmlXPathObject) is native(LIB) {*}

    multi method coerce(Bool $v)           { xmlXPathNewBoolean($v) }
    multi method coerce(Numeric $v)        { xmlXPathNewFloat($v.Num) }
    multi method coerce(Str $v)            { xmlXPathNewString($v) }
    multi method coerce(anyNode:D $v)      { xmlXPathNewNodeSet($v) }
    multi method coerce(xmlNodeSet:D $v)   { xmlXPathWrapNodeSet($v.copy) }
    multi method coerce($_) is default     { fail "unable to coerce to an XPath Object: {.perl}" }

    method select {
        self.value: :select;
    }

    method value(Bool :$select = False) {
        return Nil unless self.defined;
        given $!type {
            when XPATH_UNDEFINED { Mu }
            when XPATH_NODESET | XPATH_XSLT_TREE {
                self.domXPathGetNodeSet(+$select); 
            }
            when XPATH_BOOLEAN { ? $!bool }
            when XPATH_NUMBER {
                given xmlXPathIsInf($!float) {
                    when +1 { Inf }
                    when -1 { -Inf }
                    default {
                        xmlXPathIsNaN($!float)
                            ?? NaN
                            !! $!float.Numeric;
                    }
                }
            }
            when XPATH_STRING { $!string }
            when XPATH_POINT {
                fail "todo: XPath point values";
            }
            when XPATH_LOCATIONSET {
                fail "todo: location-set values";
            }
            when XPATH_USERS {
                fail "todo: XPath user objects";
            }
            default {
                fail "unhandled XPath Object type: $_";
            }
        }
    }
}

class xmlXPathContext is repr('CStruct') is export {
    has xmlDoc $.doc;                            # The current document
    has anyNode $.node;                          # The current node
    has int32 $.nb_variables_unused;             # unused (hash table)
    has int32 $.max_variables_unused;            # unused (hash table)
    has xmlHashTable $.varHash;                  # Hash table of defined variables

    has int32 $.nb_types;                        # number of defined types
    has int32 $.max_types;                       # max number of types
    has Pointer[xmlXPathType] $.types;           # Array of defined types

    has int32 $.nb_funcs_unused;                 # unused (hash table)
    has int32 $.max_funcs_unused;                # unused (hash table)
    has xmlHashTable $.funcHash;                 # Hash table of defined funcs

    has int32 $.nb_axis;                         # number of defined axis
    has int32 $.max_axis;                        # max number of axis
    has xmlXPathAxis $.axis;                     # Array of defined axis

    # the namespace nodes of the context node
    has Pointer[xmlNs] $.namespaces;             # Array of namespaces
    has int32 $.nsNr;                            # number of namespace in scope
    has Pointer $.user;                          # function to free

    # extra variables
    has int32 $.contextSize is rw;               # the context size
    has int32 $.proximityPosition is rw;         # the proximity position

    # the set of namespace declarations in scope for the expression
    has xmlHashTable $.nsHash;                   # The namespaces hash table
    my constant xmlXPathVariableLookupFunc = Pointer;
    has xmlXPathVariableLookupFunc $.varLookupFunc;# variable lookup func
    has Pointer $.varLookupData;                 # variable lookup data

    # Possibility to link in an extra item
    has Pointer $.extra;                         # needed for XSLT

    # The function name and URI when calling a function
    has xmlCharP $.function;
    has xmlCharP $.functionURI;

    # function lookup function and data
    my constant xmlXPathFuncLookupFunc = Pointer;
    has xmlXPathFuncLookupFunc $.funcLookupFunc; # function lookup func
    has Pointer $.funcLookupData;                # function lookup data

    # temporary namespace lists kept for walking the namespace axis
    has Pointer[xmlNs] $.tmpNsList;              # Array of namespaces
    has int32 $.tmpNsNr;                         # number of namespaces in scope

    # error reporting mechanism
    has Pointer $.userData;                      # user specific data block
    my constant xmlStructuredErrorFunc = Pointer;
    has xmlStructuredErrorFunc $.error;          # the callback in case of errors
    HAS xmlError $.lastError;                    # the last error
    has anyNode  $.debugNode;                    # the source node XSLT

    # dictionary
    has xmlDict $.dict;                          # dictionary if any

    has int32 $.flags;                           # flags to control compilation

    # Cache for reusal of XPath objects
    has Pointer $.cache;

    # Resource limits
    has ulong $.opLimit;
    has ulong $.opCount;
    has int32 $.depth;
    has int32 $.maxDepth;
    has int32 $.maxParserDepth;

    sub domXPathNewCtxt(anyNode --> xmlXPathContext) is native(BIND-LIB) {*}
    method Free is symbol('domXPathFreeCtxt') is native(BIND-LIB) {*}
    method domXPathFindCtxt(xmlXPathCompExpr, anyNode, int32 --> xmlXPathObject) is native(BIND-LIB) {*}
    method domXPathSelectCtxt(xmlXPathCompExpr, anyNode --> xmlNodeSet) is native(BIND-LIB) {*}
    method domXPathCtxtSetNode(anyNode) is native(BIND-LIB) {*}
    multi method new(xmlDoc:D :$doc!) {
        domXPathNewCtxt($doc);
    }
    multi method new(xmlNode :$node) is default {
        domXPathNewCtxt($node);
    }

    method findnodes(xmlXPathCompExpr:D $expr, anyNode $ref-node? --> xmlNodeSet) { self.domXPathSelectCtxt($expr, $ref-node); }

    method find(xmlXPathCompExpr:D $expr, anyNode $ref-node?, Bool :$bool) {
        self.domXPathFindCtxt($expr, $ref-node, $bool);
    }
    method RegisterNs(Str, Str --> int32) is symbol('xmlXPathRegisterNs') is native(LIB) {*}
    method NsLookup(xmlCharP --> xmlCharP) is symbol('xmlXPathNsLookup') is native(LIB) {*}

    method RegisterFunc(xmlCharP $name, &func1 (xmlXPathParserContext, int32 --> xmlXPathObject) ) is symbol('xmlXPathRegisterFunc') is native(LIB) {*}
    method RegisterFuncNS(xmlCharP $name, xmlCharP $ns-uri, &func2 (xmlXPathParserContext, int32 --> xmlXPathObject) ) is symbol('xmlXPathRegisterFuncNS') is native(LIB) {*}
    method RegisterVariableLookup( &func3 (xmlXPathContext, Str, Str --> xmlXPathObject), Pointer ) is symbol('xmlXPathRegisterVariableLookup') is native(LIB) {*}
}

class xmlXPathParserContext is export {

    has xmlCharP $.cur;                      # the current char being parsed
    has xmlCharP $.base;                     # the full expression

    has int32 $.error;                       # error code

    has xmlXPathContext          $.context; # the evaluation context
    has xmlXPathObject             $.value; # the current value
    has int32                    $.valueNr; # number of values stacked
    has int32                   $.valueMax; # max number of values stacked
    has Pointer[xmlXPathObject] $.valueTab; # stack of values

    has xmlXPathCompExpr            $.comp; # the precompiled expression
    has int32                       $.xptr; # it this an XPointer expression
    has anyNode                 $.ancestor; # used for walking preceding axis

    has int32                 $.valueFrame; # used to limit Pop on the stack

    method valuePop(--> xmlXPathObject) is native(LIB) {*}
    method valuePush(xmlXPathObject --> int32) is native(LIB) {*}
}

class anyNode is export does LibXML::Native::DOM::Node {
    has Pointer $._private; # application data
    has int32       $.type; # type number, must be second !
    has xmlCharP    $!name; # the name of the node, or the entity
    method name { $!name }
    has xmlNode $.children; # parent->childs link
    has xmlNode     $.last; # last child link
    has xmlNode   $.parent; # child->parent link
    has xmlNode     $.next; # next sibling link
    has xmlNode     $.prev; # previous sibling link
    has xmlDoc       $.doc  # the containing document
         is rw-ptr(method xml6_node_set_doc(xmlDoc) is native(BIND-LIB) {*});
    # + additional fields, depending on node-type; see xmlElem, xmlDoc, xmlAttr, etc...

    method GetBase { self.doc.NodeGetBase(self) }
    method SetBase(xmlCharP) is native(LIB) is symbol('xmlNodeSetBase') {*}
    method Free() is native(LIB) is symbol('xmlFreeNode') {*}
    method SetListDoc(xmlDoc) is native(LIB) is symbol('xmlSetListDoc') {*}
    method GetLineNo(--> long) is native(LIB) is symbol('xmlGetLineNo') {*}
    method IsBlank(--> int32) is native(LIB) is symbol('xmlIsBlankNode') {*}
    method GetNodePath(--> xmlCharP) is native(LIB) is symbol('xmlGetNodePath') {*}
    method AddChild(anyNode --> anyNode) is native(LIB) is symbol('xmlAddChild') {*}
    method AddChildList(anyNode --> anyNode) is native(LIB) is symbol('xmlAddChildList') {*}
    method AddContent(xmlCharP) is native(LIB) is symbol('xmlNodeAddContent') {*}
    method SetContext(xmlXPathContext --> int32) is symbol('xmlXPathSetContextNode') is native(LIB) {*}
    method XPathEval(Str, xmlXPathContext --> xmlXPathObject) is symbol('xmlXPathNodeEval') is native(LIB) {*}
    method domXPathSelectStr(Str --> xmlNodeSet) is native(BIND-LIB) {*}
    method domXPathFind(xmlXPathCompExpr, int32 --> xmlXPathObject) is native(BIND-LIB) {*}
    method domFailure(--> xmlCharP) is native(BIND-LIB) {*}
    method dom-error { die $_ with self.domFailure }
    method domAppendChild(anyNode --> anyNode) is native(BIND-LIB) {*}
    method domReplaceNode(anyNode --> anyNode) is native(BIND-LIB) {*}
    method domAddSibling(anyNode --> anyNode) is native(BIND-LIB) {*}
    method domReplaceChild(anyNode, anyNode --> anyNode) is native(BIND-LIB) {*}
    method domInsertBefore(anyNode, anyNode --> anyNode) is native(BIND-LIB) {*}
    method domInsertAfter(anyNode, anyNode --> anyNode) is native(BIND-LIB) {*}
    method domGetNodeName(--> Str) is native(BIND-LIB) {*}
    method domSetNodeName(Str) is native(BIND-LIB) {*}
    method domGetNodeValue(--> Str) is native(BIND-LIB) {*}
    method domSetNodeValue(Str) is native(BIND-LIB) {*}
    method domRemoveChild(anyNode --> anyNode) is native(BIND-LIB) {*}
    method domRemoveChildNodes(--> xmlDocFrag) is native(BIND-LIB) {*}

    method domAppendTextChild(Str $name, Str $value) is native(BIND-LIB) {*}
    method domAddNewChild(Str $uri, Str $name --> anyNode) is native(BIND-LIB) {*}
    method domSetNamespace(Str $URI, Str $prefix, int32 $flag --> int32) is native(BIND-LIB) {*}
    method first-child(int32 --> anyNode) is native(BIND-LIB) is symbol('xml6_node_first_child') {*}
    method next-node(int32 --> anyNode) is native(BIND-LIB) is symbol('xml6_node_next') {*}
    method prev-node(int32 --> anyNode) is native(BIND-LIB) is symbol('xml6_node_prev') {*}
    method is-referenced(--> int32) is native(BIND-LIB) is symbol('domNodeIsReferenced') {*}
    method root(--> anyNode) is native(BIND-LIB) is symbol('xml6_node_find_root') {*}
    method domGetChildrenByLocalName(Str --> xmlNodeSet) is native(BIND-LIB) {*}
    method domGetChildrenByTagName(Str --> xmlNodeSet) is native(BIND-LIB) {*}
    method domGetChildrenByTagNameNS(Str, Str --> xmlNodeSet) is native(BIND-LIB) {*}
    method domNormalize(--> int32) is native(BIND-LIB) {*}

    method xml6_node_to_str(int32 $opts --> Str) is native(BIND-LIB) {*}
    method xml6_node_to_str_C14N(int32 $comments, int32 $mode, CArray[Str] $inc-prefix is rw, xmlNodeSet --> Str) is native(BIND-LIB) {*}

    method Str(UInt :$options = 0 --> Str) is default {
        with self {
            .xml6_node_to_str($options);
        }
        else {
            Str
        }
    }

    method Blob(UInt :$options = 0, Str :$enc --> Blob) {
        method xml6_node_to_buf(int32 $opts, size_t $len is rw, Str $enc  --> Pointer[uint8]) is native(BIND-LIB) {*}
        sub memcpy(Blob, Pointer, size_t) is native {*}
        sub free(Pointer) is native {*}
        my buf8 $buf;
        with self {
            with .xml6_node_to_buf($options, my size_t $len, $enc) {
                $buf .= allocate($len);
                memcpy($buf, $_, $len);
                free($_);
            }
        }
        $buf;
    }

    method xmlCopyNode (int32 $extended --> anyNode) is native(LIB) {*}
    method xmlDocCopyNode(xmlDoc, int32 --> anyNode) is native(LIB) {*}
    method copy(Bool :$deep) {
        my $extended := $deep ?? 1 !! 2;
        with $.doc {
            $.xmlDocCopyNode($_, $extended);
        }
        else {
            $.xmlCopyNode( $extended );
        }
    }

    method string-value(--> xmlCharP) is native(LIB) is symbol('xmlXPathCastNodeToString') {*}
    method Unlink is native(LIB) is symbol('xmlUnlinkNode') {*}
    method Release is native(BIND-LIB) is symbol('domReleaseNode') {*}
    method Reference is native(BIND-LIB) is symbol('xml6_node_add_reference') {*}
    method remove-reference(--> int32) is native(BIND-LIB) is symbol('xml6_node_remove_reference') {*}
    method lock(--> int32) is native(BIND-LIB) is symbol('xml6_node_lock') {*}
    method unlock(--> int32) is native(BIND-LIB) is symbol('xml6_node_unlock') {*}
    method Unreference{
        with self {
            if .remove-reference {
                # this particular node is no longer referenced directly
                given .root {
                    # release or keep the tree, in it's entirety
                    .Free unless .is-referenced;
                }
            }
        }
    }
    # role refactor needed
    method domSetNamespaceDeclPrefix { ... }
    method domSetNamespaceDeclURI { ... }
    method domGetNamespaceDeclURI { ... }
    method ItemNode handles<delegate> { nativecast(itemNode, self) }
}

class xmlNode is anyNode {
    has xmlNs            $.ns  # pointer to the associated namespace
        is rw-ptr( method xml6_node_set_ns(xmlNs) is native(BIND-LIB) {*});
    has xmlCharP    $.content  # the content
        is rw-str(method xml6_node_set_content(xmlCharP) is native(BIND-LIB) {*});
    has xmlAttr  $.properties; # properties list
    has xmlNs         $.nsDef  # namespace definitions on this node
        is rw-ptr(method xml6_node_set_nsDef(xmlNs) is native(BIND-LIB) {*});
    has Pointer        $.psvi; # for type/PSVI informations
    has uint16         $.line; # line number
    has uint16        $.extra; # extra data for XPath/XSLT

    method domSetNamespaceDeclURI(xmlCharP $prefix, xmlCharP $uri --> int32) is native(BIND-LIB) {*}
    method domGetNamespaceDeclURI(xmlCharP $prefix --> xmlCharP) is native(BIND-LIB) {*}
    method domSetNamespaceDeclPrefix(xmlCharP $prefix, xmlCharP $ns-prefix --> int32) is native(BIND-LIB) {*}
}

class xmlElem is xmlNode is export does LibXML::Native::DOM::Element {
    # type: XML_ELEMENT_NODE
    method NewNs(xmlCharP $href, xmlCharP $prefix --> xmlNs) is native(LIB) is symbol('xmlNewNs') {*};
    method SetProp(Str, Str --> xmlAttr) is native(LIB) is symbol('xmlSetProp') {*}
    method domGetAttributeNode(xmlCharP $qname --> xmlAttr) is native(BIND-LIB) {*}
    method domGetAttribute(xmlCharP $qname --> xmlCharP) is native(BIND-LIB)  {*}
    method domHasAttributeNS(xmlCharP $uri, xmlCharP $name --> int32) is native(BIND-LIB) {*}
    method domGetAttributeNS(xmlCharP $uri, xmlCharP $name --> xmlCharP) is native(BIND-LIB) {*}
    method domGetAttributeNodeNS(xmlCharP $uri, xmlCharP $name --> xmlAttr) is native(BIND-LIB) {*}
    method domSetAttribute(Str, Str --> int32) is native(BIND-LIB) {*}
    method domSetAttributeNode(xmlAttr --> xmlAttr) is native(BIND-LIB) {*}
    method domSetAttributeNodeNS(xmlAttr --> xmlAttr) is native(BIND-LIB) {*}
    method domSetAttributeNS(Str $URI, Str $name, Str $value --> xmlAttr) is native(BIND-LIB) {*}
    method domGenNsPrefix(Str $base-prefix --> Str) is native(BIND-LIB) {*}

    sub xmlNewNode(xmlNs, Str $name --> xmlElem) is native(LIB) {*}
    multi method new(Str:D :$name!, xmlNs:D :$ns, xmlDoc:D :$doc!) {
        $doc.new-node(:$name, :$ns);
    }
    multi method new(Str:D :$name!, xmlNs :$ns) {
        given xmlNewNode($ns, $name) -> xmlElem:D $node {
            $node.nsDef = $_ with $ns;
            $node;
        }
    }

}

class xmlTextNode is xmlNode is repr('CStruct') is export {
    # type: XML_TEXT_NODE
    sub xmlNewText(Str $content --> xmlTextNode) is native(LIB) {*}
    method new(Str :$content!, xmlDoc :$doc) {
        given xmlNewText($content) -> xmlTextNode:D $node {
            $node.doc = $_ with $doc;
            $node;
        }
    }

}

class xmlCommentNode is xmlNode is repr('CStruct') is export {
    # type: XML_COMMENT_NODE
    sub xmlNewComment(Str $content --> xmlCommentNode) is native(LIB) {*}
    method new(Str :$content!, xmlDoc :$doc) {
        given xmlNewComment($content) -> xmlCommentNode:D $node {
            $node.doc = $_ with $doc;
            $node;
        }
    }
}

class xmlCDataNode is xmlNode is repr('CStruct') is export {
    # type: XML_CDATA_SECTION_NODE
    sub xmlNewCDataBlock(xmlDoc, Blob $content, int32 $len --> xmlCDataNode) is native(LIB) {*}
    multi method new(Str :content($string)!, xmlDoc :$doc --> xmlCDataNode:D) {
        my Blob $content = $string.encode;
        self.new: :$content, :$doc;
    }
    multi method new(Blob :content($buf)!, xmlDoc :$doc --> xmlCDataNode:D) {
        my $len = $buf.elems;
        xmlNewCDataBlock($doc, $buf, $len);
    }
}

class xmlPINode is xmlNode is repr('CStruct') is export {
    # type: XML_PI_NODE
    sub xmlNewPI(xmlCharP $name, xmlCharP $content) is native(LIB) {*}
    multi method new(xmlDoc:D :$doc!, Str:D :$name!, Str :$content) {
        $doc.new-pi(:$name, :$content);
    }
    multi method new(Str:D :$name!, Str :$content) {
        xmlNewPI($name, $content);
    }
}

class xmlEntityRefNode is xmlNode is repr('CStruct') is export {
    # type: XML_ENTITY_REF_NODE
    multi method new(xmlDoc:D :$doc!, Str:D :$name!) {
        $doc.new-ent-ref(:$name);
    }
}

class xmlAttr is anyNode does LibXML::Native::DOM::Attr is export {
    # type: XML_ATTRIBUTE_NODE
    has xmlNs       $.ns; # the associated namespace
    has int32    $.atype; # the attribute type if validating
    has Pointer   $.psvi; # for type/PSVI informations

    method Free is native(LIB) is symbol('xmlFreeProp') {*}
    method xmlCopyProp(--> xmlAttr) is native(LIB) {*}
    method copy() { $.xmlCopyProp }
    method new(Str :$name!, Str :$value!, xmlDoc :$doc --> xmlAttr:D) {
        $doc.NewProp($name, $value);
    }
    method domAttrSerializeContent(--> xmlCharP) is native(BIND-LIB) {*}
}

class xmlDoc is anyNode does LibXML::Native::DOM::Document is export {
    # type: XML_DOCUMENT_NODE
    has int32           $.compression; # level of zlib compression
    has int32           $.standalone is rw;  # standalone document (no external refs)
                                       # 1 if standalone="yes"
                                       # 0 if standalone="no"
                                       # -1 if there is no XML declaration
                                       # -2 if there is an XML declaration, but no
                                       #    standalone attribute was specified
    has xmlDtd          $.intSubset;   # the document internal subset
    has xmlDtd          $.extSubset;   # the document external subset
    has xmlNs           $.oldNs;       # Global namespace, the old way
    has xmlCharP        $.version      # the XML version string
             is rw-str(method xml6_doc_set_version(Str) is native(BIND-LIB) {*});
    has xmlCharP        $.encoding     # external initial encoding, if any
             is rw-str(method xml6_doc_set_encoding(Str) is native(BIND-LIB) {*});
    has Pointer         $.ids;         # Hash table for ID attributes if any
    has Pointer         $.refs;        # Hash table for IDREFs attributes if any
    has xmlCharP        $.URI          # The URI for that document
             is rw-str(method xml6_doc_set_URI(Str) is native(BIND-LIB) {*});
    has int32           $.charset;     # Internal flag for charset handling,
                                       # actually an xmlCharEncoding 
    has xmlDict         $.dict         # dict used to allocate names or NULL
             is rw-ptr(method xml6_doc_set_dict(xmlDict) is native(BIND-LIB) {*});
    has Pointer         $.psvi;        # for type/PSVI informations
    has int32           $.parseFlags;  # set of xmlParserOption used to parse the
                                       # document
    has int32           $.properties;  # set of xmlDocProperties for this document
                                       # set at the end of parsing

    method DumpFormatMemoryEnc(Pointer[uint8] $ is rw, int32 $ is rw, Str, int32 ) is symbol('xmlDocDumpFormatMemoryEnc') is native(LIB) is export {*}
    sub xmlSaveFormatFile(Str $filename, xmlDoc $doc, int32 $format --> int32) is native(LIB) is export {*}
    # this method can save documents with compression
    method write(Str:D $filename, Int() :$format = 0) {
         xmlSaveFormatFile($filename, self, $format);
    }
    method GetRootElement(--> xmlElem) is symbol('xmlDocGetRootElement') is native(LIB) is export { * }
    method SetRootElement(xmlElem --> xmlElem) is symbol('xmlDocSetRootElement') is native(LIB) is export { * }
    method Copy(int32 $deep --> xmlDoc) is symbol('xmlCopyDoc') is native(LIB) {*}
    method copy(Bool :$deep = True) { $.Copy(+$deep) }
    method Free is native(LIB) is symbol('xmlFreeDoc') {*}
    method xmlParseBalancedChunkMemory(xmlSAXHandler $sax-handler, Pointer $user-data, int32 $depth, xmlCharP $string, Pointer[anyNode] $list is rw --> int32) is native(LIB) {*}
    method xmlParseBalancedChunkMemoryRecover(xmlSAXHandler $sax-handler, Pointer $user-data, int32 $depth, xmlCharP $string, Pointer[anyNode] $list is rw, int32 $repair --> int32) is native(LIB) {*}
    method NewNode(xmlNs, xmlCharP $name, xmlCharP $content --> xmlElem) is native(LIB) is symbol('xmlNewDocNode') {*}
    method NewDtd(Str, Str, Str --> xmlDtd) is native(LIB) is symbol('xmlNewDtd') {*}
    method CreateIntSubset(Str, Str, Str --> xmlDtd) is native(LIB) is symbol('xmlCreateIntSubset') {*}
    method GetCompressMode(--> int32) is native(LIB) is symbol('xmlGetDocCompressMode') {*}
    method SetCompressMode(int32) is native(LIB) is symbol('xmlSetDocCompressMode') {*}

    method new-node(Str:D :$name!, xmlNs :$ns, Str :$content --> xmlElem:D) {
        given self.NewNode($ns, $name, $content) -> xmlElem:D $node {
            $node.nsDef = $_ with $ns;
            $node;
        }
    }
    method NewPI(xmlCharP $name, xmlCharP $content --> xmlPINode) is native(LIB) is symbol('xmlNewDocPI') {*}
    method new-pi(Str:D :$name!, Str :$content --> xmlPINode:D) {
       self.NewPI($name, $content);
    }
    method NewEntityRef(xmlCharP $name --> xmlEntityRefNode) is native(LIB) is symbol('xmlNewReference') {*}
    method new-ent-ref(Str:D :$name! --> xmlEntityRefNode:D) {
       self.NewEntityRef($name);
    }

    method NodeGetBase(anyNode --> xmlCharP) is native(LIB) is symbol('xmlNodeGetBase') {*}
    method EncodeEntitiesReentrant(xmlCharP --> xmlCharP) is native(LIB) is symbol('xmlEncodeEntitiesReentrant') {*}
    method NewProp(xmlCharP $name, xmlCharP $value --> xmlAttr) is symbol('xmlNewDocProp') is native(LIB) {*}
    method XIncludeProcessFlags(uint32 $flags --> int32) is symbol('xmlXIncludeProcessFlags') is native(LIB) {*}
    method SearchNs(anyNode, Str --> xmlNs) is native(LIB) is symbol('xmlSearchNs') {*}
    method SearchNsByHref(anyNode, Str --> xmlNs) is native(LIB) is symbol('xmlSearchNsByHref') {*}
    method GetID(Str --> xmlAttr) is native(LIB) is symbol('xmlGetID') {*}
    method IsID(xmlNode, xmlAttr --> int32) is native(LIB) is symbol('xmlIsID') {*}
    method IndexElements(--> long) is symbol('xmlXPathOrderDocElems') is native(LIB) {*}

    sub xmlNewDoc(xmlCharP $version --> xmlDoc) is native(LIB) {*}
    method new(Str:D() :$version = '1.0') {
        xmlNewDoc($version);
    }

    method domCreateAttribute(Str, Str --> xmlAttr) is native(BIND-LIB) {*}
    method domCreateAttributeNS(Str, Str, Str --> xmlAttr) is native(BIND-LIB) {*}
    method domImportNode(anyNode, int32, int32 --> anyNode) is native(BIND-LIB) {*}
    method domGetInternalSubset(--> xmlDtd) is native(BIND-LIB) {*}
    method domGetExternalSubset(--> xmlDtd) is native(BIND-LIB) {*}
    method domSetInternalSubset(xmlDtd) is native(BIND-LIB) {*}
    method domSetExternalSubset(xmlDtd) is native(BIND-LIB) {*}

}

class htmlDoc is xmlDoc is repr('CStruct') is export {
    # type: XML_HTML_DOCUMENT_NODE
    method DumpFormat(Pointer[uint8] $ is rw, int32 $ is rw, int32 ) is symbol('htmlDocDumpMemoryFormat') is native(LIB) {*}
    sub memcpy(Blob, Pointer, size_t) is native {*}
    sub free(Pointer) is native {*}

    method dump(Bool:D :$format = True) {
        my Pointer[uint8] $out .= new;
        my int32 $len;

        self.DumpFormat($out, $len, +$format);

        if +$out && $len {
            my buf8 $buf .= allocate($len);
            memcpy($buf, $out, $len);
            free($out);
            $buf.decode; # encoding?
        }
        else {
            Str;
        }
    }
}

class xmlDocFrag is xmlNode is export {
    # type: XML_DOCUMENT_FRAG_NODE
    sub xmlNewDocFragment(xmlDoc $doc --> xmlDocFrag) is native(LIB) {*}
    method new(xmlDoc :$doc, xmlNode :$nodes) {
        my xmlDocFrag:D $frag = xmlNewDocFragment($doc);
        $frag.set-nodes($_) with $nodes;
        $frag;
    }
}

class xmlDtd is anyNode is export {
    # type: XML_DTD_NODE
    has Pointer   $.notations; # Hash table for notations if any
    has Pointer    $.elements; # Hash table for elements if any
    has Pointer  $.attributes; # Hash table for attributes if any
    has Pointer    $.entities; # Hash table for entities if any
    has xmlCharP $.ExternalID; # External identifier for PUBLIC DTD
    has xmlCharP   $.SystemID; # URI for a SYSTEM or PUBLIC DTD
    has Pointer   $.pentities; # Hash table for param entities if any

    method publicId { $!ExternalID }
    method systemId { $!SystemID }

    method Copy(--> xmlDtd) is native(LIB) is symbol('xmlCopyDtd') {*}
    method copy() { $.Copy }
    sub xmlIOParseDTD(xmlSAXHandler, xmlParserInputBuffer:D, int32 $enc --> xmlDtd) is native(LIB) {*}
    sub xmlSAXParseDTD(xmlSAXHandler, Str, Str --> xmlDtd) is native(LIB) {*}

    multi method new(:type($)! where 'internal', xmlDoc:D :$doc, Str :$name, Str :$external-id, Str :$system-id) {
        $doc.CreateIntSubset( $name, $external-id, $system-id);
    }
    multi method new(:type($)! where 'external', xmlDoc :$doc, Str :$name, Str :$external-id, Str :$system-id) {
        $doc.NewDtd( $name, $external-id, $system-id);
    }
    multi method new(|c) is default { fail c.perl }
    multi method parse(Str:D :$string!, xmlSAXHandler :$sax-handler, xmlEncodingStr:D :$enc!) {
        my Int $encoding = xmlParseCharEncoding($enc);
        my xmlParserInputBuffer:D $buffer .= new: :$enc, :$string;
        xmlIOParseDTD($sax-handler, $buffer, $encoding);
    }
    multi method parse(Str :$external-id, Str :$system-id, xmlSAXHandler :$sax-handler) is default {
        xmlSAXParseDTD($sax-handler, $external-id, $system-id);
    }
}

class xmlAttrDecl is repr('CStruct') is anyNode is export {
    # type: XML_ATTRIBUTE_DECL
    has xmlAttr        $.nexth; # next in hash table
    has int32          $.atype; # the attribute type
    has int32            $.def; # default mode (enum xmlAttributeDefault)
    has xmlCharP$.defaultValue; # or the default value
    has xmlEnumeration  $.tree; # or the enumeration tree if any
    has xmlCharP      $.prefix; # the namespace prefix if any
    has xmlCharP        $.elem; # Element holding the attribute

}

class xmlEntity is anyNode is export {
    # type: XML_ENTITY_DECL
    has xmlCharP       $.orig; # content without ref substitution */
    has xmlCharP    $.content; # content or ndata if unparsed */
    has int32        $.length; # the content length */
    has int32         $.etype; # The entity type */
    has xmlCharP $.ExternalID; # External identifier for PUBLIC */
    has xmlCharP   $.SystemID; # URI for a SYSTEM or PUBLIC Entity */

    has xmlEntity     $.nexte; # unused */
    has xmlCharP        $.URI; # the full URI as computed */
    has int32         $.owner; # does the entity own the childrens */
    has int32       $.checked; # was the entity content checked */
                               # this is also used to count entities
                               # references done from that entity
                               # and if it contains '<' */
    sub xmlGetPredefinedEntity(xmlCharP $name --> xmlEntity) is native(LIB)is export { * }
    sub xml6_entity_create(xmlCharP $name, int32 $type, xmlCharP $ext-id, xmlCharP $int-id, xmlCharP $value --> xmlEntity) is native(BIND-LIB) {*}
    method get-predefined(Str :$name!) {
        xmlGetPredefinedEntity($name);
    }
    method Free is native(LIB) is symbol('xmlFreeEntity') {*}
    method create(Str:D :$name!, Str:D :$content!, Int :$type = XML_INTERNAL_GENERAL_ENTITY, Str :$external-id, Str :$internal-id) {
        xml6_entity_create($name, $type, $external-id, $internal-id, $content );
    }
}

class xmlElementDecl is repr('CStruct') is anyNode is export {
    # type: XML_ELEMENT_DECL
    has int32                $.etype; # The type */
    has xmlElementContent  $.content; # the allowed element content */
    has xmlAttrDecl     $.attributes; # List of the declared attributes */
    has xmlCharP            $.prefix; # the namespace prefix if any */
    has xmlRegexp        $.contModel; # the validating regexp */
}

# itemNodes are xmlNodeSet members; which can be either anyNode or xmlNs objects.
# These have distinct structs, but have the second field, 'type' in common
class itemNode is export {
    has Pointer $._; # first field depends on type
    has int32 $.type;
    # + other fields, which also depend on type
    method delegate {
        my $class := do given $!type {
            when XML_ATTRIBUTE_DECL     { xmlAttrDecl }
            when XML_ATTRIBUTE_NODE     { xmlAttr }
            when XML_CDATA_SECTION_NODE { xmlCDataNode }
            when XML_COMMENT_NODE       { xmlCommentNode }
            when XML_DOCUMENT_FRAG_NODE { xmlDocFrag }
            when XML_DOCUMENT_NODE      { xmlDoc }
            when XML_DTD_NODE           { xmlDtd }
            when XML_ELEMENT_DECL       { xmlElementDecl }
            when XML_ELEMENT_NODE       { xmlElem }
            when XML_ENTITY_DECL        { xmlEntity }
            when XML_ENTITY_REF_NODE    { xmlEntityRefNode }
            when XML_HTML_DOCUMENT_NODE { htmlDoc }
            when XML_NAMESPACE_DECL     { xmlNs }
            when XML_PI_NODE            { xmlPINode }
            when XML_TEXT_NODE          { xmlTextNode }
            default {
                warn "node type not yet handled: $_";
                anyNode;
            }
        }
        nativecast($class, self);
    }
}

class xmlNodeSet is export {
    has int32            $.nodeNr;
    has int32            $.nodeMax;
    has CArray[itemNode] $.nodeTab;

    sub xmlXPathNodeSetCreate(anyNode --> xmlNodeSet) is export is native(LIB) {*}
    method Reference is native(BIND-LIB) is symbol('domReferenceNodeSet') {*}
    method Unreference is native(BIND-LIB) is symbol('domUnreferenceNodeSet') {*}
    method delete(itemNode --> int32) is symbol('domDeleteNodeSetItem') is native(BIND-LIB) {*}
    method copy(--> xmlNodeSet) is symbol('domCopyNodeSet') is native(BIND-LIB) {*}
    method push(itemNode) is symbol('domPushNodeSet') is native(BIND-LIB) {*}
    method pop(--> itemNode) is symbol('domPopNodeSet') is native(BIND-LIB) {*}
    sub domCreateNodeSetFromList(itemNode, int32 --> xmlNodeSet) is native(BIND-LIB) {*}

    multi method new(itemNode:D :$node, :list($)! where .so, Bool :$keep-blanks = True) {
        domCreateNodeSetFromList($node, +$keep-blanks);
    }
    multi method new(anyNode :$node) is default {
        xmlXPathNodeSetCreate($node);
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
    has Pointer                $.warning;   # the callback in case of warnings

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

    method ValidateDtd(xmlDoc, xmlDtd --> int32) is native(LIB) is symbol('xmlValidateDtd') {*}
    method ValidateDocument(xmlDoc --> int32) is native(LIB) is symbol('xmlValidateDocument') {*}
    method SetStructuredErrorFunc( &error-func (xmlValidCtxt $, xmlError $)) is native(LIB) is symbol('xmlSetStructuredErrorFunc') {*};
    method Free is symbol('xmlFreeValidCtxt') is native(LIB) {*}
    sub xmlNewValidCtxt(--> xmlValidCtxt) is native(LIB) {*}
    method new { xmlNewValidCtxt() }
    method validate(xmlDoc:D :$doc!, xmlDtd :$dtd) {
        with $dtd {
            self.ValidateDtd($doc, $_);
        }
        else {
            self.ValidateDocument($doc);
        }
    }
}

class xmlParserCtxt is export {
    has xmlSAXHandler          $.sax           # The SAX handler
        is rw-ptr(method xml6_parser_ctx_set_sax( xmlSAXHandler ) is native(BIND-LIB) {*} );
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
                                               # actually an xmlEncodingStr
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

    has int32                  $.input_id;     # we need to label inputs
    has ulong                  $.sizeentcopy;  # volume of entity copy

    sub xmlNewParserCtxt (--> xmlParserCtxt) is native(LIB) {*};
    method new { xmlNewParserCtxt() }
    method ReadDoc(Str $xml, Str $uri, xmlEncodingStr $enc, int32 $flags --> xmlDoc) is native(LIB) is symbol('xmlCtxtReadDoc') {*};
    method ReadFile(Str $xml, xmlEncodingStr $enc, int32 $flags --> xmlDoc) is native(LIB) is symbol('xmlCtxtReadFile') {*};
    method ReadFd(int32 $fd, xmlCharP $uri, xmlEncodingStr $enc, int32 $flags --> xmlDoc) is native(LIB) is symbol('xmlCtxtReadFd') {*};
    method UseOptions(int32 --> int32) is native(LIB) is symbol('xmlCtxtUseOptions') { * }
    method SetGenericErrorFunc( &error-func (xmlParserCtxt $, Str $fmt, Pointer $arg)) is symbol('xmlSetGenericErrorFunc') is native(LIB) {*};
    method SetStructuredErrorFunc( &error-func (xmlParserCtxt $, xmlError $)) is native(LIB) is symbol('xmlSetStructuredErrorFunc') {*};
    method GetLastError(--> xmlError) is native(LIB) is symbol('xmlCtxtGetLastError') is native('xml2') {*}
    method ParserError(Str $msg) is native(LIB) is symbol('xmlParserError') {*}
    method StopParser is native(LIB) is symbol('xmlStopParser') { * }
    method Reference is native(BIND-LIB) is symbol('xml6_parser_ctx_add_reference') {*}
    method remove-reference(--> int32) is native(BIND-LIB) is symbol('xml6_parser_ctx_remove_reference') {*}
    method Free is native(LIB) is symbol('xmlFreeParserCtxt') { * }
    method Unreference {
        with self {
            .Free if .remove-reference;
        }
    }

    # SAX2 Handler callbacks
    #-- Document Properties --#
    method xmlSAX2GetPublicId(--> Str) is native(LIB) {*};
    method xmlSAX2GetSystemId(--> Str) is native(LIB) {*};
    method xmlSAX2SetDocumentLocator(xmlSAXLocator $loc) is native(LIB) {*};
    method xmlSAX2GetLineNumber(--> int32) is native(LIB) {*};
    method xmlSAX2GetColumnNumber(--> int32) is native(LIB) {*};
    method xmlSAX2IsStandalone(--> int32) is native(LIB) {*};
    method xmlSAX2HasInternalSubset(--> int32) is native(LIB) {*};
    method xmlSAX2HasExternalSubset(--> int32) is native(LIB) {*};
    method xmlSAX2InternalSubset(Str $name , Str $ext-id, Str $int-id--> int32) is native(LIB) {*};
    method xmlSAX2ExternalSubset(Str $name , Str $ext-id, Str $int-id--> int32) is native(LIB) {*};

    #-- Entities --#
    method xmlSAX2GetEntity(Str $name --> xmlEntity) is native(LIB) {*};
    method xmlSAX2GetParameterEntity(Str $name --> xmlEntity) is native(LIB) {*};
    method xmlSAX2ResolveEntity(Str $public-id, Str $system-id --> xmlParserInput) is native(LIB) {*};

    #-- Declarations --#
    method xmlSAX2EntityDecl(Str $name, int32 $type, Str $public-id, Str $system-id, Str $content --> xmlParserInput) is native(LIB) {*};
    method xmlSAX2AttributeDecl(Str $elem, Str $fullname, int32 $type, int32 $def, Str $default-value, xmlEnumeration $tree) is native(LIB) {*};
    method xmlSAX2ElementDecl(Str $name, int32 $type, xmlElementContent $content) is native(LIB) {*};
    method xmlSAX2NotationDecl(Str $name, Str $public-id, Str $system-id) is native(LIB) {*};
    method xmlSAX2UnparsedEntityDecl(Str $name, Str $public-id, Str $system-id, Str $notation-name) is native(LIB) {*};

    #-- Content --#
    method xmlSAX2StartDocument() is native(LIB) {*};
    method xmlSAX2EndDocument() is native(LIB) {*};
    method xmlSAX2StartElement(Str $name, CArray $atts) is native(LIB) {*};
    method xmlSAX2EndElement(Str $name) is native(LIB) {*};
    method xmlSAX2StartElementNs(Str $local-name, Str $prefix, Str $uri, int32 $num-namespaces, CArray[Str] $namespaces, int32 $num-attributes, int32 $num-defaulted, CArray[Str] $attributes) is native(LIB) {*};
    method xmlSAX2EndElementNs(Str $local-name, Str $prefix, Str $uri) is native(LIB) {*};
    method xmlSAX2Reference(Str $name) is native(LIB) {*};
    method xmlSAX2Characters(Blob $chars, int32 $len) is native(LIB) {*};
    method xmlSAX2IgnorableWhitespace(Blob $chars, int32 $len) is native(LIB) {*};
    method xmlSAX2ProcessingInstruction(Str $target, Str $data) is native(LIB) {*};
    method xmlSAX2Comment(Str $value) is native(LIB) {*};
    method xmlSAX2CDataBlock(Blob $chars, int32 $len) is native(LIB) {*};
}

# XML file parser context
class xmlFileParserCtxt is xmlParserCtxt is repr('CStruct') is export {

    sub xmlCreateFileParserCtxt(Str $file --> xmlFileParserCtxt) is native(LIB) {*};
    method ParseDocument(--> int32) is native(LIB) is symbol('xmlParseDocument') {*}
    method new(Str() :$file!) { xmlCreateFileParserCtxt($file) }
}

#| an incremental XML push parser context. Determines encoding and reads data in binary chunks
class xmlPushParserCtxt is xmlParserCtxt is repr('CStruct') is export {

    sub xmlCreatePushParserCtxt(xmlSAXHandler $sax-handler, Pointer $user-data, Blob $chunk, int32 $size, Str $path --> xmlPushParserCtxt) is native(LIB) {*};
    method new(Blob :$chunk!, :$size = +$chunk, xmlSAXHandler :$sax-handler, Pointer :$user-data, Str :$path) {
        xmlCreatePushParserCtxt($sax-handler, $user-data, $chunk, $size, $path);
    }
    method ParseChunk(Blob $chunk, int32 $size, int32 $terminate --> int32) is native(LIB) is symbol('xmlParseChunk') {*};
};

#| a vanilla HTML parser context - can be used to read files or strings
class htmlParserCtxt is xmlParserCtxt is repr('CStruct') is export {

    method myDoc { nativecast(htmlDoc, callsame) }
    method UseOptions(int32 --> int32) is native(LIB) is symbol('htmlCtxtUseOptions') { * }

    sub htmlNewParserCtxt(--> htmlParserCtxt) is native(LIB) {*};
    method new { htmlNewParserCtxt() }
    method ReadDoc(Str $xml, Str $uri, xmlEncodingStr $enc, int32 $flags --> htmlDoc) is native(LIB) is symbol('htmlCtxtReadDoc') {*};
    method ReadFile(Str $xml, Str $uri, xmlEncodingStr $enc, int32 $flags --> htmlDoc) is native(LIB) is symbol('htmlCtxtReadFile') {*}
    method ReadFd(int32 $fd, xmlCharP $uri, xmlEncodingStr $enc, int32 $flags --> htmlDoc) is native(LIB) is symbol('htmlCtxtReadFd') {*};
};

# HTML file parser context
class htmlFileParserCtxt is htmlParserCtxt is repr('CStruct') is export {

    sub htmlCreateFileParserCtxt(Str $file, xmlEncodingStr $enc --> htmlFileParserCtxt) is native(LIB) {*};
    method ParseDocument(--> int32) is native(LIB) is symbol('htmlParseDocument') {*}
    method new(Str() :$file!, xmlEncodingStr :$enc) { htmlCreateFileParserCtxt($file, $enc) }
}

#| an incremental HTMLpush parser context. Determines encoding and reads data in binary chunks
class htmlPushParserCtxt is htmlParserCtxt is repr('CStruct') is export {

    sub htmlCreatePushParserCtxt(xmlSAXHandler $sax-handler, Pointer $user-data, Blob $chunk, int32 $size, Str $path, int32 $encoding --> htmlPushParserCtxt) is native(LIB) {*};
    method new(Blob :$chunk!, :$size = +$chunk, xmlSAXHandler :$sax-handler, Pointer :$user-data, Str :$path, xmlEncodingStr :$enc) {
        my UInt $encoding = do with $enc { xmlParseCharEncoding($_) } else { 0 };
        htmlCreatePushParserCtxt($sax-handler, $user-data, $chunk, $size, $path, $encoding);
    }
    method ParseChunk(Blob $chunk, int32 $size, int32 $terminate --> int32) is native(LIB) is symbol('htmlParseChunk') { *};
};

class xmlMemoryParserCtxt is xmlParserCtxt is repr('CStruct') is export {
    sub xmlCreateMemoryParserCtxt(Blob $buf, int32 $len --> xmlMemoryParserCtxt) is native(LIB) {*}
    method ParseDocument(--> int32) is native(LIB) is symbol('xmlParseDocument') {*}
    multi method new( Str() :$string! ) {
        my Blob $buf = ($string || ' ').encode;
        self.new: :$buf;
    }
    multi method new( Blob() :$buf!, UInt :$bytes = $buf.bytes --> xmlMemoryParserCtxt:D) {
         xmlCreateMemoryParserCtxt($buf, $bytes);
    }
}

class htmlMemoryParserCtxt is htmlParserCtxt is repr('CStruct') is export {
    sub CreateStr(xmlCharP:D, xmlEncodingStr --> htmlMemoryParserCtxt) is native(BIND-LIB) is symbol('xml6_parser_ctx_html_create_str') {*}
    sub CreateBuf(Blob:D, int32, xmlEncodingStr --> htmlMemoryParserCtxt) is native(BIND-LIB) is symbol('xml6_parser_ctx_html_create_buf') {*}
    method ParseDocument(--> int32) is native(LIB) is symbol('htmlParseDocument') {*}
    multi method new( Blob() :$buf!, xmlEncodingStr :$enc = 'UTF-8') {
        CreateBuf($buf, $buf.bytes, $enc);
    }
    multi method new( Str() :$string! ) {
        CreateStr($string, 'UTF-8');
    }
}

sub xmlFree(Pointer) is native(LIB) is export { * }

sub xmlGetLastError(--> xmlError) is export is native(LIB) { * }

multi method GetLastError(xmlParserCtxt:D $ctx) { $ctx.GetLastError() // $.GetLastError()  }
multi method GetLastError { xmlGetLastError()  }

## Input callbacks

sub xmlPopInputCallbacks(--> int32) is native(LIB) is export {*}
sub xmlRegisterDefaultInputCallbacks is native(LIB) is export {*}
sub xmlRegisterInputCallbacks(
    &match (Str --> int32),
    &open (Str --> Pointer),
    &read (Pointer, CArray[uint8], int32 --> int32),
    &close (Pointer --> int32)
--> int32) is native(LIB) is export {*}
sub xmlCleanupInputCallbacks is native(LIB) is export {*}

sub xmlLoadCatalog(Str --> int32) is native(LIB) is export {*}

## xmlInitParser() should be called once at start-up
sub xmlInitParser is native(LIB) is export {*}
sub xml6_ref_init is native(BIND-LIB) {*}
INIT {
    xmlInitParser();
    xml6_ref_init();
}

## Globals aren't yet writable in Rakudo

method KeepBlanksDefault is rw {
    constant value = cglobal(LIB, "xmlKeepBlanksDefaultValue", int32);
    sub xmlKeepBlanksDefault(int32 $v --> int32) is native(LIB) is export { * }

    Proxy.new(
        FETCH => { ? value },
        STORE => sub ($, Bool() $_) {
            xmlKeepBlanksDefault($_);
        },
    );
}

method TagExpansion is rw {
    constant value = cglobal(LIB, "xmlSaveNoEmptyTags", int32);
    sub xml6_gbl_set_tag_expansion(int32 $v --> int32) is native(BIND-LIB) is export { * }

    Proxy.new(
        FETCH => { ? value },
        STORE => sub ($, Bool() $_) {
            xml6_gbl_set_tag_expansion($_);
        },
    );
}

method ExternalEntityLoader is rw {
    sub xmlSetExternalEntityLoader( &loader (xmlCharP, xmlCharP, xmlParserCtxt --> xmlParserInput) ) is native(LIB) is export {*}
    sub xmlGetExternalEntityLoader( --> Pointer ) is native(LIB) is export {*}
    Proxy.new(
        FETCH => { nativecast( :(xmlCharP, xmlCharP, xmlParserCtxt --> xmlParserInput), xmlGetExternalEntityLoader()) },
        STORE => sub ($, &loader) {
             xmlSetExternalEntityLoader(&loader)
        }
    );
}

=begin pod

=head1 AUTHORS

Matt Sergeant,
Christian Glahn,
Petr Pajas,
Shlomi Fish,
Tobias Leich,
Xliff,
David Warring

=head1 VERSION

2.0200

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
