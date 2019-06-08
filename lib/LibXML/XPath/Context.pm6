use v6;
class LibXML::XPath::Context {

    use LibXML::Native;
    use LibXML::Node :iterate, :NodeSetElem, :NameVal, :native;
    use LibXML::Document;
    use LibXML::Types :QName;
    use LibXML::Node::Set;
    use LibXML::XPath::Expression;
    use LibXML::XPath::Object :XPathRange;
    use NativeCall;

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

    multi method findnodes(LibXML::XPath::Expression:D $xpath-expr, LibXML::Node $ref-node?) {
        my domNode $node = .native with $ref-node;
        my xmlNodeSet $node-set := $.native.findnodes( native($xpath-expr), $node);
        .rethrow with @!callback-errors.tail;
        iterate(NodeSetElem, $node-set);
    }
    multi method findnodes(Str:D $expr, LibXML::Node $ref-node?) is default {
        $.findnodes( LibXML::XPath::Expression.new(:$expr), $ref-node );
    }

    method !select(xmlXPathObject $native, Bool :$values) {
        .rethrow with @!callback-errors.tail;
        my LibXML::XPath::Object $object .= new: :$native;
        $object.select: :$values;
    }

    multi method find(LibXML::XPath::Expression:D $xpath-expr, LibXML::Node $ref-node?, Bool:D :$bool = False, Bool :$values) {
        my domNode $node = .native with $ref-node;
        self!select: $!native.find( native($xpath-expr), $node, :$bool), :$values;
    }
    multi method find(Str:D $expr, LibXML::Node $ref-node?, |c) is default {
        $.find(LibXML::XPath::Expression.parse($expr), $ref-node, |c);
    }

    multi method findvalue(LibXML::XPath::Expression:D $xpath-expr, LibXML::Node $ref-node?, |c) {
        $.find( $xpath-expr, $ref-node, :values, |c);
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
    multi method registerNs(NameVal $_) {
        $.registerNs(.key, .value);
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
        $!native.domXPathCtxtSetNode(domNode);
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
                self.SetContextSize($size);
            }
        );
    }

    has %!pool{UInt}; # Keep objects alive, while they are on the stack
    my subset NodeObj where LibXML::Node::Set|LibXML::Node::List|LibXML::Node;
    multi method park(NodeObj:D $node, :$scope --> xmlNodeSet:D) {
        my UInt $c-addr = 0;
        with $scope {
            # scope to a particular parser/eval context
            $c-addr = +nativecast(Pointer, $_); # associated with a particular parse/eval
            # context stack is clear. We can also clear the associated pool
            %!pool{$c-addr} = %()
                if .valueNr == 0;
        }
        %!pool{$c-addr}{ +nativecast(Pointer, $node.native) } //= $node;
        # return a copied, or newly created native node-set
        given $node {
            when LibXML::Node::Set  { .native.copy }
            when LibXML::Node::List {
                my domNode:D $node = .native;
                my $keep-blanks = .keep-blanks;
                xmlNodeSet.new( :list, :$node, :$keep-blanks);
            }
            when LibXML::Node       { xmlNodeSet.new( node => .native );}
            default { fail "unhandled node type: {.WHAT.perl}" }
        }
    }
    # anything else (Bool, Numeric, Str)
    multi method park(XPathRange $_) is default { $_ }

    method registerFunction(QName:D $name, &func) {
        self.registerFunctionNS($name, Str, &func);
    }

    method registerFunctionNS(QName:D $name, Str $url, &func) {
        $!native.RegisterFuncNS(
            $name, $url,
            -> xmlXPathParserContext $ctxt, Int $n {
                CATCH { default { @!callback-errors.push: $_ } }
                my @params;
                @params.unshift: self!select($ctxt.valuePop) for 0 ..^ $n;
                my $ret = &func(|@params);
                my xmlXPathObject:D $out := xmlXPathObject.coerce: $.park($ret, :scope($ctxt));
                $ctxt.valuePush($_) for $out;
            }
        );
    }

    method registerVarLookupFunc(&func) {
        $!native.RegisterVariableLookup(
            -> xmlXPathContext $ctxt, Str $name, Str $url --> xmlXPathObject:D {
                CATCH { default { @!callback-errors.push: $_ } }
                my $ret = &func($name, $url);
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
            Mu;
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
