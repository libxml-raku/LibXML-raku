#| interface to libxml2 regular expressions
unit class LibXML::RegExp;

=begin pod

    =head2 Synopsis

        use LibXML::RegExp;
        my LibXML::RegExp $compiled-re .= compile('[0-9]{5}(-[0-9]{4})?');
        my LibXML::RegExp $compiled-re .= new(rexexp => '[0-9]{5}(-[0-9]{4})?');
        if $compiled-re.isDeterministic() { ... }
        if $compiled-re.matches($string) { ... }
        if $string ~~ $compiled-re { ... }

        my LibXML::RegExp $compiled-re .= new( :$regexp );
        my Bool $matched = $compiled-re.matches($string);
        my Bool $det     = $compiled-re.isDeterministic();

    =head2 Description

    This is a Raku interface to libxml2's implementation of regular expressions,
    which are used e.g. for validation of XML Schema simple types (pattern facet).

   =head2 Methods
=end pod

use LibXML::Enums;
use LibXML::Raw;
use LibXML::Node;
use LibXML::ErrorHandling;
use NativeCall;
use Method::Also;

has xmlRegexp $!native; # is built Rakudo 2020.xx+
method native { $!native }

submethod TWEAK(Str:D :$regexp!) {
    $!native .= new(:$regexp)
       // die X::LibXML::OpFail.new(:what<RegExp>, :op<Compile>);
}
=begin pod
    =head2 method new

          method new(Str :$regexp) returns LibXML
          my LibXML::RegExp $compiled-re .= new( :$regexp );

    The new constructor takes a string containing a regular expression and return an object that contains a compiled regexp.
=end pod


#| Compile constructor
method compile(Str:D $regexp --> LibXML::RegExp) {
    self.new: :$regexp;
}
=para `LibXML::RegExp.compile($regexp)` is equivalent to `LibXML::RegExp.new(:$regexp)`

method !try-bool(Str:D $op, |c) {
    my $rv := $!native."$op"(|c);
    fail X::LibXML::OpFail.new(:what<RegExp>, :$op)
        if $rv < 0;
    $rv > 0;
}

#| (alias matches) Returns True if $content matches the regular expression
multi method ACCEPTS(LibXML::RegExp:D: Str:D $content --> Bool) is also<matches> {
    self!try-bool('Match', $content);
}

#| Returns True if the regular expression is deterministic. 
method isDeterministic returns Bool {
    self!try-bool('IsDeterministic');
}
=para (See the definition of determinism in the XML spec L<<<<<<http://www.w3.org/TR/REC-xml/#determinism >>>>>>)

submethod DESTROY {
    .Free with $!native;
}

=begin pod

=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
