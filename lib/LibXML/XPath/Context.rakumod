#| XPath Evaluation Context
unit class LibXML::XPath::Context;

=begin pod
    =head2 Synopsis

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

    =head2 Description

    The LibXML::XPath::Context class provides an almost complete interface to
    libxml2's XPath implementation. With LibXML::XPath::Context, it is possible to
    evaluate XPath expressions in the context of arbitrary node, context size, and
    context position, with a user-defined namespace-prefix mapping, custom XPath
    functions written in Raku, and even a custom XPath variable resolver.

    =head2 Examples


    =head3 1. Namespaces

    This example demonstrates C<registerNs()> method. It finds all paragraph nodes in an XHTML document.

      my LibXML::XPath::Context $xc .= new: doc($xhtml-doc);
      $xc.registerNs('xhtml', 'http://www.w3.org/1999/xhtml');
      my LibXML::Node @nodes = $xc.findnodes('//xhtml:p');

   Alternatively, namespaces can be defined on the constructor:

      my LibXML::XPath::Context $xc .= new: doc($xhtml-doc), :ns{ xhtml => 'http://www.w3.org/1999/xhtml' };
      my LibXML::Node @nodes = $xc.findnodes('//xhtml:p');
                     
    =head3 2. Custom XPath functions

    This example demonstrates C<registerFunction()> method by defining a function filtering nodes based on a Raku regular expression:

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

    =head3 3. Variables

    This example demonstrates C<registerVarLookup()> method. We use XPath variables to recycle results of previous evaluations:

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
=end pod

use LibXML::Config;
use LibXML::Document;
use LibXML::Item;
use LibXML::Raw;
use LibXML::Namespace;
use LibXML::Node :iterate-set, :NameVal;
use LibXML::Node::List;
use LibXML::Node::Set;
use LibXML::Types :NCName, :QName;
use LibXML::XPath::Expression;
use LibXML::XPath::Object :XPathRange;
use NativeCall;
use Method::Also;

has $.sax-handler is rw;
has $.query-handler is rw = LibXML::Config.query-handler;
has xmlXPathContext $!raw .= new;
method raw { $!raw }

# for the LibXML::ErrorHandling role
use LibXML::ErrorHandling;
use LibXML::_Options;
has Bool ($.recover, $.suppress-errors, $.suppress-warnings) is rw;
also does LibXML::_Options[%( :recover, :suppress-errors, :suppress-warnings)];
also does LibXML::ErrorHandling;

my subset XPathExpr where LibXML::XPath::Expression|Str|Any:U;

=head2 Methods

multi submethod TWEAK(LibXML::Document:D :$doc!, :%ns) {
    self.setContextNode($doc);
    self.registerNs($_) for %ns.pairs;
}

multi submethod TWEAK(LibXML::Node :$node, :%ns) {
    self.setContextNode($_) with $node;
    self.registerNs($_) for %ns.pairs;
}

=head3 method new
  =begin code :lang<raku>
  multi method new(LibXML::Document :$doc!, *%opts) returns LibXML::XPath::Context;
  multi method new(LibXML::Node :$node, *%opts) returns LibXML::XPath::Context;
  =end code
  =para Creates a new LibXML::XPath::Context object with an optional context document or node.

  submethod DESTROY {
      with $!raw {
          .Unreference with .node;
          .Free;
      }
}

sub structured-error-cb(xmlXPathContext $ctx, xmlError:D $err) is export(:structured-error-cb) {
    CATCH { default { warn "error handling structured error: $_" } }
    $*XPATH-CONTEXT.structured-error($err);
}
method !try(&action) {
    my $rv;
    given xml6_gbl_save_error_handlers() {
        $!raw.SetStructuredErrorFunc: &structured-error-cb;
        my $*XPATH-CONTEXT = self;
        $rv := &action();
        xml6_gbl_restore_error_handlers($_);
    }
    temp self.recover //= $rv.defined;
    self.flush-errors;
    $rv;
}

my subset Zero of Int where 0;
multi method registerNs(QName:D :$prefix!, Str :$uri --> Zero) {
    $.registerNs($prefix, $uri);
}
multi method registerNs(QName:D $prefix!, Str $uri? --> Zero) {
    my $stat = self!try: {
        $uri
            ?? $!raw.RegisterNs($prefix, $uri)
            !! $!raw.RegisterNs($prefix, Str);
    }
    die "XPathContext: cannot {$uri ?? '' !! 'un'}register namespace"
       if $stat == -1;
    $stat;
}
multi method registerNs(NameVal:D $_ --> Zero) {
    $.registerNs(.key, .value);
}
multi method registerNs(LibXML::Namespace:D $_ --> Zero) {
    $.registerNs(.localname, .URI);
}
=head3 method registerNs
  =begin code :lang<raku>
  multi method registerNs(NCName:D :$prefix!, Str :$uri) returns 0
  multi method registerNs(NCName:D $prefix!, Str $uri?) returns 0
  multi method registerNs(LibXML::Namespace:D $ns) returns 0
  =end code
=para Registers a namespace with a given prefix and uri.
=para  A uri of Str:U will unregister any namespace with the given prefix.

multi method unregisterNs(NCName:D :$prefix!) {
    $.registerNs($prefix);
}
multi method unregisterNs(NCName:D $prefix!) {
    $.registerNs($prefix);
}
multi method unregisterNs(LibXML::Namespace:D $_ --> 0) {
    $.registerNs(.localname);
}
=head3 method unregisterNs
  =begin code :lang<raku>
  multi method unregisterNs(NCName:D :$prefix!) returns 0
  multi method unregisterNs(NCName:D $prefix!) returns 0
  multi method unregisterNs(LibXML::Namespace:D $ns) returns 0
  =end code
=para Unregisters a namespace with the given prefix

#| Returns namespace URI registered with $prefix.
method lookupNs(NCName:D $prefix --> Str) {
    $!raw.NsLookup($prefix);
}
=para If C<$prefix> is not registered to any namespace URI returns C<Str:U>.

#| Registers a variable lookup function.
method registerVarLookupFunc(&callback, |args) {
    $!raw.RegisterVariableLookup(
        -> xmlXPathContext $ctxt, Str $name, Str $url --> xmlXPathObject:D {
            CATCH { default { xpath-callback-error($_); } }
            my $ret = &callback($name, $url, |args) // '';
            xmlXPathObject.coerce: $*XPATH-CONTEXT.park($ret);
        },
        Pointer,
    );
}
=begin pod
    =para The registered function is executed by the XPath engine each time an XPath
    variable is evaluated. The callback function has two required arguments:
    `$name`, variable name, and `$uri`.

    The function must return one value: Bool, Str, Numeric, LibXML::Node (e.g.
    Document, Element, etc.), L<<<LibXML::Node::Set>>> or L<<<LibXML::Node::List>>>.

    For convenience, types: List, Seq and Slip can also be returned,
    these should contain only L<LibXML::Node> objects.

    Any additional arguments are captured and passed to the callback function. For example:
      =begin code :lang<raku>
      $xpc.registerVarLookupFunc(&my-callback, 'Xxx', :%vars);
      =end code
    matches the signature:
      =begin code :lang<raku>
      sub my-callback(Str $name, Str $uri, 'Xxx', :%vars!) {
        ...
      }
      =end code
=end pod

#| Removes the variable lookup function. Disables variable lookup
method unregisterVarLookupFunc {
    $!raw.RegisterVariableLookup(Pointer, Pointer);
}

#| Gets the current variable lookup function
method getVarLookupFunc returns Routine {
    do with $!raw.varLookupFunc {
        nativecast( :($ctxt, Str $name, Str $url --> xmlXPathObject:D), $_)
    } // Routine;
}

method varLookupFunc returns Routine is rw {
    Proxy.new(
        FETCH => { $.getVarLookupFunc },
        STORE => -> $, &func {
            $.registerVarLookupFunc(&func)
        }
    );
}

#| Registers an extension function $name in $uri namespace
method registerFunctionNS(QName:D $name, Str $uri, &func, |args) {
    $!raw.RegisterFuncNS(
        $name, $uri,
        -> xmlXPathParserContext $ctxt, Int $n {
            CATCH { default { xpath-callback-error($_); } }
            my @params;
            @params.unshift: get-value($ctxt.valuePop) for 0 ..^ $n;
            my $ret = &func(|@params, |args) // '';
            my xmlXPathObject:D $out := xmlXPathObject.coerce: $*XPATH-CONTEXT.park($ret, :$ctxt);
            $ctxt.valuePush($_) for $out;
        }
    );
}
=para The arguments of the callback function are either
    simple scalars or C<LibXML::*> objects depending on the XPath argument types.

=para The function must return one value: Bool, Str, Numeric, LibXML::Node (e.g.
    Document, Element, etc.), L<<<LibXML::Node::Set>>> or L<<<LibXML::Node::List>>>.

=para For convenience, types: List, Seq and Slip can also be returned, these shoulf contain only L<LibXML::Node> objects.

#| Unregisters extension function $name in $uri namespace.
method unregisterFunctionNS(QName:D $name, Str $uri) { $!raw.RegisterFuncNS($name, $uri, Pointer) }

#| Like registerFunctionNS; same argument order as LibXSLT.register-function()
method register-function(Str $url, QName:D $name, &func, |c) {
    $.registerFunctionNS($name, $url, &func, |c)
}

#| Same as registerFunctionNS but without a namespace.
method registerFunction(QName:D $name, &func, |c) {
    self.registerFunctionNS($name, Str, &func, |c);
}

#| Same as unregisterFunctionNS but without a namespace.
method unregisterFunction(QName:D $name) { $.unregisterFunctionNS($name, Str) }

method !findnodes(LibXML::XPath::Expression:D $xpath-expr, LibXML::Node $ref --> xmlNodeSet) {
    my anyNode $node = .raw with $ref;
    self!try: { $!raw.findnodes( $xpath-expr.raw, $node); }
}
method !find(LibXML::XPath::Expression:D $xpath-expr, LibXML::Node $ref-node?, Bool:D :$bool = False, Bool :$literal) {
    my anyNode $node = .raw with $ref-node;
    my xmlXPathObject $xo := self!try: {$!raw.find( $xpath-expr.raw, $node, :$bool);}
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

proto method findnodes($, $?, :deref($) --> LibXML::Node::Set) {*}
multi method findnodes(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?, Bool :$deref) {
    iterate-set(LibXML::Item, self!findnodes($expr, $ref), :$deref);
}
multi method findnodes(Str:D $_, LibXML::Node $ref?, Bool :$deref) is default {
    my $expr = LibXML::XPath::Expression.new: :expr($_);
    iterate-set(LibXML::Item, self!findnodes($expr, $ref), :$deref);
}
=begin pod
    =head3 method findnodes
      =begin code :lang<raku>
      multi method findnodes(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?, Bool :$deref) returns LibXML::Node::Set;
      multi method findnodes(Str:D $expr, LibXML::Node $ref?, Bool :$deref) returns LibXML::Node::Set;
      # Examples
      my LibXML::Node @nodes = $xpc.findnodes($xpath);
      @nodes = $xpc.findnodes($xpath, $context-node );
      my LibXML::Node::Set $nodes = $xpc.findnodes($xpath);
      for  $xpc.findnodes($xpath) { ... }
      =end code
    Performs the xpath statement on the current node and returns the result as an L<LibXML::Node::Set> object.

    Optionally, a node may be passed as a second argument to set the context node for the query.

    The xpath expression can be passed either as a string, or as a L<LibXML::XPath::Expression> object.
=end pod

proto method first($, $? --> LibXML::Item) {*}
multi method first(Str:D $expr, LibXML::Node $ref?) {
    $.first(LibXML::XPath::Expression.new(:$expr), $ref);
}
multi method first(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?) {
    my $rv = LibXML::Node;
    with self!findnodes($expr, $ref) -> xmlNodeSet $_ {
        $rv = LibXML::Item.box: .nodeTab[0]
           if .nodeNr;
        .Free;
    }
    $rv;
}
=head3 method first
  =begin code :lang<raku>
    multi method first(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?) returns LibXML::Item;
    multi method first(Str:D $expr, LibXML::Node $ref?) returns LibXML::Item;
    my LibXML::Node $body = $doc.first('body');
  =end code
=para The C<first> method is similar to C<findnodes>, except it returns
    a single node representing the first matching row. If no nodes were found,
    C<LibXML::Node:U> is returned.

proto method last($, $? --> LibXML::Item) {*}
multi method last(Str:D $expr, LibXML::Node $ref?) {
    $.last(LibXML::XPath::Expression.new(:$expr), $ref);
}
multi method last(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?) {
    do with self!findnodes($expr, $ref) -> xmlNodeSet $nodes {
        my $n := $nodes.nodeNr;
        my itemNode $node = $nodes.nodeTab[$n - 1] if $n;
        my $rv := LibXML::Item.box: $node;
        $nodes.Free;
        $rv;
    } // LibXML::Node;
}
=head3 method last
  =begin code :lang<raku>
    my LibXML::Node $last-row = $body.last('descendant::tr');
  =end code
=para The C<last> method is similar to C<first>, except it returns
    the last rather than the first matching row.

#| Alias for findnodes($_, :deref)
method AT-KEY($_, Bool :$deref = True --> LibXML::Node::Set) {
    self.findnodes($_, :$deref);
}
=para Example
    =begin code :lang<raku>
    my LibXML::XPath::Context $xpc .= new: :node($table-elem);
    for $xpc<tr> -> LibXML::Element $row-elem {...}
    =end code

proto sub get-value(xmlXPathObject, Bool :literal($)) is export(:get-value) {*}
multi sub get-value(xmlXPathObject:D $raw, Bool :$literal) {
    my LibXML::XPath::Object $object .= new: :$raw;
    $object.value: :$literal;
}
multi sub get-value(xmlXPathObject:U $, Bool :literal($))  {
    fail "No value";
}

multi method find(LibXML::XPath::Expression $expr, LibXML::Node $ref-node?, |c) {
    self!find($expr, $ref-node, |c);
}
multi method find(Str:D $expr, LibXML::Node $ref-node?, |c) {
    self!find(LibXML::XPath::Expression.parse($expr), $ref-node, |c);
}
=begin pod
    =head3 method find
      =begin code :lang<raku>
      multi method find(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?, Bool :$deref) returns Any;
      multi method find(Str:D $expr, LibXML::Node $ref?, Bool :$deref) returns Any;
      my Any $object = $xpc.find($xpath );
      $object = $xpc.find($xpath, $context-node );
      =end code
    Finds nodes or values.

    Performs the xpath expression using the current node as the context of the
    expression, and returns the result depending on what type of result the XPath
    expression had. For example, the XPath C<1 * 3 + 	      52> results in a Numeric object being returned. Other expressions might return a Bool object, or a string. Optionally, a node may be passed as a second argument to set the context node for the query.

    The xpath expression can be passed either as a string, or as a L<LibXML::XPath::Expression> object.
=end pod

multi method findvalue(LibXML::XPath::Expression:D $xpath-expr, LibXML::Node $ref-node?, |c) {
    $.find( $xpath-expr, $ref-node, |c, :literal);
}
multi method findvalue(Str:D $expr, LibXML::Node $ref-node?, |c) {
    $.findvalue(LibXML::XPath::Expression.parse($expr), $ref-node, |c);
}
=begin pod
    =head3 method findvalue
      =begin code :lang<raku>
      multi method findvalue(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?) returns Any;
      multi method findvalue(Str:D $expr, LibXML::Node $ref?) returns Any;
      =end code

    Returns only a simple value as string, numeric or boolean.

    An expression that would return an L<LibXML::Node::Set> is coerced by calling `string-value()` on each of its members and joing the result.

    This could be used as the equivalent of <xsl:value-of select=``some-xpath''/>.

    Optionally, a node may be passed in the second argument to set the context node
    for the query.

    The xpath expression can be passed either as a string, or as a L<LibXML::XPath::Expression> object.
=end pod

method exists(XPathExpr:D $xpath-expr, LibXML::Node $node? --> Bool:D) {
    $.find($xpath-expr, $node, :bool);
}
=head3 method exists
=begin code :lang<raku>
multi method exists(LibXML::XPath::Expression:D $expr, LibXML::Node $ref?) returns Bool;
multi method exists(Str:D $expr, LibXML::Node $ref?) returns Bool;
=end code
=para This method behaves like I<find>, except that it only returns a Bool value (True if the expression matches a
    node, False otherwise) and may be faster than I<find>, because the XPath evaluation may stop early on the first match.

=para For XPath expressions that do not return node-sets, the method returns True if
    the returned value is a non-zero number or a non-empty string.


method getContextNode {
    LibXML::Node.box: $!raw.node;
}

# defining the context node
multi method setContextNode(LibXML::Node:D $node) {
    $node.raw.Reference;
    .Unreference with $!raw.node;
    $!raw.SetNode($node.raw);
    die $_ with $node.domFailure;
    $node;
}

# undefining the context node
multi method setContextNode(LibXML::Node:U $node) {
    .Unreference with $!raw.node;
    $!raw.SetNode(anyNode);
    $node;
}

#| Set or get the context node
method contextNode is rw returns LibXML::Node {
    Proxy.new(
        FETCH => { $.getContextNode },
        STORE => -> $, LibXML::Node $_ {
            $.setContextNode($_);
        }
    );
}

method getContextPosition { $!raw.proximityPosition }
method setContextPosition(Int:D $pos) {
    fail "XPathContext: invalid position"
        unless -1 <= $pos <= $!raw.contextSize;
    $!raw.proximityPosition = $pos;
}

#| Set or get the current context position.
method contextPosition returns Int is rw {
    Proxy.new(
        FETCH => { self.getContextPosition },
        STORE => -> $, Int:D $pos {
            self.setContextPosition($pos)
        }
    );
}
=para By default, this value is -1 (and evaluating
    XPath function C<position()> in the initial context raises an XPath error), but can be set to any value up
    to context size. This usually only serves to cheat the XPath engine to return
    given position when C<position()> XPath function is called.
=para Setting this value to -1 restores the default behavior.

method getContextSize { $!raw.contextSize }
method setContextSize(Int:D $size) {
    fail "XPathContext: invalid size"
        unless -1 <= $size;
    $!raw.contextSize = $size;
    $!raw.proximityPosition = +($size <=> 0);
}

#| Set or get the current context size.
method contextSize returns Int is rw {
    Proxy.new(
        FETCH => { self.getContextSize },
        STORE => -> $, Int:D $size {
            self.setContextSize($size);
        }
    );
}
=para By default, this value is -1 (and evaluating
    XPath function C<last()> in the initial context raises an XPath error), but can be set to any
    non-negative value. This usually only serves to cheat the XPath engine to
    return the given value when C<last()> XPath function is called.
=item If context size is set to 0, position is
    automatically also set to 0.
=item If context size is positive, position is
    automatically set to 1. Setting context size to -1 restores the default
    behavior.

has %!pool{UInt}; # Keep objects alive, while they are on the stack
my subset NodeObj where LibXML::Node::Set|LibXML::Node::List|LibXML::Node;
method !stash(xmlNodeSet:D $raw, xmlXPathParserContext :$ctxt --> xmlNodeSet:D) {
    my UInt $ctxt-addr = 0;
    with $ctxt {
        # scope to a particular parser/eval context
        $ctxt-addr = +nativecast(Pointer, $_); # associated with a particular parse/eval
        # context stack is clear. We can also clear the associated pool
        %!pool{$ctxt-addr} = []
             if .valueNr == 0  && !.value.defined;
    }
    %!pool{$ctxt-addr}.push: LibXML::Node::Set.new: :$raw;
    $raw;
}
multi method park(NodeObj:D $node, xmlXPathParserContext :$ctxt --> xmlNodeSet:D) {
    # return a copied, or newly created raw node-set
    self!stash: do given $node {
        when LibXML::Node::Set  { .raw.copy }
        when LibXML::Node::List { xmlNodeSet.new: node => .raw, :list;}
        when LibXML::Node       { xmlNodeSet.new: node => .raw;}
        default { fail "unhandled node type: {.WHAT.perl}" }
    }, :$ctxt
}
multi method park(XPathRange:D $_) { $_ }
subset Listy where List|Seq;
multi method park(Listy:D $_, xmlXPathParserContext :$ctxt --> xmlNodeSet) {
    # create a node-set for a list of nodes
    constant NoRef = 0;
    my LibXML::Node:D @nodes = .List;
    my xmlNodeSet $set .= new;
    $set.push(.raw, NoRef) for @nodes;
    self!stash: $set, :$ctxt;
}
# anything else (Bool, Numeric, Str)
multi method park($_) is default { fail "unexpected return value: {.perl}"; }

sub xpath-callback-error(Exception $error) {
    CATCH { default { warn "error handling callback error: $_" } }
    $*XPATH-CONTEXT.callback-error: X::LibXML::XPath::AdHoc.new: :$error;
}

method querySelector(Str() $selector, |c) {
    self.first: $!query-handler.query-to-xpath($selector);
}

method querySelectorAll(Str() $selector, |c) {
    self.find: $!query-handler.query-to-xpath($selector);
}

=begin pod

=head3 methods query-handler, querySelector, querySelectorAll

These methods provide pluggable support for CSS Selectors, as described
in https://www.w3.org/TR/selectors-api/#DOM-LEVEL-2-STYLE.

The query handler is a third-party class or object that implements a method `$.query-to-xpath(Str $selector --> Str) {...}`, that typically maps CSS selectors to XPath querys.

The handler may be configured globally:
    =begin code :lang<raku>
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
    =end code

=head3 methods set-options, suppress-warnings, suppress-errors
  =begin code :lang<raku>
   my LibXML::XPath::Context $ctx .= new: :suppress-warnings;
   $ctx.suppress-errors = True;
  =end code
XPath Contexts have some Boolean error handling options:

  =item C<suppress-warnings> - Don't report warnings
  =item C<suppress-errors> - Don't report or handle errors


=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
