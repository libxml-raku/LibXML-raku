#!/usr/bin/perl

# This code used to generate a memory error in valgrind/etc.
# Testing it.

use Test;
use LibXML;
use LibXML::Reader;
use LibXML::Enums;

plan 2;

unless LibXML.have-reader {
    skip-rest "LibXML Reader not supported in this libxml2 build";
}


class Test::XML::Ordered {

    use LibXML::Reader;
    has LibXML::Reader $.expected is required;
    has LibXML::Reader $.got is required;
    has Str $.diag-message;
    has Bool $!expected-end = False;
    has Bool $!got-end = False;

    method !read-got {
        if $!got.native.read() <= 0 {
            $!got-end = True;
        }
    }

    method !read-expected {
        if $!expected.native.read() <= 0 {
            $!expected-end = True;
        }
    }

    method !next-elem {
        self!read-got();
        self!read-expected();
    }

    method !ns($elem) {
        $elem.namespaceURI() // ''
    }

    method !compare-loop {
        my &calc-prob = -> % ( :$param! ) {
            %( :!verdict, :$param )
        }

        while ! $!got-end && ! $!expected-end {
            my $type = $!got.nodeType();
            my $exp_type = $!expected.nodeType();

            if $type == XML_READER_TYPE_SIGNIFICANT_WHITESPACE {
                self!read-got();
            }
            elsif $exp_type == XML_READER_TYPE_SIGNIFICANT_WHITESPACE {
                self!read-expected();
            }
            else {
                if $type != $exp_type {
                    return &calc-prob({:param<nodeType>});
                }
                elsif $type == XML_READER_TYPE_TEXT {
                    my $got_text = $!got.value();
                    my $expected_text = $!expected.value();

                    for $got_text, $expected_text -> $t is rw {
                        $t ~~ s/^s+//;
                        $t ~~ s/\s+$//;
                        $t ~~ s:g/\s+/ /;
                    }
                    if $got_text ne $expected_text {
                        return &calc-prob({:param<text>});
                    }
                }
                elsif $type == XML_READER_TYPE_ELEMENT {
                    if $!got.name() ne $!expected.name() {
                        return &calc-prob({:param<element_name>});
                    }
                    if self!ns($!got) ne self!ns($!expected) {
                        return &calc-prob({:param<mismatch_ns>});
                    }
                }
                self!next-elem();
            }
        }

        return { verdict => 1};
    }

    method !get-diag-message($status_struct) {

        if ($status_struct<param> eq "nodeType") {
            return
                "Different Node Type!\n"
                ~ "Got: " ~ $!got.nodeType() ~ " at line " ~ $!got.lineNumber()
                ~ "\n"
                ~ "Expected: " ~ $!expected.nodeType() ~ " at line " ~ $!expected.lineNumber()
                ;
        }
        elsif ($status_struct<param> eq "text") {
            return
                "Texts differ: Got at " ~ $!got.lineNumber()~ " with value <<{$!got.value()}>> ; Expected at "~ $!expected.lineNumber() ~ " with value <<{$!expected.value()}>>.";
        }
        elsif ($status_struct<param> eq "element_name") {
            return
                "Got name: " ~ $!got.name()~ " at " ~ $!got.lineNumber() ~
                " ; " ~
                "Expected name: " ~ $!expected.name() ~ " at " ~$!expected.lineNumber();
        }
        elsif ($status_struct<param> eq "mismatch_ns") {
            return
                "Got Namespace: " ~ self!ns($!got)~ " at " ~ $!got.lineNumber() ~
                " ; " ~
                "Expected Namespace: " ~ self!ns($!expected) ~ " at " ~$!expected.lineNumber();
        }

        else
        {
            die "Unknown param";
        }
    }

    method compare {
        self!next-elem();

        my $status_struct = self!compare-loop();
        my $verdict = $status_struct<verdict>;

        if !$verdict {
            diag(self!get-diag-message($status_struct));
        }

        return ok($verdict, $.diag-message);
    }

    our sub is-xml-ordered(|c) {
        my $comparator =
            Test::XML::Ordered.new(|c);

        return $comparator.compare();
    }
}

my $xml_source = q:to<EOF>;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:fic="http://web-cpan.berlios.de/modules/XML-Grammar-Fortune/fiction-xml-0.2/">
  <head>
    <title>David vs. Goliath - Part I</title>
  </head>
  <body>
    <div class="fiction story" xml:id="index">
      <h1>David vs. Goliath - Part I</h1>
      <div class="fiction section" xml:id="top">
        <h2>The Top Section</h2>
        <p>
    King David and Goliath were standing by each other.
    </p>
        <p>
    David said unto Goliath: "I will shoot you. I <b>swear</b> I will"
    </p>
        <div class="fiction section" xml:id="goliath">
          <h3>Goliath's Response</h3>
          <p>
    Goliath was not amused.
    </p>
          <p>
    He said to David: "Oh, really. <i>David</i>, the red-headed!".
    </p>
          <p>
    David started listing Goliath's disadvantages:
    </p>
        </div>
      </div>
    </div>
  </body>
</html>
EOF

my $final_source = q:to<EOF>;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:fic="http://web-cpan.berlios.de/modules/XML-Grammar-Fortune/fiction-xml-0.2/">
  <head>
    <title>David vs. Goliath - Part I</title>
  </head>
  <body>
    <div class="fiction story" xml:id="index">
      <h1>David vs. Goliath - Part I</h1>
      <div class="fiction section" xml:id="top">
        <h2>The Top Section</h2>
        <p>
    King David and Goliath were standing by each other.
    </p>
        <p>
    David said unto Goliath: "I will shoot you. I <b>swear</b> I will"
    </p>
        <div class="fiction section" xml:id="goliath">
          <h3>Goliath's Response</h3>
          <p>
    Goliath was not amused.
    </p>
          <p>
    He said to David: "Oh, really. <i>David</i>, the red-headed!".
    </p>
          <p>
    David started listing Goliath's disadvantages:
    </p>
        </div>
      </div>
    </div>
  </body>
</html>
EOF

{
    my %opts = %( :!validation, :!load-ext-dtd );
    # TEST
    my LibXML::Reader $got .= new: :string($final_source), |%opts;
    my LibXML::Reader $expected .= new: :string($xml_source), |%opts;

    Test::XML::Ordered::is-xml-ordered( :$got, :$expected, :diag-message<foo> );
}

# TEST
ok(1, "Finished");
