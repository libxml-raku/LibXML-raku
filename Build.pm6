#! /usr/bin/env perl6
#Note `zef build .` will run this script
use v6;

class Build {
    need LibraryMake;
    # adapted from deprecated Native::Resources

    #| Sets up a C<Makefile> and runs C<make>.  C<$folder> should be
    #| C<"$folder/resources/lib"> and C<$libname> should be the name of the library
    #| without any prefixes or extensions.
    sub make(Str $folder, Str $destfolder, IO() :$libname!, Str :$I) {
        my %vars = LibraryMake::get-vars($destfolder);
        %vars<LIB-NAME> = ~ $*VM.platform-library-name($libname);
        if Rakudo::Internals.IS-WIN {
            unless $I {
                note "Using prebuilt DLLs on Windows";
                return True;
            }

            %vars<LIB-CFLAGS> = "-I$I";
            %vars<LIBS> = '-lxml2'; 
            %vars<MAKE> = 'make';
            %vars<CC> = 'gcc';
            %vars<CCFLAGS> = '-fPIC -O3 -DNDEBUG --std=gnu99 -Wextra -Wall';
            %vars<LD> = 'gcc';
            %vars<LDSHARED> = '-shared';
            %vars<LDFLAGS> = "-fPIC -O3 -Lresources/libraries";
            %vars<CCOUT> = '-o ';
            %vars<LDOUT> = '-o ';
        }
        else {
            %vars<LIBS> = chomp(qx{xml2-config --libs 2>/dev/null} || '-lxml2');
            %vars<LIB-CFLAGS>  = chomp(qx{xml2-config --cflags 2>/dev/null} || '-I/usr/include/libxml2');
            s/:s '-DNDEBUG'// for %vars<CCFLAGS>, %vars<LDFLAGS>;
        }

        mkdir($destfolder);
        LibraryMake::process-makefile($folder, %vars);
        shell(%vars<MAKE>);
        True;
    }

    method build($workdir, Str :$I) {
        my $destdir = 'resources/libraries';
        mkdir $destdir;
        make($workdir, "$destdir", :libname<xml6>, :$I);
        True;
    }
}

# Build.pm can also be run standalone
sub MAIN(Str $working-directory = '.', Str :$I ) {
    Build.new.build($working-directory, :$I);
}
