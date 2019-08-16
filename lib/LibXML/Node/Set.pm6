class LibXML::Node::Set does Iterable does Iterator does Positional {
    use LibXML::Native;
    use LibXML::Node :box-class, :cast-elem, :NodeSetElem;
    use Method::Also;

    has $.of = NodeSetElem;
    has xmlNodeSet $.native;
    has UInt $!idx = 0;
    has @!store;
    has Hash $!hstore;
    has Bool $!lazy = True;

    submethod TWEAK {
        $!native //= xmlNodeSet.new;
        .Reference given $!native;
    }
    submethod DESTROY {
        .Unreference with $!native;
    }
    method !box(xmlNodeSetElem $elem) {
        do with $elem {
            my $class = box-class(.type);
            die "unexpected node of type {$class.perl} in node-set"
               unless $class ~~ $!of;

            $class.box: cast-elem($_);
        } // $!of.WHAT;
    }
    method elems is also<Numeric> { $!native.nodeNr }
    method Array handles<List list pairs keys values> {
        if $!lazy {
            $!idx = 0;
            @!store = self;
            $!lazy = False;
        }
        @!store;
    }
    method Hash {
        $!hstore //= self.Array.classify(*.tagName);
    }
    multi method AT-POS(UInt:D $pos where !$!lazy) { @!store[$pos] }
    multi method AT-POS(UInt:D $pos where $_ >= $!native.nodeNr) { $!of }
    multi method AT-POS(UInt:D $pos) is default {
        self!box: $!native.nodeTab[$pos].deref;
    }
    method push(LibXML::Node:D $node) {
        @!store.push: $_ unless $!lazy;
        .{$node.tagName}.push: $node with $!hstore;
        $!native.push: $node.native;
        $node;
    }
    method pop {
        my $node := $!native.pop;
        if $node.defined {
            .{$node.tagName}.pop with $!hstore;
        }
        $!lazy ?? self!box($node) !! @!store.pop;
    }
    method string-value { do with self.AT-POS(0) { .string-value } // Str}
    multi method to-literal( :list($)! where .so ) { self.map({ .string-value }) }
    multi method to-literal( :delimiter($_) = '' ) { self.to-literal(:list).join: $_ }
    method Str handles <Int Num trim chomp> { $.to-literal }
    method size { $!native.nodeNr }
    method iterator {
        $!idx = 0;
        self;
    }
    method pull-one {
        if $!native.defined && $!idx < $!native.nodeNr {
            self.AT-POS($!idx++);
        }
        else {
            IterationEnd;
        }
    }
}

