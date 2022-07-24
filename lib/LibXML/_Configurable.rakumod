unit role LibXML::_Configurable;

use LibXML::Config;

has LibXML::Config:D $!config is built is required handles<load-catalog>;

proto method config(|) {*}
multi method config(::?CLASS:U:) { LibXML::Config }
multi method config(::?CLASS:D:) { $!config }
