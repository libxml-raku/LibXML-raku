unit class LibXML::Config;

use LibXML::Native;
use LibXML::InputCallback;

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

method external-entity-loader is rw {
    LibXML::Native.ExternalEntityLoader;
}

method input-callbacks is rw {
    Proxy.new(
        FETCH => sub ($) { $inputCallbacks },
        STORE => sub ($, LibXML::InputCallback $callbacks) {
            $inputCallbacks = $callbacks;
        }
    );
}

