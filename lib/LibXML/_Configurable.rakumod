unit role LibXML::_Configurable;

use LibXML::Config;

has LibXML::Config $.config handles<load-catalog>;
multi method config(::?CLASS:U:) { LibXML::Config }
multi method config(::?CLASS:D:) { $!config }
