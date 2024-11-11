unit class Stacker;
use Collector;
also is Collector;

use Test;

has @.stack is rw;
has &.gen-cb;

method _calc_op_callback {
    -> $item { @!stack.push: $item }
}

method test(@value, $blurb) {
    my $rv := is-deeply @!stack, @value, $blurb;
    @!stack = [];
    $rv;
}
