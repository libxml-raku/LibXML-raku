class LibXML::Node::Set does Iterable does Iterator does Positional {
    use LibXML::Native;
    use LibXML::Item :box-class;
    use Method::Also;

    has Any:U $.of = LibXML::Item;
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
    method !box(itemNode $elem) {
        do with $elem {
            my $class = box-class(.type);
            die "unexpected node of type {$class.WHAT.perl} in node-set"
               unless $class ~~ $!of;

            $class.box: .delegate;
        } // $!of;
    }
    method elems is also<Numeric> { $!native.nodeNr }
    method Array handles<List list values map grep> {
        if $!lazy {
            $!idx = 0;
            @!store = self;
            $!lazy = False;
        }
        @!store;
    }
    method Hash handles <AT-KEY> {
        $!hstore //= do {
            my LibXML::Node::Set %h = ();
            for self.Array {
                (%h{.tagName} //= LibXML::Node::Set.new).push: $_;
            }
            %h;
        }
    }
    multi method AT-POS(UInt:D $pos where !$!lazy) { @!store[$pos] }
    multi method AT-POS(UInt:D $pos where $_ >= $!native.nodeNr) { $!of }
    multi method AT-POS(UInt:D $pos) is default {
        self!box: $!native.nodeTab[$pos];
    }
    method push(LibXML::Item:D $node) {
        @!store.push: $_ unless $!lazy;
        .{$node.tagName}.push: $node with $!hstore;
        $!native.push: $node.native.ItemNode;
        $node;
    }
    method delete(LibXML::Item:D $node) {
        my UInt $idx := $!native.delete($node.native.ItemNode);
        if $idx >= 0 {
            @!store.slice($idx, 1) unless $!lazy;
            .{$node.tagName}.delete with $!hstore;
            $node;
        }
        else {
            $!of;
        }
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

=begin pod
=head1 NAME

LibXML::Node::Set - LibXML Class for XPath Node Collections

=head1 SYNOPSIS

  use LibXML::Node::Set;
  my LibXML::Node::Set $node-set;

  $node-set = $elem.childNodes;
  $node-set = $elem.findnodes($xpath);
  $node-set .= new;
  $node-set.push: $elem;

  my LibXML::Item @items = $node-set;
  for $node-set -> LibXML::Item $item { ... }
  for 0 ..^ $node-set.elems { my $item = $node-set[$_]; ... }

  my LibXML::Node::Set %nodes-by-tag-name = $node-set.Hash;
  ...

=head1 DESCRIPTION

This class is commonly used for handling result sets from XPath queries.

=head1 METHODS

=head1 AUTHORS

Matt Sergeant,
Christian Glahn,
Petr Pajas,
Shlomi Fish,
Tobias Leich,
Xliff,
David Warring

=head1 VERSION

2.0200

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
