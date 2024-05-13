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
    with %?RESOURCES{'libraries/' ~ $base} -> Distribution::Resource $file {
        my $tmpdir = $*SPEC.tmpdir ~ '/' ~ 'raku-libxml-' ~ $?DISTRIBUTION.meta<ver>;
        my $lib = $*VM.platform-library-name($base.IO);
        my IO() $dest = $tmpdir ~ '/' ~ $lib;
	{
	    my $fh = $file.open;
	    $fh.lock: :shared;
            unless $dest.e && $dest.s == $file.IO.s {
                # install it
                note "installing: " ~ $dest.Str;
                mkdir $tmpdir;
                $file.IO.copy($dest);
	    }
	    LEAVE $fh.close;
        }
        $dest;
    }
    else {
        $base
    }
}
