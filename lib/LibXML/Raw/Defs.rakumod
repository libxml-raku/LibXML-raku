unit module LibXML::Raw::Defs;

our $XML2 is export(:XML2) = Rakudo::Internals.IS-WIN ?? find-library('libxml2') !! 'xml2';
our $BIND-XML2 is export(:BIND-XML2) = Rakudo::Internals.IS-WIN ?? find-library('xml6') !!  %?RESOURCES<libraries/xml6>;
our $CLIB is export(:CLIB) = Rakudo::Internals.IS-WIN ?? 'msvcrt' !! Str;

constant Opaque is export(:Opaque) = 'CPointer';
constant xmlCharP is export(:xmlCharP) = Str;
my constant XML_XMLNS_NS is export(:XML_XMLNS_NS) = 'http://www.w3.org/2000/xmlns/';
my constant XML_XML_NS is export(:XML_XML_NS) = 'http://www.w3.org/XML/1998/namespace';

sub find-library($base) {
    # unmangle library names, so xml6.dll can load libxml.dll 
    if my $file = %?RESOURCES{'libraries/' ~ $base} {
        my $tmpdir = $*SPEC.tmpdir ~ '/' ~ 'raku-libxml-' ~ $?DISTRIBUTION.meta<ver>;
        my $lib = $*VM.platform-library-name($base.IO);
        my $inst = ($tmpdir ~ '/' ~ $lib).IO;
        unless $inst.e && $inst.s == $file.IO.s {
            # install it
            note "installing: " ~ $inst.Str;
            mkdir $tmpdir;
            $file.copy($inst);
        }
        $inst;
    }
    else {
        $base
    }
}
