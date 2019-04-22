use v6;
unit class Collector;
has &.callback;
has &.returned-callback;

method _calc_op_callback {...}

submethod TWEAK(:&gen-cb!) {
    &!callback = gen-cb(self._calc_op_callback());
    &!returned-callback = &!callback;
}

method cb {
    &!returned-callback
}
