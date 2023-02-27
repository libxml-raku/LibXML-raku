use v6.d;
unit role LibXML::_Configurable;
use LibXML::Config;

has LibXML::Config:D $!config is built handles<load-catalog> = LibXML::Config.global;

proto method config(|) {*}
multi method config(::?CLASS:U:) { LibXML::Config.global }
multi method config(::?CLASS:D:) { $!config }

proto method create(|) {*}
multi method create(::?CLASS:U: \kind, |c) {
    kind.new: |c
}
multi method create(::?CLASS:D: \kind, |c) {
    kind.new: :$!config, |c
}
multi method create(::?ROLE:D :from(:$for)! is raw, |c) {
    self.WHAT.new: :config($for.config), |c
}

multi method box(::?CLASS:D: LibXML::_Configurable \kind, |c) {
    $!config.class-from(kind, :!strict).box: :$!config, |c
}
