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
        my xmlNode $node = .native with $node-obj;
        $!native .= new: :$node;
    }
    multi submethod TWEAK(LibXML::Document :doc($doc-obj)!) {
        my xmlDoc $node = .native with $doc-obj;
        $!native .= new: :$node;
    }
    submethod DESTROY {
        .Free with $!native;
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
}
