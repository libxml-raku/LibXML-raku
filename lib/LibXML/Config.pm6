unit class LibXML::Config;

use LibXML::Native;
use LibXML::InputCallback;

our $skipXMLDeclaration;
our $skipDTD;
our $inputCallbacks;

method skip-xml-declaration is rw { $skipXMLDeclaration }
method skip-dtd is rw { $skipDTD }

method keep-blanks-default is rw {
    LibXML::Native.KeepBlanksDefault;
}

method tag-expansion is rw {
    LibXML::Native.TagExpansion;
}

method input-callbacks is rw {
    Proxy.new(
        FETCH => sub ($) { $inputCallbacks },
        STORE => sub ($, LibXML::InputCallback $callbacks) {
            $inputCallbacks = $callbacks;
        }
    );
}

