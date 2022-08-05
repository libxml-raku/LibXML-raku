use v6.d;

role X::LibXML is Exception { }

role X::LibXML::BadClass does X::LibXML {
    has Str:D $.class is required;
    has Str $.why;
    method message {
        "Bad LibXML $.what '$.class'" ~ |(": " ~ $_ with $.why)
    }
}

class X::LibXML::ClassName does X::LibXML::BadClass {
    has Str:D $.what = "class name";
}

class X::LibXML::Class does X::LibXML::BadClass {
    has Str:D $.what = "type object";
}

class X::LibXML::ArgumentType is X::TypeCheck does X::LibXML {
    has Str:D $.routine is required;
    method message {
        "Bad argument in call to $.routine: " ~ self.explain
    }
}