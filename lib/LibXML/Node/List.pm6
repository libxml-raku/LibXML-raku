class LibXML::Node::List does Iterable does Iterator {
    use LibXML::Native;
    use LibXML::Node;

    has Bool $.keep-blanks;
    has $.doc is required;
    has anyNode $.native is required handles <string-value>;
    has $!cur;
    has $.of is required;
    has LibXML::Node @!store;
    has Hash $!hstore;
    has Bool $!lazy = True;
    has LibXML::Node $!first; # just to keep the list alive
    has LibXML::Node $.parent;
    method parent { $!parent // $!first.parent // fail "parent not found"; }
    submethod TWEAK {
        $!first = $!of.box: $_ with $!native;
        $!cur = $!native;
    }

    method Array handles<AT-POS elems List list values Numeric> {
        if $!lazy-- {
            $!cur = $!native;
            @!store = self;
        }
        @!store;
    }
    method Hash {
        $!hstore //= do {
            my $set-class := (require ::('LibXML::Node::Set'));
            my %h = ();
            for self.Array {
                (%h{.tagName} //= $set-class.new).push: $_;
            }
            %h;
        }
    }
    method push(LibXML::Node:D $node) {
        $.parent.appendChild($node);
        @!store.push($node) unless $!lazy;
        .{$node.tagName}.push: $node with $!hstore;
        $node;
    } 
    method pop {
        do with self.Array.tail -> LibXML::Node $node {
            @!store.pop;
            .{$node.tagName}.pop with $!hstore;
            $node.unbindNode;
        } // LibXML::Node;
    }
    method ASSIGN-POS(UInt() $pos, LibXML::Node $node) {
        $!hstore = Nil; # invalidate Hash cache
        if $pos < $.elems {
            $.parent.replaceChild($node, $.Array[$pos]);
        }
        elsif $pos == $.elems {
            # allow vivification of tail element
            $.parent.appendChild($node);
        }
        else {
            fail "array index out of bounds";
        }
    }
    multi method to-literal( :list($)! where .so ) { self.map(*.string-value) }
    multi method to-literal( :delimiter($_) = '' ) { self.to-literal(:list).join: $_ }
    method Str  { $.to-literal }
    method iterator {
        $!cur = $!native;
        self;
    }
    method pull-one {
        with $!cur -> $this {
            $!cur = $this.next-node($!keep-blanks);
            $!of.box: $this, :$!doc
        }
        else {
            IterationEnd;
        }
    }
    method to-node-set {
        require LibXML::Node::Set;
        my xmlNodeSet:D $native = $!native.list-to-nodeset($!keep-blanks);
        LibXML::Node::Set.new: :$native;
    }
}
