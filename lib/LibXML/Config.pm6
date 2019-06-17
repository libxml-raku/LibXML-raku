unit class LibXML::Config;

use LibXML::Native;
use LibXML::InputCallback;

our $skipXMLDeclaration;
our $skipDTD;
our $inputCallbacks;
our &externalEntityCallback;

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

method external-entity-loader is rw {
    Proxy.new(
        FETCH => {
            &externalEntityCallback // xmlGetExternalEntityLoader()
        },
        STORE => -> $, &cb {
            &externalEntityCallback = &cb;
            my constant XML_CHAR_ENCODING_NONE = 0;
            my constant XML_ERR_ENTITY_PROCESSING = 104;
            xmlSetExternalEntityLoader(
                sub (Str $url, Str $id,  xmlParserCtxt $ctxt --> xmlParserInput) {
                    CATCH {
                        default {
                            with $ctxt {
                                .FatalErr(XML_ERR_ENTITY_PROCESSING,
                                          xmlStrdup(.message)
                                         );
                            }
                            else {
                                warn $_;
                            }
                            return xmlParserInput;
                        }
                    }
                    my Str $string := externalEntityCallback($url, $id);
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

