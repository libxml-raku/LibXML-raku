use v6;
class LibXML::XPathContext {

    use LibXML::Native;
    use LibXML::Node :iterate, :XPathRange, :native, :NameVal;
    use LibXML::Document;
    use LibXML::XPathExpression;
    use LibXML::Types :QName;

    has xmlXPathContext $!native;
    method native { $!native }

    multi submethod TWEAK(LibXML::Node :node($node-obj)!) {
        my xmlNode:D $node = .native given $node-obj;
        $!native .= new: :$node;
        die $_ with $node.domFailure;
    }
    multi submethod TWEAK(LibXML::Document :doc($doc-obj)!) {
        my xmlDoc:D $node = .native given $doc-obj;
        $!native .= new: :$node;
        die $_ with $node.domFailure;
    }
    submethod DESTROY {
        .Free with $!native;
    }

    multi method findnodes($expr, LibXML::Node:D $node) {
        temp $!native.node = .native with $node;
        $.findnodes($expr);
    }
    multi method findnodes(LibXML::XPathExpression:D $xpath-expr) {
        my xmlNodeSet:D $node-set := $.native.findnodes: native($xpath-expr);
        iterate(XPathRange, $node-set);
    }
    multi method findnodes(Str:D $expr) is default {
        $.findnodes(LibXML::XPathExpression.new: :$expr);
    }

    multi method find(LibXML::XPathExpression:D $xpath-expr, Bool:D $to-bool = False, Bool :$values) {
        given  $.native.find( native($xpath-expr), $to-bool) {
            when xmlNodeSet:D { iterate(XPathRange, $_, :$values) }
            default { $_ }
        }
    }
    multi method find(Str:D $expr, |c) is default {
        $.find(LibXML::XPathExpression.parse($expr), |c);
    }

    multi method findvalue(LibXML::XPathExpression:D $xpath-expr) {
        $.find( $xpath-expr, :values);
    }
    multi method findvalue(Str:D $expr) {
        $.findvalue(LibXML::XPathExpression.parse($expr));
    }

    my subset XPathDomain where LibXML::XPathExpression|Str|Any:U;

    multi method exists(XPathDomain:D $xpath-expr, LibXML::Node $node --> Bool:D) {
        temp $!native.node = .native with $node;
        $.exists($xpath-expr);
    }
    multi method exists(XPathDomain:D $xpath-expr --> Bool:D) {
        $.find($xpath-expr, True);
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
        LibXML::Node.box(.node) with $!native;
    }

    method setContextNode(LibXML::Node $_) {
        my domNode:D $node = do with $_ { .native } // $!native.doc;
        $!native.node = $node;
        die $_ with $node.domFailure;
        $_;
    }

    method contextNode is rw {
        Proxy.new(
            FETCH => { $.getContextNode },
            STORE => -> $, LibXML::Node $_ {
                $.setContextNode($_);
            }
        );
    }
}
