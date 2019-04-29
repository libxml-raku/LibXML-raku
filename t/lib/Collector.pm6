use v6;
unit class Collector;
has &.cb;

method _calc_op_callback {...}

submethod TWEAK(:&gen-cb!) {
    &!cb = &gen-cb(self._calc_op_callback());
}

