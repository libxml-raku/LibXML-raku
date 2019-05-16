use Test;

use LibXML;
use LibXML::Schema;

plan 8;

given LibXML.parser-version {
    when * < v20.51.0 {
        skip-rest "Skip No Schema Support compiled for libxml2 $_";
        exit;
    }
}

sub slurp(Str $_) { .IO.slurp }

my $xmlparser = LibXML.new();

my $file         = "test/schema/schema.xsd";
my $badfile      = "test/schema/badschema.xsd";
my $validfile    = "test/schema/demo.xml";
my $invalidfile  = "test/schema/invaliddemo.xml";


# 1 parse schema from a file
{
    my $rngschema = LibXML::Schema.new( location => $file );
    # TEST
    ok ( $rngschema.defined, 'Good LibXML::Schema was initialised' );

    dies-ok { $rngschema = LibXML::Schema.new( location => $badfile ); },  'Bad LibXML::Schema throws an exception.';
}

# 2 parse schema from a string
{
    my $string = slurp($file);

    my $rngschema = LibXML::Schema.new( string => $string );
    # TEST
    ok ( $rngschema, 'RNG Schema initialized from string.' );

    $string = slurp($badfile);
    dies-ok { $rngschema = LibXML::Schema.new( string => $string ); }, 'Bad string schema throws an exception.';
}

# 3 validate a document
{
    my $doc       = $xmlparser.parse: :file( $validfile );
    my $rngschema = LibXML::Schema.new( location => $file );

    my $valid = $rngschema.validate( $doc );
    # TEST
    is( $valid, 0, 'validate() returns 0 to indicate validity of valid file.' );

    $doc       = $xmlparser.parse: :file( $invalidfile );
    $valid     = 0;
    dies-ok { $valid = $rngschema.validate( $doc ); }, 'Invalid file throws an excpetion.';
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

    my $nodelist = $doc.findnodes('/shiporder/shipto');
    my $result = 1;
    lives-ok { $result = $schema.validate($nodelist[0]) }, 'validate() with element doesn\'t throw';
    # TEST
    is( $result, 0, 'validate() with element returns 0' );
}

