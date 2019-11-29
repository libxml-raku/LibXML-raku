use v6;
use Test;

use LibXML;
use LibXML::Schema;
use LibXML::InputCallback;
use LibXML::Element;

plan 16;

sub slurp(Str $_) { .IO.slurp }

my $xmlparser = LibXML.new();

my $file         = "test/schema/schema.xsd";
my $badfile      = "test/schema/badschema.xsd";
my $validfile    = "test/schema/demo.xml";
my $invalidfile  = "test/schema/invaliddemo.xml";
my $netfile      = "test/schema/net.xsd";

# 1 parse schema from a file
{
    my $schema = LibXML::Schema.new( location => $file );
    ok ( $schema.defined, 'Good LibXML::Schema was initialised' );

    dies-ok { $schema = LibXML::Schema.new( location => $badfile ); },  'Bad LibXML::Schema throws an exception.';
}

# 2 parse schema from a string
{
    my $string = slurp($file);

    my $schema = LibXML::Schema.new( string => $string );
    ok ( $schema, 'Schema initialized from string.' );

    $string = slurp($badfile);
    dies-ok { $schema = LibXML::Schema.new( string => $string ); }, 'Bad string schema throws an exception.';
}

# 3 validate a document
{
    my $doc       = $xmlparser.parse: :file( $validfile );
    my $schema = LibXML::Schema.new( location => $file );

    is-deeply $schema.is-valid( $doc ), True, 'is-valid on valid doc';
    my $valid = $schema.validate( $doc );
    is( $valid, 0, 'validate() returns 0 to indicate validity of valid file.' );

    $doc       = $xmlparser.parse: :file( $invalidfile );
    $valid     = 0;
    is-deeply $schema.is-valid( $doc ), False, 'is-valid on invalid doc';
    dies-ok { $valid = $schema.validate( $doc ); }, 'Invalid file throws an excpetion.';
}

# 4 validate a node
{
    my $doc = $xmlparser.load: string => q:to<EOF>;
<shiporder orderid="889923">
  <orderperson>John Smith</orderperson>
  <shipto>
    <name>Ola Nordmann</name>
  </shipto>
</shiporder>
EOF

    my $schema = LibXML::Schema.new(string => q:to<EOF>);
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="shiporder">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="orderperson" type="xs:string"/>
        <xs:element ref="shipto"/>
      </xs:sequence>
      <xs:attribute name="orderid" type="xs:string" use="required"/>
    </xs:complexType>
  </xs:element>
  <xs:element name="shipto">
    <xs:complexType>
      <xs:sequence>
        <xs:element name="name" type="xs:string"/>
      </xs:sequence>
    </xs:complexType>
  </xs:element>
</xs:schema>
EOF

    my LibXML::Element:D $node = $doc.first('/shiporder/shipto');
    my $result = 1;
    lives-ok { $result = $schema.validate($node) }, 'validate() with element doesn\'t throw';
    is( $result, 0, 'validate() with element returns 0' );
}

# 5 check that :network works

#  guard against actual network access attempts
my LibXML::InputCallback $input-callbacks .= new: :callbacks{
    :match(sub ($f) {return $f.IO.e }),
    :open(sub ($f)  {$f.IO.open(:r) }),
    :read(sub ($fh, $n) {$fh.read($n)}),
    :close(sub ($fh) {$fh.close}),
};
$input-callbacks.activate;

{
    my $schema = try { LibXML::Schema.new( location => $netfile ); };
    like( $!, /'I/O error : Attempt to load network entity'/, 'Schema from file location with external import throws an exception.' );
    nok( defined($schema), 'Schema from file location with external import and !network is not loaded.' );
}
{
    my $schema = try { LibXML::Schema.new( string => q:to<EOF>, :!network ) };
<?xml version="1.0" encoding="UTF-8"?>
<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <xsd:import namespace="http://example.com/namespace" schemaLocation="http://example.com/xml.xsd"/>
</xsd:schema>
EOF
    like( $!, /'I/O error : Attempt to load network entity'/, 'Schema from buffer with external import throws an exception.' );
    nok( defined($schema), 'Schema from buffer with external import and !network is not loaded.' );
}

{
    my $schema = try { LibXML::Schema.new( location => $netfile, :network, :suppress-warnings ); };
    ok ! $!.defined, "no exception";
}
{
    my $schema = try { LibXML::Schema.new( string => q:to<EOF>, :network, :suppress-warnings ) };
<?xml version="1.0" encoding="UTF-8"?>
<xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <xsd:import namespace="http://example.com/namespace" schemaLocation="http://example.com/xml.xsd"/>
</xsd:schema>
EOF
    ok ! $!.defined, "no exception";
}

$input-callbacks.deactivate;
