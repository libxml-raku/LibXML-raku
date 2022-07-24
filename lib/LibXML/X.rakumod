use v6.d;

role LibXML::X is Exception { }

role LibXML::X::BadClass does LibXML::X {
    has Str:D $.class is required;
    has Str $.why;
    method message {
        "Bad LibXML $.what '$.class'" ~ |(": " ~ $_ with $.why)
    }
}

class LibXML::X::ClassName does LibXML::X::BadClass {
    has Str:D $.what = "class name";
}

class LibXML::X::Class does LibXML::X::BadClass {
    has Str:D $.what = "type object";
}

class LibXML::X::ArgumentType is X::TypeCheck does LibXML::X {
    has Str:D $.routine is required;
    method message {
        "Bad argument in call to $.routine: " ~ self.explain
    }
}