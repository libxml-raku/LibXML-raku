#| LibXML Global configuration
unit class LibXML::Config;

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
use AttrX::Mooish;

# XXX Temporary solution for testing where no specific config object is required
my LibXML::Config $singleton;
method use-global() { $singleton //= ::?CLASS.new }
method global { $singleton }

=head2 Configuration Methods

#| Returns the run-time version of the `libxml2` library.
my $version;
method version returns Version {
    return $_ with ⚛$version;
    cas $version, { $_ // Version.new(xmlParserVersion.match(/^ (.) (..) (..) /).join: '.') };
}

#| Returns the version of the `libxml2` library that the LibXML module was built against
my $config-version;
method config-version {
    return $_ with ⚛$config-version;
    cas $config-version, { $_ // Version.new: xml6_config::version() }
}

#| Returns True if the `libxml2` library supports XML Reader (LibXML::Reader) functionality.
method have-reader returns Bool {
    resolve-package('LibXML::Reader').have-reader
}

#| Returns True if the `libxml2` library supports XML Schema (LibXML::Schema) functionality.
method have-schemas returns Bool {
    given $.version {
        $_ >= v2.05.10 && $_ != v2.09.04
    }
}

#| Returns True if the `libxml2` library supports threads
method have-threads returns Bool { ? xml6_config::have_threads(); }

#| Returns True if the `libxml2` library supports compression
method have-compression returns Bool { ? xml6_config::have_compression(); }

my $catalogs = SetHash.new;
my $lock = Lock.new;
method load-catalog(Str:D $filename --> Nil) {
    $lock.protect: {
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

my Bool:D $skip-xml-declaration = False;
has Bool:D $!skip-xml-declaration is mooish(:lazy);
method !build-skip-xml-declaration { $skip-xml-declaration }

proto method skip-xml-declaration() {*}
multi method skip-xml-declaration(::?CLASS:U: --> Bool) is rw { flag-proxy($skip-xml-declaration) }
multi method skip-xml-declaration(::?CLASS:D: --> Bool) is rw { flag-proxy($!skip-xml-declaration) }

=head3 method skip-dtd
=for code :lang<raku>
method skip-dtd() is rw returns Bool
=para Whether to omit internal DTDs (default False)

my Bool:D $skip-dtd = False;
has Bool:D $!skip-dtd is mooish(:lazy);
method !build-skip-dtd { $skip-dtd }

proto method skip-dtd() {*}
multi method skip-dtd(::?CLASS:U: --> Bool) is rw { flag-proxy($skip-dtd) }
multi method skip-dtd(::?CLASS:D: --> Bool) is rw { flag-proxy($!skip-dtd) }

#| Whether to output empty tags as '<a></a>' rather than '<a/>' (default False)
my Bool:D $tag-expansion = False;
has Bool:D $!tag-expansion is mooish(:lazy);
method !build-tag-expansion { $tag-expansion }

proto method tag-expansion() {*}
multi method tag-expansion(::?CLASS:U: --> Bool) is rw { flag-proxy($tag-expansion) }
multi method tag-expansion(::?CLASS:D: --> Bool) is rw { flag-proxy($!tag-expansion) }

=head3 method max-errors
=for code :lang<raku>
method max-errors() is rw returns Int:D
=para Maximum errors before throwing a fatal X::LibXML::TooManyErrors

my Int:D $max-errors = 100;
has UInt:D $!max-errors is mooish(:lazy);
method !build-max-errors { $max-errors }

proto method max-errors() {*}
multi method max-errors(::?CLASS:U: --> UInt:D) is rw { $max-errors }
multi method max-errors(::?CLASS:D: --> UInt:D) is rw { $!max-errors }

=head2 Parsing Default Options

has xmlElementType:D $.document-kind = XML_DOCUMENT_NODE;

my sub flag-proxy($flag is rw) is rw {
    Proxy.new( FETCH => sub ($) { $flag.so },
               STORE => sub ($, $_) { $flag = .so } );
}

method keep-blanks-default is rw is DEPRECATED<keep-blanks> { $.keep-blanks }
method default-parser-flags is DEPRECATED<parser-flags> { $.parser-flags }

method setup returns List {
    if self.defined && &!external-entity-loader.defined && !self.parser-locking {
        warn q:to<END>.chomp;
        Unsafe use of local 'external-entity-loader' configuration.
        Please configure globally, or set 'parser-locking' to disable threaded parsing
        END
    }
    my @prev[4] = (
        $*STACK-ID,
        xml6_gbl::get-tag-expansion(),
        xml6_gbl::get-keep-blanks(),
        xml6_gbl::get-external-entity-loader,
    );
    xml6_gbl::set-tag-expansion(self.tag-expansion);
    xml6_gbl::set-keep-blanks(self.keep-blanks);
    set-external-entity-loader(&!external-entity-loader) with self;
    @prev;
}

multi method restore([]) { }
multi method restore(@prev where .elems == 4) {
    if $*STACK-ID == @prev[0] {
        xml6_gbl::set-tag-expansion(@prev[1]);
        xml6_gbl::set-keep-blanks(@prev[2]);
        xml6_gbl::set-external-entity-loader(@prev[3]) with self;
    }
    else {
        warn "OS thread change";
    }
}

my Bool:D $keep-blanks = True;
has Bool:D $!keep-blanks is built is mooish(:lazy) = True;
method !build-keep-blanks { $keep-blanks }

proto method keep-blanks() {*}
multi method keep-blanks(::?CLASS:U: --> Bool) is rw { flag-proxy($keep-blanks) }
multi method keep-blanks(::?CLASS:D: --> Bool) is rw { flag-proxy($!keep-blanks) }

#| Low-level default parser flags (Read-only)
method parser-flags returns UInt {
    XML_PARSE_NONET
    + XML_PARSE_NODICT
    + ($.keep-blanks ?? 0 !! XML_PARSE_NOBLANKS)
}

my &external-entity-loader;
has &!external-entity-loader is mooish(:lazy);
method !build-external-entity-loader { &external-entity-loader }

proto method external-entity-loader() {*}
multi method external-entity-loader(::?CLASS:D: --> Callable) is rw { &!external-entity-loader }
multi method external-entity-loader(::?CLASS:U: --> Callable) is rw {
    Proxy.new(
        FETCH => { $lock.protect: { &external-entity-loader } },
        STORE => -> $, &loader {
            set-external-entity-loader(&loader);
            &external-entity-loader = &loader;
        }
    );
}

#| External entity handler to be used when parser expand-entities is set.
sub set-external-entity-loader(&loader) {
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

my $input-callbacks;
has $!input-callbacks is mooish(:lazy);
method !build-input-callbacks { $input-callbacks }

proto method input-callbacks(|) {*}
multi method input-callbacks(::?CLASS:U:) is rw {
    Proxy.new(
        FETCH => sub ($) { $lock.protect: { $input-callbacks } },
        STORE => sub ($, $callbacks) {
            $lock.protect: {
                .deactivate with $input-callbacks;
                .activate(:config( $singleton // ::?CLASS.new )) with $callbacks;
                $input-callbacks = $callbacks;
            }
        }
    );
}
multi method input-callbacks(::?CLASS:D:) is rw {
    Proxy.new(
        FETCH => sub ($) { $!input-callbacks },
        STORE => sub ($, $callbacks) { $!input-callbacks = $callbacks }
        );
}
=para See L<LibXML::InputCallback>

=head3 parser-locking
=para This configuration setting will lock the parsing of documents to disable
concurrent parsing. It needs to be set to allow per-parser input-callbacks,
which are not currently thread safe.

my Bool $parser-locking = ! $?CLASS.have-threads;
method parser-locking(::?CLASS:U:) is rw { $parser-locking }

=head2 Query Handler

my subset QueryHandler where .can('query-to-xpath').so;

my QueryHandler $query-handler = class NoQueryHandler {
    method query-to-xpath($) {
        fail "query-handler has not been configured";
    }
}

method lock handles<protect> {
    # global lock
    BEGIN Lock.new;
}

sub protected(&action) is hidden-from-backtrace is export(:protected) {
    $parser-locking
        ?? $?CLASS.protect(&action)
	!! &action();
}


=head3 method query-handler
=for code :lang<raku>
method query-handler() is rw returns LibXML::Config::QueryHandler
=para Default query handler to service querySelector() and querySelectorAll() methods

has $!query-handler is mooish(:lazy);
method !build-query-handler { $query-handler }

proto method query-handler() {*}
multi method query-handler(::?CLASS:U: --> QueryHandler) is rw {
    Proxy.new(
        FETCH => sub ($) { $query-handler },
        STORE => sub ($, QueryHandler $_) { $query-handler = $_; }
    );
}
multi method query-handler(::?CLASS:D: --> QueryHandler) is rw {
    Proxy.new(
        FETCH => sub ($) { $!query-handler },
        STORE => sub ($, QueryHandler $_) { $!query-handler = $_; }
        );
}
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

# COW clone of @ClassMap
has @.class-map is default(Nil) is mooish(:lazy);

method build-class-map {
    @ClassMap
        .map({ .defined ?? resolve-package($_) !! Nil })
}

method !validate-map-class-name(Str:D $class, Str:D $why, Bool:D :$strict = True) {
    %DefaultClassMap{$class}:exists
        || ($strict ?? LibXML::X::ClassName.new(:$class, :$why).throw !! False)
}

method !validate-map-class(Any:U \type, Str:D $why, Bool:D :$strict = True) {
    %DefaultClassMap{type.^name}:exists
        || ($strict ?? LibXML::X::Class.new(:class(type.^name), :$why).throw !! False)
}

proto method map-class(|) {*}
multi method map-class(Int:D $id, Mu:U \user-type) {
    self.protect: { @!class-map[$id] := user-type }
}
multi method map-class(Str:D $class, Mu:U \user-type) {
    self!validate-map-class-name($class, q<unknown to configuration 'map-call' method>);
    samewith(%DefaultClassMap{$class}, user-type);
}
multi method map-class(LibXML::Types::Itemish:U \from-type, Mu:U \user-type) {
    self!validate-map-class(from-type, q<unsupported by configuration 'map-call' method>);
    samewith(from-type.^name, user-type)
}
# Maps LibXML::* class names into user classes
multi method map-class(*@pos, *%mappings) {
    for %mappings.kv -> Str:D $class, \user-type {
        samewith(%DefaultClassMap{$class}, user-type);
    }

    for @pos -> $mapping {
        unless $mapping ~~ Pair {
            LibXML::X::ArgumentType.new(:got($mapping.WHAT),
                :expected(Pair),
                :routine(q<configuration method 'map-class'>)).throw;
        }
        samewith($mapping.key, $mapping.value);
    }
}

proto method class-from($) {*}
multi method class-from(LibXML::Types::Itemish:U \from-type, Bool:D :$strict = True) {
    return from-type
        unless self!validate-map-class(
            from-type,
            q<unsupported by configuration 'class-map' method>,
            :$strict);
    samewith(%DefaultClassMap{from-type.^name});
}
multi method class-from(Str:D $class, Bool:D :$strict = True) {
    return resolve-package($class)
        unless self!validate-map-class-name(
            $class,
            q<unknown to configuration 'class-map' method>,
            :$strict);
    samewith(%DefaultClassMap{$class});
}
multi method class-from(::?CLASS:D: Int:D $id) { @!class-map[$id] }
multi method class-from(::?CLASS:U: Int:D $id) { resolve-package(@ClassMap[$id]) }

=begin pod

=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
