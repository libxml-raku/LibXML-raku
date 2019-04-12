use v6;
class LibXML::XPathContext {

    use LibXML::Native;
    use LibXML::Node :iterate, :XPathDomain, :XPathRange, :unbox;
    use LibXML::Document;
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

    method findnodes(XPathDomain:D $xpath-expr) {
        my xmlNodeSet:D $node-set := $.unbox.findnodes: unbox($xpath-expr);
        iterate(XPathRange, $node-set);
    }

    method find(XPathDomain:D $xpath-expr, Bool:D $to-bool = False) {
        given  $.unbox.find( unbox($xpath-expr), $to-bool) {
            when xmlNodeSet:D { iterate(XPathRange, $_) }
            default { $_ }
        }
    }

    method findvalue(XPathDomain:D $xpath-expr) {
        given $.unbox.find( unbox($xpath-expr), False) {
            with iterate(XPathRange, $_).pull-one {
                .string-value;
            }
            else {
                Str;
            }
        }
    }
}
