use v6;
class LibXML::XPathContext {

    use LibXML::Native;
    use LibXML::Node :iterate, :XPathRange, :native, :NameVal;
    use LibXML::Document;
    use LibXML::XPathExpression;
    use LibXML::Types :QName;

    has xmlXPathContext $!native .= new;
    has LibXML::Node $!context-node;
    method native { $!native }

    submethod TWEAK(LibXML::Node :$node, LibXML::Document :$doc) {
        self.setContextNode($_) with $node // $doc;
    }

    submethod DESTROY {
        .Free with $!native;
    }

    multi method findnodes(LibXML::XPathExpression:D $xpath-expr, LibXML::Node $ref-node?) {
        my domNode $node = .native with $ref-node;
        my xmlNodeSet:D $node-set := $.native.findnodes( native($xpath-expr), $node);
        iterate(XPathRange, $node-set);
    }
    multi method findnodes(Str:D $expr, LibXML::Node $ref-node?) is default {
        $.findnodes( LibXML::XPathExpression.new(:$expr), $ref-node );
    }

    multi method find(LibXML::XPathExpression:D $xpath-expr, LibXML::Node $ref-node?, Bool:D :$bool = False, Bool :$values) {
        my domNode $node = .native with $ref-node;
        given  $.native.find( native($xpath-expr), $node, :$bool) {
            when xmlNodeSet:D { iterate(XPathRange, $_, :$values) }
            default { $_ }
        }
    }
    multi method find(Str:D $expr, LibXML::Node $ref-node?, |c) is default {
        $.find(LibXML::XPathExpression.parse($expr), $ref-node, |c);
    }

    multi method findvalue(LibXML::XPathExpression:D $xpath-expr, LibXML::Node $ref-node?, |c) {
        $.find( $xpath-expr, $ref-node, :values, |c);
    }
    multi method findvalue(Str:D $expr, LibXML::Node $ref-node?, |c) {
        $.findvalue(LibXML::XPathExpression.parse($expr), $ref-node, |c);
    }

    my subset XPathDomain where LibXML::XPathExpression|Str|Any:U;

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
}
