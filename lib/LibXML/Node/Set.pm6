class LibXML::Node::Set does Iterable does Iterator does Positional {
    use LibXML::Native;
    use LibXML::Node :native-class, :cast-elem, :NodeSetElem;
    use Method::Also;

    has $.of = NodeSetElem;
    has xmlNodeSet $.native;
    has UInt $!idx = 0;
    has @!array;
    has Bool $!slurped;
    has Bool $.values;

    submethod TWEAK {
        $!native //= xmlNodeSet.new;
        .Reference given $!native;
    }
    submethod DESTROY {
        .Release with $!native;
    }
    method elems is also<Numeric> { $!slurped ?? @!array.elems !! $!native.nodeNr }
    method Array handles<List list pairs keys values map grep shift pop push append> {
        unless $!slurped {
            $!idx = 0;
            @!array = self;
            $!slurped = True;
        }
        @!array;
    }
    multi method AT-POS(UInt:D $pos where $!slurped) { @!array[$pos] }
    multi method AT-POS(UInt:D $pos where $_ >= $!native.nodeNr) { $!of }
    multi method AT-POS(UInt:D $pos) is default {
        my $rv := $!values ?? Str !! $!of;

        with $!native.nodeTab[$pos].deref {
            my $class = native-class(.type);
            die "unexpected node of type {$class.perl} in node-set"
               unless $class ~~ $!of;

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
    method size { $!native.nodeNr }
    method iterator { self }
    method pull-one {
        if $!native.defined && $!idx < $!native.nodeNr {
            self.AT-POS($!idx++);
        }
        else {
            IterationEnd;
        }
    }
}

