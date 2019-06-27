use v6;
use LibXML;
use LibXML::Document;
use LibXML::Node;
use LibXML::Enums;

class ChapterHandler {...}

# ------------------------------------------------------------------------- #
# (c) 2003 christian p. glahn
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# This is an example how to use the DOM interface of LibXML The
# script reads a XML File with a module specification. If the module
# contains several classes, the script fetches them and stores the
# data into different POD Files.
#
# Note this is just an example, to demonstrate how LibXML works.
# The code works for the LibXML documentation, but may not work
# for any other docbook file.
#
# If you are interested what the results are, check the README and the POD
# files shipped with LibXML.
# ------------------------------------------------------------------------- #

# ------------------------------------------------------------------------- #
# SYNOPSIS:
# xmllibxmldocs.pl $dokbook_file $targetdir
#
sub MAIN(Str $srcfile, Str $targetdir) {

    unless $targetdir.ends-with('/') {
        $targetdir ~= '/';
    }

    # -------------------------------------------------------------------------     #
    #
    # -------------------------------------------------------------------------     #
    # init the parser
    my LibXML $parser .= new: :!load-ext-dtd, :!keep-blanks;

    # ------------------------------------------------------------------------- #
    #
    # ------------------------------------------------------------------------- #
    # load the document into memory.
    my LibXML::Document $doc = $parser.parse: :file( $srcfile );
    # ------------------------------------------------------------------------- #
    #
    # ------------------------------------------------------------------------- #
    # good implementations would use XSLT to convert a docbook to any other
    # text format. Since the module does not presume libxslt installed, we
    # have to do the dirty job.
    my ChapterHandler $ch .= new: directory => $targetdir.IO;

    # ------------------------------------------------------------------------- #
    # init the common parts in all pods
    my ( $bookinfo ) = $doc.findnodes( "//bookinfo" );
    $ch.set_general_info( $bookinfo );
    # ------------------------------------------------------------------------- #

    # ------------------------------------------------------------------------- #
    # then process each chapter of the LibXML book
    my @chapters = $doc.findnodes( "//chapter" );
    for @chapters -> $chap {
        $ch.handle( $chap );
    }
    # ------------------------------------------------------------------------- #
    # ------------------------------------------------------------------------- #

    # ------------------------------------------------------------------------- #
    # the class to process our docbook file
    # ------------------------------------------------------------------------- #
}

class ChapterHandler {
    use LibXML;

    has IO::Path $.directory is required;
    has IO::Handle $!OFILE; # current output file
    has Str $!infoblock;
    # ------------------------------------------------------------------------- #

    # ------------------------------------------------------------------------- #
    # set_general_info
    # ------------------------------------------------------------------------- #
    # processes the bookinfo tag of LibXML to extract common information such
    # as version or copyright information
    method set_general_info(LibXML::Node $infonode) {
        return unless defined $infonode;

        my $infostr = "=head1 AUTHORS\n\n";
        my @authors = $infonode.findnodes( "authorgroup/author" );
        for @authors -> $author {
            my ( $node_fn ) = $author.getChildrenByTagName( "firstname" );
            my ( $node_sn ) = $author.getChildrenByTagName( "surname" );
            with $node_fn {
                $infostr ~= .string-value();
            }
            with $node_sn {
                $infostr ~= " " ~ .string-value();
            }
            with $author.nextSibling() {
                $infostr ~= ", \n";
            }
            else {
                $infostr ~= "\n\n";
            }
        }

    my ( $version ) = $infonode.findnodes( "edition" );
    with $version {
        $infostr ~= "\n=head1 VERSION\n\n" ~ .string-value() ~ "\n\n";
    }

    my @copyright = $infonode.findnodes( "copyright" );
    if @copyright {
        $infostr ~= "=head1 COPYRIGHT\n\n";
        for @copyright -> $copyright {
          my $node_y = $copyright.getChildrenByTagName( "year" );
          my $node_h = $copyright.getChildrenByTagName( "holder" );
          with $node_y {
            $infostr ~= .string-value() ~ ", ";
          }
          with $node_h {
            $infostr ~= .string-value();
          }
          $infostr ~= ".\n\n";
        }
        $infostr ~= "=cut\n";

        $infostr ~= "\n\n" ~ q:to<EOF>;
=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

EOF
    }

    $!infoblock = $infostr;
}

    # ------------------------------------------------------------------------- #
    # handle
    # ------------------------------------------------------------------------- #
    # This method opens the output file and decides how the chapter is
    # processed
    method handle(LibXML::Node:D $chapter) {

        my ( $abbr ) = $chapter.findnodes( "titleabbrev" );
        with $abbr {
            # create a new file.
            my $filename = $abbr.string-value();
            $filename .= trim();
            my $dir = $!directory;
warn $filename;

            $filename ~~ s:g/'LibXML'//;
            $filename ~~ s:g/^['-'|'::']//;   # remove the first colon or minus.
            $filename .= subst('::', '/', :g);     # transform remaining colons to paths.
            # the previous statement should work for existing modules. This could be
            # dangerous for nested modules, which do not exist at the time of writing
            # this code.

            unless $filename {
                $dir = "";
                $filename = "LibXML";
            }

            if $filename !~~ "README"|"LICENSE" {
                $filename ~= ".pod";
            }
            else {
                $dir = "";
            }

            warn [:$dir, :$filename].perl;
            $!OFILE = ($dir ~ $filename).IO.open(:w);

            if ( $abbr.string-value() eq "README"
                 or $abbr.string-value() eq "LICENSE" ) {

                # Text only chapters in the documentation
                $.dump_text( $chapter );
            }
            else {
                # print header
                # print synopsis
                # process the information itself
                # dump the info block
                $.dump_pod( $chapter );
                $!OFILE.print( $!infoblock );
            }
            # close the file
            $!OFILE.close();

            # Strip trailing space.
            my $text = ($dir~$filename).IO.slurp;
            $text ~~ s:g/[' '|\t]+$//;

            ($dir~$filename).IO.spurt: $text;
        }
    }

    # ------------------------------------------------------------------------- #
    # dump_text
    # ------------------------------------------------------------------------- #
    # convert the chapter into a textfile, such as README.
    method dump_text(LibXML::Node:D $chap) {

        if $chap.nodeName() eq "chapter" {
            my ( $title ) = $chap.getChildrenByTagName( "title" );
            my $str =  $title.string-value();
            my $len = chars $str;
            $!OFILE.print( uc($str) ~ "\n" );
            $!OFILE.print( "=" x $len );
            $!OFILE.print( "\n\n" );
        }

        for $chap.childNodes() -> $node {
            given $node.nodeName { 

                when "para" {
                    # we split at the last whitespace before 80 chars
                    my $string = $node.string-value();
                    my $os = "";
                    for $string.words -> $word {
                    if ( (chars( $os ) + chars( $word ) + 1) < 80 ) {
                        if ( chars $os ) { $os ~= " "; }
                        $os ~= $word;
                    }
                    else {
                        $!OFILE.print( $os ~ "\n" );
                        $os = $word;
                    }
                    }
                    $!OFILE.print( $os );
                    $!OFILE.print( "\n\n" );
                }

                when "sect1"  {
                    my ( $title ) = $node.getChildrenByTagName( "title" );
                    my $str = $title.string-value();
                    my $len = chars $str;

                    $!OFILE.print( "\n" ~ uc($str) ~ "\n" );
                    $!OFILE.print( "=" x $len );
                    $!OFILE.print( "\n\n" );
                    $.dump_text( $node );
                }

                when "sect2" {
                    my ( $title ) = $node.getChildrenByTagName( "title" );
                    my $str = $title.string-value();
                    my $len = chars $str;

                    $!OFILE.print( "\n" ~ $str ~ "\n" );
                    $!OFILE.print( "=" x $len );
                    $!OFILE.print( "\n\n" );
                    $.dump_text( $node );
                }

                when "itemizedlist" {
                    my @items = $node.findnodes( "listitem" );
                    my $sp = "  ";
                    for @items -> $item {
                        $!OFILE.print( "$sp o " );
                        my $str = $item.string-value();
                        $str .= trim();
                        $!OFILE.print( $str );
                        $!OFILE.print( "\n" );
                    }
                    $!OFILE.print( "\n" );
                }

                when "orderedlist" {
                    my @items = $node.findnodes( "listitem" );
                    my $i = 0;
                    my $sp= "  ";
                    for @items -> $item {
                        $i++;
                        $!OFILE.print( "$sp $i " );
                        my $str = $item.string-value();
                        $str .= trim();
                        $!OFILE.print( $str );
                        $!OFILE.print( "\n" );
                    }
                    $!OFILE.print( "\n" );
                }

                when "programlisting" {
                    my $str = $node.string-value();
                    $str ~~ s:g/\n/\n> /;
                    $!OFILE.print( "> " ~ $str );
                    $!OFILE.print( "\n\n" );
                }
            }
        }

        # ------------------------------------------------------------------------- #
        # dump_pod
        # ------------------------------------------------------------------------- #
        # This method is used to create the real POD files for LibXML. It is not
        # too sophisticated, but it already does quite a good job.
        method dump_pod(LibXML::Node:D $chap) {

            if $chap.nodeName() eq "chapter" {
                my ( $title ) = $chap.getChildrenByTagName( "title" );
                my ( $ttlabbr ) = $chap.getChildrenByTagName( "titleabbrev" );
                my $str =  $ttlabbr.string-value() ~ " - " ~ $title.string-value();
                $str .= trim();
                $!OFILE.print(  "=head1 NAME\n\n$str\n" );
                my ($synopsis) = $chap.findnodes( "sect1[title='Synopsis']" );
                my @funcs = $chap.findnodes( ".//funcsynopsis" );
                if $synopsis or +@funcs {
                    $!OFILE.print( "\n=head1 SYNOPSIS\n\n" )
                }
                if $synopsis {
                    $.dump_pod( $synopsis );
                }
                if +@funcs  {
                    for @funcs -> $s {
                        $.dump_pod( $s );
                    }
                    # $self.{OFILE}.print( "\n\n=head1 DESCRIPTION\n\n" );
                }
            }

            for $chap.childNodes() -> $node {
                if $node.nodeType == XML_TEXT_NODE | XML_CDATA_SECTION_NODE {
                    # we split at the last whitespace before 80 chars
                    my $prev_inline =
                    ($node.previousSibling and
                     $node.previousSibling.nodeName !~~ 'itemizedlist'|'orderedlist'|'variablelist'|'programlisting'|'funcsynopsis');
                    my $str = $node.data();
##                    $str=~s/(^|\n)[ \t]+($|\n)/$1$2/g;
                    if $str ~~ /\S/ {
                        my $string = $str;
                        my $space_before = ($string ~~ s:g/^\s+//) ?? $prev_inline !! False;
                        my $space_after = ? ($string ~~ s:g/\s+$//);
                        $!OFILE.print( " " ) if $space_before;
                        my $os = "";
                        for $string.words -> $word {
                            if ( (chars( $os ) + chars( $word ) + 1) < 80 ) {
                                if ( chars $os ) { $os ~= " "; }
                                $os ~= $word;
                            }
                            else {
                                $!OFILE.print( $os ~ "\n" );
                                $os = $word;
                            }
                        }
                        $os ~= " " if $space_after;
                        $!OFILE.print( $os );
                    }
                }
                else {
                    given $node.nodeName {
                        when "para" {
                            $.dump_pod( $node );
                            $!OFILE.print( "\n\n" );
                        }
                        when "sect1" {
                            my ( $title ) = $node.getChildrenByTagName( "title" );
                            my $str = $title.string-value();
                            unless $chap.nodeName eq "chapter" and $str eq 'Synopsis' {
                                warn :$str.perl;
                                $!OFILE.print( "\n=head1 " ~ uc($str) );
                                $!OFILE.print( "\n\n" );
                                $.dump_pod( $node );
                            }
                        }
                        when "sect2" {
                            my ( $title ) = $node.getChildrenByTagName( "title" );
                            my $str = $title.string-value();
                            my $len = chars $str;
                            
                            $!OFILE.print( "\n=head2 " ~ $str ~ "\n\n" );
                            
                            $.dump_pod( $node );
                        }
                        when "sect3" {
                            my ( $title ) = $node.getChildrenByTagName( "title" );
                            my $str = $title.string-value();
                            my $len = chars $str;

                            $!OFILE.print( "\n=head3 " ~ $str ~ "\n\n" );

                            $.dump_pod( $node );
                        }
                        when "itemizedlist" {
                            my @items = $node.findnodes( "listitem" );
                            $!OFILE.print( "\n=over 4\n\n" );
                            for @items -> $item {
                                $!OFILE.print( "=item *\n\n" );
                                $.dump_pod( $item );
                                $!OFILE.print( "\n\n" );
                            }
                            $!OFILE.print( "=back\n\n" );
                        }
                        when "orderedlist" {
                            my @items = $node.findnodes( "listitem" );
                            my $i = 0;
                            $!OFILE.print( "\n=over 4\n\n" );

                            for @items -> $item {
                                $i++;
                                $!OFILE.print( "=item $i.\n\n" );
                                $.dump_pod($item);
                                $!OFILE.print( "\n\n" );
                            }
                            $!OFILE.print( "=back\n\n" );
                        }
                        when "variablelist" {
                            $!OFILE.print( "=over 4\n\n" );
                            my @nodes = $node.findnodes( "varlistentry" );
                            $.dump_pod( $node );
                            $!OFILE.print( "\n=back\n\n" );
                        }
                        when "varlistentry" {
                            my ( $term ) = $node.findnodes( "term" );
                            $!OFILE.print( "=item " );
                            if ( defined $term ) {
                                $.dump_pod( $term );
                            }
                            $!OFILE.print( "\n\n" );
                            my @nodes =$node.findnodes( "listitem" );
                            for @nodes -> $it {
                                $.dump_pod( $it );
                            }
                            $!OFILE.print( "\n" );
                        }
                        when "programlisting" {
                            my $str = $node.string-value();
                            $str .= trim();
                            $str ~~ s:g/\n/\n  /;
                            #$str=~s/(^|\n)[ \t]+($|\n)/$1$2/g;
                            $!OFILE.print( "\n\n" );
                            $!OFILE.print( "  " ~ $str );
                            $!OFILE.print( "\n\n" );
                        }
                        when "funcsynopsis" {
                            if (($node.getAttribute('role')||'') ne 'synopsis') {
                                $.dump_pod($node);
                                $!OFILE.print( "\n" );
                            }
                        }
                        when "funcsynopsisinfo" {
                            my $str = $node.string-value() ;
                            $str ~~ s:g/\n/\n  /;
                            $!OFILE.print( "  $str\n" );
                        }
                        when "title"|"titleabbrev" {
                            # IGNORE
                        }
                        when "emphasis" {
                            my $str = $node.string-value() ;
                            $str ~~ s:g/\n/ /;
                            $str = pod_escape($str);
                            $!OFILE.print( "I<<<<<< $str >>>>>>" );
                        }
                        when "function"|"email"|"literal" {
                            my $str = $node.string-value() ;
                            $str ~~ s:g/\n/ /;
                            $str = pod_escape($str);
                            $!OFILE.print( "C<<<<<< $str >>>>>>" );
                        }
                        when "ulink" {
                            my $str = $node.string-value() ;
                            my $url = $node.getAttribute('url');
                            $str ~~ s:g/\n/ /;
                            if ($str eq $url) {
                                $!OFILE.print( "L<<<<<< $url >>>>>>" );
                            } else {
                                $!OFILE.print( "$str (L<<<<<< $url >>>>>>)" );
                            }
                        }
                        when "xref" {
                            my $linkend = $node.getAttribute('linkend');
                            my ($target) = $node.findnodes(qq{//*[\@id="$linkend"]/titleabbrev});
                            ($target) = $node.findnodes(qq{//*[\@id="$linkend"]/title}) unless $target;
                            if ($target) {
                                my $str = $target.string-value();
                                $str ~~ s:g/\n/ /;
                                $str = pod_escape($str);
                                $!OFILE.print( "L<<<<<< $str >>>>>>" );
                            } else {
                                warn "WARNING: Didn't find any section with id='$linkend'\n";
                                $!OFILE.print( "$linkend" );
                            }
                        }
                        when "olink" {
                            my $str = pod_escape($node.string-value());
                            my $url = $node.getAttribute('targetdoc');
                            if (!defined $url) {
                                warn $node.Str(:format),"\n";
                            }
                            $str ~~ s:g/\n/ /;
                            if $str eq $url {
                                $!OFILE.print( "L<<<<<< $url >>>>>>" );
                            } else {
                                $!OFILE.print( "$str (L<<<<<< $url >>>>>>)" );
                            }
                        }
                        default {
                            $*ERR.print: "Ignoring $_\n";
                            $.dump_pod($node);
                        }
                    }
                }
            }
        }
    }
    sub pod_escape($str) {
        $str.subst('>', '&gt;', :g).subst('<', '&lt;', :g);
    }
}

