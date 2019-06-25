unit class LibXML::RegExp;

use LibXML::Enums;
use LibXML::Native;
use LibXML::Node;
use NativeCall;

enum Flags (
    PAT_FROM_ROOT => 1 +< 8,
    PAT_FROM_CUR  => 1 +< 9
);

has xmlRegexp $!native;
method native { $!native }
has UInt $.flags;

submethod TWEAK(Str:D :$regexp!) {
    $!native .= new(:$regexp)
       // die "failed to compile regexp";
}

submethod DESTROY {
    .Free with $!native;
}

method compile(Str:D $regexp, |c) {
    self.new: :$regexp, |c;
}

method !try-bool(Str:D $op, |c) {
    my $rv := $!native."$op"(|c);
    fail X::LibXML::Reader::OpFail.new(:$op)
        if $rv < 0;
    $rv > 0;
}

method matches(Str:D $content) {
    self!try-bool('Match', $content);
}

method isDeterministic {
    self!try-bool('IsDeterministic');
}

=begin pod

=head1 NAME

LibXML::RegExp - LibXML::RegExp - interface to libxml2 regular expressions

=head1 SYNOPSIS



  use LibXML::RegExp;
  my LibXML::RegExp $compiled-re .= new(rexexp => '[0-9]{5}(-[0-9]{4})?');
  if $compiled-re.isDeterministic() { ... }
  if $compiled-re.matches($string) { ... }

  my LibXML::RegExp $compiled-re .= new( :$regexp );
  my Bool $matched = $compiled-re.matches($string);
  my Bool $det     = $compiled-re.isDeterministic();

=head1 DESCRIPTION

This is a perl interface to libxml2's implementation of regular expressions,
which are used e.g. for validation of XML Schema simple types (pattern facet).

=begin item
new()

  my LibXML::RegExp $compiled-re .= new( :$regexp );

The constructor takes a string containing a regular expression and returns an object that contains a compiled regexp.
=end item

=begin item
matches($string)

  my Bool $matched = $compiled_re.matches($string);

Given a string value, returns True if the value is matched by the
compiled regular expression.
=end item

=begin item
isDeterministic()

  my Bool $det = $compiled_re.isDeterministic();

Returns True if the regular expression is deterministic; returns False
otherwise. (See the definition of determinism in the XML spec (L<<<<<< http://www.w3.org/TR/REC-xml/#determinism >>>>>>))

=end item

=head1 AUTHORS

Matt Sergeant,
Christian Glahn,
Petr Pajas

Ported from Perl 5 to 6 by David Warring <david.warring@gmail.com>


=head1 VERSION

2.0132

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
