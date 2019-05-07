use v6;
class LibXML::XPathContext {

    use LibXML::Native;
    use LibXML::Node :iterate, :XPathRange, :unbox, :NameVal;
    use LibXML::Document;
    use LibXML::XPathExpression;
    use LibXML::Types :QName;

    has xmlXPathContext $!struct;
    method unbox { $!struct }

    multi submethod TWEAK(LibXML::Node :node($node-obj)!) {
        my xmlNode $node = .unbox with $node-obj;
        $!struct .= new: :$node;
    }
    multi submethod TWEAK(LibXML::Document :doc($doc-obj)!) {
        my xmlDoc $node = .unbox with $doc-obj;
        $!struct .= new: :$node;
    }
    submethod DESTROY {
        .Free with $!struct;
    }

    multi method findnodes(LibXML::XPathExpression:D $xpath-expr) {
        my xmlNodeSet:D $node-set := $.unbox.findnodes: unbox($xpath-expr);
        iterate(XPathRange, $node-set);
    }
    multi method findnodes(Str:D $expr) is default {
        $.findnodes(LibXML::XPathExpression.new: :$expr);
    }

    multi method find(LibXML::XPathExpression:D $xpath-expr, Bool:D $to-bool = False) {
        given  $.unbox.find( unbox($xpath-expr), $to-bool) {
            when xmlNodeSet:D { iterate(XPathRange, $_) }
            default { $_ }
        }
    }
    multi method find(Str:D $expr, |c) is default {
        $.find(LibXML::XPathExpression.new(:$expr), |c);
    }

    multi method findvalue(LibXML::XPathExpression:D $xpath-expr) {
        given $.unbox.find( unbox($xpath-expr), False) {
            with iterate(XPathRange, $_).pull-one {
                .string-value;
            }
            else {
                Str;
            }
        }
    }
    multi method findvalue(Str:D $expr) {
        $.findvalue(LibXML::XPathExpression.new: :$expr);
    }

    multi method registerNs(QName:D :$prefix!, Str :$uri) {
        $.registerNs($prefix, $uri);
    }
    multi method registerNs(QName:D $prefix!, Str $uri?) {
        my $stat = $uri
        ?? $.unbox.RegisterNs($prefix, $uri)
        !! $.unbox.RegisterNs($prefix, Str);
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
