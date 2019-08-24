use v6;
class LibXML::XPath::Context {

    use LibXML::Native;
    use LibXML::Node :iterate-set, :NodeSetItem, :NameVal, :native;
    use LibXML::Document;
    use LibXML::Types :QName;
    use LibXML::Node::List;
    use LibXML::Node::Set;
    use LibXML::Namespace;
    use LibXML::XPath::Expression;
    use LibXML::XPath::Object :XPathRange;
    use NativeCall;
    use Method::Also;

    has LibXML::Node $!context-node;
    has Exception @!callback-errors;
    has xmlXPathContext $!native .= new;
    method native { $!native }

    submethod TWEAK(LibXML::Node :$node, LibXML::Document :$doc) {
        self.setContextNode($_) with $node // $doc;
    }

    submethod DESTROY {
        .Free with $!native;
    }

    method !find(LibXML::XPath::Expression:D $xpath-expr, LibXML::Node $ref --> xmlNodeSet) {
        my anyNode $node = .native with $ref;
        my xmlNodeSet $node-set := $.native.findnodes( native($xpath-expr), $node);
        .rethrow with @!callback-errors.tail;
        $node-set.copy;
    }
    proto method findnodes($, $?) is also<AT-KEY> {*}
    multi method findnodes(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?) {
        iterate-set(NodeSetItem, self!find($expr, $ref));
    }
    multi method findnodes(Str:D $_, LibXML::Node $ref?) is default {
        my $expr = LibXML::XPath::Expression.new: :expr($_);
        iterate-set(NodeSetItem, self!find($expr, $ref));
    }

    method !value(xmlXPathObject $native, Bool :$literal) {
        .rethrow with @!callback-errors.tail;
        my LibXML::XPath::Object $object .= new: :$native;
        $object.value: :$literal;
    }

    multi method find(LibXML::XPath::Expression:D $xpath-expr, LibXML::Node $ref-node?, Bool:D :$bool = False, Bool :$literal) {
        my anyNode $node = .native with $ref-node;
        self!value: $!native.find( native($xpath-expr), $node, :$bool), :$literal;
    }
    multi method find(Str:D $expr, LibXML::Node $ref-node?, |c) is default {
        $.find(LibXML::XPath::Expression.parse($expr), $ref-node, |c);
    }

    multi method findvalue(LibXML::XPath::Expression:D $xpath-expr, LibXML::Node $ref-node?, |c) {
        $.find( $xpath-expr, $ref-node, :literal, |c);
    }
    multi method findvalue(Str:D $expr, LibXML::Node $ref-node?, |c) {
        $.findvalue(LibXML::XPath::Expression.parse($expr), $ref-node, |c);
    }

    my subset XPathDomain where LibXML::XPath::Expression|Str|Any:U;

    method exists(XPathDomain:D $xpath-expr, LibXML::Node $node? --> Bool:D) {
        $.find($xpath-expr, $node, :bool);
    }

    multi method registerNs(QName:D :$prefix!, Str :$uri) {
        $.registerNs($prefix, $uri);
    }
    multi method registerNs(QName:D $prefix!, Str $uri?) {
        my $stat = $uri
            ?? $.native.RegisterNs($prefix, $uri)
            !! $.native.RegisterNs($prefix, Str);
        die "XPathContext: cannot {$uri ?? '' !! 'un'}register namespace"
           if $stat == -1;
        $stat;
    }
    multi method registerNs(NameVal:D $_) {
        $.registerNs(.key, .value);
    }
    multi method registerNs(LibXML::Namespace:D $_) {
        $.registerNs(.localname, .URI);
    }

    multi method unregisterNs(QName:D :$prefix!) {
        $.registerNs($prefix);
    }
    multi method unregisterNs(QName:D $prefix!) {
        $.registerNs($prefix);
    }

    method lookupNs(QName:D $prefix) {
        $!native.NsLookup($prefix);
    }

    method getContextNode {
        $!context-node;
    }

    #| defining the context node
    multi method setContextNode(LibXML::Node:D $!context-node) {
        $!native.domXPathCtxtSetNode($!context-node.native);
        die $_ with $!context-node.domFailure;
        $!context-node;
    }

    #| undefining the context node
    multi method setContextNode(LibXML::Node:U $!context-node) is default {
        $!native.domXPathCtxtSetNode(anyNode);
        $!context-node;
    }

    method contextNode is rw {
        Proxy.new(
            FETCH => { $.getContextNode },
            STORE => -> $, LibXML::Node $_ {
                $.setContextNode($_);
            }
        );
    }

    method getContextPosition { $!native.proximityPosition }
    method setContextPosition(Int:D $pos) {
        fail "XPathContext: invalid position"
            unless -1 <= $pos <= $!native.contextSize; 
        $!native.proximityPosition = $pos;
    }
    method contextPosition is rw {
        Proxy.new(
            FETCH => { self.getContextPosition },
            STORE => -> $, Int:D $pos {
                self.setContextPosition($pos) 
            }
        );
    }

    method getContextSize { $!native.contextSize }
    method setContextSize(Int:D $size) {
        fail "XPathContext: invalid size"
            unless -1 <= $size;
        $!native.contextSize = $size;
        $!native.proximityPosition = +($size <=> 0);
    }
    method contextSize is rw {
        Proxy.new(
            FETCH => { self.getContextSize },
            STORE => -> $, Int:D $size {
                self.setContextSize($size);
            }
        );
    }

    has %!pool{UInt}; # Keep objects alive, while they are on the stack
    my subset NodeObj where LibXML::Node::Set|LibXML::Node::List|LibXML::Node;
    method !keep(xmlNodeSet:D $native, xmlXPathParserContext :$ctxt --> xmlNodeSet:D) {
        my UInt $ctxt-addr = 0;
        with $ctxt {
            # scope to a particular parser/eval context
            $ctxt-addr = +nativecast(Pointer, $_); # associated with a particular parse/eval
            # context stack is clear. We can also clear the associated pool
            %!pool{$ctxt-addr} = []
                 if .valueNr == 0  && !.value.defined;
        }
        %!pool{$ctxt-addr}.push: LibXML::Node::Set.new: :$native;
        $native;
    }
    multi method park(NodeObj:D $node, xmlXPathParserContext :$ctxt --> xmlNodeSet:D) {
        # return a copied, or newly created native node-set
        self!keep: do given $node {
            when LibXML::Node::Set  { .native.copy }
            when LibXML::Node::List { xmlNodeSet.new: node => .native, :list;}
            when LibXML::Node       { xmlNodeSet.new: node => .native;}
            default { fail "unhandled node type: {.WHAT.perl}" }
        }, :$ctxt
    }
    multi method park(XPathRange:D $_) { $_ }
    subset Listy where List|Seq|Slip;
    multi method park(Listy:D $_, xmlXPathParserContext :$ctxt --> xmlNodeSet) {
        # create a node-set for a list of nodes
        my LibXML::Node:D @nodes = .List;
        my xmlNodeSet $set .= new;
        $set.push(.native) for @nodes;
        self!keep: $set, :$ctxt;
    }
    # anything else (Bool, Numeric, Str)
    multi method park($_) is default { fail "unexpected return value: {.perl}"; }

    method registerFunction(QName:D $name, &func, |c) {
        self.registerFunctionNS($name, Str, &func, |c);
    }

    method registerFunctionNS(QName:D $name, Str $url, &func, |c) {
        $!native.RegisterFuncNS(
            $name, $url,
            -> xmlXPathParserContext $ctxt, Int $n {
                CATCH { default { @!callback-errors.push: $_ } }
                my @params;
                @params.unshift: self!value($ctxt.valuePop) for 0 ..^ $n;
                my $ret = &func(|@params, |c);
                my xmlXPathObject:D $out := xmlXPathObject.coerce: $.park($ret, :$ctxt);
                $ctxt.valuePush($_) for $out;
            }
        );
    }

    method registerVarLookupFunc(&func, |c) {
        $!native.RegisterVariableLookup(
            -> xmlXPathContext $ctxt, Str $name, Str $url --> xmlXPathObject:D {
                CATCH { default { @!callback-errors.push: $_ } }
                my $ret = &func($name, $url, |c);
                xmlXPathObject.coerce: $.park($ret);
            },
            Pointer,
        );
    }
    method unregisterVarLookupFunc {
        $!native.RegisterVariableLookup(Pointer, Pointer);
    }
    method getVarLookupFunc {

        with $!native.varLookupFunc {
            nativecast( :($ctxt, Str $name, Str $url --> xmlXPathObject:D), $_)
        }
        else {
            Routine;
        }
    }
    method varLookupFunc is rw {
        Proxy.new(
            FETCH => { $.getVarLookupFunc },
            STORE => -> $, &func {
                $.registerVarLookupFunc(&func)
            }
        );
    }

    method unregisterFunction(QName:D $name) { $.unregisterFunctionNS($name, Str) }
    method unregisterFunctionNS(QName:D $name, Str $url) { $!native.RegisterFuncNS($name, $url, Pointer) }
}

=begin pod
=head1 NAME

LibXML::XPathContext - XPath Evaluation

=head1 SYNOPSIS

  use LibXML::XPathContext;
  use LibXML::Node;
  my LibXML::XPath::Context $xpc .= new();
  $xpc .= new(:$node);
  $xpc.registerNs($prefix, $namespace-uri);
  $xpc.unregisterNs($prefix);
  my Str $uri = $xpc.lookupNs($prefix);
  $xpc.registerVarLookupFunc(&get-variable);
  my &func = $xpc.getVarLookupFunc();
  $xpc.unregisterVarLookupFunc;
  $xpc.registerFunctionNS($name, $uri, &callback);
  $xpc.unregisterFunctionNS($name, $uri);
  $xpc.registerFunction($name, &callback);
  $xpc.unregisterFunction($name);
  my @nodes = $xpc.findnodes($xpath);
  @nodes = $xpc.findnodes($xpath, $ref-node );
  my LibXML::Node::Set $nodes = $xpc.findnodes($xpath, $ref-node );
  my Any $object = $xpc.find($xpath );
  $object = $xpc.find($xpath, $ref-node );
  my $value = $xpc.findvalue($xpath );
  $value = $xpc.findvalue($xpath, $ref-node );
  my Bool $found = $xpc.exists( $xpath, $ref-node );
  $xpc.contextNode = $node;
  $node = $xpc.contextNode;
  my Int $position = $xpc.contextPosition;
  $xpc.contextPosition = $position;
  my Int $size = $xpc.contextSize;
  $xpc.contextSize = $size;

=head1 DESCRIPTION

The LibXML::XPath::Context class provides an almost complete interface to
libxml2's XPath implementation. With LibXML::XPath::Context, it is possible to
evaluate XPath expressions in the context of arbitrary node, context size, and
context position, with a user-defined namespace-prefix mapping, custom XPath
functions written in Perl, and even a custom XPath variable resolver. 

=head1 EXAMPLES


=head2 Namespaces

This example demonstrates C<<<<<< registerNs() >>>>>> method. It finds all paragraph nodes in an XHTML document.



  my LibXML::XPath::Context $xc .= new: doc($xhtml-doc);
  $xc.registerNs('xhtml', 'http://www.w3.org/1999/xhtml');
  my LibXML::Node @nodes = $xc.findnodes('//xhtml:p');


=head2 Custom XPath functions

This example demonstrates C<<<<<< registerFunction() >>>>>> method by defining a function filtering nodes based on a Perl regular
expression:

    sub grep-nodes(LibXML::Node::Set $nodes, Str $regex) {
        $nodes.grep: {.textContent ~~ / <$regex> /};
    };

    my LibXML::Document $doc .= parse: "example/article.xml";
    $node = $doc.root;
    my $xc = LibXML::XPath::Context.new(:$node);
    $xc.registerFunction('grep-nodes', &grep-nodes);
    @nodes = $xc.findnodes('grep-nodes(section,"^Bar")').list;

=head2 Variables

This example demonstrates C<<<<<< registerVarLookup() >>>>>> method. We use XPath variables to recycle results of previous evaluations:



  sub var-lookup(Str $name, Str $uri, Hash $data) {
    return $data{$name};
  }
  
  my $areas = LibXML.new.parse: :file('areas.xml');
  my $empl = LibXML.new.parse: :file('employees.xml');
  
  my $xc = LibXML::XPath::Context.new(node => $empl);
  
  my %variables = (
    A => $xc.find('/employees/employee[@salary>10000]'),
    B => $areas.find('/areas/area[district='Brooklyn']/street'),
  );
  
  # get names of employees from $A working in an area listed in $B
  $xc.registerVarLookupFunc(&var-lookup, %variables);
  my @nodes = $xc.findnodes('$A[work_area/street = $B]/name');


=head1 METHODS

=begin item1
new

  my $xpc = LibXML::XPath::Context.new();

Creates a new LibXML::XPath::Context object without a context node.

  my $xpc = LibXML::XPath::Context.new($node);

Creates a new LibXML::XPath::Context object with the context node set to C<<<<<< $node >>>>>>.

=end item1

=begin item1
registerNs

  $xpc.registerNs($prefix, $namespace-uri);

Registers namespace C<<<<<< $prefix >>>>>> to C<<<<<< $namespace-uri >>>>>>.

=end item1

=begin item1
unregisterNs

  $xpc.unregisterNs($prefix);

Unregisters namespace C<<<<<< $prefix >>>>>>.

=end item1

=begin item1
lookupNs

  $uri = $xpc.lookupNs($prefix);

Returns namespace URI registered with C<<<<<< $prefix >>>>>>. If C<<<<<< $prefix >>>>>> is not registered to any namespace URI returns C<<<<<< undef >>>>>>.

=end item1

=begin item1
registerVarLookupFunc

  $xpc.registerVarLookupFunc(&callback, |args);

Registers variable lookup function C<<<<<< $prefix >>>>>>. The registered function is executed by the XPath engine each time an XPath
variable is evaluated. The callback function has two required arguments: C<<<<<< $data >>>>>>, variable name, and variable ns-URI.

The function must return one value: Bool, Str, Numeric, LibXML::Node (e.g.
Document, Element, etc.), LibXML::Node::Set or LibXML::Node::List. For convenience, types: List, Seq and Slip can also be returned
array references containing only L<<<<<< LibXML::Node >>>>>> objects can be used instead of an L<<<<<< LibXML::NodeList >>>>>>.

Any additional arguments are curried and passed to the callback function. For example:

  $xpc.registerVarLookupFunc(&my-callback, 'Xxx', :%vars);

matches the signature:

sub my-callback(Str $name, Str $uri, 'Xxxx', :%vars!) {
    ...
}

=end item1


=begin item1
registerFunctionNS

  $xpc.registerFunctionNS($name, $uri, &callback, |args);

Registers an extension function C<<<<<< $name >>>>>> in C<<<<<< $uri >>>>>> namespace. The arguments of the callback function are either
simple scalars or C<<<<<< LibXML::* >>>>>> objects depending on the XPath argument types.

The function must return one value: Bool, Str, Numeric, LibXML::Node (e.g.
Document, Element, etc.), LibXML::Node::Set or LibXML::Node::List. For convenience, types: List, Seq and Slip can also be returned
array references containing only L<<<<<< LibXML::Node >>>>>> objects can be used instead of an L<<<<<< LibXML::NodeList >>>>>>.

=end item1

=begin item1
unregisterFunctionNS

  $xpc.unregisterFunctionNS($name, $uri);

Unregisters extension function C<<<<<< $name >>>>>> in C<<<<<< $uri >>>>>> namespace. Has the same effect as passing C<<<<<< undef >>>>>> as C<<<<<< $callback >>>>>> to registerFunctionNS.

=end item1

=begin item1
registerFunction

  $xpc.registerFunction($name, &callback, |args);

Same as C<<<<<< registerFunctionNS >>>>>> but without a namespace.

=end item1

=begin item1
unregisterFunction

  $xpc.unregisterFunction($name);

Same as C<<<<<< unregisterFunctionNS >>>>>> but without a namespace.

=end item1

=begin item1
findnodes

  my LibXML::Node @nodes = $xpc.findnodes($xpath);

  @nodes = $xpc.findnodes($xpath, $context-node );

  my LibXML::Node::Set $nodes = $xpc.findnodes($xpath, $context-node );

Performs the xpath statement on the current node and returns the result as an
array. In scalar context, returns an L<<<<<< LibXML::NodeList >>>>>> object. Optionally, a node may be passed as a second argument to set the
context node for the query.

The xpath expression can be passed either as a string, or as a L<<<<<< LibXML::XPathExpression >>>>>> object. 

=end item1

=begin item1
find

  my Any $object = $xpc.find($xpath );

  $object = $xpc.find($xpath, $context-node );

Performs the xpath expression using the current node as the context of the
expression, and returns the result depending on what type of result the XPath
expression had. For example, the XPath C<<<<<< 1 * 3 + 	      52 >>>>>> results in a Numeric object being returned. Other expressions might return a Bool object, or a L<<<<<< LibXML::Literal >>>>>> object (a string). Optionally, a node may be passed as a
second argument to set the context node for the query.

The xpath expression can be passed either as a string, or as a L<<<<<< LibXML::XPathExpression >>>>>> object. 

=end item1

=begin item1
findvalue

  my Str $value = $xpc.findvalue($xpath );

  my Str $value = $xpc.findvalue($xpath, $context-node );

Is exactly equivalent to:



  $xpc.find( $xpath, $context-node ).to-literal;

That is, it returns the literal value of the results. This enables you to
ensure that you get a string back from your search, allowing certain shortcuts.
This could be used as the equivalent of <xsl:value-of select=``some-xpath''/>.
Optionally, a node may be passed in the second argument to set the context node
for the query.

The xpath expression can be passed either as a string, or as a L<<<<<< LibXML::XPathExpression >>>>>> object. 

=end item1

=begin item1
exists

  my Bool $found = $xpc.exists( $xpath-expression, $context-node );

This method behaves like I<<<<<< findnodes >>>>>>, except that it only returns a Bool value (True if the expression matches a
node, False otherwise) and may be faster than I<<<<<< findnodes >>>>>>, because the XPath evaluation may stop early on the first match (this is true
for libxml2 >= 2.6.27). 

For XPath expressions that do not return node-set, the method returns True if
the returned value is a non-zero number or a non-empty string.

=end item1

=begin item1
contextNode

  $xpc.contextNode = $node;
  $node = $xpc.contextNode

Set or get the current context node.

=end item1

=begin item1
contextPosition

  $xpc.contextPosition = $position;
  $position = $xpc.contextPosition;

Set or get the current context position. By default, this value is -1 (and evaluating
XPath function C<<<<<< position() >>>>>> in the initial context raises an XPath error), but can be set to any value up
to context size. This usually only serves to cheat the XPath engine to return
given position when C<<<<<< position() >>>>>> XPath function is called. Setting this value to -1 restores the default
behavior.

=end item1

=begin item1
contextSize

  $xpc.setContextSize = $size;

Set or get the current context size. By default, this value is -1 (and evaluating
XPath function C<<<<<< last() >>>>>> in the initial context raises an XPath error), but can be set to any
non-negative value. This usually only serves to cheat the XPath engine to
return the given value when C<<<<<< last() >>>>>> XPath function is called. If context size is set to 0, position is
automatically also set to 0. If context size is positive, position is
automatically set to 1. Setting context size to -1 restores the default
behavior.

=end item1

=head1 AUTHORS

Ilya Martynov and Petr Pajas, based on LibXML and XML::LibXSLT code by Matt
Sergeant and Christian Glahn.


=head1 AUTHORS

Matt Sergeant, 
Christian Glahn, 
Petr Pajas, 

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
