use  v6;
use Collector;

unit class Stacker is Collector;
use Test;
has @.stack is rw;
has &.gen-cb;

method _calc_op_callback {
    sub ($item) { @!stack.push: $item }
}

method test(@value, $blurb) {
    my $rv := is-deeply @!stack, @value, $blurb;
    @!stack = [];
    $rv;
}
