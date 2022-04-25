#| LibXML Global configuration
unit class LibXML::Config;

=head2 Synopsis

  =begin code :lang<raku>
  use LibXML::Config;
  if  LibXML::Config.have-compression { ... }
  =end code

use LibXML::Enums;
use LibXML::Raw;
use LibXML::Types :resolve-package;
use NativeCall;
use AttrX::Mooish;

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
my $catalog-lock = Lock.new;
method load-catalog(Str:D $filename --> Nil) {
    $catalog-lock.protect: {
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

my $inputCallbacks;

# -- Output options --

my Bool:D $skipXMLDeclaration = False;
my Bool:D $skipDTD = False;
my Int:D $maxErrors = 100;

#| Whether to omit '<?xml ...>' preamble (default False)
has Bool:D $!skipXMLDeclaration is mooish(:lazy);
method !build-skipXMLDeclaration { $skipXMLDeclaration }

proto method skip-xml-declaration() {*}
multi method skip-xml-declaration(::?CLASS:U: --> Bool) is rw { flag-proxy($skipXMLDeclaration) }
multi method skip-xml-declaration(::?CLASS:D: --> Bool) is rw { flag-proxy($!skipXMLDeclaration) }

#| Whether to omit internal DTDs (default False)
has Bool:D $!skipDTD is mooish(:lazy);
method !build-skipDTD { $skipDTD }

proto method skip-dtd() {*}
multi method skip-dtd(::?CLASS:U: --> Bool) is rw { flag-proxy($skipDTD) }
multi method skip-dtd(::?CLASS:D: --> Bool) is rw { flag-proxy($!skipDTD) }

#| Whether to output empty tags as '<a></a>' rather than '<a/>' (default False)
method tag-expansion is rw returns Bool {
    LibXML::Raw.TagExpansion;
}

#| Maximum errors before throwing a fatal X::LibXML::TooManyErrors
has UInt:D $!maxErrors is mooish(:lazy);
method !build-maxErrors { $maxErrors }

proto method max-errors() {*}
multi method max-errors(::?CLASS:U: --> UInt:D) is rw { $maxErrors }
multi method max-errors(::?CLASS:D: --> UInt:D) is rw { $!maxErrors }

=head2 Parsing Default Options

sub flag-proxy($flag is rw) is rw {
    Proxy.new( FETCH => sub ($) { $flag.so },
               STORE => sub ($, $_) { $flag = .so } );
}

method keep-blanks-default is rw is DEPRECATED<keep-blanks> { $.keep-blanks }
method default-parser-flags is DEPRECATED<parser-flags> { $.parser-flags }

#| Keep blank nodes (Default True)
method keep-blanks returns Bool is rw {
   Proxy.new(
        FETCH => { ? xmlKeepBlanksDefaultValue() },
        STORE => sub ($, Bool() $_) {
            xmlKeepBlanksDefault($_);
        },
    );
}

#| Low-level default parser flags (Read-only)
method parser-flags returns UInt {
    XML_PARSE_NONET
    + XML_PARSE_NODICT
    + ($.keep-blanks() ?? 0 !! XML_PARSE_NOBLANKS)
}

state &externalEntityLoader;
#| External entity handler to be used when parser expand-entities is set.
method external-entity-loader returns Callable is rw {
    Proxy.new(
        FETCH => {
            &externalEntityLoader //= nativecast( :(Str, Str, xmlParserCtxt --> xmlParserInput), xmlExternalEntityLoader::Get())
        },
        STORE => -> $, &cb {
            &externalEntityLoader = &cb;
            my constant XML_CHAR_ENCODING_NONE = 0;
            my constant XML_ERR_ENTITY_PROCESSING = 104;
            xmlExternalEntityLoader::Set(
                sub (Str $url, Str $id, xmlParserCtxt $ctxt --> xmlParserInput) {
                    CATCH {
                        default {
                            if $ctxt.defined {
                                $ctxt.ParserError(.message);
                            }
                            else {
                                warn $_;
                            }
                            return xmlParserInput;
                        }
                    }
                    my Str $string := externalEntityLoader($url, $id);
                    my xmlParserInputBuffer $buf .= new: :$string;
                    $ctxt.NewInputStream($buf, XML_CHAR_ENCODING_NONE);
                });
        }
    );
}

=para The routine provided is called whenever the parser needs to retrieve the
    content of an external entity. It is called with two arguments: the system ID
    (URI) and the public ID. The value returned by the subroutine is parsed as the
    content of the entity. 

=para This method can be used to completely disable entity loading, e.g. to prevent
    exploits of the type described at  (L<http://searchsecuritychannel.techtarget.com/generic/0,295582,sid97_gci1304703,00.html>), where a service is tricked to expose its private data by letting it parse a
   remote file (RSS feed) that contains an entity reference to a local file (e.g. C</etc/fstab>). 

=para A more granular solution to this problem, however, is provided by custom URL
    resolvers, as in 
        =begin code :lang<raku>
        my LibXML::InputCallback $cb .= new;
        sub match($uri) {   # accept file:/ URIs except for XML catalogs in /etc/xml/
          my ($uri) = @_;
          ? ($uri ~~ m|^'file:/'}
             and $uri !~~ m|^'file:///etc/xml/'|)
        }
        sub deny(|c) { }
        $cb.register-callbacks(&match, &deny, &deny, &deny);
        $parser.input-callbacks($cb);
        =end code

#| Default input callback handlers
has $!inputCallbacks is mooish(:lazy);
method !build-inputCallbacks { $inputCallbacks }

proto method input-callbacks(|) {*}
multi method input-callbacks(::?CLASS:U:) is rw {
    Proxy.new(
        FETCH => sub ($) { $inputCallbacks },
        STORE => sub ($, $callbacks) { $inputCallbacks = $callbacks }
    );
}
multi method input-callbacks(::?CLASS:D:) is rw {
    Proxy.new(
        FETCH => sub ($) { $!inputCallbacks },
        STORE => sub ($, $callbacks) { $!inputCallbacks = $callbacks }
        );
}
=para See L<LibXML::InputCallback>

=head2 Query Handler

my subset QueryHandler where .can('query-to-xpath').so;

my QueryHandler $queryHandler = class NoQueryHandler {
    method query-to-xpath($) {
        fail "queryHandler has not been configured";
    }
}

method lock handles<protect> {
    # global lock
    BEGIN Lock.new;
}

#| Default query handler to service querySelector() and querySelectorAll() methods
has $!queryHandler is mooish(:lazy);
method !build-queryHandler { $queryHandler }

proto method query-handler() {*}
multi method query-handler(::?CLASS:U: --> QueryHandler) is rw {
    Proxy.new(
        FETCH => sub ($) { $queryHandler },
        STORE => sub ($, QueryHandler $_) { $queryHandler = $_; }
    );
}
multi method query-handler(::?CLASS:D: --> QueryHandler) is rw {
    Proxy.new(
        FETCH => sub ($) { $!queryHandler },
        STORE => sub ($, QueryHandler $_) { $!queryHandler = $_; }
        );
}
=para See L<LibXML::XPath::Context>

our @ClassMap = BEGIN do {
    my Str @map;
    for (
        'LibXML::Attr'             => XML_ATTRIBUTE_NODE,
        'LibXML::CDATA'            => XML_CDATA_SECTION_NODE,
        'LibXML::Comment'          => XML_COMMENT_NODE,
        'LibXML::Dtd'              => XML_DTD_NODE,
        'LibXML::Dtd::AttrDecl'    => XML_ATTRIBUTE_DECL,
        'LibXML::Dtd::ElementDecl' => XML_ELEMENT_DECL,
        'LibXML::Dtd::Entity'      => XML_ENTITY_DECL,
        'LibXML::DocumentFragment' => XML_DOCUMENT_FRAG_NODE,
        'LibXML::Document'         => XML_DOCUMENT_NODE,
        'LibXML::Document'         => XML_HTML_DOCUMENT_NODE,
        'LibXML::Document'         => XML_DOCB_DOCUMENT_NODE,
        'LibXML::Element'          => XML_ELEMENT_NODE,
        'LibXML::EntityRef'        => XML_ENTITY_REF_NODE,
        'LibXML::Namespace'        => XML_NAMESPACE_DECL,
        'LibXML::PI'               => XML_PI_NODE,
        'LibXML::Text'             => XML_TEXT_NODE,
    ) {
        @map[.value] = .key
    }
    @map;
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
