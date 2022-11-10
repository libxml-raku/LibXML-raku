use v6.d;
unit role LibXML::_Collection;

use LibXML::_Configurable;
use LibXML::Config;
use LibXML::Raw;
use LibXML::Types :resolve-package;

method create(|) {...}

my class NOT-YET { }

my $NODE-SET = NOT-YET;
my $NODE-LIST = NOT-YET;

method iterate-set($of, xmlNodeSet $raw, Bool :$deref) is implementation-detail {
    cas $NODE-SET, { resolve-package('LibXML::Node::Set') } if $NODE-SET === NOT-YET;
    # iterate through a set of nodes
    self.create: $NODE-SET, :$raw, :$of, :$deref
}

method iterate-list($of, Bool :$blank = True) is implementation-detail {
    cas $NODE-LIST, { resolve-package('LibXML::Node::List') } if $NODE-LIST === NOT-YET;
    # follow a chain of .next links.
    self.create: $NODE-LIST, :$of, :$blank, :parent(self);
}

