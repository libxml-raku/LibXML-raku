class LibXML::Node::List does Iterable does Iterator {
    has Bool $.keep-blanks;
    has $.doc is required;
    has $.native is required handles <string-value>;
    has $!cur;
    has $.type is required;
    has @!array;
    has Bool $!slurped;
    has $!ref; # just to keep the list alive
    submethod TWEAK {
        $!ref = $!type.box: $_ with $!native;
        $!cur = $!native;
    }

    method Array handles<AT-POS elems List list pairs keys values map grep shift pop> {
        unless $!slurped++ {
            $!cur = $!native;
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
