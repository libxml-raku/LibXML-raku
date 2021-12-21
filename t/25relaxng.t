use v6;

use Test;
use LibXML;
use LibXML::RelaxNG;

plan 5;

sub slurp(Str $_) { .IO.slurp }

my LibXML $xmlparser .= new();

my $file         = "test/relaxng/schema.rng";
my $badfile      = "test/relaxng/badschema.rng";
my $validfile    = "test/relaxng/demo.xml";
my $invalidfile  = "test/relaxng/invaliddemo.xml";
my $demo4        = "test/relaxng/demo4.rng";

subtest 'parse schema from a file', {
    my LibXML::RelaxNG $rngschema .= new( location => $file );
    ok $rngschema.defined;

    dies-ok { $rngschema .= new( location => $badfile ); }, 'parse of bad file';

}

subtest 'parse schema from a string', {
    my $string = slurp($file);

    my LibXML::RelaxNG $rngschema .= new( string => $string );
    ok $rngschema.defined;

    $string = slurp($badfile);

    dies-ok { $rngschema .= new( string => $string ); }, 'bad rng schema dies';
}

subtest 'parse schema from a document', {
    my LibXML::Document:D $doc       = $xmlparser.parse: :file( $file );
    my LibXML::RelaxNG $rngschema .= new( :$doc );
    ok $rngschema.defined;

    $doc       = $xmlparser.parse: :file( $badfile );
    dies-ok { $rngschema .= new( :$doc ); }, 'parse of invalid doc dies';
}

subtest 'validate a document', {
    my $doc       = $xmlparser.parse: :file( $validfile );
    my LibXML::RelaxNG $rngschema .= new( location => $file );

    is-deeply $rngschema.is-valid( $doc ), True, 'is-valid on valid doc';
    my $stat = 0;
    lives-ok { $stat = $rngschema.validate( $doc ); }, 'validate valid document';
    is $stat, 0;
    ok $doc.is-valid($rngschema);

    $doc  = $xmlparser.parse: :file( $invalidfile );
    dies-ok { $rngschema.validate( $doc ); }, 'validate invalid document';
    is-deeply $rngschema.is-valid( $doc ), False, 'is-valid on invalid doc';
    nok $doc.is-valid($rngschema);
}

subtest 're-validate a modified document', {
    my LibXML::RelaxNG $rng .= new(location => $demo4);
    my $seed_xml = q:to<EOXML>;
    <?xml version="1.0" encoding="UTF-8"?>
    <root/>
    EOXML

    my $doc = $xmlparser.parse: :string($seed_xml);
    my $rootElem = $doc.documentElement;
    my $bogusElem = $doc.createElement('bogus-element');

    dies-ok {$rng.validate($doc);}, 'unmodified (invalid) document dies';

    $rootElem.setAttribute('name', 'rootElem');
    lives-ok { $rng.validate($doc); }, 'modified (valid) document lives';

    $rootElem.appendChild($bogusElem);
    dies-ok {$rng.validate($doc);}, 'modified (invalid) document dies';

    $bogusElem.unlinkNode();
    lives-ok {$rng.validate($doc);}, 'modified (fixed) document lives';

    $rootElem.removeAttribute('name');
    dies-ok {$rng.validate($doc);}, 'modified (broken) document dies';
}
