use v6;

unit class LibXML::Native;

=begin pod

=head1 NAME

LibXML::Native - bindings to the libxml2 library

=head1 SYNOPSIS

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

=head1 DESCRIPTION

The LibXML::Native module contains class definitions for native and bindings to the LibXML2 library.

=head2 Low level native access

Other high level classes, by convention, have a `native()` accessor, which can be
used, if needed, to gain access to native objects from this module.

Some care needs to be taken in keeping persistant references to native structures.

The following is unsafe:

   my LibXML::Element $elem .= new: :name<Test>;
   my xmlElem:D $native = $elem.native;
   $elem = Nil;
   say $native.Str; # could have been destroyed along with $elem

If the native object supports the `Reference` and `Unreference` methods, the object
can be reference counted and uncounted:

   my LibXML::Element $elem .= new: :name<Test>;
   my xmlElem:D $native = $elem.native;
   $native.Reference; # add a reference to the object
   $elem = Nil;
   say $native.Str; # now safe
   with $native {
       .Unreference; # unreference, free if no more references
       $_ = Nil;
   }

Otherwise, the object can usually be copied. That copy then needs to be freed, to avoid memory leaks:

  my LibXML::Namespace $ns .= new: :prefix<foo>, :URI<http://foo.org>;
  my xmlNs:D $native = $ns.native;
   $native .= Copy;
   $ns = Nil;
   say $native.Str; # safe
   with $native {
       .Free; # free the copy
       $_ = Nil;
   }


=end pod

use NativeCall;
use LibXML::Enums;
use LibXML::Native::Dict;
use LibXML::Native::HashTable;
use LibXML::Native::DOM::Attr;
use LibXML::Native::DOM::Document;
use LibXML::Native::DOM::Element;
use LibXML::Native::DOM::Node;

use LibXML::Native::Defs :$XML2, :$BIND-XML2, :$CLIB, :Opaque, :xmlCharP;

sub xmlParserVersion is export { cglobal($XML2, 'xmlParserVersion', Str); }
sub xml6_config_have_threads(-->int32) is native($BIND-XML2) is export {*}
sub xml6_config_have_compression(-->int32) is native($BIND-XML2) is export {*}
sub xml6_config_version(--> Str) is native($BIND-XML2) is export {*};

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
                     is repr('CStruct') is export {...}
class xmlXPathObject is repr('CStruct') is export {...}

# Opaque structs
#| A libxml automata description, It can be compiled into a regexp
class xmlAutomata is repr(Opaque) is export {}

#| A state int the automata description,
class xmlAutomataState is repr(Opaque) is export {}

#| old buffer struct limited to 32bit signed addressing (2Gb). xmlBuf is preferred, where available
class xmlBuffer32 is repr(Opaque) is export {
    our sub New( --> xmlBuffer32) is native($XML2) is symbol('xmlBufferCreate') is export {*};
    method Write(xmlCharP --> int32) is native($XML2) is symbol('xmlBufferCat') {*}
    method WriteQuoted(xmlCharP --> int32) is native($XML2) is symbol('xmlBufferWriteQuotedString') {*}
    method NodeDump(xmlDoc $doc, xmlNode $cur, int32 $level, int32 $format --> int32) is native($XML2) is symbol('xmlNodeDump') {*};
    method Content(--> Str) is symbol('xmlBufferContent') is native($XML2) { * }
    method Free() is native($XML2) is symbol('xmlBufferFree') {*};
    method new(--> xmlBuffer32:D) { New() }
}

#| New buffer structure, introduced in libxml 2.09.00, the actual structure internals are not public
class xmlBuf is repr(Opaque) is export {
    our sub New(--> xmlBuf) is native($XML2) is symbol('xmlBufCreate') {*}
    method Write(xmlCharP --> int32) is native($XML2) is symbol('xmlBufCat') {*}
    method WriteQuoted(xmlCharP --> int32) is native($XML2) is symbol('xmlBufWriteQuotedString') {*}
    method NodeDump(xmlDoc $doc, anyNode $cur, int32 $level, int32 $format --> int32) is native($XML2) is symbol('xmlBufNodeDump') { * }
    method Content(--> Str) is symbol('xmlBufContent') is native($XML2) { * }
    method Free is symbol('xmlBufFree') is native($XML2) { * }
    method new(--> xmlBuf:D) { New() }
}

# type defs
class xmlCharEncodingHandler is repr(Opaque) is export {
    our sub Find(Str --> xmlCharEncodingHandler) is native($XML2) is symbol('xmlFindCharEncodingHandler') {*}
}

# subsets
sub xmlParseCharEncoding(Str --> int32) is export is native($XML2) {*}
my subset xmlEncodingStr of Str is export where {!.defined || xmlCharEncodingHandler::Find($_).defined}


#| List structure used when there is an enumeration in DTDs.
class xmlEnumeration is repr(Opaque) is export {}

#| An XML Element content as stored after parsing an element definition
#| in a DTD.
class xmlElementContent is repr(Opaque) is export {}

#| A Location Set
class xmlLocationSet is repr(Opaque) is export {}

#| Callback for freeing some parser input allocations.
class xmlParserInputDeallocate is repr(Opaque) is export {}

#| The parser can be asked to collect Node informations, i.e. at what
#| place in the file they were detected.
class xmlParserNodeInfo is repr(Opaque) is export {}

#| The structure of a compiled expression form is not public.
class xmlXPathCompExpr is repr(Opaque) is export {
    our sub Compile(xmlCharP:D --> xmlXPathCompExpr)  is symbol('xmlXPathCompile') is native($XML2) {*}
    method Free is native($XML2) is symbol('xmlXPathFreeCompExpr') {*}
    method new(Str:D :$expr) {
        Compile($expr);
    }
}

#| A compiled (XPath based) pattern to select nodes
class xmlPattern is repr(Opaque) is export {
    method Match(anyNode --> int32) is native($XML2) is symbol('xmlPatternMatch') {*}
    our sub Compile (xmlCharP, xmlDict, int32, CArray[xmlCharP] --> xmlPattern) is symbol('xmlPatterncompile') is native($XML2) {*}
    method Free is native($XML2) is symbol('xmlFreePattern') {*}
    method new(Str:D :$pattern!, xmlDict :$dict, UInt :$flags, CArray[xmlCharP] :$ns) {
        Compile($pattern, $dict, $flags, $ns);
    }
}

#| A libxml regular expression, they can actually be far more complex
#| thank the POSIX regex expressions.
class xmlRegexp is repr(Opaque) is export {
    our sub Compile(xmlCharP --> xmlRegexp) is symbol('xmlRegexpCompile') is native($XML2) {*}
    method Match(xmlCharP --> int32) is symbol('xmlRegexpExec') is native($XML2) {*}
    method IsDeterministic(--> int32) is symbol('xmlRegexpIsDeterminist') is native($XML2) {*}
    method Free is native($XML2) is symbol('xmlRegFreeRegexp') {*}
    method new(Str:D :$regexp) {
        Compile($regexp);
    }
}

#| An XInclude context
class xmlXIncludeCtxt is repr(Opaque) is export {}

#| A mapping of name to axis function
class xmlXPathAxis is repr(Opaque) is export {}

#|  A mapping of name to conversion function
class xmlXPathType is repr(Opaque) is export {}

#| Each xmlValidState represent the validation state associated to the
#| set of nodes currently open from the document root to the current element.
class xmlValidState is repr(Opaque) is export {}

multi trait_mod:<is>(Attribute $att, :&rw-ptr!) {

    my role PointerSetter[&setter] {
        # override standard Attribute method for generating accessors
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

    our sub Alloc(int32 $enc --> xmlParserInputBuffer) is native($XML2) is symbol('xmlAllocParserInputBuffer') {*}
    method new(xmlEncodingStr :$enc, xmlCharP :$string) {
        my Int $encoding = xmlParseCharEncoding($enc);
        given Alloc($encoding) {
             if $string {
                 my $n := .PushStr($string);
                 die "push to input buffer failed"
                     if $n < 0;
             }
            $_;
        }
    }
    method PushStr(xmlCharP:D --> int32) is native($BIND-XML2) is symbol('xml6_input_buffer_push_str') {*}
}

#|An xmlParserInput is an input flow for the XML processor.
#| Each entity parsed is associated an xmlParserInput (except the
#| few predefined ones). 
class xmlParserInput is repr('CStruct') is export {
    has xmlParserInputBuffer           $.buf;  # UTF-8 encoded buffer
    has Str                       $.filename   # The file analyzed, if any
          is rw-str(method xml6_input_set_filename(Str) is native($BIND-XML2) {*});
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

    method Free is native($XML2) is symbol('xmlFreeInputStream') {*}
}

#| An XML namespace.
#| Note that prefix == NULL is valid, it defines the default namespace
#| within the subtree (until overridden).
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
    method Free is native($XML2) is symbol('xmlFreeNs') {*}
    method Copy(--> xmlNs) is native($BIND-XML2) is symbol('xml6_ns_copy') {*}
    method copy { $.Copy }
    method next-node($) { self.next }
    method UniqueKey(--> xmlCharP) is native($BIND-XML2) is symbol('xml6_ns_unique_key') {*}
    method Str {
        nextsame without self;
        nextsame if self.prefix ~~ 'xml';
        # approximation of xmlsave.c: xmlNsDumpOutput(...)
        my xmlBuffer32 $buf .= new;

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

#| A SAX Locator.
class xmlSAXLocator is repr('CStruct') is export {
    has Pointer  $.getPublicIdFunc is rw-ptr(
        method xml6_sax_locator_set_getPublicId( &cb (xmlParserCtxt $ctx --> Str) ) is native($BIND-XML2) {*}
    );

    has Pointer $.getSystemIdFunc is rw-ptr(
        method xml6_sax_locator_set_getSystemId( &cb (xmlParserCtxt $ctx --> Str) ) is native($BIND-XML2) {*}
    );

    has Pointer $.getLineNumberFunc is rw-ptr(
        method xml6_sax_locator_set_getLineNumber( &cb (xmlParserCtxt $ctx --> int32) ) is native($BIND-XML2) {*}
    );

    has Pointer $.getColumnNumberFunc is rw-ptr(
        method xml6_sax_locator_set_getColumnNumber( &cb (xmlParserCtxt $ctx --> int32) ) is native($BIND-XML2) {*}
    );
    method init is native($XML2) is symbol('xml6_sax_locator_init') {*}

    submethod BUILD(*%atts) {
        for %atts.pairs.sort {
            self."{.key}"() = .value;
        }
    }

    method getPublicId(xmlParserCtxt $ctx) {
        with nativecast(:(xmlParserCtxt $ctx --> int32), $!getPublicIdFunc) -> &cb {
            &cb($ctx)
        }
    }

    method getSystemId(xmlParserCtxt $ctx) {
        with nativecast(:(xmlParserCtxt $ctx --> int32), $!getSystemIdFunc) -> &cb {
            &cb($ctx)
        }
    }

    method getLineNumber(xmlParserCtxt $ctx) {
        with nativecast(:(xmlParserCtxt $ctx --> int32), $!getLineNumberFunc) -> &cb {
            &cb($ctx)
        }
    }

    method getColumnNumber(xmlParserCtxt $ctx) {
        with nativecast(:(xmlParserCtxt $ctx --> int32), $!getColumnNumberFunc) -> &cb {
            &cb($ctx)
        }
    }

    method default {
         cglobal($XML2, 'xmlDefaultSAXLocator', xmlSAXLocator);
    }
}

#| A SAX handler is bunch of callbacks called by the parser when processing
#| of the input generate data or structure informations.
class xmlSAXHandler is repr('CStruct') is export {

    submethod BUILD(*%atts) {
        for %atts.pairs.sort {
            self."{.key}"() = .value;
        }
    }
    method native { self } # already native

    has Pointer   $.internalSubset is rw-ptr(
        method xml6_sax_set_internalSubset( &cb (xmlParserCtxt $ctx, Str $name, Str $external-id, Str $system-id) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.isStandalone is rw-ptr(
        method xml6_sax_set_isStandalone( &cb (xmlParserCtxt $ctx --> int32) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.hasInternalSubset is rw-ptr(
        method xml6_sax_set_hasInternalSubset( &cb (xmlParserCtxt $ctx --> int32) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.hasExternalSubset is rw-ptr(
        method xml6_sax_set_hasExternalSubset( &cb (xmlParserCtxt $ctx --> int32) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.resolveEntity is rw-ptr(
        method xml6_sax_set_resolveEntity( &cb (xmlParserCtxt $ctx, Str $name, Str $public-id, Str $system-id --> xmlParserInput) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.getEntity is rw-ptr(
        method xml6_sax_set_getEntity( &cb (xmlParserCtxt $ctx, Str $name --> xmlEntity) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.entityDecl is rw-ptr(
        method xml6_sax_set_entityDecl( &cb (xmlParserCtxt $ctx, Str $name, uint32 $type, Str $public-id, Str $system-id) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.notationDecl is rw-ptr(
        method xml6_sax_set_notationDecl( &cb (xmlParserCtxt $ctx, Str $name, Str $public-id, Str $system-id) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.attributeDecl is rw-ptr(
        # todo xmlEnumeration $tree
        method xml6_sax_set_attributeDecl( &cb (xmlParserCtxt $ctx, Str $elem, Str $fullname, uint32 $type, uint32 $def, Str $default-value, xmlEnumeration $tree) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.elementDecl is rw-ptr(
        method xml6_sax_set_elementDecl( &cb (xmlParserCtxt $ctx, Str $name, uint32 $type, xmlElementContent $content) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.unparsedEntityDecl is rw-ptr(
        method xml6_sax_set_unparsedEntityDecl( &cb (xmlParserCtxt $ctx, Str $name, Str $public-id, Str $system-id, Str $notation-name) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.setDocumentLocator is rw-ptr(
        method xml6_sax_set_setDocumentLocator( &cb (xmlParserCtxt $ctx, xmlSAXLocator $loc) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.startDocument is rw-ptr(
        method xml6_sax_set_startDocument( &cb (xmlParserCtxt $ctx) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.endDocument is rw-ptr(
        method xml6_sax_set_endDocument( &cb (xmlParserCtxt $ctx) ) is native($BIND-XML2) {*}
    );

    has Pointer   $.startElement is rw-ptr(
        method xml6_sax_set_startElement( &cb (xmlParserCtxt $ctx, Str $name, CArray[Str] $atts) ) is native($BIND-XML2) {*}
    );
    
    has Pointer   $.endElement is rw-ptr(
        method xml6_sax_set_endElement( &cb (xmlParserCtxt $ctx, Str $name) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.reference is rw-ptr(
        method xml6_sax_set_reference( &cb (xmlParserCtxt $ctx, Str $name) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.characters is rw-ptr(
        method xml6_sax_set_characters( &cb (xmlParserCtxt $ctx, CArray[byte] $chars, int32 $len) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.ignorableWhitespace is rw-ptr(
        method xml6_sax_set_ignorableWhitespace( &cb (xmlParserCtxt $ctx, CArray[byte] $chars, int32 $len) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.processingInstruction is rw-ptr(
        method xml6_sax_set_processingInstruction( &cb (xmlParserCtxt $ctx, Str $target, Str $data) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.comment is rw-ptr(
        method xml6_sax_set_comment( &cb (xmlParserCtxt $ctx, Str $value) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.warning is rw-ptr(
        method xml6_sax_set_warning( &cb (xmlParserCtxt $ctx, Str $msg) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.error is rw-ptr(
        method xml6_sax_set_error( &cb (xmlParserCtxt $ctx, Str $msg) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.fatalError is rw-ptr(
        method xml6_sax_set_fatalError( &cb (xmlParserCtxt $ctx, Str $msg) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.getParameterEntity is rw-ptr(
        method xml6_sax_set_getParameterEntity( &cb (xmlParserCtxt $ctx, Str $name) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.cdataBlock is rw-ptr(
        method xml6_sax_set_cdataBlock( &cb (xmlParserCtxt $ctx, CArray[byte] $chars, int32 $len) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.externalSubset is rw-ptr(
        method xml6_sax_set_externalSubset( &cb (xmlParserCtxt $ctx, Str $name, Str $external-id, Str $system-id) ) is native($BIND-XML2) {*}
    );
    has uint32    $.initialized;
    has Pointer   $._private;
    has Pointer   $.startElementNs is rw-ptr(
        method xml6_sax_set_startElementNs( &cb (xmlParserCtxt $ctx, Str $local-name, Str $prefix, Str $uri, int32 $num-namespaces, CArray[Str] $namespaces, int32 $num-attributes, int32 $num-defaulted, CArray[Str] $attributes) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.endElementNs is rw-ptr(
        method xml6_sax_set_endElementNs( &cb (xmlParserCtxt $ctx, Str $local-name, Str $prefix, Str $uri) ) is native($BIND-XML2) {*}
    );
    has Pointer   $.serror is rw-ptr(
        method xml6_sax_set_serror( &cb (xmlParserCtxt $ctx, xmlError $error) ) is native($BIND-XML2) {*}
    );

    method xmlSAX2InitDefaultSAXHandler(int32 $warning) is native($XML2) {*}
    method xmlSAX2InitHtmlDefaultSAXHandler is native($XML2) {*}
    method init(Bool :$html, Bool :$warning = True) {
        $html
        ?? $.xmlSAX2InitHtmlDefaultSAXHandler()
        !! $.xmlSAX2InitDefaultSAXHandler( +$warning );
    }
    method ParseDoc(Str, int32 $recovery --> xmlDoc) is native($XML2) is symbol('xmlSAXParseDoc') {*};
    method IOParseDTD(xmlParserInputBuffer:D, int32 $enc --> xmlDtd) is native($XML2) is symbol('xmlIOParseDTD') {*}

    method ParseDTD(Str, Str --> xmlDtd) is native($XML2) is symbol('xmlSAXParseDTD') {*}

}

#| An XML Error instance.
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

    our sub Last(--> xmlError) is native($XML2) is symbol('xmlGetLastError') {*}; 
    method Reset() is native($XML2) is symbol('xmlResetError') {*};
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

    our sub IsInf(num64 --> int32) is native($XML2) is symbol('xmlXPathIsInf') {*}
    our sub IsNaN(num64 --> int32) is native($XML2) is symbol('xmlXPathIsNaN') {*}
    method add-reference is native($BIND-XML2) is symbol('xml6_xpath_object_add_reference') {*}
    method is-referenced(--> int32) is native($BIND-XML2) is symbol('xml6_xpath_object_is_referenced') {*}
    method remove-reference(--> int32) is native($BIND-XML2) is symbol('xml6_xpath_object_remove_reference') {*}
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

    method domXPathGetNodeSet(int32 $select --> xmlNodeSet) is native($BIND-XML2) {*}
    method Free is symbol('xmlXPathFreeObject') is native($XML2) {*}

    our sub NewString(xmlCharP --> xmlXPathObject) is native($XML2) is symbol('xmlXPathNewString') {*}
    our sub NewFloat(num64 --> xmlXPathObject) is native($XML2) is symbol('xmlXPathNewFloat') {*}
    our sub NewBoolean(int32 --> xmlXPathObject) is native($XML2) is symbol('xmlXPathNewBoolean') {*}
    our sub NewNodeSet(anyNode:D --> xmlXPathObject) is native($XML2) is symbol('xmlXPathNewNodeSet') {*}
    our sub WrapNodeSet(xmlNodeSet --> xmlXPathObject) is native($XML2) is symbol('xmlXPathWrapNodeSet') {*}

    multi method coerce(Bool $v)           { NewBoolean($v) }
    multi method coerce(Numeric $v)        { NewFloat($v.Num) }
    multi method coerce(Str $v)            { NewString($v) }
    multi method coerce(anyNode:D $v)      { NewNodeSet($v) }
    multi method coerce(xmlNodeSet:D $v)   { WrapNodeSet($v.copy) }
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
                given IsInf($!float) {
                    when +1 { Inf }
                    when -1 { -Inf }
                    default {
                        IsNaN($!float)
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

#| Expression evaluation occurs with respect to a context.
#| the context consists of:
#|    - a node (the context node)
#|    - a node list (the context node list)
#|    - a set of variable bindings
#|    - a function library
#|    - the set of namespace declarations in scope for the expression
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

    our sub New(anyNode --> xmlXPathContext) is native($BIND-XML2) is symbol('domXPathNewCtxt') {*}
    method Free is symbol('domXPathFreeCtxt') is native($BIND-XML2) {*}
    method Find(xmlXPathCompExpr, anyNode, int32 --> xmlXPathObject) is native($BIND-XML2) is symbol('domXPathFindCtxt') {*}
    method Select(xmlXPathCompExpr, anyNode --> xmlNodeSet) is native($BIND-XML2) is symbol('domXPathSelectCtxt') {*}
    method SetNode(anyNode) is native($BIND-XML2) is symbol('domXPathCtxtSetNode') {*}
    multi method new(xmlDoc:D :$doc!) {
        New($doc);
    }
    multi method new(xmlNode :$node) is default {
        New($node);
    }

    method findnodes(xmlXPathCompExpr:D $expr, anyNode $ref-node? --> xmlNodeSet) {
        self.Select($expr, $ref-node);
    }

    method find(xmlXPathCompExpr:D $expr, anyNode $ref-node?, Bool :$bool) {
        self.Find($expr, $ref-node, $bool);
    }
    method RegisterNs(Str, Str --> int32) is symbol('xmlXPathRegisterNs') is native($XML2) {*}
    method NsLookup(xmlCharP --> xmlCharP) is symbol('xmlXPathNsLookup') is native($XML2) {*}

    method RegisterFunc(xmlCharP $name, &func1 (xmlXPathParserContext, int32 --> xmlXPathObject) ) is symbol('xmlXPathRegisterFunc') is native($XML2) {*}
    method RegisterFuncNS(xmlCharP $name, xmlCharP $ns-uri, &func2 (xmlXPathParserContext, int32 --> xmlXPathObject) ) is symbol('xmlXPathRegisterFuncNS') is native($XML2) {*}
    method RegisterVariableLookup( &func3 (xmlXPathContext, Str, Str --> xmlXPathObject), Pointer ) is symbol('xmlXPathRegisterVariableLookup') is native($XML2) {*}
    constant xmlXPathFunction = Pointer;
    method RegisterFuncLookup( &func4 (xmlXPathContext, xmlCharP $name, xmlCharP $ns-uri --> xmlXPathFunction), Pointer) is native($XML2) is symbol('xmlXPathRegisterFuncLookup') {*};
    method FunctionLookupNS(xmlCharP $name, xmlCharP $ns_uri --> xmlXPathFunction) is native($XML2) is symbol('xmlXPathFunctionLookupNS') {*};
    method SetStructuredErrorFunc( &error-func (xmlXPathContext $, xmlError $)) is native($BIND-XML2) is symbol('domSetXPathCtxtErrorHandler') {*};
}

#| An XPath parser context. It contains pure parsing informations,
#| an xmlXPathContext, and the stack of objects.
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

    method valuePop(--> xmlXPathObject) is native($XML2) {*}
    method valuePush(xmlXPathObject --> int32) is native($XML2) {*}
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
         is rw-ptr(method xml6_node_set_doc(xmlDoc) is native($BIND-XML2) {*});
    # + additional fields, depending on node-type; see xmlElem, xmlDoc, xmlAttr, etc...

    method GetBase { self.doc.NodeGetBase(self) }
    method SetBase(xmlCharP) is native($XML2) is symbol('xmlNodeSetBase') {*}
    method Free() is native($XML2) is symbol('xmlFreeNode') {*}
    method SetListDoc(xmlDoc) is native($XML2) is symbol('xmlSetListDoc') {*}
    method GetLineNo(--> long) is native($XML2) is symbol('xmlGetLineNo') {*}
    method IsBlank(--> int32) is native($XML2) is symbol('xmlIsBlankNode') {*}
    method GetNodePath(--> xmlCharP) is native($XML2) is symbol('xmlGetNodePath') {*}
    method AddChild(anyNode --> anyNode) is native($XML2) is symbol('xmlAddChild') {*}
    method AddChildList(anyNode --> anyNode) is native($XML2) is symbol('xmlAddChildList') {*}
    method AddContent(xmlCharP) is native($XML2) is symbol('xmlNodeAddContent') {*}
    method SetContext(xmlXPathContext --> int32) is symbol('xmlXPathSetContextNode') is native($XML2) {*}
    method XPathEval(Str, xmlXPathContext --> xmlXPathObject) is symbol('xmlXPathNodeEval') is native($XML2) {*}
    method domXPathSelectStr(Str --> xmlNodeSet) is native($BIND-XML2) {*}
    method domXPathFind(xmlXPathCompExpr, int32 --> xmlXPathObject) is native($BIND-XML2) {*}
    method domFailure(--> xmlCharP) is native($BIND-XML2) {*}
    method dom-error { die $_ with self.domFailure }
    method domAppendChild(anyNode --> anyNode) is native($BIND-XML2) {*}
    method domReplaceNode(anyNode --> anyNode) is native($BIND-XML2) {*}
    method domAddSibling(anyNode --> anyNode) is native($BIND-XML2) {*}
    method domReplaceChild(anyNode, anyNode --> anyNode) is native($BIND-XML2) {*}
    method domInsertBefore(anyNode, anyNode --> anyNode) is native($BIND-XML2) {*}
    method domInsertAfter(anyNode, anyNode --> anyNode) is native($BIND-XML2) {*}
    method domGetNodeName(int32 --> Str) is native($BIND-XML2) {*}
    method domSetNodeName(Str) is native($BIND-XML2) {*}
    method domGetNodeValue(--> Str) is native($BIND-XML2) {*}
    method domSetNodeValue(Str) is native($BIND-XML2) {*}
    method domRemoveChild(anyNode --> anyNode) is native($BIND-XML2) {*}
    method domRemoveChildNodes(--> xmlDocFrag) is native($BIND-XML2) {*}

    method domAppendTextChild(Str $name, Str $value) is native($BIND-XML2) {*}
    method domAddNewChild(Str $uri, Str $name --> anyNode) is native($BIND-XML2) {*}
    method domSetNamespace(Str $URI, Str $prefix, int32 $flag --> int32) is native($BIND-XML2) {*}
    method first-child(int32 --> anyNode) is native($BIND-XML2) is symbol('xml6_node_first_child') {*}
    method next-node(int32 --> anyNode) is native($BIND-XML2) is symbol('xml6_node_next') {*}
    method prev-node(int32 --> anyNode) is native($BIND-XML2) is symbol('xml6_node_prev') {*}
    method is-referenced(--> int32) is native($BIND-XML2) is symbol('domNodeIsReferenced') {*}
    method root(--> anyNode) is native($BIND-XML2) is symbol('xml6_node_find_root') {*}
    method domGetChildrenByLocalName(Str --> xmlNodeSet) is native($BIND-XML2) {*}
    method domGetChildrenByTagName(Str --> xmlNodeSet) is native($BIND-XML2) {*}
    method domGetChildrenByTagNameNS(Str, Str --> xmlNodeSet) is native($BIND-XML2) {*}
    method domNormalize(--> int32) is native($BIND-XML2) {*}
    method domUniqueKey(--> xmlCharP) is native($BIND-XML2) {*}
    method domIsSameNode(anyNode --> int32) is native($BIND-XML2) {*}

    method xml6_node_to_str(int32 $opts --> Str) is native($BIND-XML2) {*}
    method xml6_node_to_str_C14N(int32 $comments, int32 $mode, CArray[Str] $inc-prefix is rw, xmlNodeSet --> Str) is native($BIND-XML2) {*}

    method Str(UInt :$options = 0 --> Str) is default {
        with self {
            .xml6_node_to_str($options);
        }
        else {
            Str
        }
    }

    method Blob(UInt :$options = 0, Str :$enc --> Blob) {
        method xml6_node_to_buf(int32 $opts, size_t $len is rw, Str $enc  --> Pointer[uint8]) is native($BIND-XML2) {*}
        sub memcpy(Blob, Pointer, size_t) is native($CLIB) {*}
        sub free(Pointer) is native($CLIB) {*}
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

    method xmlCopyNode (int32 $extended --> anyNode) is native($XML2) {*}
    method xmlDocCopyNode(xmlDoc, int32 --> anyNode) is native($XML2) {*}
    method copy(Bool :$deep) {
        my $extended := $deep ?? 1 !! 2;
        with $.doc {
            $.xmlDocCopyNode($_, $extended);
        }
        else {
            $.xmlCopyNode( $extended );
        }
    }

    method string-value(--> xmlCharP) is native($XML2) is symbol('xmlXPathCastNodeToString') {*}
    method Unlink is native($XML2) is symbol('xmlUnlinkNode') {*}
    method Release is native($BIND-XML2) is symbol('domReleaseNode') {*}
    method Reference is native($BIND-XML2) is symbol('xml6_node_add_reference') {*}
    method remove-reference(--> int32) is native($BIND-XML2) is symbol('xml6_node_remove_reference') {*}
    method lock(--> int32) is native($BIND-XML2) is symbol('xml6_node_lock') {*}
    method unlock(--> int32) is native($BIND-XML2) is symbol('xml6_node_unlock') {*}
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
    method domSetNamespaceDeclPrefix(|c) { ... }
    method domSetNamespaceDeclURI(|c) { ... }
    method domGetNamespaceDeclURI(|c) { ... }
    method ItemNode handles<delegate> { nativecast(itemNode, self) }
}

#| A node in an XML tree.
class xmlNode is anyNode {
    has xmlNs            $.ns  # pointer to the associated namespace
        is rw-ptr( method xml6_node_set_ns(xmlNs) is native($BIND-XML2) {*});
    has xmlCharP    $.content  # the content
        is rw-str(method xml6_node_set_content(xmlCharP) is native($BIND-XML2) {*});
    has xmlAttr  $.properties; # properties list
    has xmlNs         $.nsDef  # namespace definitions on this node
        is rw-ptr(method xml6_node_set_nsDef(xmlNs) is native($BIND-XML2) {*});
    has Pointer        $.psvi; # for type/PSVI informations
    has uint16         $.line; # line number
    has uint16        $.extra; # extra data for XPath/XSLT

    method domSetNamespaceDeclURI(xmlCharP $prefix, xmlCharP $uri --> int32) is native($BIND-XML2) {*}
    method domGetNamespaceDeclURI(xmlCharP $prefix --> xmlCharP) is native($BIND-XML2) {*}
    method domSetNamespaceDeclPrefix(xmlCharP $prefix, xmlCharP $ns-prefix --> int32) is native($BIND-XML2) {*}
}


#| xmlNode of type: XML_ELEMENT_NODE
class xmlElem is xmlNode is export does LibXML::Native::DOM::Element {
    method NewNs(xmlCharP $href, xmlCharP $prefix --> xmlNs) is native($XML2) is symbol('xmlNewNs') {*};
    method SetProp(Str, Str --> xmlAttr) is native($XML2) is symbol('xmlSetProp') {*}
    method domGetAttributeNode(xmlCharP $qname --> xmlAttr) is native($BIND-XML2) {*}
    method domGetAttribute(xmlCharP $qname --> xmlCharP) is native($BIND-XML2)  {*}
    method domHasAttributeNS(xmlCharP $uri, xmlCharP $name --> int32) is native($BIND-XML2) {*}
    method domGetAttributeNS(xmlCharP $uri, xmlCharP $name --> xmlCharP) is native($BIND-XML2) {*}
    method domGetAttributeNodeNS(xmlCharP $uri, xmlCharP $name --> xmlAttr) is native($BIND-XML2) {*}
    method domSetAttribute(Str, Str --> int32) is native($BIND-XML2) {*}
    method domSetAttributeNode(xmlAttr --> xmlAttr) is native($BIND-XML2) {*}
    method domSetAttributeNodeNS(xmlAttr --> xmlAttr) is native($BIND-XML2) {*}
    method domSetAttributeNS(Str $URI, Str $name, Str $value --> xmlAttr) is native($BIND-XML2) {*}
    method domGenNsPrefix(Str $base-prefix --> Str) is native($BIND-XML2) {*}

    our sub New(xmlNs, Str $name --> xmlElem) is native($XML2) is symbol('xmlNewNode') {*}
    multi method new(Str:D :$name!, xmlNs:D :$ns, xmlDoc:D :$doc!) {
        $doc.new-node(:$name, :$ns);
    }
    multi method new(Str:D :$name!, xmlNs :$ns) {
        given New($ns, $name) -> xmlElem:D $node {
            $node.nsDef = $_ with $ns;
            $node;
        }
    }

}

#| xmlNode of type: XML_TEXT_NODE
class xmlTextNode is xmlNode is repr('CStruct') is export {
    our sub New(Str $content --> xmlTextNode) is native($XML2) is symbol('xmlNewText') {*}
    method new(Str :$content!, xmlDoc :$doc) {
        given New($content) -> xmlTextNode:D $node {
            $node.doc = $_ with $doc;
            $node;
        }
    }

}

#| xmlNode of type: XML_COMMENT_NODE
class xmlCommentNode is xmlNode is repr('CStruct') is export {
    our sub New(Str $content --> xmlCommentNode) is native($XML2) is symbol('xmlNewComment') {*}
    method new(Str :$content!, xmlDoc :$doc) {
        given New($content) -> xmlCommentNode:D $node {
            $node.doc = $_ with $doc;
            $node;
        }
    }
}

#| xmlNode of type: XML_CDATA_SECTION_NODE
class xmlCDataNode is xmlNode is repr('CStruct') is export {
    our sub New(xmlDoc, Blob $content, int32 $len --> xmlCDataNode) is native($XML2) is symbol('xmlNewCDataBlock') {*}
    multi method new(Str :content($string)!, xmlDoc :$doc --> xmlCDataNode:D) {
        my Blob $content = $string.encode;
        self.new: :$content, :$doc;
    }
    multi method new(Blob :content($buf)!, xmlDoc :$doc --> xmlCDataNode:D) {
        my $len = $buf.elems;
        New($doc, $buf, $len);
    }
}

#| xmlNode of type: XML_PI_NODE
class xmlPINode is xmlNode is repr('CStruct') is export {
    our sub New(xmlCharP $name, xmlCharP $content) is native($XML2) is symbol('xmlNewPI') {*}
    multi method new(xmlDoc:D :$doc!, Str:D :$name!, Str :$content) {
        $doc.new-pi(:$name, :$content);
    }
    multi method new(Str:D :$name!, Str :$content) {
        New($name, $content);
    }
}

#| xmlNode of type: XML_ENTITY_REF_NODE
class xmlEntityRefNode is xmlNode is repr('CStruct') is export {
    multi method new(xmlDoc:D :$doc!, Str:D :$name!) {
        $doc.new-ent-ref(:$name);
    }
}

#| An attribute on an XML node (type: XML_ATTRIBUTE_NODE)
class xmlAttr is anyNode does LibXML::Native::DOM::Attr is export {
    has xmlNs       $.ns; # the associated namespace
    has int32    $.atype; # the attribute type if validating
    has Pointer   $.psvi; # for type/PSVI informations

    method Free is native($XML2) is symbol('xmlFreeProp') {*}
    method xmlCopyProp(--> xmlAttr) is native($XML2) {*}
    method copy() { $.xmlCopyProp }
    method new(Str :$name!, Str :$value!, xmlDoc :$doc --> xmlAttr:D) {
        $doc.NewProp($name, $value);
    }
    method domAttrSerializeContent(--> xmlCharP) is native($BIND-XML2) {*}
}

#| An XML document (type: XML_DOCUMENT_NODE)
class xmlDoc is anyNode does LibXML::Native::DOM::Document is export {
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
             is rw-str(method xml6_doc_set_version(Str) is native($BIND-XML2) {*});
    has xmlCharP        $.encoding     # external initial encoding, if any
             is rw-str(method xml6_doc_set_encoding(Str) is native($BIND-XML2) {*});
    has Pointer         $.ids;         # Hash table for ID attributes if any
    has Pointer         $.refs;        # Hash table for IDREFs attributes if any
    has xmlCharP        $.URI          # The URI for that document
             is rw-str(method xml6_doc_set_URI(Str) is native($BIND-XML2) {*});
    has int32           $.charset;     # Internal flag for charset handling,
                                       # actually an xmlCharEncoding 
    has xmlDict         $.dict         # dict used to allocate names or NULL
             is rw-ptr(method xml6_doc_set_dict(xmlDict) is native($BIND-XML2) {*});
    has Pointer         $.psvi;        # for type/PSVI informations
    has int32           $.parseFlags;  # set of xmlParserOption used to parse the
                                       # document
    has int32           $.properties;  # set of xmlDocProperties for this document
                                       # set at the end of parsing

    method DumpFormatMemoryEnc(Pointer[uint8] $ is rw, int32 $ is rw, Str, int32 ) is symbol('xmlDocDumpFormatMemoryEnc') is native($XML2) {*}
    sub xmlSaveFormatFile(Str $filename, xmlDoc $doc, int32 $format --> int32) is native($XML2) is export {*}
    # this method can save documents with compression
    method write(Str:D $filename, Int() :$format = 0) {
         xmlSaveFormatFile($filename, self, $format);
    }
    method GetRootElement(--> xmlElem) is symbol('xmlDocGetRootElement') is native($XML2) { * }
    method SetRootElement(xmlElem --> xmlElem) is symbol('xmlDocSetRootElement') is native($XML2) { * }
    method Copy(int32 $deep --> xmlDoc) is symbol('xmlCopyDoc') is native($XML2) {*}
    method copy(Bool :$deep = True) { $.Copy(+$deep) }
    method Free is native($XML2) is symbol('xmlFreeDoc') {*}
    method xmlParseBalancedChunkMemory(xmlSAXHandler $sax-handler, Pointer $user-data, int32 $depth, xmlCharP $string, Pointer[anyNode] $list is rw --> int32) is native($XML2) {*}
    method xmlParseBalancedChunkMemoryRecover(xmlSAXHandler $sax-handler, Pointer $user-data, int32 $depth, xmlCharP $string, Pointer[anyNode] $list is rw, int32 $repair --> int32) is native($XML2) {*}
    method NewNode(xmlNs, xmlCharP $name, xmlCharP $content --> xmlElem) is native($XML2) is symbol('xmlNewDocNode') {*}
    method NewDtd(Str, Str, Str --> xmlDtd) is native($XML2) is symbol('xmlNewDtd') {*}
    method CreateIntSubset(Str, Str, Str --> xmlDtd) is native($XML2) is symbol('xmlCreateIntSubset') {*}
    method GetCompressMode(--> int32) is native($XML2) is symbol('xmlGetDocCompressMode') {*}
    method SetCompressMode(int32) is native($XML2) is symbol('xmlSetDocCompressMode') {*}

    method new-node(Str:D :$name!, xmlNs :$ns, Str :$content --> xmlElem:D) {
        given self.NewNode($ns, $name, $content) -> xmlElem:D $node {
            $node.nsDef = $_ with $ns;
            $node;
        }
    }
    method NewPI(xmlCharP $name, xmlCharP $content --> xmlPINode) is native($XML2) is symbol('xmlNewDocPI') {*}
    method new-pi(Str:D :$name!, Str :$content --> xmlPINode:D) {
       self.NewPI($name, $content);
    }
    method NewEntityRef(xmlCharP $name --> xmlEntityRefNode) is native($XML2) is symbol('xmlNewReference') {*}
    method new-ent-ref(Str:D :$name! --> xmlEntityRefNode:D) {
       self.NewEntityRef($name);
    }

    method NodeGetBase(anyNode --> xmlCharP) is native($XML2) is symbol('xmlNodeGetBase') {*}
    method EncodeEntitiesReentrant(xmlCharP --> xmlCharP) is native($XML2) is symbol('xmlEncodeEntitiesReentrant') {*}
    method NewProp(xmlCharP $name, xmlCharP $value --> xmlAttr) is symbol('xmlNewDocProp') is native($XML2) {*}
    method XIncludeProcessFlags(uint32 $flags --> int32) is symbol('xmlXIncludeProcessFlags') is native($XML2) {*}
    method SearchNs(anyNode, Str --> xmlNs) is native($XML2) is symbol('xmlSearchNs') {*}
    method SearchNsByHref(anyNode, Str --> xmlNs) is native($XML2) is symbol('xmlSearchNsByHref') {*}
    method GetID(Str --> xmlAttr) is native($XML2) is symbol('xmlGetID') {*}
    method IsID(xmlNode, xmlAttr --> int32) is native($XML2) is symbol('xmlIsID') {*}
    method IndexElements(--> long) is symbol('xmlXPathOrderDocElems') is native($XML2) {*}

    our sub New(xmlCharP $version --> xmlDoc) is native($XML2) is symbol('xmlNewDoc') {*}
    method new(Str:D() :$version = '1.0') {
        New($version);
    }

    method domCreateAttribute(Str, Str --> xmlAttr) is native($BIND-XML2) {*}
    method domCreateAttributeNS(Str, Str, Str --> xmlAttr) is native($BIND-XML2) {*}
    method domImportNode(anyNode, int32, int32 --> anyNode) is native($BIND-XML2) {*}
    method domGetInternalSubset(--> xmlDtd) is native($BIND-XML2) {*}
    method domGetExternalSubset(--> xmlDtd) is native($BIND-XML2) {*}
    method domSetInternalSubset(xmlDtd) is native($BIND-XML2) {*}
    method domSetExternalSubset(xmlDtd) is native($BIND-XML2) {*}

}

#| xmlDoc of type: XML_HTML_DOCUMENT_NODE
class htmlDoc is xmlDoc is repr('CStruct') is export {
    method DumpFormat(Pointer[uint8] $ is rw, int32 $ is rw, int32 ) is symbol('htmlDocDumpMemoryFormat') is native($XML2) {*}
    sub memcpy(Blob, Pointer, size_t) is native($CLIB) {*}
    sub free(Pointer) is native($CLIB) {*}

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

#| xmlNode of type: XML_DOCUMENT_FRAG_NODE
class xmlDocFrag is xmlNode is export {
    our sub New(xmlDoc $doc --> xmlDocFrag) is native($XML2) is symbol('xmlNewDocFragment') {*}
    method new(xmlDoc :$doc, xmlNode :$nodes) {
        my xmlDocFrag:D $frag = New($doc);
        $frag.set-nodes($_) with $nodes;
        $frag;
    }
}

#| An XML DTD, as defined by <!DOCTYPE ... There is actually one for
#| the internal subset and for the external subset (type: XML_DTD_NODE).
class xmlDtd is anyNode is export {
    has Pointer   $.notations; # Hash table for notations if any
    has Pointer    $.elements; # Hash table for elements if any
    has Pointer  $.attributes; # Hash table for attributes if any
    has Pointer    $.entities; # Hash table for entities if any
    has xmlCharP $.ExternalID; # External identifier for PUBLIC DTD
    has xmlCharP   $.SystemID; # URI for a SYSTEM or PUBLIC DTD
    has Pointer   $.pentities; # Hash table for param entities if any

    method publicId { $!ExternalID }
    method systemId { $!SystemID }

    method Copy(--> xmlDtd) is native($XML2) is symbol('xmlCopyDtd') {*}
    method copy() { $.Copy }

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
        $sax-handler.IOParseDTD($buffer, $encoding);
    }
    multi method parse(Str :$external-id, Str :$system-id, xmlSAXHandler :$sax-handler) is default {
        $sax-handler.ParseDTD($external-id, $system-id);
    }
}

#| An Attribute declaration in a DTD (type: XML_ATTRIBUTE_DECL).
class xmlAttrDecl is repr('CStruct') is anyNode is export {
    has xmlAttrDecl    $.nexth; # next in hash table
    has int32          $.atype; # the attribute type
    has int32            $.def; # default mode (enum xmlAttributeDefault)
    has xmlCharP$.defaultValue; # or the default value
    has xmlEnumeration  $.tree; # or the enumeration tree if any
    has xmlCharP      $.prefix; # the namespace prefix if any
    has xmlCharP        $.elem; # Element holding the attribute

}

#| An unit of storage for an entity, contains the string, the value and
#| the data needed for the linking in the hash table (type: XML_ENTITY_DECL).
class xmlEntity is anyNode is export {
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
    our sub GetPredefined(xmlCharP $name --> xmlEntity) is native($XML2) is symbol('xmlGetPredefinedEntity') { * }
    our sub Create(xmlCharP $name, int32 $type, xmlCharP $ext-id, xmlCharP $int-id, xmlCharP $value --> xmlEntity) is native($BIND-XML2) is symbol('xml6_entity_create') {*}
    method get-predefined(Str :$name!) {
        GetPredefined($name);
    }
    method Free is native($XML2) is symbol('xmlFreeEntity') {*}
    method create(Str:D :$name!, Str:D :$content!, Int :$type = XML_INTERNAL_GENERAL_ENTITY, Str :$external-id, Str :$internal-id) {
        Create($name, $type, $external-id, $internal-id, $content );
    }
}

#| An XML Element declaration from a DTD (type: XML_ELEMENT_DECL).
class xmlElementDecl is repr('CStruct') is anyNode is export {
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
    our sub NodeType(Str --> int32) is native($BIND-XML2) is symbol('domNodeType') {*}
}

#| A node-set (an unordered collection of nodes without duplicates)
class xmlNodeSet is export {
    has int32             $.nodeNr; # number of nodes in the set
    has int32            $.nodeMax; # size of the array as allocated
    has CArray[itemNode] $.nodeTab; # array of nodes in no particular order

    our sub NewFromNode(anyNode --> xmlNodeSet) is export is native($XML2) is symbol('xmlXPathNodeSetCreate') {*}
    our sub NewFromList(itemNode, int32 --> xmlNodeSet) is native($BIND-XML2) is symbol('domCreateNodeSetFromList') {*}

    method Reference is native($BIND-XML2) is symbol('domReferenceNodeSet') {*}
    method Unreference is native($BIND-XML2) is symbol('domUnreferenceNodeSet') {*}
    method Free is native($XML2) is symbol('xmlXPathFreeNodeSet') {*}
    method delete(itemNode --> int32) is symbol('domDeleteNodeSetItem') is native($BIND-XML2) {*}
    method copy(--> xmlNodeSet) is symbol('domCopyNodeSet') is native($BIND-XML2) {*}
    method reverse(--> xmlNodeSet) is symbol('domReverseNodeSet') is native($BIND-XML2) {*}
    method push(itemNode) is symbol('domPushNodeSet') is native($BIND-XML2) {*}
    method pop(--> itemNode) is symbol('domPopNodeSet') is native($BIND-XML2) {*}
    method hasSameNodes(xmlNodeSet --> int32) is symbol('xmlXPathHasSameNodes') is native($XML2) {*}

    multi method new(itemNode:D :$node, :list($)! where .so, Bool :$keep-blanks = True) {
        NewFromList($node, +$keep-blanks);
    }
    multi method new(anyNode :$node) is default {
        NewFromNode($node);
    }
}

class xmlParserNodeInfoSeq is repr('CStruct') is export {
    has ulong                  $.maximum;
    has ulong                  $.length;
    has xmlParserNodeInfo      $.buffer;
}

#| An xmlValidCtxt is used for error reporting when validating.
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

    our sub New(--> xmlValidCtxt) is native($XML2) is symbol('xmlNewValidCtxt') {*}
    method ValidateDtd(xmlDoc, xmlDtd --> int32) is native($XML2) is symbol('xmlValidateDtd') {*}
    method ValidateDocument(xmlDoc --> int32) is native($XML2) is symbol('xmlValidateDocument') {*}
    method SetStructuredErrorFunc( &error-func (xmlValidCtxt $, xmlError $)) is native($XML2) is symbol('xmlSetStructuredErrorFunc') {*};
    method Free is symbol('xmlFreeValidCtxt') is native($XML2) {*}
    method new { New() }
    method validate(xmlDoc:D :$doc!, xmlDtd :$dtd) {
        with $dtd {
            self.ValidateDtd($doc, $_);
        }
        else {
            self.ValidateDocument($doc);
        }
    }
}

#| The parser context.
class xmlParserCtxt is export {
    has xmlSAXHandler          $.sax           # The SAX handler
        is rw-ptr(method xml6_parser_ctx_set_sax( xmlSAXHandler ) is native($BIND-XML2) {*} );
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

    our sub New(--> xmlParserCtxt) is native($XML2) is symbol('xmlNewParserCtxt') {*};
    method new { New() }
    method ReadDoc(Str $xml, Str $uri, xmlEncodingStr $enc, int32 $flags --> xmlDoc) is native($XML2) is symbol('xmlCtxtReadDoc') {*};
    method ReadFile(Str $xml, xmlEncodingStr $enc, int32 $flags --> xmlDoc) is native($XML2) is symbol('xmlCtxtReadFile') {*};
    method ReadFd(int32 $fd, xmlCharP $uri, xmlEncodingStr $enc, int32 $flags --> xmlDoc) is native($XML2) is symbol('xmlCtxtReadFd') {*};
    method UseOptions(int32 --> int32) is native($XML2) is symbol('xmlCtxtUseOptions') { * }
    method NewInputStream(xmlParserInputBuffer, int32 $enc --> xmlParserInput) is native($XML2) is symbol('xmlNewIOInputStream') is export {*}
    method NewInputFile(Str --> xmlParserInput) is native($XML2) is export is symbol('xmlNewInputFromFile') {*}
    method SetStructuredErrorFunc( &error-func (xmlParserCtxt $, xmlError $)) is native($XML2) is symbol('xmlSetStructuredErrorFunc') {*};
    method GetLastError(--> xmlError) is native($XML2) is symbol('xmlCtxtGetLastError') is native($XML2) {*}
    method ParserError(Str $msg) is native($XML2) is symbol('xmlParserError') {*}
    method StopParser is native($XML2) is symbol('xmlStopParser') { * }
    method Reference is native($BIND-XML2) is symbol('xml6_parser_ctx_add_reference') {*}
    method remove-reference(--> int32) is native($BIND-XML2) is symbol('xml6_parser_ctx_remove_reference') {*}
    method Free is native($XML2) is symbol('xmlFreeParserCtxt') { * }
    method Unreference {
        with self {
            .Free if .remove-reference;
        }
    }

    # SAX2 Handler callbacks
    #-- Document Properties --#
    method xmlSAX2GetPublicId(--> Str) is native($XML2) {*};
    method xmlSAX2GetSystemId(--> Str) is native($XML2) {*};
    method xmlSAX2SetDocumentLocator(xmlSAXLocator $loc) is native($XML2) {*};
    method xmlSAX2GetLineNumber(--> int32) is native($XML2) {*};
    method xmlSAX2GetColumnNumber(--> int32) is native($XML2) {*};
    method xmlSAX2IsStandalone(--> int32) is native($XML2) {*};
    method xmlSAX2HasInternalSubset(--> int32) is native($XML2) {*};
    method xmlSAX2HasExternalSubset(--> int32) is native($XML2) {*};
    method xmlSAX2InternalSubset(Str $name , Str $ext-id, Str $int-id--> int32) is native($XML2) {*};
    method xmlSAX2ExternalSubset(Str $name , Str $ext-id, Str $int-id--> int32) is native($XML2) {*};
    method xmlParserWarning(Str $msg ) is native($XML2) {*};
    method xmlParserError(Str $msg ) is native($XML2) {*};

    #-- Entities --#
    method xmlSAX2GetEntity(Str $name --> xmlEntity) is native($XML2) {*};
    method xmlSAX2GetParameterEntity(Str $name --> xmlEntity) is native($XML2) {*};
    method xmlSAX2ResolveEntity(Str $public-id, Str $system-id --> xmlParserInput) is native($XML2) {*};

    #-- Declarations --#
    method xmlSAX2EntityDecl(Str $name, int32 $type, Str $public-id, Str $system-id, Str $content --> xmlParserInput) is native($XML2) {*};
    method xmlSAX2AttributeDecl(Str $elem, Str $fullname, int32 $type, int32 $def, Str $default-value, xmlEnumeration $tree) is native($XML2) {*};
    method xmlSAX2ElementDecl(Str $name, int32 $type, xmlElementContent $content) is native($XML2) {*};
    method xmlSAX2NotationDecl(Str $name, Str $public-id, Str $system-id) is native($XML2) {*};
    method xmlSAX2UnparsedEntityDecl(Str $name, Str $public-id, Str $system-id, Str $notation-name) is native($XML2) {*};

    #-- Content --#
    method xmlSAX2StartDocument() is native($XML2) {*};
    method xmlSAX2EndDocument() is native($XML2) {*};
    method xmlSAX2StartElement(Str $name, CArray $atts) is native($XML2) {*};
    method xmlSAX2EndElement(Str $name) is native($XML2) {*};
    method xmlSAX2StartElementNs(Str $local-name, Str $prefix, Str $uri, int32 $num-namespaces, CArray[Str] $namespaces, int32 $num-attributes, int32 $num-defaulted, CArray[Str] $attributes) is native($XML2) {*};
    method xmlSAX2EndElementNs(Str $local-name, Str $prefix, Str $uri) is native($XML2) {*};
    method xmlSAX2Reference(Str $name) is native($XML2) {*};
    method xmlSAX2Characters(Blob $chars, int32 $len) is native($XML2) {*};
    method xmlSAX2IgnorableWhitespace(Blob $chars, int32 $len) is native($XML2) {*};
    method xmlSAX2ProcessingInstruction(Str $target, Str $data) is native($XML2) {*};
    method xmlSAX2Comment(Str $value) is native($XML2) {*};
    method xmlSAX2CDataBlock(Blob $chars, int32 $len) is native($XML2) {*};
}

#| XML file parser context
class xmlFileParserCtxt is xmlParserCtxt is repr('CStruct') is export {

    our sub New(Str $file --> xmlFileParserCtxt) is native($XML2) is symbol('xmlCreateFileParserCtxt') {*};
    method ParseDocument(--> int32) is native($XML2) is symbol('xmlParseDocument') {*}
    method new(Str() :$file!) { New($file) }
}

#| an incremental XML push parser context. Determines encoding and reads data in binary chunks
class xmlPushParserCtxt is xmlParserCtxt is repr('CStruct') is export {

    our sub New(xmlSAXHandler $sax-handler, Pointer $user-data, Blob $chunk, int32 $size, Str $path --> xmlPushParserCtxt) is native($XML2) is symbol('xmlCreatePushParserCtxt') {*};
    method new(Blob :$chunk!, :$size = +$chunk, xmlSAXHandler :$sax-handler, Pointer :$user-data, Str :$path) {
        New($sax-handler, $user-data, $chunk, $size, $path);
    }
    method ParseChunk(Blob $chunk, int32 $size, int32 $terminate --> int32) is native($XML2) is symbol('xmlParseChunk') {*};
};

#| a vanilla HTML parser context - can be used to read files or strings
class htmlParserCtxt is xmlParserCtxt is repr('CStruct') is export {

    method myDoc { nativecast(htmlDoc, callsame) }
    method UseOptions(int32 --> int32) is native($XML2) is symbol('htmlCtxtUseOptions') { * }

    our sub New(--> htmlParserCtxt) is native($XML2) is symbol('htmlNewParserCtxt') {*};
    method new {New() }
    method ReadDoc(Str $xml, Str $uri, xmlEncodingStr $enc, int32 $flags --> htmlDoc) is native($XML2) is symbol('htmlCtxtReadDoc') {*};
    method ReadFile(Str $xml, Str $uri, xmlEncodingStr $enc, int32 $flags --> htmlDoc) is native($XML2) is symbol('htmlCtxtReadFile') {*}
    method ReadFd(int32 $fd, xmlCharP $uri, xmlEncodingStr $enc, int32 $flags --> htmlDoc) is native($XML2) is symbol('htmlCtxtReadFd') {*};
};

#| HTML file parser context
class htmlFileParserCtxt is htmlParserCtxt is repr('CStruct') is export {

    our sub New(Str $file, xmlEncodingStr $enc --> htmlFileParserCtxt) is native($XML2) is symbol('htmlCreateFileParserCtxt') {*};
    method ParseDocument(--> int32) is native($XML2) is symbol('htmlParseDocument') {*}
    method new(Str() :$file!, xmlEncodingStr :$enc) { New($file, $enc) }
}

#| an incremental HTMLpush parser context. Determines encoding and reads data in binary chunks
class htmlPushParserCtxt is htmlParserCtxt is repr('CStruct') is export {

    our sub New(xmlSAXHandler $sax-handler, Pointer $user-data, Blob $chunk, int32 $size, Str $path, int32 $encoding --> htmlPushParserCtxt) is native($XML2) is symbol('htmlCreatePushParserCtxt') {*};
    method new(Blob :$chunk!, :$size = +$chunk, xmlSAXHandler :$sax-handler, Pointer :$user-data, Str :$path, xmlEncodingStr :$enc) {
        my UInt $encoding = do with $enc { xmlParseCharEncoding($_) } else { 0 };
        New($sax-handler, $user-data, $chunk, $size, $path, $encoding);
    }
    method ParseChunk(Blob $chunk, int32 $size, int32 $terminate --> int32) is native($XML2) is symbol('htmlParseChunk') { *};
};

#| a parser context for an XML in-memory document.
class xmlMemoryParserCtxt is xmlParserCtxt is repr('CStruct') is export {
    our sub New(Blob $buf, int32 $len --> xmlMemoryParserCtxt) is native($XML2) is symbol('xmlCreateMemoryParserCtxt') {*}
    method ParseDocument(--> int32) is native($XML2) is symbol('xmlParseDocument') {*}
    multi method new( Str() :$string! ) {
        my Blob $buf = ($string || ' ').encode;
        self.new: :$buf;
    }
    multi method new( Blob() :$buf!, UInt :$bytes = $buf.bytes --> xmlMemoryParserCtxt:D) {
         New($buf, $bytes);
    }
}

class htmlMemoryParserCtxt is htmlParserCtxt is repr('CStruct') is export {
    sub NewBuf(Blob:D, int32, xmlEncodingStr --> htmlMemoryParserCtxt) is native($BIND-XML2) is symbol('xml6_parser_ctx_html_create_buf') {*}
    sub NewStr(xmlCharP:D, xmlEncodingStr --> htmlMemoryParserCtxt) is native($BIND-XML2) is symbol('xml6_parser_ctx_html_create_str') {*}
    method ParseDocument(--> int32) is native($XML2) is symbol('htmlParseDocument') {*}
    multi method new( Blob() :$buf!, xmlEncodingStr :$enc = 'UTF-8') {
        NewBuf($buf, $buf.bytes, $enc);
    }
    multi method new( Str() :$string! ) {
        NewStr($string, 'UTF-8');
    }
}

multi method GetLastError(xmlParserCtxt:D $ctx) { $ctx.GetLastError() // $.GetLastError()  }
multi method GetLastError { xmlError::Last()  }

## Input callbacks

module xmlInputCallbacks is export {
    our sub Pop(--> int32) is native($XML2) is symbol('xmlPopInputCallbacks') {*}
    our sub RegisterDefault() is native($XML2) is symbol('xmlRegisterDefaultInputCallbacks') {*}
    our sub Register(
        &match (Str --> int32),
        &open (Str --> Pointer),
        &read (Pointer, CArray[uint8], int32 --> int32),
        &close (Pointer --> int32)
         --> int32) is native($XML2) is symbol('xmlRegisterInputCallbacks') {*}
    our sub Cleanup() is native($XML2) is symbol('xmlCleanupInputCallbacks') {*}
}

sub xmlLoadCatalog(Str --> int32) is native($XML2) is export {*}

## xmlInitParser() should be called once at start-up
sub xmlInitParser is native($XML2) is export {*}
sub xml6_ref_init is native($BIND-XML2) {*}
sub xml6_gbl_init_external_entity_loader() is native($BIND-XML2) {*}

## Globals aren't yet writable in Rakudo

method KeepBlanksDefault is rw {
    sub xmlKeepBlanksDefault(int32 $v --> int32) is native($XML2) is export { * }

    Proxy.new(
        FETCH => { ? cglobal($XML2, "xmlKeepBlanksDefaultValue", int32); },
        STORE => sub ($, Bool() $_) {
            xmlKeepBlanksDefault($_);
        },
    );
}

method TagExpansion is rw {
    sub xml6_gbl_set_tag_expansion(int32 $v --> int32) is native($BIND-XML2) is export { * }

    Proxy.new(
        FETCH => { ? cglobal($XML2, "xmlSaveNoEmptyTags", int32); },
        STORE => sub ($, Bool() $_) {
            xml6_gbl_set_tag_expansion($_);
        },
    );
}

module xmlExternalEntityLoader is export {
    our sub Default(xmlCharP, xmlCharP, xmlParserCtxt --> xmlParserInput) is native($XML2) is symbol('xmlDefaultExternalEntityLoader') {*}
    our sub NoNet(xmlCharP, xmlCharP, xmlParserCtxt --> xmlParserInput) is native($XML2) is symbol('xmlNoNetExternalEntityLoader') {*}
    our sub Set( &loader (xmlCharP, xmlCharP, xmlParserCtxt --> xmlParserInput) ) is native($XML2) is symbol('xmlSetExternalEntityLoader') {*}
    our sub Get( --> Pointer ) is native($XML2) is symbol('xmlGetExternalEntityLoader') {*}
    our sub network-enable(int32 $ --> int32) is native($BIND-XML2) is symbol('xml6_gbl_set_external_entity_loader') {*}
}

method ExternalEntityLoader is rw {
    Proxy.new(
        FETCH => { nativecast( :(xmlCharP, xmlCharP, xmlParserCtxt --> xmlParserInput), xmlEntityLoader::Get()) },
        STORE => sub ($, &loader) {
             xmlExternalEntityLoader::Set(&loader)
        }
    );
}

INIT {
    xmlInitParser();
    xml6_ref_init();
    xml6_gbl_init_external_entity_loader; # disables network external entityloading
}
sub xml6_gbl_message_func is export { cglobal($BIND-XML2, 'xml6_gbl_message_func', Pointer) }

=begin pod

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
