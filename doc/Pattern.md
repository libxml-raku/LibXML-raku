NAME
====

LibXML::Pattern - LibXML::Pattern - interface to libxml2 XPath patterns

SYNOPSIS
========

    use LibXML;
    my $pattern = LibXML::Pattern.new('/x:html/x:body//x:div', :ns{ 'x' => 'http://www.w3.org/1999/xhtml' });
    # test a match on an LibXML::Node $node

    if $pattern.matchesNode($node) { ... }

    # or on an LibXML::Reader

    if $reader.matchesPattern($pattern) { ... }

    # or skip reading all nodes that do not match

    print $reader.nodePath while $reader.nextPatternMatch($pattern);

    my LibXML::Pattern $pattern .= new( pattern, :ns{prefix => namespace_URI} );
    my Bool $matched = $pattern.matchesNode($node);

DESCRIPTION
===========

This is a perl interface to libxml2's pattern matching support *http://xmlsoft.org/html/libxml-pattern.html *. This feature requires recent versions of libxml2.

Patterns are a small subset of XPath language, which is limited to (disjunctions of) location paths involving the child and descendant axes in abbreviated form as described by the extended BNF given below: 

    Selector ::=     Path ( '|' Path )*
    Path     ::=     ('.//' | '//' | '/' )? Step ( '/' Step )*
    Step     ::=     '.' | NameTest
    NameTest ::=     QName | '*' | NCName ':' '*'

For readability, whitespace may be used in selector XPath expressions even though not explicitly allowed by the grammar: whitespace may be freely added within patterns before or after any token, where

    token     ::=     '.' | '/' | '//' | '|' | NameTest

Note that no predicates or attribute tests are allowed.

Patterns are particularly useful for stream parsing provided via the `LibXML::Reader ` interface.

  * new()

        $pattern = LibXML::Pattern.new( pattern, :ns{ prefix => namespace_URI, ... } );

    The constructor of a pattern takes a pattern expression (as described by the BNF grammar above) and an optional Hash mapping prefixes to namespace URIs. The method returns a compiled pattern object. 

    Note that if the document has a default namespace, it must still be given an prefix in order to be matched (as demanded by the XPath 1.0 specification). For example, to match an element `&lt;a xmlns="http://foo.bar"&lt;/a&gt; `, one should use a pattern like this: 

        my LibXML::Pattern $pattern .= new( 'foo:a', :ns(foo => 'http://foo.bar') );

  * matchesNode($node)

        my Bool $matched = $pattern.matchesNode($node);

    Given an LibXML::Node object, returns Tru if the node is matched by the compiled pattern expression.

SEE ALSO
========

[LibXML::Reader ](LibXML::Reader ) for other methods involving compiled patterns.

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

