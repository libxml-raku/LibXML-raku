class LibXML::Node::Set does Iterable does Iterator {
    use LibXML::Native;
    use LibXML::Node :box-class, :cast-elem;
    has $.range is required;
    has xmlNodeSet $.set is required;
    has UInt $!idx = 0;
    has @!array;
    has Bool $!slurped;
    has Bool $.values;
    submethod TWEAK {
        .Reference with $!set;
    }
    submethod DESTROY {
        # xmlNodeSet is managed by us
        .Release with $!set;
    }
    method elems { $!slurped ?? @!array.elems !! $!set.nodeNr }
    method Array handles<List pairs keys values map grep shift pop push append> {
        unless $!slurped {
            $!idx = 0;
            @!array = self;
            $!slurped = True;
        }
        @!array;
    }
    multi method AT-POS(UInt:D $pos where $!slurped) { @!array[$pos] }
    multi method AT-POS(UInt:D $pos where $_ >= $!set.nodeNr) { $!range }
    multi method AT-POS(UInt:D $pos) is default {
        my $rv := $!values ?? Str !! $!range;

        with $!set.nodeTab[$pos].deref {
            my $class = box-class(.type);
            die "unexpected node of type {$class.perl} in node-set"
            unless $class ~~ $!range;

            with $class.box: cast-elem($_) {
                $rv := $!values ?? .string-value !! $_;
            }
        }

        $rv;
    }

    method string-value { with self.AT-POS(0) { $!values ?? $_ !! .string-value }}
    multi method to-literal( :list($)! where .so ) { self.map({$!values ?? $_ !! .string-value}) }
    multi method to-literal( :delimiter($_) = '' ) { self.to-literal(:list).join: $_ }
    method Str  { $.to-literal }
    method size { $!set.nodeNr }
    method iterator { self }
    method pull-one {
        if $!set.defined && $!idx < $!set.nodeNr {
            self.AT-POS($!idx++);
        }
        else {
            IterationEnd;
        }
    }
}

