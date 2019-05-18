use v6;
class LibXML::XPathExpression {

    use LibXML::Native;
    has xmlXPathCompExpr $.native;

    submethod TWEAK(Str:D :$expr!) {
        $!native .= new(:$expr);
        die "invalid xpath expression: $expr"
            without $!native;
    }
    submethod DESTROY {
        .Free with $!native;
    }
}
