unit class LibXML::Pattern;

use LibXML::Enums;
use LibXML::Native;
use LibXML::Node;
use LibXML::_Options;
use NativeCall;
use LibXML::ErrorHandling;

enum Flags (
    PAT_FROM_ROOT => 1 +< 8,
    PAT_FROM_CUR  => 1 +< 9
);

also does LibXML::_Options[
    %(
        :default(XML_PATTERN_DEFAULT),
        :xpath(XML_PATTERN_XPATH),
        :xssel(XML_PATTERN_XSSEL),
        :xsfield(XML_PATTERN_XSFIELD),
        :from-root(PAT_FROM_ROOT),
        :from-cur(PAT_FROM_CUR),
    )
];

has xmlPattern $!native;
method native { $!native }
has UInt $.flags;

submethod TWEAK(Str:D :$pattern!, :%ns, *%opts) {
    self.set-flags($!flags, |%opts);
    my CArray[Str] $ns .= new: |(%ns.kv.sort), Str;
    $!native .= new(:$pattern, :$!flags, :$ns)
        // die X::LibXML::OpFail.new(:what<Pattern>, :op<Compile>);
}

submethod DESTROY {
    .Free with $!native;
}

method compile(Str:D $pattern, |c) {
    self.new: :$pattern, |c;
}

method !try-bool(Str:D $op, |c) {
    my $rv := $!native."$op"(|c);
    fail X::LibXML::OpFail.new(:what<Pattern>, :$op)
        if $rv < 0;
    $rv > 0;
}

multi method matchesNode(LibXML::Node $node) {
    self!try-bool('Match', $node.native);
}

multi method matchesNode(anyNode $node) {
    self!try-bool('Match', $node);
}

multi method ACCEPTS(LibXML::Pattern:D: LibXML::Node:D $node) {
    self.matchesNode($node);
}

method FALLBACK($key, |c) is rw {
    $.option-exists($key)
        ?? $.option($key, |c)
        !! die X::Method::NotFound.new( :method($key), :typename(self.^name) );
}

=begin pod
=head1 NAME

LibXML::Pattern - LibXML::Pattern - interface to libxml2 XPath patterns

=head1 SYNOPSIS



  use LibXML;
  my LibXML::Pattern $pattern = complie('/x:html/x:body//x:div', :ns{ 'x' => 'http://www.w3.org/1999/xhtml' });
  # test a match on an LibXML::Node $node
  
  if $pattern.matchesNode($node) { ... }
  if $node ~~ $pattern;
  
  # or on an LibXML::Reader
  
  if $reader.matchesPattern($pattern) { ... }
  
  # or skip reading all nodes that do not match
  
  print $reader.nodePath while $reader.nextPatternMatch($pattern);

  my LibXML::Pattern $pattern .= new( pattern, :ns{prefix => namespace_URI} );
  my Bool $matched = $pattern.matchesNode($node);

=head1 DESCRIPTION

This is a Raku interface to libxml2's pattern matching support I<<<<<< http://xmlsoft.org/html/libxml-pattern.html >>>>>>. This feature requires recent versions of libxml2.

Patterns are a small subset of XPath language, which is limited to
(disjunctions of) location paths involving the child and descendant axes in
abbreviated form as described by the extended BNF given below: 



  Selector ::=     Path ( '|' Path )*
  Path     ::=     ('.//' | '//' | '/' )? Step ( '/' Step )*
  Step     ::=     '.' | NameTest
  NameTest ::=     QName | '*' | NCName ':' '*'

For readability, whitespace may be used in selector XPath expressions even
though not explicitly allowed by the grammar: whitespace may be freely added
within patterns before or after any token, where



  token     ::=     '.' | '/' | '//' | '|' | NameTest

Note that no predicates or attribute tests are allowed.

Patterns are particularly useful for stream parsing provided via the C<<<<<< LibXML::Reader >>>>>> interface.

=begin item1
new / compile

  my LibXML::Pattern $pattern .= compile( $expr, :ns{ prefix => namespace_URI, ... } );
  my LibXML::Pattern $pattern2 .= new ( pattern => $expr, :ns{ prefix => namespace_URI, ... } );

The constructors of a pattern takes a pattern expression (as described by the
BNF grammar above) and an optional Hash mapping prefixes to namespace
URIs. The methods return a compiled pattern object. 

Note that if the document has a default namespace, it must still be given an
prefix in order to be matched (as demanded by the XPath 1.0 specification). For
example, to match an element C<<<<<< &lt;a xmlns="http://foo.bar"&lt;/a&gt; >>>>>>, one should use a pattern like this: 



  my LibXML::Pattern $pattern .= compile( 'foo:a', :ns(foo => 'http://foo.bar') );

=end item1

=begin item1
matchesNode / ACCEPTS

  my Bool $matched = $pattern.matchesNode($node);
  $matched = $node ~~ $pattern;

Given an LibXML::Node object, returns True if the node is matched by
the compiled pattern expression.

=end item1


=head1 SEE ALSO

L<<<<<< LibXML::Reader >>>>>> for other methods involving compiled patterns.

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
