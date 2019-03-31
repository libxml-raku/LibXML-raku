use v6;
class LibXML::XPathExpression {

    use LibXML::Native;
    has xmlXPathCompExpr $!struct;
    method unbox { $!struct }

    submethod TWEAK(Str:D :$expr!) {
        $!struct .= new: :$expr;
    }
    submethod DESTROY {
        .Free with $!struct;
    }
}
