#| LibXML DTD Handling
unit class LibXML::Dtd;

use LibXML::_Configurable;
use LibXML::_Validator;
use LibXML::_Rawish;
use LibXML::ErrorHandling :&structured-error-cb;
use LibXML::_Options;
use LibXML::Raw;
use LibXML::Raw::HashTable;
use LibXML::Parser::Context;
use LibXML::Attr;
use LibXML::Element;
use LibXML::EntityRef;
use LibXML::Node;
use LibXML::Dtd::AttrDecl;
use LibXML::Dtd::ElementDecl;
use LibXML::Dtd::Entity;
use LibXML::Dtd::Notation;
use LibXML::HashMap;
use LibXML::Config :&protected;
use LibXML::Enums;
use Method::Also;
use NativeCall;
use W3C::DOM;

also is LibXML::Node;
also does W3C::DOM::DocumentType;
also does LibXML::_Validator;
also does LibXML::_Rawish[xmlDtd, <systemId publicId>];

  =begin pod
  =head2 Synopsis

      =begin code :lang<raku>
      use LibXML::Dtd;
      use LibXML::Dtd::Entity;
      use LibXML::Dtd::Notation;
      use LibXML::Dtd::ElementDecl;
      use LibXML::Dtd::AttrDecl;

      my LibXML::Dtd $dtd .= new($public-id, $system-id);
      my LibXML::Dtd $dtd .= parse: :string($dtd-str);

      # Information retrieval
      my Str $dtdName = $dtd.getName();
      my Str $publicId = $dtd.publicId();
      my Str $systemId = $dtd.systemId();
      my Bool $is-html = $dtd.is-XHTML;

      my LibXML::Dtd::Entity = $dtd.getEntity("bar");
      my LibXML::Dtd::Notation $foo = $dtd.getNotation("foo");
      my LibXML::Dtd::ElementDecl $elem-decl = $dtd.getElementDeclaration($elem-name);
      my LibXML::Dtd::AttrDecl $attr-decl = $dtd.getAttrDeclaration($elem-name, $attr-name);
      # get declaration associated with an element, attribute or entity reference
      my LibXML::Node $node-decl = $dtd.getNodeDeclaration($node);

      # Associative Interfaces
      my LibXML::Dtd::DeclMap $entities = $dtd.entities;
      $foo = $entities<foo>;
      my LibXML::Dtd::NotationDeclMap $notations = $dtd.notations;
      $bar = $notations<bar>;
      my LibXML::Dtd::DeclMap $elem-decls = $dtd.element-declarations;
      $elem-decl = $elem-decls{$elem-name}
      my LibXML::Dtd::AttrDeclMap $elem-attr-decls = $dtd.attribute-declarations;
      $attr-decl = $elem-attr-decls{$elem-name}{$attr-name};
      # -- or --
      $attr-decl = $elem-decls{$elem-name}{'@' ~ $attr-name};

      # Validation
      try { $dtd.validate($doc) };
      my Bool $valid = $dtd.is-valid($doc);
      $valid = $dtd.is-valid($node);
      if $doc ~~ $dtd { ... } # if doc is valid against the DTD
      =end code

  =head2 Description

  This class holds a DTD. You may parse a DTD from either a string, or from an
  external SYSTEM identifier.

  No support is available as yet for parsing from a file-handle.

  LibXML::Dtd is a sub-class of L<LibXML::Node>, so all the methods available to nodes (particularly Str()) are available
  to Dtd objects.

  A DTD may contain the following objects.

  =item L<LibXML::Dtd::Entity> - LibXML DTD entity declarations
  =item L<LibXML::Dtd::Notation> - LibXML DTD notations
  =item L<LibXML::Dtd::ElementDecl> - LibXML DTD element declarations (experimental)
  =item L<LibXML::Dtd::ElementContent> - LibXML DTD element content declarations (experimental)
  =item L<LibXML::Dtd::AttrDecl> - LibXML DTD attribute declarations (experimental)
  =end  pod

constant DocNode = W3C::DOM::Document;

class ValidContext {
    also does LibXML::_Configurable;

    has xmlValidCtxt $!raw .= new;
    # for the LibXML::ErrorHandling role
    has $.sax-handler is rw;
    has Bool ($.recover, $.suppress-errors, $.suppress-warnings) is rw;
    also does LibXML::_Options[%( :recover, :suppress-errors, :suppress-warnings)];
    also does LibXML::ErrorHandling;

    method !validate-raw(xmlDoc:D :$doc, xmlDtd :$dtd, xmlElem :$elem, Bool :$check) is hidden-from-backtrace {
        self.do: :$!raw, sub () is hidden-from-backtrace {
            my $rv := $!raw.validate(:$doc, :$dtd, :$elem);
            $rv := self.validity-check
                if $check;
            $rv.so;
        }
    }

    multi method validate(
        DocNode:D $doc-obj,
        LibXML::Dtd :dtd($dtd-obj),
        Bool() :$check
    ) is hidden-from-backtrace {
        my xmlDoc:D $doc = .raw given $doc-obj;
        my xmlDtd   $dtd = .raw with $dtd-obj;
        with $dtd {
            # redo internal validation
            $_ = Nil
               if .isSameNode($doc.getInternalSubset)
               or .isSameNode($doc.getExternalSubset);
        }
        self!validate-raw(:$doc, :$dtd, :$check);
    }

    multi method validate(
        LibXML::Element:D $_,
        LibXML::Attr $attr-obj?,
        DocNode :doc($doc-obj) = .ownerDocument,
        Bool() :$check
    ) is hidden-from-backtrace {
        my xmlElem:D $elem = .raw;
        my xmlDoc:D $doc = $doc-obj.raw;
        my xmlAttr $attr = .raw with $attr-obj;
        self!validate-raw(:$doc, :$elem, :$attr, :$check);
    }

    method is-valid(LibXML::Element:D $elem, |c) {
        self.validate($elem, :check, |c);
    }

}

=begin pod
    =head2 Methods
=end pod

multi method new( Str:D :$type!,
                  LibXML::Node :doc($owner),
                  Str:D :$name!,
                  Str :$external-id,
                  Str :$system-id,
                  *%c )
{
    my xmlDoc $doc = .raw with $owner;
    my xmlDtd:D $new-dtd .= new: :$doc, :$name, :$external-id, :$system-id, :$type;
    self.box: $new-dtd, |%c;
}

# for Perl compatiblity
multi method new($external-id, $system-id, *%c) is hidden-from-backtrace {
    self.parse(:$external-id, :$system-id, |%c);
}

=begin pod
    =head3 method new

        # preferred constructor
        multi method new(Str :$public-id, Str :$system-id) returns LibXML::Dtd
        # for Perl compat
        multi method new(Str $public-id, Str $system-id) returns LibXML::Dtd

    Parse a DTD from the system identifier, and return a DTD object that you can
    pass to $doc.is-valid() or $doc.validate().

        my $dtd = LibXML::Dtd.new(
                              "SOME // Public / ID / 1.0",
                              "test.dtd"
                                        );
        my $doc = LibXML.load: :file("test.xml");
        $doc.validate($dtd);

        $doc.is-valid($dtd);
        #-OR-
        $doc ~~ $dtd;

    =head3 method getName

        method getName() returns Str

    Returns the name of DTD; i.e., the name immediately following the DOCTYPE
    keyword.

    =head3 method publicId

        method publicId() returns Str

    Returns the public identifier of the external subset.


    =head3 method systemId

        method systemId() returns Str

    Returns the system identifier of the external subset.
=end pod

has LibXML::Parser::Context $!parser-ctx;
method !parser-ctx(Bool :$html) {
    my $raw = ($html ?? htmlParserCtxt !! xmlParserCtxt).new;
    my $local-errors = $.config.version >= v2.14.0;
    (self.defined ?? $!parser-ctx !! my $) //= self.create: LibXML::Parser::Context, :$raw, :$local-errors;
}

multi method parse(Str :$string!, xmlEncodingStr:D :$enc = 'UTF-8', Str :$external-id, Str :$system-id) is hidden-from-backtrace {
    my $ctx := self!parser-ctx;
    my xmlDtd:D $raw = $ctx.do: {
        if $ctx.local-errors {
            my xmlParserInput $input .= new: :$string;
            $ctx.raw.ParseDtd($input, $external-id, $system-id);
        }
        else {
            xmlDtd.parse: :$string, :$enc
        }
    };
    self.box($raw)
}
=begin pod
    =head3 method parse

        multi method parse(Str :$string) returns LibXML::Dtd;
        multi method parse(Str:D :$system-id!, Str :$external-id) returns LibXML::Dtd;

    =para The same as new() above, except you can parse a DTD from a string or external-id. Note that
    parsing from string may fail if the DTD contains external parametric-entity
    references with relative URLs.
=end pod

multi method parse(Str :$external-id, Str:D :$system-id!) is hidden-from-backtrace {
    my Bool() $html = xmlDtd::xmlIsXHTML($system-id, $external-id);
    my $ctx := self!parser-ctx: :$html;
    my xmlDtd $raw;
    $ctx.do: {
        if $ctx.local-errors {
           my xmlParserInput $input = $ctx.raw.LoadDtd($external-id, $system-id);
           $raw := $ctx.raw.ParseDtd($input, $external-id, $system-id);
        }
        else {
            $raw = xmlDtd.parse: :$external-id, :$system-id;
        }

        unless $raw.defined || $ctx.will-die {
           for $ctx.errors {
               .level = XML_ERR_ERROR
                   if .code ~~ XML_IO_ENOENT|XML_IO_LOAD_ERROR;
           }
       }
    }
    self.box: $raw
}
multi method parse(Str $external-id, Str $system-id) is default {
    self.parse: :$external-id, :$system-id;
}

method getPublicId { $.publicId }
method getSystemId { $.systemId }
method cloneNode(LibXML::Dtd:D: $?) is also<clone> {
    self.box: self.raw.copy;
}

#| Notation declaration lookup
method getNotation(Str $name --> LibXML::Dtd::Notation) {
    LibXML::Dtd::Notation.box: $.raw.getNotation($name)
}

#| Entity declaration lookup
method getEntity(Str $name --> LibXML::Dtd::Entity) {
    self.box: LibXML::Dtd::Entity, $.raw.getEntity($name)
}

#| Element declaration lookup
method getElementDeclaration(Str $name --> LibXML::Dtd::ElementDecl) {
    self.box: LibXML::Dtd::ElementDecl, $.raw.getElementDecl($name)
}

#| Attribute declaration lookup
method getAttrDeclaration(Str $elem-name, Str $attr-name --> LibXML::Dtd::AttrDecl) {
    self.box: LibXML::Dtd::AttrDecl, $.raw.getAttrDecl($elem-name, $attr-name)
}

=head3 getNodeDeclaration
=begin code :lang<raku>
multi method getNodeDeclaration(LibXML::Element --> LibXML::Dtd::ElementDecl);
multi method getNodeDeclaration(LibXML::Attr --> LibXML::Dtd::AttrDecl);
multi method getNodeDeclaration(LibXML::EntityRef --> LibXML::Dtd::Entity);
=end code
=para Looks up a definition in the DtD for a DOM Element, Attribute or Entity-Reference node

multi method getNodeDeclaration(LibXML::EntityRef:D $_) {
    $.getEntity: .nodeName;
}

multi method getNodeDeclaration(LibXML::Element:D $_) {
    $.getElementDeclaration: .nodeName;
}

multi method getNodeDeclaration(LibXML::Attr:D $_) {
    $.getAttrDeclaration: .getOwnerElement.nodeName, .nodeName;
}

method !valid-ctx($schema: :$config!) { self.create: ValidContext, :$schema, |(:$config with $config) }

method validate(LibXML::Dtd:D $dtd: DocNode:D $doc = $.ownerDocument, Bool :$check , LibXML::Config :$config --> UInt) is hidden-from-backtrace {
    self!valid-ctx(:$config).validate($doc, :$dtd, :$check);
}
  =begin pod
  =head3 method validate

      method validate($doc = $.ownerDocument --> UInt)

  =para This function allows one to validate a (parsed) document against the given XML
  Schema. The argument of this function should be a L<LibXML::Document> object.  If this function succeeds, it will return 0, otherwise it will throw an exception
  reporting the errors found.
  =end pod

#| Returns True if the passed document is valid against the DTD
method is-valid(LibXML::Dtd:D $dtd: DocNode:D $doc, LibXML::Config :$config --> Bool) {
    self!valid-ctx(:$config).validate($doc, :$dtd, :check);
}

#| Returns True if the publicId or systemId match an XHTML identifier
method is-XHTML(--> Bool) {
    return [False, True][ $.raw.IsXHTML ] // Bool;
}
=para Returns False if the Id's don't match or Bool:U if the DtD lack either a publicId or systemId

# NYI DOM Level-2 methods
method internalSubset {
    die X::NYI.new
}

class DeclMap is LibXML::HashMap[LibXML::Item] {
    has LibXML::Dtd $.dtd is required;
    method DELETE-KEY($) { die X::NYI.new }
    method ASSIGN-KEY($, $) { die X::NYI.new }
    submethod TWEAK(xmlHashTable:D :raw($)!) {
        self.raw .= Copy: -> Pointer $p, $ --> Pointer {
            itemNode.cast($p).Reference;
            $p;
        }
    }
}

class NotationDeclMap is LibXML::HashMap[LibXML::Dtd::Notation] {
    has LibXML::Dtd $.dtd is required;
    method DELETE-KEY($) { die X::NYI.new }
    method ASSIGN-KEY($, $) { die X::NYI.new }
    submethod TWEAK(xmlHashTable:D :raw($)!) {
        self.raw .= Copy: -> Pointer $p, $ --> Pointer {
            nativecast Pointer, nativecast(xmlNotation, $p).Copy;
        }
    }
}

class AttrDeclMap does LibXML::_Configurable {
    my class HoHMap is LibXML::HashMap {
        method of {xmlHashTable}
        method freeze($) { die X::NYI.new }
        method thaw(Pointer:D $p) {
            nativecast($.of, $p);
        }
        method deallocator() {
            -> Pointer $p, $ {
                 nativecast($.of, $p).Discard;
            }
        }
    }
    has HoHMap $!map handles<keys>;
    has LibXML::Dtd:D $.dtd is required;
    has DeclMap %!cache;

    submethod TWEAK(xmlHashTable:D :$raw! is copy, LibXML::Config :$config) {
        $raw .= BuildDtdAttrDeclTable();
        $!map = self.create: HoHMap, :$raw;
    }
    method AT-KEY($k) {
        $!dtd.protect: {
            if %!cache{$k}:exists {
                 %!cache{$k}
            }
            else {
                %!cache{$k} = do {
                                with $!map.AT-KEY($k) -> $raw {
                                    self.create: DeclMap, :$raw, :$!dtd;
                                }
                                else {
                                    DeclMap.of;
                                }
                            }
            }
        }
    }
    method values { $.keys.map: { $.AT-KEY($_) } }
    method pairs  { $.keys.map: { $_ => $.AT-KEY($_) } }
    method DELETE-KEY($) { die X::NYI.new }
    method ASSIGN-KEY($, $) { die X::NYI.new }
}

has NotationDeclMap $!notations;
#| returns a hash-map of notation declarations
method notations($dtd: --> NotationDeclMap) {
    $!notations //= NotationDeclMap.new: :raw($_), :$dtd
        with $.raw.notations;
}

has DeclMap $!entities;
#| returns a hash-map of entity declarations
method entities(LibXML::Dtd:D $dtd: --> DeclMap) {
    $!entities //= self.create: DeclMap, :$dtd, :raw($_), :of(LibXML::Dtd::Entity)
        with $.raw.entities;
}

has DeclMap $!elements;
#| returns a hash-map of element declarations
method element-declarations(LibXML::Dtd:D $dtd: --> DeclMap) {
    $!elements //= self.create: DeclMap, :$dtd, :raw($_), :of(LibXML::Dtd::ElementDecl)
        with $.raw.elements;
}

method Hash handles<AT-KEY keys pairs values> {
    my % = .pairs with $.element-declarations;
}

has AttrDeclMap $!element-attributes;
#| returns a hash-map of attribute declarations
method attribute-declarations(LibXML::Dtd:D $dtd: --> AttrDeclMap) {
    $!element-attributes //= self.create: AttrDeclMap, :$dtd, :raw($_), :of(LibXML::Dtd::AttrDecl)
        with $.raw.attributes;
}
=para Actually returns a two dimensional hash of element declarations and element names

#| True if the node is validated by the DtD
multi method ACCEPTS(LibXML::Dtd:D: LibXML::Node:D $node --> Bool) {
    self.is-valid($node);
}

=begin pod
=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.


=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
