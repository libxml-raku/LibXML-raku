use v6;

#| Bindings to the libxml2 library
unit class LibXML::Raw;

=begin pod

=head2 Synopsis

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

=head2 Description

The LibXML::Raw module contains class definitions for native bindings to the LibXML2 library.

=head3 Low level native access

Other high level classes, by convention, have a `raw()` accessor, which can be
used, if needed, to gain access to native objects from this module.

Some care needs to be taken in keeping persistent references to raw structures.

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

=end pod

use NativeCall;
use LibXML::Enums;
use LibXML::Raw::Dict;
use LibXML::Raw::HashTable;
use LibXML::Raw::DOM::Attr;
use LibXML::Raw::DOM::Document;
use LibXML::Raw::DOM::Element;
use LibXML::Raw::DOM::Node;
use Method::Also;

our @ClassMap;

use LibXML::Raw::Defs :$XML2, :$BIND-XML2, :Opaque, :xmlCharP;

sub xmlParserVersion is export { cglobal($XML2, 'xmlParserVersion', Str); }

module xml6_config is export {
    our sub have_threads(-->int32) is native($BIND-XML2) is symbol('xml6_config_have_threads') is export {*}
    our sub have_compression(-->int32) is native($BIND-XML2) is symbol('xml6_config_have_compression') is export {*}
    our sub have_iconv(-->int32) is native($BIND-XML2) is symbol('xml6_config_have_iconv') is export {*}
    our sub version(--> Str) is native($BIND-XML2) is symbol('xml6_config_version') is export {*};
}

our sub ref-current(-->int32) is native($BIND-XML2) is symbol('xml6_ref_current') {*}
our sub ref-total(-->int32) is native($BIND-XML2) is symbol('xml6_ref_total') {*}

module xml6_gbl {...}

module CLib {
    use LibXML::Raw::Defs :$CLIB;
    our sub memcpy(Blob:D, Pointer:D, size_t) is native($CLIB) {*}
    our sub free(Pointer:D) is native($CLIB) {*}
}

# Pointer to string, expected to be freed by the caller
class xmlAllocedStr is Pointer is repr('CPointer') {
    method Str {
        Str.&nativecast(self);
    }
    submethod DESTROY {
        xml6_gbl::xml-free(self);
    }
}

# forward declarations
class anyNode        is repr('CStruct') is export {...}
class itemNode       is repr('CStruct') is export {...}
class xmlAttr        is repr('CStruct') is export {...}
class xmlAttrDecl    is repr('CStruct') is export {...}
class xmlDtd         is repr('CStruct') is export {...}
class xmlDoc         is repr('CStruct') is export {...}
class xmlDocFrag     is repr('CStruct') is export {...}
class xmlElem        is repr('CStruct') is export {...}
class xmlElementDecl is repr('CStruct') is export {...}
class xmlEntity      is repr('CStruct') is export {...}
class xmlError       is repr('CStruct') is export {...}
class xmlNode        is repr('CStruct') is export {...}
class xmlNodeSet     is repr('CStruct') is export {...}
class xmlNotation    is repr('CStruct') is export {...}
class xmlParserCtxt  is repr('CStruct') is export {...}
class xmlParserInput is repr('CStruct') is export {...}
class xmlSAXLocator  is repr('CStruct') is export {...}
class xmlXPathParserContext
                     is repr('CStruct') is export {...}
class xmlXPathObject is repr('CStruct') is export {...}

module xml6_gbl is export {

    our sub cache-size(-->int32) is native($BIND-XML2) is symbol('xml6_gbl_cache_size') {*}

    our sub save-error-handlers(--> Pointer) is symbol('xml6_gbl_save_error_handlers') is native($BIND-XML2) is export {*}
    our sub restore-error-handlers(Pointer) is symbol('xml6_gbl_restore_error_handlers') is native($BIND-XML2) is export {*}

    our sub set-generic-error-handler( &callb (Str $msg), Pointer $setter) is native($BIND-XML2) is symbol('xml6_gbl_set_generic_error_handler') {*}

    our sub get-keep-blanks(--> int32) is symbol('xml6_gbl_os_thread_get_keep_blanks') is native($BIND-XML2) is export { * }
    our sub set-keep-blanks(int32 $v) is symbol('xml6_gbl_os_thread_set_keep_blanks') is native($BIND-XML2) is export { * }

    our sub get-tag-expansion(--> int32) is symbol('xml6_gbl_os_thread_get_tag_expansion') is native($BIND-XML2) is export { * }
    our sub set-tag-expansion(int32 $v) is symbol('xml6_gbl_os_thread_set_tag_expansion') is native($BIND-XML2) is export { * }

    our sub get-external-entity-loader( --> Pointer ) is native($BIND-XML2) is symbol('xml6_gbl_get_external_entity_loader') {*}
    our sub set-external-entity-loader( Pointer --> xmlParserInput) is native($BIND-XML2) is symbol('xml6_gbl_set_external_entity_loader') {*}

    our sub get-default-sax-locator( --> xmlSAXLocator ) is native($BIND-XML2) is symbol('xml6_gbl_get_default_sax_locator') {*}

    our sub xml-free(Pointer) is symbol('xml6_gbl_os_thread_xml_free') is native($BIND-XML2) is export {*}
    our sub init() is symbol('xml6_gbl_init') is native($BIND-XML2) is export {*}
}

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
    method NodeDump(xmlDoc $doc, anyNode $cur, int32 $level, int32 $format --> int32) is native($XML2) is symbol('xmlNodeDump') {*};
    method Content(--> Pointer) is symbol('xmlBufferContent') is native($XML2) { * }
    method Length(--> int32) is symbol('xmlBufferLength') is native($XML2) { * }
    method NotationDump(xmlNotation) is native($XML2) is symbol('xmlDumpNotationDecl') {*};
    method Blob {
        my buf8 $buf;
        my $size = self.Length;
        fail "buffer size $size < 0" unless $size >= 0;
        if $size {
            $buf .= allocate: $size;
            my Pointer $content = self.Content
                || fail "Null Buffer content";
            CLib::memcpy($buf, $content, $size);
        }
        $buf;
    }
    method Str { self.Blob.decode }
    method Free() is native($XML2) is symbol('xmlBufferFree') {*};
    method new(--> xmlBuffer32:D) { New() }
}

#| New buffer structure, introduced in libxml 2.09.00, the actual structure internals are not public
class xmlBuf is repr(Opaque) is export {
    our sub New(size_t --> xmlBuf) is native($XML2) is symbol('xmlBufCreate') {*}
    method Write(xmlCharP --> int32) is native($XML2) is symbol('xmlBufCat') {*}
    method WriteQuoted(xmlCharP --> int32) is native($XML2) is symbol('xmlBufWriteQuotedString') {*}
    method NodeDump(xmlDoc $doc, anyNode $cur, int32 $level, int32 $format --> int32) is native($XML2) is symbol('xmlBufNodeDump') { * }
    method Content(--> Pointer) is symbol('xmlBufContent') is native($XML2) { * }
    method Length(--> int32) is symbol('xmlBufLength') is native($XML2) { * }
    method Blob {
        my buf8 $buf;
        my $size = self.Length;
        fail "buffer size $size < 0" unless $size >= 0;
        if $size {
            $buf .= allocate: $size;
            my Pointer $content = self.Content
                || fail "Null Buffer content";
            CLib::memcpy($buf, $content, $size);
        }
        $buf;
    }
    method Str { self.Blob.decode }
    method Free is symbol('xmlBufFree') is native($XML2) { * }
    method new(UInt:D :$size = 0 --> xmlBuf:D) { New($size) }
}

# type defs
class xmlCharEncodingHandler is repr(Opaque) is export {
    our sub Find(Str --> xmlCharEncodingHandler) is native($XML2) is symbol('xmlFindCharEncodingHandler') {*}
}

# subsets
sub xmlParseCharEncoding(Str --> int32) is export is native($XML2) {*}
my subset xmlEncodingStr of Str is export where {!.defined || xmlParseCharEncoding($_).defined}


#| List structure used when there is an enumeration in DTDs.
class xmlEnumeration is repr('CStruct') is export {
    has xmlEnumeration $.next;
    has xmlCharP $.value;
}

#| A Location Set
class xmlLocationSet is repr(Opaque) is export {}

#| Callback for freeing some parser input allocations.
class xmlParserInputDeallocate is repr(Opaque) is export {}

#| The parser can be asked to collect Node information, i.e. at what
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

#| An XInclude context (libxml v2.13.00+)
class xmlXIncludeCtxt is repr(Opaque) is export {
    our sub New(xmlDoc --> xmlXIncludeCtxt) is native($XML2) is symbol('xmlXIncludeNewContext') {*}
    method new(xmlDoc:D :$doc!) { New($doc) }
    method SetFlags(int32) is native($XML2) is symbol('xmlXIncludeSetFlags') {*}
    # recommended libxml 2.13.0+
    method SetErrorHandler(&error-func (xmlXIncludeCtxt $, xmlError $)) is native($XML2) is symbol('xmlXIncludeSetErrorHandler') {*};
    # legacy
    method SetStructuredErrorFunc(&error-func (xmlXIncludeCtxt $, xmlError $)) is native($XML2) is symbol('xmlSetStructuredErrorFunc') {*};
    method ProcessNode(xmlNode --> int32) is native($XML2) is symbol('xmlXIncludeProcessNode') {*}
    method Free()  is native($XML2) is symbol('xmlXIncludeFreeContext') {*}
}

#| A mapping of name to axis function
class xmlXPathAxis is repr(Opaque) is export {}

#|  A mapping of name to conversion function
class xmlXPathType is repr(Opaque) is export {}

#| Each xmlValidState represent the validation state associated to the
#| set of nodes currently open from the document root to the current element.
class xmlValidState is repr(Opaque) is export {}

multi trait_mod:<is>(Attribute $att, :&rw-ptr!) {

    my role PointerSetterHOW[&setter] {
        # override standard Attribute method for generating accessors
        method compose(Mu $package) {
            my $name = self.name.subst(/^(\$|\@|\%)'!'/, '');
            sub accessor(\obj) is rw {
                sub FETCH($) { self.get_value(obj) }
                sub STORE($, $val is raw) {
                    setter(obj, $val);
                }
                Proxy.new: :&FETCH, :&STORE;
            }
            try $package.^add_method( $name, &accessor );
        }
    }

    $att does PointerSetterHOW[&rw-ptr]
}

multi trait_mod:<is>(Attribute $att, :&rw-str!) {

    my role StringSetterHOW[&setter] {
        method compose(Mu $package) {
            my $name = self.name.subst(/^(\$|\@|\%)'!'/, '');
            my sub accessor(\obj) is rw {
                sub FETCH($) { self.get_value(obj) }
                sub STORE($, $val) {
                    my $str := do with $val {.Str} else { Str };
                    setter(obj, $str);
                }
                Proxy.new: :&FETCH, :&STORE;
            }
            try $package.^add_method( $name, &accessor );
        }
    }

    $att does StringSetterHOW[&rw-str]
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
class xmlParserInput is export {
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

    # since libxml 2.14.0
    our sub NewFromString(Str $url, Str $str, int32 $flags --> ::?CLASS) is native($XML2) is symbol('xmlNewInputFromString') {*}
    method Free is native($XML2) is symbol('xmlFreeInputStream') {*}
    method new(Str:D :$string!, Str :$url, UInt:D :$flags = 0) {
        NewFromString($url, $string, $flags);
    }
}

#| An XML Element content as stored after parsing an element definition
#| in a DTD.
class xmlElementContent is repr('CStruct') is export {
    has int32             $.type;   # PCDATA, ELEMENT, SEQ or OR
    has int32             $.occurs; # ONCE, OPT, MULT or PLUS
    has xmlCharP          $.name;   # Element name
    has xmlElementContent $.c1;     # First child
    has xmlElementContent $.c2;     # Second child
    has xmlElementContent $.parent; # Parent
    has xmlCharP          $.prefix; # Namespace prefix
    method PotentialChildren(CArray[Pointer], int32 $len is rw, int32 $max --> int32)  is native($XML2) is symbol('xmlValidGetPotentialChildren') {*}
    our sub Dump(Blob, int32, xmlElementContent, bool) is native($XML2) is symbol('xmlSnprintfElementContent') {*}
    method Str(UInt :$max = 255, Bool:D :$paren = so ($!type == XML_ELEMENT_CONTENT_SEQ|XML_ELEMENT_CONTENT_OR)) {
        my buf8 $buf .= allocate($max);
        Dump($buf, $max, self, +$paren);
        Str.&nativecast($buf);
    }
}

role domNode[$class, UInt:D $type] is export {
    @ClassMap[$type] = $class;
    method delegate {
        fail "expected node of type $type, got {self.type}"
            unless self.type == $type;
        self
    }
}

#| An XML namespace.
#| Note that prefix == NULL is valid, it defines the default namespace
#| within the subtree (until overridden).
class xmlNs is export is repr('CStruct') {
    also does domNode[$?CLASS, XML_NAMESPACE_DECL];

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
        # approximation of xmlsave.c static function: xmlNsDumpOutput(...)
        my xmlBuffer32 $buf .= new;

        $buf.Write('xmlns');
        $buf.Write(':' ~ $_)
            with self.prefix;

        with self.href {
            $buf.Write('=');
            $buf.WriteQuoted($_);
        }

        my Str $content = $buf.Str;
        $buf.Free;
        $content;
    }
    method ItemNode { itemNode.&nativecast(self) }
}

#| A SAX Locator.
class xmlSAXLocator is export {
    has Pointer  $.getPublicIdFunc is rw-ptr(
        method xml6_sax_locator_set_getPublicId( &cb (xmlParserCtxt $ctx) ) is native($BIND-XML2) {*}
    );

    has Pointer $.getSystemIdFunc is rw-ptr(
        method xml6_sax_locator_set_getSystemId( &cb (xmlParserCtxt $ctx) ) is native($BIND-XML2) {*}
    );

    has Pointer $.getLineNumberFunc is rw-ptr(
        method xml6_sax_locator_set_getLineNumber( &cb (xmlParserCtxt $ctx --> int32) ) is native($BIND-XML2) {*}
    );

    has Pointer $.getColumnNumberFunc is rw-ptr(
        method xml6_sax_locator_set_getColumnNumber( &cb (xmlParserCtxt $ctx --> int32) ) is native($BIND-XML2) {*}
    );

    submethod BUILD(*%atts) {
        for %atts.pairs.sort {
            self."{.key}"() = .value;
        }
    }

    method getPublicId(xmlParserCtxt $ctx) {
        with nativecast(:(xmlParserCtxt $ctx --> xmlCharP), $!getPublicIdFunc) -> &cb {
            &cb($ctx)
        }
    }

    method getSystemId(xmlParserCtxt $ctx --> xmlCharP) {
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
         xml6_gbl::get-default-sax-locator();
    }
}

#| A SAX handler is bunch of callbacks called by the parser when processing
#| of the input generate data or structure information.
class xmlSAXHandler is repr('CStruct') is export {

    submethod BUILD(*%atts) {
        for %atts.pairs.sort {
            self."{.key}"() = .value;
        }
    }
    method raw { self } # already raw

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
        method xml6_sax_set_entityDecl( &cb (xmlParserCtxt $ctx, Str $name, uint32 $type, Str $public-id, Str $system-id, Str $content) ) is native($BIND-XML2) {*}
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
    method initxmlDefaultSAXHandler(int32 $warning) is native($XML2) {*} # until v2.9.14
    method inithtmlDefaultSAXHandler is native($XML2) {*}                # until v2.9.14
    multi method init(Int:D :$version! where 1, Bool :$html! where .so, ) {
        $.inithtmlDefaultSAXHandler()
    }
    multi method init(Int:D :$version! where 1, Bool :$warning = True, ) {
        $.initxmlDefaultSAXHandler( +$warning );
    }
    multi method init(Bool :$html! where .so) {
        $.xmlSAX2InitHtmlDefaultSAXHandler()
    }
    multi method init(:$warning = True) {
        $.xmlSAX2InitDefaultSAXHandler( +$warning );
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

    our sub Last(--> xmlError) is native($BIND-XML2) is symbol('xml6_gbl_os_thread_get_last_error') {*}
    method context(uint32 is rw --> xmlAllocedStr) is native($BIND-XML2) is symbol('xml6_error_context_and_column') {*}
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
                when xmlNodeSet|anyNode { .Reference }
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
            $v.Unreference if $v ~~ xmlNodeSet:D|anyNode:D;
        }
    }

    method domXPathGetNodeSet(int32 $select --> xmlNodeSet) is native($BIND-XML2) {*}
    method domXPathGetPoint(int32 $select --> anyNode) is native($BIND-XML2) {*}
    method Free is symbol('xmlXPathFreeObject') is native($XML2) {*}

    our sub NewString(xmlCharP --> xmlXPathObject) is native($XML2) is symbol('xmlXPathNewString') {*}
    our sub NewFloat(num64 --> xmlXPathObject) is native($XML2) is symbol('xmlXPathNewFloat') {*}
    our sub NewBoolean(int32 --> xmlXPathObject) is native($XML2) is symbol('xmlXPathNewBoolean') {*}
    our sub NewNodeSet(anyNode:D --> xmlXPathObject) is native($XML2) is symbol('xmlXPathNewNodeSet') {*}
    our sub NewPoint(anyNode:D, int32 --> xmlXPathObject) is native($BIND-XML2) is symbol('domXPathNewPoint') {*}
    our sub WrapNodeSet(xmlNodeSet --> xmlXPathObject) is native($XML2) is symbol('xmlXPathWrapNodeSet') {*}

    multi method COERCE(Bool:D $v)           { NewBoolean($v) }
    multi method COERCE(Numeric:D $v)        { NewFloat($v.Num) }
    multi method COERCE(Str:D $v)            { NewString($v) }
    multi method COERCE(anyNode:D $v, UInt :$index = 0)      { NewPoint($v, $index) }
    multi method COERCE(xmlNodeSet:D $v)     { WrapNodeSet($v.copy) }
    method coerce($v) is DEPRECATED<COERCE>  { self.COERCE($v) }

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
                self.domXPathGetPoint(+$select);
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
    method Compile(xmlCharP --> xmlXPathCompExpr) is native($XML2) is symbol('xmlXPathCtxtCompile') {*}
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
        self.Find($expr, $ref-node, $bool.so);
    }
    method RegisterNs(Str, Str --> int32) is symbol('xmlXPathRegisterNs') is native($XML2) {*}
    method NsLookup(xmlCharP --> xmlCharP) is symbol('xmlXPathNsLookup') is native($XML2) {*}

    method RegisterFunc(xmlCharP $name, &func1 (xmlXPathParserContext, int32 --> xmlXPathObject) ) is symbol('xmlXPathRegisterFunc') is native($XML2) {*}
    method RegisterFuncNS(xmlCharP $name, xmlCharP $ns-uri, &func2 (xmlXPathParserContext, int32 --> xmlXPathObject) ) is symbol('xmlXPathRegisterFuncNS') is native($XML2) {*}
    method RegisterVariableLookup( &func3 (xmlXPathContext, Str, Str --> xmlXPathObject), Pointer ) is symbol('xmlXPathRegisterVariableLookup') is native($XML2) {*}
    method GetVariableLookupFunc( --> Pointer) is symbol('xml6_xpath_ctxt_get_var_lookup_func') is native($BIND-XML2) {*}
    constant xmlXPathFunction = Pointer;
    method RegisterFuncLookup( &func4 (xmlXPathContext, xmlCharP $name, xmlCharP $ns-uri --> xmlXPathFunction), Pointer) is native($XML2) is symbol('xmlXPathRegisterFuncLookup') {*};
    method FunctionLookupNS(xmlCharP $name, xmlCharP $ns_uri --> xmlXPathFunction) is native($XML2) is symbol('xmlXPathFunctionLookupNS') {*};
    # recommended libxml 2.13.0+
    method SetErrorHandler(&error-func (xmlXIncludeCtxt $, xmlError $)) is native($XML2) is symbol('xmlXPathSetErrorHandler') {*};
    # legacy
    method SetStructuredErrorFunc( &error-func (xmlXPathContext $, xmlError $)) is native($BIND-XML2) is symbol('domSetXPathCtxtErrorHandler') {*};
}

#| An XPath parser context. It contains pure parsing information,
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

    #++ valuePush, valuePop renamed in libxml2 v2.15.0
    method valuePop(--> xmlXPathObject) is native($XML2) {*}
    method valuePush(xmlXPathObject --> int32) is native($XML2) {*}
    #++ libxml2 v2.15.0+
    method XPathPop(--> xmlXPathObject) is symbol('xmlXPathValuePop') is native($XML2) {*}
    method XPathPush(xmlXPathObject --> int32)  is symbol('xmlXPathValuePush') is native($XML2) {*}
}

class anyNode is export does LibXML::Raw::DOM::Node {
    has Pointer $._private; # application data
    has int32       $.type; # type number, must be second !
    has xmlCharP    $!name; # the name of the node, or the entity
    method name { $!name }
    has anyNode $.children; # parent->child link
    has anyNode     $.last; # last child link
    has anyNode   $.parent; # child->parent link
    has anyNode     $.next; # next sibling link
    has anyNode     $.prev; # previous sibling link
    has xmlDoc       $.doc  # the containing document
         is rw-ptr(method xml6_node_set_doc(xmlDoc) is native($BIND-XML2) {*});
    # + additional fields, depending on node-type; see xmlElem, xmlDoc, xmlAttr, etc...

    method GetBase { self.doc.NodeGetBase(self) }
    method SetBase(xmlCharP) is native($XML2) is symbol('xmlNodeSetBase') {*}
    method Free() is native($XML2) is symbol('xmlFreeNode') {*}
    method FreeList() is native($XML2) is symbol('xmlFreeNodeList') {*}
    method SetListDoc(xmlDoc) is native($XML2) is symbol('xmlSetListDoc') {*}
    method GetLineNo(--> long) is native($XML2) is symbol('xmlGetLineNo') {*}
    method IsBlank(--> int32) is native($XML2) is symbol('xmlIsBlankNode') {*}
    method GetNodePath(--> xmlAllocedStr) is native($XML2) is symbol('xmlGetNodePath') {*}
    method AddChild(anyNode --> anyNode) is native($XML2) is symbol('xmlAddChild') {*}
    method AddChildList(anyNode --> anyNode) is native($XML2) is symbol('xmlAddChildList') {*}
    method AddContent(xmlCharP --> int32) is native($XML2) is symbol('xmlNodeAddContent') {*}
    method SetContext(xmlXPathContext --> int32) is symbol('xmlXPathSetContextNode') is native($XML2) {*}
    method XPathEval(Str, xmlXPathContext --> xmlXPathObject) is symbol('xmlXPathNodeEval') is native($XML2) {*}
    method domXPathSelectStr(Str --> xmlNodeSet) is native($BIND-XML2) {*}
    method domXPathFind(xmlXPathCompExpr, int32 --> xmlXPathObject) is native($BIND-XML2) {*}
    method domFailure(--> xmlAllocedStr) is native($BIND-XML2) {*}
    method dom-error { die .Str with self.domFailure }
    method domAppendChild(anyNode --> anyNode) is native($BIND-XML2) {*}
    method domReplaceNode(anyNode --> anyNode) is native($BIND-XML2) {*}
    method domAddSibling(anyNode --> anyNode) is native($BIND-XML2) {*}
    method domReplaceChild(anyNode, anyNode --> anyNode) is native($BIND-XML2) {*}
    method domInsertBefore(anyNode, anyNode --> anyNode) is native($BIND-XML2) {*}
    method domInsertAfter(anyNode, anyNode --> anyNode) is native($BIND-XML2) {*}
    method domGetNodeName(--> xmlCharP) is native($BIND-XML2) {*}
    method domSetNodeName(Str) is native($BIND-XML2) {*}
    method domGetNodeValue(--> xmlAllocedStr) is native($BIND-XML2) {*}
    method domGetXPathKey(--> xmlCharP) is native($BIND-XML2) {*}
    method domGetASTKey(--> xmlCharP) is native($BIND-XML2) {*}
    method domSetNodeValue(Str) is native($BIND-XML2) {*}
    method domRemoveChild(anyNode --> anyNode) is native($BIND-XML2) {*}
    method domRemoveChildNodes(--> xmlDocFrag) is native($BIND-XML2) {*}

    method domAppendTextChild(Str $name, Str $value --> anyNode) is native($BIND-XML2) {*}
    method domAddNewChild(Str $uri, Str $name --> anyNode) is native($BIND-XML2) {*}
    method domSetNamespace(Str $URI, Str $prefix, int32 $flag --> int32) is native($BIND-XML2) {*}
    method first-child(int32 --> anyNode) is native($BIND-XML2) is symbol('xml6_node_first_child') {*}
    method last-child(int32 --> anyNode) is native($BIND-XML2) is symbol('xml6_node_last_child') {*}
    method next-node(int32 --> anyNode) is native($BIND-XML2) is symbol('xml6_node_next') {*}
    method prev-node(int32 --> anyNode) is native($BIND-XML2) is symbol('xml6_node_prev') {*}
    method is-referenced(--> int32) is native($BIND-XML2) is symbol('domNodeIsReferenced') {*}
    method root(--> anyNode) is native($BIND-XML2) is symbol('xml6_node_find_root') {*}
    method domGetChildrenByLocalName(Str --> xmlNodeSet) is native($BIND-XML2) {*}
    method domGetChildrenByTagName(Str --> xmlNodeSet) is native($BIND-XML2) {*}
    method domGetChildrenByTagNameNS(Str, Str --> xmlNodeSet) is native($BIND-XML2) {*}
    method domGetElementsByLocalName(Str --> xmlNodeSet) is native($BIND-XML2) {*}
    method domGetElementsByTagName(Str --> xmlNodeSet) is native($BIND-XML2) {*}
    method domGetElementsByTagNameNS(Str, Str --> xmlNodeSet) is native($BIND-XML2) {*}
    method !hash(int32 $keep-blanks --> xmlHashTable) is native($BIND-XML2) is symbol('xml6_hash_xpath_node_children') {*}
    method Hash(:$blank) {
        self!hash(+$blank.so);
    }

    method domNormalize(--> int32) is native($BIND-XML2) {*}
    method domUniqueKey(--> xmlAllocedStr) is native($BIND-XML2) {*}
    method domIsSameNode(anyNode --> int32) is native($BIND-XML2) {*}

    method xml6_node_to_str_C14N(int32 $comments, int32 $mode, CArray[Str] $inc-prefix is rw, xmlNodeSet --> xmlAllocedStr) is native($BIND-XML2) {*}

    method Str(anyNode:D: UInt :$options = 0 --> xmlCharP) is default {
        do with self.Blob(:$options) {
            .decode('utf8');
        } // Str;
    }

    method xml6_node_is_htmlish(--> int32) is native($BIND-XML2) {*}
    method isHTMLish { ? self.xml6_node_is_htmlish }
    method xml6_node_to_buf(int32 $opts, size_t $len is rw, Str $enc  --> Pointer[uint8]) is native($BIND-XML2) {*}

    method Blob(anyNode:D: int32 :$options = 0, xmlEncodingStr :$enc --> Blob) {
        my buf8 $buf;

        if self.xml6_node_to_buf($options, my size_t $len, $enc) -> $p {
            $buf .= allocate($len);
            CLib::memcpy($buf, $p, $len);
            xml6_gbl::xml-free($p);
        }

        $buf;
    }

    method xmlCopyNode (int32 $extended --> anyNode) is native($XML2) {*}
    method xmlDocCopyNode(xmlDoc, int32 --> anyNode) is native($XML2) {*}
    method copy(Bool :$deep) {
        my $extended := $deep ?? 1 !! 2;
        with $.doc {
            $.xmlDocCopyNode($_, $extended).delegate;
        }
        else {
            $.xmlCopyNode( $extended ).delegate;
        }
    }

    method string-value(--> xmlAllocedStr) is native($XML2) is symbol('xmlXPathCastNodeToString') {*}
    method Unlink is native($BIND-XML2) is symbol('domUnlinkNode') {*}
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
    method ItemNode handles<delegate cast> {  itemNode.&nativecast(self) }

    method new() { fail "new() not available for " ~ self.WHAT.raku }
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
    has Pointer        $.psvi; # for type/PSVI information
    has uint16         $.line; # line number
    has uint16        $.extra; # extra data for XPath/XSLT

    method domSetNamespaceDeclURI(xmlCharP $prefix, xmlCharP $uri --> int32) is native($BIND-XML2) {*}
    method domGetNamespaceDeclURI(xmlCharP $prefix --> xmlCharP) is native($BIND-XML2) {*}
    method domSetNamespaceDeclPrefix(xmlCharP $prefix, xmlCharP $ns-prefix --> int32) is native($BIND-XML2) {*}
}

#| xmlNode of type: XML_ELEMENT_NODE
class xmlElem is xmlNode is export does LibXML::Raw::DOM::Element {
    also does domNode[$?CLASS, XML_ELEMENT_NODE];

    method NewNs(xmlCharP $href, xmlCharP $prefix --> xmlNs) is native($XML2) is symbol('xmlNewNs') {*};
    method SetProp(Str, Str --> xmlAttr) is native($XML2) is symbol('xmlSetProp') {*}
    method domGetAttributeNode(xmlCharP $qname --> xmlAttr) is native($BIND-XML2) {*}
    method domGetAttribute(xmlCharP $qname --> xmlAllocedStr) is native($BIND-XML2)  {*}
    method domHasAttributeNS(xmlCharP $uri, xmlCharP $name --> int32) is native($BIND-XML2) {*}
    method domGetAttributeNS(xmlCharP $uri, xmlCharP $name --> xmlAllocedStr) is native($BIND-XML2) {*}
    method domGetAttributeNodeNS(xmlCharP $uri, xmlCharP $name --> xmlAttr) is native($BIND-XML2) {*}
    method domSetAttribute(Str, Str --> int32) is native($BIND-XML2) {*}
    method domSetAttributeNode(xmlAttr --> xmlAttr) is native($BIND-XML2) {*}
    method domSetAttributeNodeNS(xmlAttr --> xmlAttr) is native($BIND-XML2) {*}
    method domSetAttributeNS(Str $URI, Str $name, Str $value --> xmlAttr) is native($BIND-XML2) {*}
    method domGenNsPrefix(Str $base-prefix --> xmlCharP) is native($BIND-XML2) {*}

    # The content field may hold the index of the element in the
    # document, if doc.IndexElements has been run
    method content(--> int32) is native($BIND-XML2) is symbol('xml6_node_get_elem_index') {*}
    method ValidElements(xmlElem, CArray[Str], int32 $max --> int32)  is native($XML2) is symbol('xmlValidGetValidElements') {*}

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
    also does domNode[$?CLASS, XML_TEXT_NODE];

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
    also does domNode[$?CLASS, XML_COMMENT_NODE];

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
    also does domNode[$?CLASS, XML_CDATA_SECTION_NODE];

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
    also does domNode[$?CLASS, XML_PI_NODE];

    method new(xmlDoc :$doc, Str:D :$name!, Str :$content) {
        $doc.new-pi(:$name, :$content);
    }

}

#| xmlNode of type: XML_ENTITY_REF_NODE
class xmlEntityRefNode is xmlNode is repr('CStruct') is export {
    also does domNode[$?CLASS, XML_ENTITY_REF_NODE];

    multi method new(xmlDoc:D :$doc!, Str:D :$name!) {
        $doc.new-ent-ref(:$name);
    }
}

#| An attribute on an XML node (type: XML_ATTRIBUTE_NODE)
class xmlAttr is anyNode does LibXML::Raw::DOM::Attr is export {
    also does domNode[$?CLASS, XML_ATTRIBUTE_NODE];

    has xmlNs       $.ns; # the associated namespace
    has int32    $.atype; # the attribute type if validating
    has Pointer   $.psvi; # for type/PSVI information
    ## todo Only available in newer libxml2 versions!
    has Pointer $!id;     # the ID struct

    method Free is native($XML2) is symbol('xmlFreeProp') {*}
    method xmlCopyProp(--> xmlAttr) is native($XML2) {*}
    method copy() { $.xmlCopyProp }
    method new(Str :$name!, Str :$value!, xmlDoc :$doc --> xmlAttr:D) {
        $doc.NewProp($name, $value);
    }
    method domAttrSerializeContent(--> xmlAllocedStr) is native($BIND-XML2) {*}
}

#| An XML document (type: XML_DOCUMENT_NODE)
class xmlDoc is anyNode does LibXML::Raw::DOM::Document is export {
    # note: htmlDoc is based on this class
    @ClassMap[XML_DOCUMENT_NODE] = $?CLASS;

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
    has xmlDict         $.dict;        # dict used to allocate names or NULL
    has Pointer         $.psvi;        # for type/PSVI information
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
    method GetRootElement(--> xmlElem) handles<nsDef> is symbol('xmlDocGetRootElement') is native($XML2) { * }
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
    method GetEntity(Str --> xmlEntity) is native($XML2) is symbol('xmlGetDocEntity') {*}

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

    method NodeGetBase(anyNode --> xmlAllocedStr) is native($XML2) is symbol('xmlNodeGetBase') {*}
    method EncodeEntitiesReentrant(xmlCharP --> xmlAllocedStr) is native($XML2) is symbol('xmlEncodeEntitiesReentrant') {*}
    method NewProp(xmlCharP $name, xmlCharP $value --> xmlAttr) is symbol('xmlNewDocProp') is native($XML2) {*}
    method XIncludeProcessFlags(uint32 $flags --> int32) is symbol('xmlXIncludeProcessFlags') is native($XML2) {*}
    method SearchNs(anyNode, Str --> xmlNs) is native($XML2) is symbol('xmlSearchNs') {*}
    method SearchNsByHref(anyNode, Str --> xmlNs) is native($XML2) is symbol('xmlSearchNsByHref') {*}
    method GetID(Str --> xmlAttr) is native($XML2) is symbol('xmlGetID') {*}
    method IsID(xmlElem, xmlAttr --> int32) is native($XML2) is symbol('xmlIsID') {*}
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
    method domSetInternalSubset(xmlDtd --> xmlDtd) is native($BIND-XML2) {*}
    method domSetExternalSubset(xmlDtd --> xmlDtd) is native($BIND-XML2) {*}

    method set-flags(int32 --> int32) is native($BIND-XML2) is symbol('xml6_doc_set_flags') {*}
    method get-flags(--> int32) is native($BIND-XML2) is symbol('xml6_doc_get_flags') {*}
    method set-doc-properties(int32 --> int32) is native($BIND-XML2) is symbol('xml6_doc_set_doc_properties') {*}
}

#| xmlDoc of type: XML_HTML_DOCUMENT_NODE
class htmlDoc is xmlDoc is repr('CStruct') is export {
    also does domNode[$?CLASS, XML_HTML_DOCUMENT_NODE];

    method DumpFormat(xmlAllocedStr $ is rw, int32 $ is rw, int32 ) is symbol('htmlDocDumpMemoryFormat') is native($XML2) {*}
    our sub New(xmlCharP $URI, xmlCharP $external-id --> htmlDoc) is native($XML2) is symbol('htmlNewDoc') {*}
    method new(Str :$URI, Str :$external-id) {
        New($URI, $external-id);
    }

    method dump(Bool:D :$format = True) is DEPRECATED("see issue #90") {
        my xmlAllocedStr $out .= new;
        my int32 $len;

        self.DumpFormat($out, $len, +$format);
        $out.Str;
    }
}

#| xmlNode of type: XML_DOCUMENT_FRAG_NODE
class xmlDocFrag is xmlNode is export {
    also does domNode[$?CLASS, XML_DOCUMENT_FRAG_NODE];

    our sub New(xmlDoc $doc --> xmlDocFrag) is native($XML2) is symbol('xmlNewDocFragment') {*}
    method new(xmlDoc :$doc, xmlNode :$nodes) {
        my xmlDocFrag:D $frag = New($doc);
        $frag.set-nodes($_) with $nodes;
        $frag;
    }
}

class xmlNotation is export {
    has xmlCharP $.name;
    has xmlCharP $.publicId;
    has xmlCharP $.systemId;

    our sub New(xmlCharP, xmlCharP, xmlCharP  --> xmlNotation) is native($BIND-XML2) is symbol('xml6_notation_create') {*}
    method new(Str:D :$name!, Str :$publicId, Str :$systemId) {
        New($name, $publicId, $systemId);
    }
    method Free is native($BIND-XML2) is symbol('xml6_notation_free') {*}
    method Copy(--> xmlNotation) is native($BIND-XML2) is symbol('xml6_notation_copy') {*}
    method UniqueKey(--> xmlAllocedStr) is native($BIND-XML2) is symbol('xml6_notation_unique_key') {*}
    method copy { $.Copy }
    multi method Str(xmlNotation:D:){
        my xmlBuffer32 $buf .= new;
        $buf.NotationDump(self);
        my Str $content = $buf.Str;
        $buf.Free;
        $content;
    }
}

#| An XML DTD, as defined by <!DOCTYPE ... There is actually one for
#| the internal subset and for the external subset (type: XML_DTD_NODE).
class xmlDtd is anyNode is export {
    BEGIN @ClassMap[XML_DTD_NODE] = $?CLASS;
    has xmlHashTable  $.notations; # Hash table for notations if any
    has xmlHashTable   $.elements; # Hash table for element declarations if any
    has xmlHashTable $.attributes; # Hash table for attribute declarations if any
    has xmlHashTable   $.entities; # Hash table for entities if any
    has xmlCharP     $.ExternalID; # External identifier for PUBLIC DTD
    has xmlCharP       $.SystemID; # URI for a SYSTEM or PUBLIC DTD
    has xmlHashTable  $.pentities; # Hash table for param entities if any

    method publicId { $!ExternalID }
    method systemId { $!SystemID }

    method Copy(--> xmlDtd) is native($XML2) is symbol('xmlCopyDtd') {*}
    method copy() { $.Copy }

    our sub xmlIsXHTML(xmlCharP $systemID, xmlCharP $publicID --> int32) is native($XML2) {*}
    method IsXHTML returns int32 { xmlIsXHTML($!SystemID, $!ExternalID) }
    method getAttrDecl(xmlCharP $elem, xmlCharP $name --> xmlAttrDecl) is native($XML2) is symbol('xmlGetDtdAttrDesc') {*}
    method getElementDecl(xmlCharP --> xmlElementDecl) is native($XML2) is symbol('xmlGetDtdElementDesc') {*}
    method getEntity(xmlCharP --> xmlEntity) is native($BIND-XML2) is symbol('domGetEntityFromDtd') {*}
    method getParameterEntity(xmlCharP --> xmlEntity) is native($BIND-XML2) is symbol('domGetParameterEntityFromDtd') {*}
    method getNotation(xmlCharP --> xmlNotation) is native($XML2) is symbol('xmlGetDtdNotationDesc') {*}
    multi method new(:type($)! where 'internal', xmlDoc:D :$doc, Str :$name, Str :$external-id, Str :$system-id) {
        $doc.CreateIntSubset( $name, $external-id, $system-id);
    }
    multi method new(:type($)! where 'external', xmlDoc :$doc, Str :$name, Str :$external-id, Str :$system-id) {
        $doc.NewDtd( $name, $external-id, $system-id);
    }
    multi method new(|c) is default { fail c.raku }
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
class xmlAttrDecl is anyNode is export {
    BEGIN @ClassMap[XML_ATTRIBUTE_DECL] = $?CLASS;
    has xmlAttrDecl     $.nexth; # next in hash table
    has int32           $.atype; # the attribute type
    has int32             $.def; # default mode (enum xmlAttributeDefault)
    has xmlCharP $.defaultValue; # or the default value
    has xmlEnumeration  $.values; # or the enumeration tree if any
    has xmlCharP       $.prefix; # the namespace prefix if any
    has xmlCharP         $.elem; # Element holding the attribute
}

#| An unit of storage for an entity, contains the string, the value and
#| the data needed for the linking in the hash table (type: XML_ENTITY_DECL).
class xmlEntity is anyNode is export {
    BEGIN @ClassMap[XML_ENTITY_DECL] = $?CLASS;
    has xmlCharP       $.orig; # content without ref substitution */
    has xmlCharP    $.content; # content or ndata if unparsed */
    has int32        $.length; # the content length */
    has int32         $.etype; # The entity type */
    
    has xmlCharP $.ExternalID; # External identifier for PUBLIC */
    has xmlCharP   $.SystemID; # URI for a SYSTEM or PUBLIC Entity */

    has xmlEntity     $.nexte; # unused */
    has xmlCharP        $.URI; # the full URI as computed */
    has int32         $.owner; # does the entity own the childrens */
    #
    # Todo: libxml2 2.10.0+ has made structural changes below this point
    # Remaining structure is version dependant
    has int32       $!checked; # was the entity content checked */
                               # this is also used to count entities
                               # references done from that entity
                               # and if it contains '<' */
    our sub GetPredefined(xmlCharP $name --> xmlEntity) is native($XML2) is symbol('xmlGetPredefinedEntity') { * }
    our sub Create(xmlCharP $name, int32 $type, xmlCharP $ext-id, xmlCharP $int-id, xmlCharP $value --> xmlEntity) is native($BIND-XML2) is symbol('xml6_entity_create') {*}
    method get-predefined(Str :$name!) {
        GetPredefined($name);
    }
    method Reference { nextsame unless self.etype == +XML_INTERNAL_PREDEFINED_ENTITY}
    method Unreference { nextsame unless self.etype == +XML_INTERNAL_PREDEFINED_ENTITY}
    method create(Str:D :$name!, Str:D :$content!, Int :$type = XML_INTERNAL_GENERAL_ENTITY, Str :$external-id, Str :$internal-id) {
        Create($name, $type, $external-id, $internal-id, $content );
    }
}

#| An XML Element declaration from a DTD (type: XML_ELEMENT_DECL).
class xmlElementDecl is anyNode is export {
    BEGIN @ClassMap[XML_ELEMENT_DECL] = $?CLASS;
    has int32                $.etype; # The type */
    has xmlElementContent  $.content; # the allowed element content */
    has xmlAttrDecl     $.attributes; # List of the declared attributes */
    has xmlCharP            $.prefix; # the namespace prefix if any */
    has xmlRegexp        $.contModel; # the validating regexp */
}

# itemNodes are xmlNodeSet members; which can be either anyNode or xmlNs objects.
# These have distinct structs, but have the second field, 'type' in common
class itemNode is export {
    has Pointer $!pad; # first field depends on type
    has int32 $.type;
    # + other fields, which also depend on type

    method delegate {
        my $class := @ClassMap[$!type];
        $class.&nativecast(self);
    }
    method cast(Pointer:D $p) {
        my $type := nativecast(itemNode, $p).type;
        my $class := @ClassMap[$type];
        $class.&nativecast($p);
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
    method !hash(int32 $deref --> xmlHashTable) is native($BIND-XML2) is symbol('xml6_hash_xpath_nodeset') {*}
    method Hash(:$deref) { self!hash(+$deref.so) }
    method Reference is native($BIND-XML2) is symbol('domReferenceNodeSet') {*}
    method Unreference is native($BIND-XML2) is symbol('domUnreferenceNodeSet') {*}
    method Free is native($XML2) is symbol('xmlXPathFreeNodeSet') {*}
    method delete(itemNode --> int32) is symbol('domDeleteNodeSetItem') is native($BIND-XML2) {*}
    method copy(--> xmlNodeSet) is symbol('domCopyNodeSet') is native($BIND-XML2) {*}
    method reverse(--> xmlNodeSet) is symbol('domReverseNodeSet') is native($BIND-XML2) {*}
    method push(itemNode, int32) is symbol('domPushNodeSet') is native($BIND-XML2) {*}
    method pop(--> itemNode) is symbol('domPopNodeSet') is native($BIND-XML2) {*}
    method hasSameNodes(xmlNodeSet --> int32) is symbol('xmlXPathHasSameNodes') is native($XML2) {*}
    method AT-POS(int32 --> itemNode) is symbol('domNodeSetAtPos') is native($BIND-XML2) {*}

    proto method new(|) {*}
    multi method new(itemNode:D :$node, :list($)! where .so, Bool :$keep-blanks = True) {
        NewFromList($node, +$keep-blanks);
    }
    multi method new(anyNode :$node) {
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
    method ValidateElement(xmlDoc, xmlElem --> int32) is native($XML2) is symbol('xmlValidateElement') {*}
    method ValidateOneAttribute(xmlDoc, xmlElem, xmlAttr, xmlCharP --> int32) is native($XML2) is symbol('xmlValidateOneAttribute') {*}
    method SetStructuredErrorFunc( &error-func (xmlValidCtxt $, xmlError $)) is native($XML2) is symbol('xmlSetStructuredErrorFunc') {*};
    method Free is symbol('xmlFreeValidCtxt') is native($XML2) {*}
    method new { New() }
    multi method validate(xmlDoc:D :$doc!, xmlDtd:D :$dtd!) {
        self.ValidateDtd($doc, $dtd);
    }
    multi method validate(xmlDoc:D :$doc!, xmlElem:D :$elem, xmlAttr:D :$attr) {
        self.ValidateOneAttribute($doc, $elem, $attr, $attr.domGetNodeValue.str);
    }
    multi method validate(xmlDoc:D :$doc!, xmlElem:D :$elem) {
        self.ValidateElement($doc, $elem);
    }
    multi method validate(xmlDoc:D :$doc!) {
        self.ValidateDocument($doc);
    }
}

#| The parser context.
class xmlParserCtxt is export {
    has xmlSAXHandler          $.sax           # The SAX handler
        is rw-ptr(method xml6_parser_ctx_set_sax( xmlSAXHandler ) is native($BIND-XML2) {*} );
    has Pointer                $.userData;     # For SAX interface only, used by DOM build
    has xmlDoc                 $.myDoc         # the document being built
       is rw-ptr(method set-myDoc( xmlDoc ) is symbol('xml6_parser_ctx_set_myDoc') is native($BIND-XML2) {*} );
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

    # the complete error information for the last error.
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
    method new() {
        New()
    }
    method ReadDoc(Str $xml, Str $uri, xmlEncodingStr $enc, int32 $flags --> xmlDoc) is native($XML2) is symbol('xmlCtxtReadDoc') {*};
    method ReadFile(Str $xml, xmlEncodingStr $enc, int32 $flags --> xmlDoc) is native($XML2) is symbol('xmlCtxtReadFile') {*};
    method ReadFd(int32 $fd, xmlCharP $uri, xmlEncodingStr $enc, int32 $flags --> xmlDoc) is native($XML2) is symbol('xmlCtxtReadFd') {*};
    method UseOptions(int32 --> int32) is native($XML2) is symbol('xmlCtxtUseOptions') { * }
    method NewInputStream(xmlParserInputBuffer, int32 $enc --> xmlParserInput) is native($XML2) is symbol('xmlNewIOInputStream') is export {*}
    method NewInputFile(Str --> xmlParserInput) is native($XML2) is export is symbol('xmlNewInputFromFile') {*}
    method LoadDtd(xmlCharP $ext-id, xmlCharP $sys-id --> xmlParserInput) is native($BIND-XML2) is symbol('xml6_parser_ctx_load_dtd') {*}
    #++ available since libxml2 v2.14.0
    method ParseDtd(xmlParserInput, xmlCharP $ext-id, xmlCharP $int-id --> xmlDtd) is native($XML2) is export is symbol('xmlCtxtParseDtd') {*}
    method ParseContent(xmlParserInput, xmlNode, int32 $has-text-decl --> xmlNode) is native($XML2) is export is symbol('xmlCtxtParseContent') {*}
    #-- available since libxml2 v2.14.0
    # deprecated
    method SetStructuredErrorFunc( &error-func (xmlParserCtxt $, xmlError $)) is native($XML2) is symbol('xmlSetStructuredErrorFunc') {*};
    # recommended libxml 2.13.0+
    method SetErrorHandler(&error-func (xmlParserCtxt $, xmlError $)) is native($XML2) is symbol('xmlCtxtSetErrorHandler') {*};
    method GetLastError(--> xmlError) is native($XML2) is symbol('xmlCtxtGetLastError') is native($XML2) {*}
    method Close(--> int32) is native($BIND-XML2) is symbol('xml6_parser_ctx_close') {*}
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

    our sub New(Str $file, int32 $flags --> xmlFileParserCtxt) is native($XML2) is symbol('xmlCreateURLParserCtxt') {*};
    method ParseDocument(--> int32) is native($XML2) is symbol('xmlParseDocument') {*}
    method new(Str() :$file!, UInt:D :$flags = 0) { New($file, $flags) }
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

    method myDoc is rw { htmlDoc.&nativecast(callsame) }
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
    our sub Register(
        &match (Str --> int32),
        &open (Str --> Pointer),
        &read (Pointer, CArray[uint8], int32 --> int32),
        &close (Pointer --> int32)
         --> int32) is native($XML2) is symbol('xmlRegisterInputCallbacks') {*}
}

sub xmlLoadCatalog(Str --> int32) is native($XML2) is export {*}

## xmlInitParser() should be called once at start-up
sub xmlInitParser is native($XML2) is export {*}

sub xmlHasFeature(int32 --> int32) is native($XML2) is export {*}

## Globals aren't yet writable in Rakudo

method KeepBlanksDefault is rw {
    sub FETCH($) { ? xml6_gbl::get-keep-blanks() }
    sub STORE($, Bool() $_) {
        xml6_gbl::set-keep-blanks($_);
    }
    Proxy.new: :&FETCH, :&STORE;
}

method TagExpansion is rw {
    sub FETCH($) { ? xml6_gbl::get-tag-expansion() }
    sub STORE($, Bool() $_) {
        xml6_gbl::set-tag-expansion($_);
    }
    Proxy.new: :&FETCH, :&STORE;
}

module xmlExternalEntityLoader is export {
    our sub NoNet(xmlCharP, xmlCharP, xmlParserCtxt --> xmlParserInput) is native($XML2) is symbol('xmlNoNetExternalEntityLoader') {*}
    our sub Set( &loader (xmlCharP, xmlCharP, xmlParserCtxt --> xmlParserInput) ) is native($BIND-XML2) is symbol('xml6_gbl_set_external_entity_loader') {*}
    our sub set-networked(int32 $ --> int32) is native($BIND-XML2) is symbol('xml6_gbl_set_external_entity_loader_net') {*}
}

method ExternalEntityLoader is rw {
    sub FETCH($) {
        nativecast( :(xmlCharP, xmlCharP, xmlParserCtxt --> xmlParserInput), xmlEntityLoader::Get())
    }
    sub STORE($, &loader) {
        xmlExternalEntityLoader::Set(&loader)
    }
    Proxy.new: :&FETCH, :&STORE;
}

INIT {
    xmlInitParser();
    xml6_gbl::init();
}

=begin pod

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
