use v6;
use LibXML::ErrorHandling;
class LibXML::XPath::Context {

    use LibXML::Config;
    use LibXML::Document;
    use LibXML::Item :box-class;
    use LibXML::Native;
    use LibXML::Namespace;
    use LibXML::Node :iterate-set, :NameVal;
    use LibXML::Node::List;
    use LibXML::Node::Set;
    use LibXML::Types :QName;
    use LibXML::XPath::Expression;
    use LibXML::XPath::Object :XPathRange;
    use NativeCall;
    use Method::Also;

    has $.query-handler is rw = $LibXML::Config::QueryHandler;
    has LibXML::Node $!context-node;
    has xmlXPathContext $!native .= new;
    method native { $!native }

    # for the LibXML::ErrorHandling role
    use LibXML::ErrorHandling;
    use LibXML::_Options;
    has $.sax-handler is rw;
    has Bool ($.recover, $.suppress-errors, $.suppress-warnings) is rw;
    also does LibXML::_Options[%( :recover, :suppress-errors, :suppress-warnings)];
    also does LibXML::ErrorHandling;

    submethod TWEAK(LibXML::Node :$node, LibXML::Document :$doc,|c) {
        self.setContextNode($_) with $node // $doc;
    }

    submethod DESTROY {
        .Free with $!native;
    }

    my subset XPathExpr where LibXML::XPath::Expression|Str|Any:U;

    sub structured-error-cb(xmlXPathContext $ctx, xmlError:D $err) is export(:structured-error-cb) {
        CATCH { default { warn "error handling structured error: $_" } }
        $*XPATH-CONTEXT.structured-error($err);
    }
    method !try(&action) {
        my $rv;
        given xml6_gbl_save_error_handlers() {
            $!native.SetStructuredErrorFunc: &structured-error-cb;
            my $*XPATH-CONTEXT = self;
            $rv := &action();
            xml6_gbl_restore_error_handlers($_);
        }
        temp self.recover //= $rv.defined;
        self.flush-errors;
        $rv;
    }

    method !findnodes(LibXML::XPath::Expression:D $xpath-expr, LibXML::Node $ref --> xmlNodeSet) {
        my anyNode $node = .native with $ref;
        self!try: { $.native.findnodes( $xpath-expr.native, $node); }
    }
    method !find(LibXML::XPath::Expression:D $xpath-expr, LibXML::Node $ref-node?, Bool:D :$bool = False, Bool :$literal) {
        my anyNode $node = .native with $ref-node;
        my xmlXPathObject $xo := self!try: {$!native.find( $xpath-expr.native, $node, :$bool);}
        do with $xo {
            my $v := .value;
            if $v ~~ xmlNodeSet {
                if $literal {
                    if $v.defined {
                        given (0 ..^ $v.nodeNr).map({$v.nodeTab[$_].delegate.string-value}).join {
                            $v.Free;
                            $v := $_;
                        }
                    }
                    else {
                        $v := Str;
                    }
                } else {
                    $v := iterate-set(LibXML::Item, $v);
                }
            }
            $v;
        } else { fail "No value"; }
    }

    proto method findnodes($, $?, :deref($)) {*}
    multi method findnodes(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?, Bool :$deref) {
        iterate-set(LibXML::Item, self!findnodes($expr, $ref), :$deref);
    }
    multi method findnodes(Str:D $_, LibXML::Node $ref?, Bool :$deref) is default {
        my $expr = LibXML::XPath::Expression.new: :expr($_);
        iterate-set(LibXML::Item, self!findnodes($expr, $ref), :$deref);
    }
    sub box(itemNode $elem) {
        box-class(.type).box(.delegate)
            with $elem;
    }

    multi method first(Str:D $expr, LibXML::Node $ref?) {
        $.first(LibXML::XPath::Expression.new(:$expr), $ref);
    }
    multi method first(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?) {
        do with self!findnodes($expr, $ref) -> xmlNodeSet $nodes {
            my itemNode $node = $nodes.nodeTab[0] if $nodes.nodeNr;
            my $rv := box($node);
            $nodes.Free;
            $rv;
        } // LibXML::Node;
    }
    multi method last(Str:D $expr, LibXML::Node $ref?) {
        $.last(LibXML::XPath::Expression.new(:$expr), $ref);
    }
    multi method last(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?) {
        do with self!findnodes($expr, $ref) -> xmlNodeSet $nodes {
            my $n = $nodes.nodeNr;
            my itemNode $node = $nodes.nodeTab[$n - 1] if $n;
            my $rv := box($node);
            $nodes.Free;
            $rv;
        } // LibXML::Node;
    }
    method AT-KEY($_, Bool :$deref = True) {
        self.findnodes($_, :$deref);
    }

    sub get-value(xmlXPathObject $_, Bool :$literal) is export(:get-value) {
        do with $_ -> $native {
            my LibXML::XPath::Object $object .= new: :$native;
            $object.value: :$literal;
        } // fail "No value";
    }

    multi method find(LibXML::XPath::Expression $expr, LibXML::Node $ref-node?, |c) is default {
        self!find($expr, $ref-node, |c);
    }
    multi method find(Str:D $expr, LibXML::Node $ref-node?, |c) is default {
        self!find(LibXML::XPath::Expression.parse($expr), $ref-node, |c);
    }

    multi method findvalue(LibXML::XPath::Expression:D $xpath-expr, LibXML::Node $ref-node?, |c) {
        $.find( $xpath-expr, $ref-node, :literal, |c);
    }
    multi method findvalue(Str:D $expr, LibXML::Node $ref-node?, |c) {
        $.findvalue(LibXML::XPath::Expression.parse($expr), $ref-node, |c);
    }

    method exists(XPathExpr:D $xpath-expr, LibXML::Node $node? --> Bool:D) {
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

    # defining the context node
    multi method setContextNode(LibXML::Node:D $!context-node) {
        $!native.SetNode($!context-node.native);
        die $_ with $!context-node.domFailure;
        $!context-node;
    }

    # undefining the context node
    multi method setContextNode(LibXML::Node:U $!context-node) is default {
        $!native.SetNode(anyNode);
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
    method !stash(xmlNodeSet:D $native, xmlXPathParserContext :$ctxt --> xmlNodeSet:D) {
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
        self!stash: do given $node {
            when LibXML::Node::Set  { .native.copy }
            when LibXML::Node::List { xmlNodeSet.new: node => .native, :list;}
            when LibXML::Node       { xmlNodeSet.new: node => .native;}
            default { fail "unhandled node type: {.WHAT.perl}" }
        }, :$ctxt
    }
    multi method park(XPathRange:D $_) { $_ }
    subset Listy where List|Seq;
    multi method park(Listy:D $_, xmlXPathParserContext :$ctxt --> xmlNodeSet) {
        # create a node-set for a list of nodes
        my LibXML::Node:D @nodes = .List;
        my xmlNodeSet $set .= new;
        $set.push(.native) for @nodes;
        self!stash: $set, :$ctxt;
    }
    # anything else (Bool, Numeric, Str)
    multi method park($_) is default { fail "unexpected return value: {.perl}"; }

    method registerFunction(QName:D $name, &func, |c) {
        self.registerFunctionNS($name, Str, &func, |c);
    }

    sub xpath-callback-error(Exception $error) {
        CATCH { default { warn "error handling callback error: $_" } }
        $*XPATH-CONTEXT.callback-error: X::LibXML::XPath::AdHoc.new: :$error;
    }

    # Perl 5 compat
    method registerFunctionNS(QName:D $name, Str $url, &func, |c) {
        $!native.RegisterFuncNS(
            $name, $url,
            -> xmlXPathParserContext $ctxt, Int $n {
                CATCH { default { xpath-callback-error($_); } }
                my @params;
                @params.unshift: get-value($ctxt.valuePop) for 0 ..^ $n;
                my $ret = &func(|@params, |c) // '';
                my xmlXPathObject:D $out := xmlXPathObject.coerce: $*XPATH-CONTEXT.park($ret, :$ctxt);
                $ctxt.valuePush($_) for $out;
            }
        );
    }

    # same argument ordering as LibXSLT.register-function()
    method register-function(Str $url, QName:D $name, &func, |c) {
        $.registerFunctionNS($name, $url, &func, |c)
    }

    method registerVarLookupFunc(&func, |c) {
        $!native.RegisterVariableLookup(
            -> xmlXPathContext $ctxt, Str $name, Str $url --> xmlXPathObject:D {
                CATCH { default { xpath-callback-error($_); } }
                my $ret = &func($name, $url, |c) // '';
                xmlXPathObject.coerce: $*XPATH-CONTEXT.park($ret);
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

    method querySelector(Str() $selector, |c) {
        self.first: $!query-handler.query-to-xpath($selector);
    }

    method querySelectorAll(Str() $selector, |c) {
        self.find: $!query-handler.query-to-xpath($selector);
    }

}

=begin pod
=head1 NAME

LibXML::XPathContext - XPath Evaluation

=head1 SYNOPSIS

  use LibXML::XPathContext;
  use LibXML::Node;
  my LibXML::XPath::Context $xpc .= new();
  $xpc .= new(:$node, :suppress-warnings, :suppress-errors);
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
  $node = $xpc.first($xpath);
  $node = $xpc.last($xpath);
  my LibXML::Node::Set $nodes = $xpc.findnodes($xpath, $ref-node );
  my Any $object = $xpc.find($xpath );
  $object = $xpc.find($xpath, $ref-node );
  my $value = $xpc.findvalue($xpath );
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
functions written in Raku, and even a custom XPath variable resolver. 

=head1 EXAMPLES


=head2 Namespaces

This example demonstrates C<<<<<< registerNs() >>>>>> method. It finds all paragraph nodes in an XHTML document.



  my LibXML::XPath::Context $xc .= new: doc($xhtml-doc);
  $xc.registerNs('xhtml', 'http://www.w3.org/1999/xhtml');
  my LibXML::Node @nodes = $xc.findnodes('//xhtml:p');


=head2 Custom XPath functions

This example demonstrates C<<<<<< registerFunction() >>>>>> method by defining a function filtering nodes based on a Raku regular expression:

    sub grep-nodes(LibXML::Node::Set $nodes, Str $regex) {
        $nodes.grep: {.textContent ~~ / <$regex> /};
    };
    # -OR-
    sub grep-nodes(Array() $nodes, Str $regex) {
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

  my LibXML::XPath::Context $xpc .= new();

Creates a new LibXML::XPath::Context object without a context node.

  my LibXML::XPath::Context $xpc .= new: :$node;

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
Document, Element, etc.), L<<<LibXML::Node::Set>>> or L<<<LibXML::Node::List>>>. For convenience, types: List, Seq and Slip can also be returned
array references containing only L<<<<<< LibXML::Node >>>>>> objects can be used instead of an L<<<<<< LibXML::Node::Set >>>>>>.

Any additional arguments are captured and passed to the callback function. For example:

  $xpc.registerVarLookupFunc(&my-callback, 'Xxx', :%vars);

matches the signature:

sub my-callback(Str $name, Str $uri, 'Xxx', :%vars!) {
    ...
}

=end item1


=begin item1
registerFunctionNS

  $xpc.registerFunctionNS($name, $uri, &callback, |args);

Registers an extension function C<<<<<< $name >>>>>> in C<<<<<< $uri >>>>>> namespace. The arguments of the callback function are either
simple scalars or C<<<<<< LibXML::* >>>>>> objects depending on the XPath argument types.

The function must return one value: Bool, Str, Numeric, LibXML::Node (e.g.
Document, Element, etc.), L<<<LibXML::Node::Set>>> or L<<<LibXML::Node::List>>>. For convenience, types: List, Seq and Slip can also be returned
array references containing only L<<<<<< LibXML::Node >>>>>> objects can be used instead of an L<<<<<< LibXML::Node::Set >>>>>>.

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
array. In item context, returns an L<<<<<< LibXML::Node::Set >>>>>> object. Optionally, a node may be passed as a second argument to set the
context node for the query.

The xpath expression can be passed either as a string, or as a L<<<<<< LibXML::XPath::Expression >>>>>> object.

=end item1

=begin item1
first, last

    my LibXML::Node $body = $doc.first('body');
    my LibXML::Node $last-row = $body.last('descendant::tr');

The C<first> and C<last> methods are similar to C<findnodes>, except they return a single node representing the first or last matching row. If no nodes were found, C<LibXML::Node:U> is returned.

=end item1

=begin item1
find

  my Any $object = $xpc.find($xpath );

  $object = $xpc.find($xpath, $context-node );

Performs the xpath expression using the current node as the context of the
expression, and returns the result depending on what type of result the XPath
expression had. For example, the XPath C<<<<<< 1 * 3 + 	      52 >>>>>> results in a Numeric object being returned. Other expressions might return a Bool object, or a L<<<<<< LibXML::Literal >>>>>> object (a string). Optionally, a node may be passed as a
second argument to set the context node for the query.

The xpath expression can be passed either as a string, or as a L<<<<<< LibXML::XPath::Expression >>>>>> object.

=end item1

=begin item1
findvalue

  my Str $value = $xpc.findvalue($xpath );

  my Str $value = $xpc.findvalue($xpath, $context-node );

Is equivalent to:



  $xpc.find( $xpath, $context-node ).to-literal;

That is, it returns the literal value of the results. This enables you to
ensure that you get a string back from your search, allowing certain shortcuts.
This could be used as the equivalent of <xsl:value-of select=``some-xpath''/>.
Optionally, a node may be passed in the second argument to set the context node
for the query.

The xpath expression can be passed either as a string, or as a L<<<<<< LibXML::XPath::Expression >>>>>> object.

=end item1

=begin item1
exists

  my Bool $found = $xpc.exists( $xpath-expression, $context-node );

This method behaves like I<<<<<< findnodes >>>>>>, except that it only returns a Bool value (True if the expression matches a
node, False otherwise) and may be faster than I<<<<<< findnodes >>>>>>, because the XPath evaluation may stop early on the first match. 

For XPath expressions that do not return node-sets, the method returns True if
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

=begin item1
query-handler, querySelector, querySelectorAll

These methods provide pluggable support for CSS Selectors, as described
in https://www.w3.org/TR/selectors-api/#DOM-LEVEL-2-STYLE.

The query handler is a third-party class or object that implements a method `$.query-to-xpath(Str $selector --> Str) {...}`, that typically maps CSS selectors to XPath querys.

The handler may be configured globally:

    # set up a global query selector. use the CSS::Selector::To::XPath module
    use CSS::Selector::To::XPath;
    use LibXML::Config;
    LibXML::Config.query-handler = CSS::Selector::To::XPath.new;

    # run queries
    my LibXML::Document $doc .= new: string => q:to<\_(ツ)_/>;
      <table id="score">
        <thead>
          <tr>  <th>Test</th>     <th>Result</th> </tr>
        <thead>
        <tbody>
          <tr>  <td>A</td>        <td>87%</td>     </tr>
          <tr>  <td>B</td>        <td>78%</td>     </tr>
          <tr>  <td>C</td>        <td>81%</td>     </tr>
        </tbody>
        <tfoot>
          <tr>  <th>Average</th>  <td>82%</td>     </tr>
        </tfoot>
      </table>
    \_(ツ)_/

    my $result-query = "#score>tbody>tr>td:nth-of-type(2)"
    my @abc-results = $document.querySelectorAll($result-query);
    my $a-result = $document.querySelector($result-query);

=end item1

=begin item
set-options, suppress-warnings, suppress-errors

   my LibXML::XPath::Context $ctx .= new: :suppress-warnings;
   $ctx.suppress-errors = True;

XPath Contexts have some Boolean error handling options:

  =item C<suppress-warnings> - Don't report warnings
  =item C<suppress-errors> - Don't report or handle errors

=end item

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
