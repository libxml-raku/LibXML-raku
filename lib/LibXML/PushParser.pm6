class LibXML::PushParser {
    use LibXML::Native;
    use LibXML::Parser::Context;
    use LibXML::Document;

    has Bool $.html;
    has @!errors;
    has LibXML::Parser::Context $!ctx;
    has Int $.err = 0;

    multi submethod TWEAK(Str :chunk($str), |c) {
        my $chunk = $str.encode;
        self.TWEAK(:$chunk, |c);
    }

    multi submethod TWEAK(Blob :$chunk!, Str :$path, :$sax-handler, xmlEncodingStr :$enc, |c) {
        my \ctx-class = $!html ?? htmlPushParserCtxt !! xmlPushParserCtxt;
        my xmlSAXHandler $sax = .native with $sax-handler;
        my xmlParserCtxt:D $native = ctx-class.new: :$chunk, :$path, :$sax, :$enc;
        $!ctx .= new: :$native, |c;
    }

    method !parse-chunk(Blob $chunk = Blob.new, UInt :$size = +$chunk, Bool :$recover, Bool :$terminate = False) {
        $!ctx.try: :$recover, {
            with $!ctx.native {
                .ParseChunk($chunk, $size, +$terminate);
            }
            else {
                die "parser has been finished";
            }
        }
    }

    multi method push(Str $chunk, |c) {
        self!parse-chunk($chunk.encode, |c);
    }

    multi method push(Blob $chunk, |c) is default {
        self!parse-chunk($chunk, |c);
    }

    method finish-push(Str :$URI, Bool :$recover, :$sax-handler, |c) {
        self!parse-chunk: :terminate, :$recover, |c;
	die "XML not well-formed in xmlParseChunk"
            unless $recover || $!ctx.wellFormed;
        my xmlDoc $native = $!ctx.native.myDoc;
        my $doc := LibXML::Document.new( :$native, :$!ctx, :$URI);
        $!ctx = Nil;
        with $sax-handler {
            .publish($doc)
        }
        else {
            $doc;
        }
    }

}

=begin pod
=head1 NAME

LibXML::PushParser - LibXMl based push parser

=head1 SYNOPSIS


  # Perl 5 Interface
  use LibXML;
  use LibXML::Document;
  my LibXML $parser .= new;
  $parser.init-push();
  $parser.push($chunk);
  $parser.push(@more-chunks);
  my $doc = $parser.finish-push;

  # Raku
  use LibXML::Document;
  use LibXML::PushParser;
  my LibXML::PushParser $push-parser .= new(
      :$chunk, :$path, :$sax-handler, :$html, |%parser-opts
  );
  $push-parser.push($another-chunk);
  $push-parser.push(@more-chunks);
  my $doc = $parser.finish-push;

=head1 DESCRIPTION

LibXML::PushParser provides a push parser interface. Rather than pulling the data from a
given source the push parser waits for the data to be pushed into it.

This allows one to parse large documents without waiting for the parser to
finish. The interface is especially useful if a program needs to pre-process
the incoming pieces of XML (e.g. to detect document boundaries).

While the LibXML parse method require the data to be a well-formed XML, the
push parser will take any arbitrary string that contains some XML data. The
only requirement is that all the pushed strings are together a well formed
document. With the push parser interface a program can interrupt the parsing
process as required, where the parse-*() functions give not enough flexibility.

The push parser is not able to find out about the documents end itself. Thus the
calling program needs to indicate explicitly when the parsing is done.

An initial chunk is usually supply to the push parser `new` method as a Str or Blob
`:$chunk` option. This allows the push parser to detect encoding. Subsequent chunks
may be supplied as types Str or Blob.

=begin item1
parse-chunk

  $parser.parse-chunk($string?, :$terminate);
  $parser.parse-chunk($blob?, :$terminate);
  $parser.parse-chunks(@chunks, :$terminate);

parse-chunk() tries to parse a given chunk, or chunks of data, which isn't necessarily
well balanced data. The function takes two parameters: The chunk of data as a
Str or Blob and optional a termination flag. If the termination flag is set to a
True, the parsing will be stopped and the resulting document
will be returned as the following example describes:



  my  LibXML::PushParser $push-parser .= new: :chunk("<foo");
  for ' bar="hello world"', "/>" {
       $push-parser.parse-chunk( $_ );
  }
  my LibXML::Document $doc = $push-parser.finish-push; # terminate the parsing

=end item1

Internally LibXML provides three functions that control the push parser
process:

=begin item1
push

  $parser.push(@chunks);

This function pushes the data stored inside the array to libxml2's parser. Each
entry in @chunks must be a string! This method can be called repeatedly.

=end item1

=begin item1
finish-push

  $doc = $parser.finish-push( :$URI, :$recover );

This function returns the result of the parsing process. If this function is
called without a parameter it will complain about non well-formed documents. If
:$recover is True, the push parser can be used to restore broken or non well formed
(XML) documents as the following example shows:



  try {
      $parser.push( "<foo>", "bar" );
      $doc = $parser.finish-push();    # will report broken XML
  };
  if ( $! ) {
     # ...
  }

This can be annoying if the closing tag is missed by accident. The following code will restore the document:



  try {
      $parser.push( "<foo>", "bar" );
      $doc = $parser.finish-push(:recover);   # will return the data parsed
                                        # unless an error happened
  };
  
  print $doc.Str(); # returns "<foo>bar</foo>"

=end item1


=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
