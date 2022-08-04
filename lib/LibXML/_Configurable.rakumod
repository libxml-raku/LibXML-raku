unit role LibXML::_Configurable; #[Bool:D :$required = True];

use LibXML::Config;

has LibXML::Config:D $!config is built handles<load-catalog> = LibXML::Config.global;

#::?ROLE.^get_attribute_for_usage('$!config').set_required(+$required);

proto method config(|) {*}
multi method config(::?CLASS:U:) { LibXML::Config }
multi method config(::?CLASS:D:) { $!config }

proto method create(|) {*}
multi method create(::?CLASS:U: \kind, |c) {
    kind.new: :config(LibXML::Config.new), |c
}
multi method create(::?CLASS:D: \kind, |c) {
    kind.new: :$.config, |c
}

multi method box(LibXML::_Configurable \kind, |c) {
    kind.box: :$.config, |c
}
