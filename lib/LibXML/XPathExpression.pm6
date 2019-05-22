use v6;
class LibXML::XPathExpression {

    use LibXML::Native;
    has xmlXPathCompExpr $!native;
    method native { $!native }

    multi submethod TWEAK(Str:D :$expr!) {
        $!native .= new(:$expr);
        die "invalid xpath expression: $expr"
            without $!native;
    }
    submethod DESTROY {
        .Free with $!native;
    }

    method parse(Str:D $expr) {
        self.new: :$expr;
    }
}
