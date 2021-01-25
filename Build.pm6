#! /usr/bin/env perl6
#Note `zef build .` will run this script
use v6;

class Build {
    need LibraryMake;
    # adapted from deprecated Native::Resources

    #| Sets up a C<Makefile> and runs C<make>.  C<$folder> should be
    #| C<"$folder/resources/lib"> and C<$libname> should be the name of the library
    #| without any prefixes or extensions.
    sub make(Str $folder, Str $destfolder, IO() :$libname!) {
        my %vars = LibraryMake::get-vars($destfolder);
        %vars<LIB-NAME> = ~ $*VM.platform-library-name($libname);
        if Rakudo::Internals.IS-WIN {
            %vars<LIB-LDFLAGS> = '-llibxml2 -liconv -lz';
            %vars<LIB-CFLAGS> = '-I/usr/include/libxml2';
        }
        else {
            %vars<LIB-LDFLAGS> = chomp(qx{xml2-config --libs 2>/dev/null} || '-lxml2');
            %vars<LIB-CFLAGS>  = chomp(qx{xml2-config --cflags 2>/dev/null} || '-I/usr/include/libxml2');
            s/:s '-DNDEBUG'// for %vars<CCFLAGS>, %vars<LDFLAGS>;
        }

        mkdir($destfolder);
        LibraryMake::process-makefile($folder, %vars);
        shell(%vars<MAKE>);
    }

    method build($workdir) {
        my $destdir = 'resources/libraries';
        mkdir $destdir;
        make($workdir, "$destdir", :libname<xml6>);
        True;
    }
}

# Build.pm can also be run standalone
sub MAIN(Str $working-directory = '.' ) {
    Build.new.build($working-directory);
}
