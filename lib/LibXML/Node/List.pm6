class LibXML::Node::List does Iterable does Iterator {
    has Bool $.keep-blanks;
    has $.doc is required;
    has $.list is required handles <string-value>;
    has $cur;
    has $.type is required;
    has @!array;
    has Bool $!slurped;
    submethod TWEAK { $!cur = $!list }
    method Array handles<AT-POS elems List pairs keys values map grep shift pop> {
        unless $!slurped++ {
            $!cur = $!list;
            @!array = self;
        }
        @!array;
    }
    multi method to-literal( :list($)! where .so ) { self.map(*.string-value) }
    multi method to-literal( :delimiter($_) = '' ) { self.to-literal(:list).join: $_ }
    method Str  { $.to-literal }
    method iterator { self }
    method pull-one {
        with $!cur -> $this {
            $!cur = $this.next-node($!keep-blanks);
            $!type.box: $this, :$!doc
        }
        else {
            IterationEnd;
        }
    }
}
