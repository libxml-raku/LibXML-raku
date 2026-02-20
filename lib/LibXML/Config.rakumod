use v6.d;
use OO::Monitors;
#| LibXML Global configuration
unit monitor LibXML::Config;

=begin pod

=head2 Synopsis

  =begin code :lang<raku>
  use LibXML::Config;
  if  LibXML::Config.have-compression { ... }

  # change global default for maximum errors
  LibXML::Config.max-errors = 42;

  # create a parser with its own configuration
  my LibXML::Config:D $config .= new: :max-errors(100);
  my LibXML::Parser:D $parser .= new: :$config;
  my LibXML::Document:D $doc = $parser.parse: :html, :file<messy.html>;
  =end code

=head2 Description

This class holds configuration settings. Some of which are read-only. Others are
writeable, as listed below.

In the simple case, the global configuration can be updated to suit the application.

Objects of type L<LibXML::Config> may be created to enable configuration to localised and more explicit.

Note however that the `input-callbacks` and `external-entity-loader` are global in the `libxml`
library and need to be configured globally:

=begin code :lang<raku>
LibXML::Config.input-callbacks = @input-callbacks;
LibXML::Config.external-entity-loader = &external-entity-loader;
=end code

...or `parser-locking` needs to be set, which allows multiple local configurations,
but disables multi-threaded parsing:

=begin code :lang<raku>
LibXML::Config.parser-locking = True;
my LibXML::Config $config .= new: :@input-callbacks, :&external-entity-loader;
=end code


Configuration instance objects may be passed to objects that perform the `LibXML::_Configurable` role,
including L<LibXML>, L<LibXML::Parser>, L<LibXML::_Reader>.

    =for code :lang<raku>
    my $doc = LibXML.parse: :file<doc.xml>, :$config;

DOM objects, generally aren't configurable, although some particular methods do support a `:$config` option.

- L<LibXML::Document> methods: `processXIncludes`, `validate`, `Str`, `Blob`, and `parse`.
- L<LibXML::Element> method: `appendWellBalancedChunk`.
- L<LibXML::Node> methods: `ast` and `xpath-class`.

=end pod

use LibXML::Enums;
use LibXML::Raw;
use LibXML::Types :resolve-package;
use LibXML::X;
use NativeCall;

# XXX Temporary solution for testing where no specific config object is required
my LibXML::Config:D $singleton .= new;
method global { $singleton }

proto method clone(|) {*}
multi method clone(::?CLASS:U: |c) { $singleton.clone(|c) }
multi method clone(::?CLASS:D: |c) { nextsame }

=head2 Configuration Methods

=head3 parser-locking
=para This configuration setting will lock the parsing of documents to disable
concurrent parsing. It needs to be set to allow per-parser input-callbacks,
which are not currently thread safe.

my Bool:D() $parser-locking = $*DISTRO.is-win || ! $singleton.have-threads;
method parser-locking is rw { $parser-locking }

=para Note: `parser-locking` defaults to `True` on Windows, as some platforms have thread-safety issues.

method Lock handles<protect> {
    # global lock
    BEGIN Lock.new;
}

sub protected(&action) is hidden-from-backtrace is export(:protected) {
    $parser-locking
        ?? $singleton.protect(&action)
        !! &action();
}

my Attribute %atts = ::?CLASS.^attributes.map: {.name => $_ };

method attr-rw($att-name) is rw {
    my Attribute:D $att := %atts{$att-name};
    sub FETCH($) {
        protected { $att.get_value: self; }
    }
    sub STORE($, $val) {
        protected { $att.set_value: self, $val; }
    }
    Proxy.new: :&FETCH, :&STORE;
}

#| Returns the run-time version of the `libxml2` library.
my $version;
method version(--> Version:D) {
    return $_ with ⚛$version;
    cas $version, { $_ // try { Version.new(xmlParserVersion.match(/^ (.) (..) (..) /).join: '.'); } // do { self.config-version } };
}

#| Returns the version of the `libxml2` library that the LibXML module was built against
my $config-version;
method config-version(--> Version:D) {
    protected {
        $config-version //= Version.new: xml6_config::version()
    }
}

#| General feature check.
method have-feature(Int:D $feature --> Bool) {
    ? xmlHasFeature($feature);
}
=para See xmlFeature in L<LibXML::Enums>.

#| Returns True if the `libxml2` library supports XML Reader (LibXML::Reader) functionality.
method have-reader(--> Bool:D) {
    $.have-feature: XML_WITH_READER;
}

#| Returns True if the `libxml2` library supports XML Writer (LibXML::Writer) functionality.
method have-writer(--> Bool:D) {
    $.have-feature: XML_WITH_WRITER;
}
=para Note: LibXML::Writer is available as a separate module.

#| Returns True if the `libxml2` library supports XML Schema (LibXML::Schema) functionality.
method have-schemas(--> Bool:D) {
    $.have-feature: XML_WITH_SCHEMAS;
}

#| Returns True if the `libxml2` library supports threads
method have-threads(--> Bool:D) { $.have-feature: XML_WITH_THREAD }

#| Returns True if the `libxml2` library supports compression
method have-compression(--> Bool:D) { $.have-feature: XML_WITH_ZLIB  }

#| Returns True if the `libxml2` library supports iconv (unicode encoding)
my $have-iconv;
method have-iconv(--> Bool:D) { $.have-feature: XML_WITH_ICONV }

my $catalogs = SetHash.new;
method load-catalog(Str:D $filename --> Nil) {
    protected {
        my Int $stat = 0;
        unless $filename ∈ $catalogs {
            $stat = xmlLoadCatalog($filename);
            fail "unable to load XML catalog: $filename"
            if $stat < 0;
            $catalogs.set: $filename;
        }
    }
}

=head2 Serialization Default Options

# -- Output options --

=head3 method skip-xml-declaration
=for code :lang<raku>
method skip-xml-declaration() is rw returns Bool
=para Whether to omit '<?xml ...>' preamble (default False)

has Bool:D() $!skip-xml-declaration is built = False;

proto method skip-xml-declaration() {*}
multi method skip-xml-declaration(::?CLASS:U: --> Bool:D) is rw { $singleton.skip-xml-declaration }
multi method skip-xml-declaration(::?CLASS:D: --> Bool:D) is rw { $.attr-rw: '$!skip-xml-declaration' }

=head3 method skip-dtd
=for code :lang<raku>
method skip-dtd() is rw returns Bool
=para Whether to omit internal DTDs (default False)

has Bool:D() $!skip-dtd is built = False;

proto method skip-dtd() {*}
multi method skip-dtd(::?CLASS:U: --> Bool) is rw { $singleton.skip-dtd }
multi method skip-dtd(::?CLASS:D: --> Bool) is rw { $.attr-rw: '$!skip-dtd' }

#| Whether to output empty tags as '<a></a>' rather than '<a/>' (default False)
has Bool:D() $!tag-expansion is built = False;

proto method tag-expansion() {*}
multi method tag-expansion(::?CLASS:U: --> Bool) is rw { $singleton.tag-expansion }
multi method tag-expansion(::?CLASS:D: --> Bool) is rw { $.attr-rw: '$!tag-expansion' }

=head3 method max-errors
=for code :lang<raku>
method max-errors() is rw returns Int:D
=para Maximum errors before throwing a fatal X::LibXML::TooManyErrors

has UInt:D $!max-errors is built = 100;

proto method max-errors() {*}
multi method max-errors(::?CLASS:U: --> UInt:D) is rw { $singleton.max-errors }
multi method max-errors(::?CLASS:D: --> UInt:D) is rw { $.attr-rw: '$!max-errors' }

=head2 Parsing Default Options

has xmlDocumentType:D $!document-kind = XML_DOCUMENT_NODE;

proto method document-kind() {*}
multi method document-kind(::?CLASS:U: --> xmlDocumentType:D) { $singleton.document-kind }
multi method document-kind(::?CLASS:D: --> xmlDocumentType:D) { $.attr-rw: '$!document-kind' }

method keep-blanks-default is rw is DEPRECATED<keep-blanks> { $.keep-blanks }
method default-parser-flags is DEPRECATED<parser-flags> { $.parser-flags }

has &!external-entity-loader;

proto method external-entity-loader() {*}
multi method external-entity-loader(::?CLASS:U:) is rw { $singleton.external-entity-loader }
multi method external-entity-loader(::?CLASS:D:) is rw {
    Proxy.new(
        FETCH => { protected { &!external-entity-loader } },
        STORE => -> $, &loader {
            protected {
                if self === $singleton {
                    set-external-entity-loader(&loader);
                }
                &!external-entity-loader = &loader;
            }
        });
}

proto method setup(|) {*}
multi method setup(::?CLASS:U: --> List:D) { protected { $singleton.setup } }
multi method setup(::?CLASS:D: --> List:D) {
    protected {
        if self.defined && &!external-entity-loader.defined && !self.parser-locking {
            warn q:to<END>.chomp;
            Unsafe use of local 'external-entity-loader' configuration.
            Please configure globally, or set 'parser-locking' to disable threaded parsing
            END
        }
        my @prev[4] = (
            $*THREAD.id,
            xml6_gbl::get-tag-expansion(),
            xml6_gbl::get-keep-blanks(),
            xml6_gbl::get-external-entity-loader,
        );
        xml6_gbl::set-tag-expansion(self.tag-expansion);
        xml6_gbl::set-keep-blanks(self.keep-blanks);
        #    xml6_gbl::set-external-entity-loader(&!external-entity-loader) with self && &!external-entity-loader;
        if self !=== $singleton && &!external-entity-loader {
            note "SETTING EXTERNAL ENT LOADER";
            set-external-entity-loader(&!external-entity-loader);
        }
        @prev;
    }
}

multi method restore([]) { }
multi method restore(@prev where .elems == 4) {
    protected {
        if $*THREAD.id == @prev[0] {
            xml6_gbl::set-tag-expansion(@prev[1]);
            xml6_gbl::set-keep-blanks(@prev[2]);
            xml6_gbl::set-external-entity-loader(@prev[3]) with self;
        }
        else {
            warn "OS thread change\n" ~ Backtrace.new.full.Str.indent(4);
        }
    }
}

has Bool:D() $!keep-blanks is built = True;

proto method keep-blanks() {*}
multi method keep-blanks(::?CLASS:U: --> Bool) is rw { $singleton.keep-blanks }
multi method keep-blanks(::?CLASS:D: --> Bool) is rw { $.attr-rw: '$!keep-blanks' }

#| Low-level default parser flags (Read-only)
method parser-flags(--> UInt:D) {
    XML_PARSE_NONET
    + XML_PARSE_NODICT
    + ($.keep-blanks ?? 0 !! XML_PARSE_NOBLANKS)
}

#| External entity handler to be used when parser expand-entities is set.
sub set-external-entity-loader(&loader) {
    protected {
        my constant XML_CHAR_ENCODING_NONE = 0;
        if &loader.defined {
            xmlExternalEntityLoader::Set(
                sub (Str $url, Str $id, xmlParserCtxt $ctxt --> xmlParserInput) {
                    CATCH {
                        default {
                            if $ctxt.defined {
                                $ctxt.ParserError(.message);
                            }
                            else {
                                note "uncaught entity loader error: " ~ .message;
                            }
                            return xmlParserInput;
                        }
                    }
                    my Str $string := &loader($url, $id);
                    my xmlParserInputBuffer $buf .= new: :$string;
                    $ctxt.NewInputStream($buf, XML_CHAR_ENCODING_NONE);
                }
            );
        }
    }
}

=para The routine provided is called whenever the parser needs to retrieve the
    content of an external entity. It is called with two arguments: the system ID
    (URI) and the public ID. The value returned by the subroutine is parsed as the
    content of the entity. 

=para This method can be used to completely disable entity loading, e.g. to prevent
    exploits of the type described at  (L<http://searchsecuritychannel.techtarget.com/generic/0,295582,sid97_gci1304703,00.html>), where a service is tricked to expose its private data by letting it parse a
   remote file (RSS feed) that contains an entity reference to a local file (e.g. C</etc/fstab>).

=para This method acts globally across all parser instances and threads.

=para A more granular and localised solution to this problem, however, is provided by
custom URL resolvers, as in
        =begin code :lang<raku>
        my LibXML::InputCallback $cb .= new;
        sub match($uri) {   # accept file:/ URIs except for XML catalogs in /etc/xml/
          my ($uri) = @_;
          ? ($uri ~~ m|^'file:/'}
             and $uri !~~ m|^'file:///etc/xml/'|)
        }
        sub deny(|c) { }
        $cb.register-callbacks(&match, &deny, &deny, &deny);
        $parser.input-callbacks($cb)
        =end code

=head3 method input-callbacks
=for code :lang<raku>
method input-callbacks is rw returns LibXML::InputCallback
=para Default input callback handlers.

=para The LibXML::Config:U `input-callbacks` method sets and enables a set of input callbacks for the entire
process.

=para The  LibXML::Config:U `input-callbacks` sets up a localised set of input callbacks.
Concurrent use of multiple input callbacks is NOT thread-safe and `parser-locking`
also needs to be set to disable concurrent parsing (see below).

has $!input-callbacks is built;

proto method input-callbacks(|) {*}
multi method input-callbacks(::?CLASS:U:) is rw { $singleton.input-callbacks }
multi method input-callbacks(::?CLASS:D:) is rw {
    Proxy.new(
        FETCH => sub ($) { protected { $!input-callbacks } },
        STORE => sub ($, $callbacks) {
            protected {
                if self === $singleton {
                    .deactivate with $!input-callbacks;
                    .activate with $callbacks;
                }
                $!input-callbacks = $callbacks
            }
        });
}
=para See L<LibXML::InputCallback>

=head2 Query Handler

my subset QueryHandler where .can('query-to-xpath').so;

my QueryHandler $query-handler = class NoQueryHandler {
    method query-to-xpath($) {
        fail "query-handler has not been configured";
    }
}

=head3 method query-handler
=for code :lang<raku>
method query-handler() is rw returns LibXML::Config::QueryHandler
=para Default query handler to service querySelector() and querySelectorAll() methods

has $!query-handler is built = $query-handler;

proto method query-handler() {*}
multi method query-handler(::?CLASS:U: --> QueryHandler) is rw { $singleton.query-handler }
multi method query-handler(::?CLASS:D: --> QueryHandler) is rw { $.attr-rw: '$!query-handler' }
=para See L<LibXML::XPath::Context>

my constant @DefaultClassMap =
    'LibXML::Attr'             => XML_ATTRIBUTE_NODE,
    'LibXML::CDATA'            => XML_CDATA_SECTION_NODE,
    'LibXML::Comment'          => XML_COMMENT_NODE,
    'LibXML::Dtd'              => XML_DTD_NODE,
    'LibXML::Dtd::AttrDecl'    => XML_ATTRIBUTE_DECL,
    'LibXML::Dtd::ElementDecl' => XML_ELEMENT_DECL,
    'LibXML::Dtd::Entity'      => XML_ENTITY_DECL,
    'LibXML::DocumentFragment' => XML_DOCUMENT_FRAG_NODE,
    'LibXML::Document'         => XML_HTML_DOCUMENT_NODE,
    'LibXML::Document'         => XML_DOCB_DOCUMENT_NODE,
    'LibXML::Document'         => XML_DOCUMENT_NODE,
    'LibXML::Element'          => XML_ELEMENT_NODE,
    'LibXML::EntityRef'        => XML_ENTITY_REF_NODE,
    'LibXML::Namespace'        => XML_NAMESPACE_DECL,
    'LibXML::PI'               => XML_PI_NODE,
    'LibXML::Text'             => XML_TEXT_NODE;

my constant %DefaultClassMap = @DefaultClassMap;
my constant @ClassMap = do {
    my Str @map;
    for @DefaultClassMap -> (:key($class-name), :value($code)) {
        @map[$code] = $class-name;
    }
    @map;
}
my constant %RawClassType =
    @LibXML::Raw::ClassMap.pairs.map({ @LibXML::Raw::ClassMap[.key]:exists ?? (.value.^name => .key) !! Empty });

has @!class-map is default(Nil);

proto method class-map() {*}
multi method class-map(::?CLASS:U:) { $singleton.class-map }
multi method class-map(::?CLASS:D:) {
    protected {
        unless @!class-map {
            @!class-map = @ClassMap.map({ .defined ?? resolve-package($_) !! Nil })
        }
        @!class-map
    }
}

method !validate-map-class-name(Str:D $class, Str:D $why, Bool:D :$strict = True) {
    %DefaultClassMap{$class}:exists
        || ($strict ?? X::LibXML::ClassName.new(:$class, :$why).throw !! False)
}

method !validate-map-class(Any:U \type, Str:D $why, Bool:D :$strict = True) {
    %DefaultClassMap{type.^name}:exists
        || ($strict ?? X::LibXML::Class.new(:class(type.^name), :$why).throw !! False)
}

proto method map-class(|) {*}
multi method map-class(::?CLASS:U: |c) { protected { $singleton.map-class(|c) } }
multi method map-class(::?CLASS:D: Int:D $id, Mu:U \user-type) {
    protected { @.class-map[$id] := user-type; }
}
multi method map-class(::?CLASS:D: Str:D $class, Mu:U \user-type) {
    self!validate-map-class-name($class, q<unknown to configuration 'map-call' method>);
    samewith(%DefaultClassMap{$class}, user-type);
}
multi method map-class(::?CLASS:D: LibXML::Types::Itemish:U \from-type, Mu:U \user-type) {
    self!validate-map-class(from-type, q<unsupported by configuration 'map-call' method>);
    samewith(from-type.^name, user-type)
}
# Maps LibXML::* class names into user classes
multi method map-class(::?CLASS:D: *@pos, *%mappings) {
    for %mappings.kv -> Str:D $class, \user-type {
        samewith(%DefaultClassMap{$class}, user-type);
    }

    for @pos -> $mapping {
        unless $mapping ~~ Pair {
            X::LibXML::ArgumentType.new(:got($mapping.WHAT),
                :expected(Pair),
                :routine(q<configuration method 'map-class'>)).throw;
        }
        samewith($mapping.key, $mapping.value);
    }
}

proto method class-from($) {*}
multi method class-from(::?CLASS:U: |c) is raw { $singleton.class-from(|c) }
multi method class-from(::?CLASS:D: LibXML::Types::Itemish:U \from-type, Bool:D :$strict = True) is raw {
    return from-type
        unless self!validate-map-class(
            from-type,
            q<unsupported by configuration 'class-from' method>,
            :$strict);
    samewith(%DefaultClassMap{from-type.^name});
}
multi method class-from(::?CLASS:D: Str:D $class, Bool:D :$strict = True) is raw {
    return resolve-package($class)
        unless self!validate-map-class-name(
            $class,
            q<unknown to configuration 'class-from' method>,
            :$strict);
    samewith(%DefaultClassMap{$class});
}
multi method class-from(::?CLASS:D: Int:D $id) is raw { @.class-map[$id] }
multi method class-from(::?CLASS:D: anyNode:D $raw) is raw { @.class-map[$raw.type] }
multi method class-from(::?CLASS:D: Any:U \raw-type, Bool:D :$strict = True) {
    my $raw-name = raw-type.^name;
    %RawClassType{$raw-name}:exists
        ?? @.class-map[ %RawClassType{$raw-name} ]
        !! ($strict
            ?? X::LibXML::Class.new(:class($raw-name), :why(q<unknown to configuration method 'class-from'>)).throw
            !! Nil)
}

#| Enable object re-use per XML node.
has Bool:D $.with-cache is built = False;

has %!node-cache;
has Lock:D $!cache-lock .= new;

proto method box(|) {*}
multi method box(::?CLASS:D: anyNode:D $raw, &vivify? is copy, *%profile) {
    &vivify //= sub { self.class-from($raw).bless: :raw($raw.delegate), |%profile }
    return &vivify() unless $!with-cache;
    $!cache-lock.protect: {
        %!node-cache{$raw.unique-key} //= &vivify();
    }
}
multi method box(::?CLASS:D: Any:U \raw-type, &vivify) {
    my $raw-name = raw-type.^name;
    %RawClassType{$raw-name}:exists
        ?? self.class-from(%RawClassType{$raw-name})
        !! (&vivify
            ?? vivify()
            !! X::LibXML::Class.new(:class($raw-name), :why(q<unknown to configuration method 'box'>)).throw)
}
multi method box(::?CLASS:U: |c) {
    $singleton.box: |c
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
