unit class LibXML::Config;

use LibXML::Native;
use LibXML::InputCallback;

method version {
    state $version //= Version.new(xmlParserVersion.match(/^ (.) (..) (..) /).join: '.');
}

method have-threads { ? xml6_gbl_have_threads(); }
method have-compression { ? xml6_gbl_have_compression(); }

method have-reader {
    require LibXML::Reader;
    LibXML::Reader.have-reader
}

method have-schemas {
    given $.version {
        $_ >= v2.05.10 && $_ != v2.09.04
    }
}

our $skipXMLDeclaration;
our $skipDTD;
our $inputCallbacks;

sub flag-proxy($flag is rw) is rw {
    Proxy.new( FETCH => sub ($) { $flag.so },
               STORE => sub ($, $_) { $flag = .so } ); 
}

method skip-xml-declaration is rw { flag-proxy($skipXMLDeclaration) }
method skip-dtd is rw { flag-proxy($skipDTD) }

method keep-blanks-default is rw {
    LibXML::Native.KeepBlanksDefault;
}

method tag-expansion is rw {
    LibXML::Native.TagExpansion;
}

state &externalEntityLoader;
method external-entity-loader is rw {
    Proxy.new(
        FETCH => {
            &externalEntityLoader // xmlGetExternalEntityLoader()
        },
        STORE => -> $, &cb {
            &externalEntityLoader = &cb;
            my constant XML_CHAR_ENCODING_NONE = 0;
            my constant XML_ERR_ENTITY_PROCESSING = 104;
            xmlSetExternalEntityLoader(
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
                    xmlNewIOInputStream($ctxt, $buf, XML_CHAR_ENCODING_NONE);
                });
        }
    );
}

method input-callbacks is rw {
    Proxy.new(
        FETCH => sub ($) { $inputCallbacks },
        STORE => sub ($, LibXML::InputCallback $callbacks) {
            $inputCallbacks = $callbacks;
        }
    );
}

=begin pod
=head1 NAME

LibXML::Config - LibXML Global configuration

=head1 SYNOPSIS



  use LibXML::Config;

=head1 METHODS

=begin item1
version

Returns the version of the `libxml2` library.
=end item1

=begin item1
have-reader

Returns True if the `libxml2` library supports XML Reader (LibXML::Reader) functionality.
=end item1

=begin item1
have-schemas

Returns True if the `libxml2` library supports XML Schema (LibXML::Schema) functionality.
=end item1

=begin item1
external-entity-loader

Provide a custom external entity handler to be used when parser expand-entities is set
to True. Possible value is a subroutine reference. 

This feature does not work properly in libxml2 < 2.6.27!

The routine provided is called whenever the parser needs to retrieve the
content of an external entity. It is called with two arguments: the system ID
(URI) and the public ID. The value returned by the subroutine is parsed as the
content of the entity. 

This method can be used to completely disable entity loading, e.g. to prevent
exploits of the type described at  (L<<<<<< http://searchsecuritychannel.techtarget.com/generic/0,295582,sid97_gci1304703,00.html >>>>>>), where a service is tricked to expose its private data by letting it parse a
remote file (RSS feed) that contains an entity reference to a local file (e.g. C<<<<<< /etc/fstab >>>>>>). 

A more granular solution to this problem, however, is provided by custom URL
resolvers, as in 

  my LibXML::InputCallback $c .= new;
  sub match ($uri) {   # accept file:/ URIs except for XML catalogs in /etc/xml/
    my ($uri) = @_;
    ? ($uri ~~ m|^'file:/'}
       and $uri !~~ m|^'file:///etc/xml/'|)
  }
  sub mu(|c) { }
  $c.register-callbacks(\&match, &mu, &mu, &mu);
  $parser.input-callbacks($c);


=end item1


=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
