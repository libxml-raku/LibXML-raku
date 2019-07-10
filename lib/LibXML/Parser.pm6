class LibXML::Parser {

    use LibXML::Config;
    use LibXML::Native;
    use LibXML::Enums;
    use LibXML::Document;
    use LibXML::PushParser;
    use LibXML::Parser::Context;
    use Method::Also;

    constant config = LibXML::Config;

    has Bool $.html;
    has Bool $.line-numbers is rw = False;
    has UInt $.flags is rw = XML_PARSE_NODICT +| XML_PARSE_DTDLOAD;
    has Str $.URI is rw;
    has $.sax-handler is rw;
    has $.input-callbacks is rw = config.input-callbacks;
    multi method input-callbacks is rw { $!input-callbacks }
    multi method input-callbacks($!input-callbacks) {}

    use LibXML::_Options;
    also does LibXML::_Options[
        %(
            :URI, :html, :line-numbers, :sax-handler, :input-callbacks,
            :clean-namespaces(XML_PARSE_NSCLEAN),
            :complete-attributes(XML_PARSE_DTDATTR),
            :dtd(XML_PARSE_DTDLOAD +| XML_PARSE_DTDVALID
                 +| XML_PARSE_DTDATTR +| XML_PARSE_NOENT),
            :expand-entities(XML_PARSE_NOENT),
            :expand-xinclude(XML_PARSE_XINCLUDE),
            :huge(XML_PARSE_HUGE),
            :load-ext-dtd(XML_PARSE_DTDLOAD),
            :no-base-fix(XML_PARSE_NOBASEFIX),
            :no-blanks(XML_PARSE_NOBLANKS),
            :no-keep-blanks(XML_PARSE_NOBLANKS),
            :no-cdata(XML_PARSE_NOCDATA),
            :no-def-dtd(HTML_PARSE_NODEFDTD),
            :no-network(XML_PARSE_NONET),
            :no-xinclude-nodes(XML_PARSE_NOXINCNODE),
            :old10(XML_PARSE_OLD10),
            :oldsax(XML_PARSE_OLDSAX),
            :pedantic-parser(XML_PARSE_PEDANTIC),
            :recover(XML_PARSE_RECOVER),
            :recover-quietly(XML_PARSE_RECOVER +| XML_PARSE_NOWARNING),
            :recover-silently(XML_PARSE_RECOVER +| XML_PARSE_NOERROR),
            :suppress-errors(XML_PARSE_NOERROR),
            :suppress-warnings(XML_PARSE_NOWARNING),
            :validation(XML_PARSE_DTDVALID),
            :xinclude(XML_PARSE_XINCLUDE),
        )];

    # Perl 5 compat
    multi method recover is rw {
        Proxy.new(
            FETCH => { 
                my $recover = $.get-flag($!flags, 'recover');
                $recover && $.get-flag($!flags, 'suppress-errors') ?? 2 !! $recover;
            },
            STORE => -> $, UInt() $v {
                $.set-flag($!flags, 'recover', $v >= 1);
                $.set-flag($!flags, 'suppress-errors', $v >= 2);
            }
        );
    }
    multi method recover($v) { $.recover = $v }

    method get-flags(:$html, *%opts) {
        my UInt $flags = $!flags;\
        $.set-flag($flags, 'load-ext-dtd', False)
            if $html;
        $.set-flags($flags, |%opts);

        $.set-flag($flags, 'dtd', False)
            unless $html || $flags +& XML_PARSE_DTDLOAD;

        $flags;
    }

    method !make-handler(parserCtxt :$native, *%opts) {
        my UInt $flags = self.get-flags(|%opts);
        LibXML::Parser::Context.new: :$native, :$flags, :$!line-numbers, :$!input-callbacks, :$.sax-handler;
    }

    method !publish(:$URI, LibXML::Parser::Context :$handler!, xmlDoc :$native = $handler.native.myDoc) {
        my LibXML::Document:D $doc .= new: :ctx($handler), :$native;
        $doc.URI = $_ with $URI;
        self.processXIncludes($doc, :$handler)
            if $.expand-xinclude;
        $doc;
    }

    method processXIncludes (
        LibXML::Document $_,
        LibXML::Parser::Context:D :$handler = self!make-handler(:native(xmlParserCtxt.new)),
        *%opts --> Int)
    is also<process-xincludes> {
        my xmlDoc $doc = .native;
        my $flags = self.get-flags(|%opts);
        $handler.try: { $doc.XIncludeProcessFlags($flags) }
    }

    method load(|c) {
        my $obj = do with self { .clone } else { .new };
        $obj.parse(|c);
    }

    multi method parse(Str:D() :$string!,
                       Bool() :$html = $!html,
                       Str() :$URI = $!URI,
                       xmlEncodingStr :$enc = 'UTF-8',
                       *%opts 
                      ) {

        # gives better diagnositics

        my LibXML::Parser::Context $handler = self!make-handler: :$html, |%opts;

        $handler.try: {
            my parserCtxt:D $ctx = $html
            ?? htmlMemoryParserCtxt.new: :$string, :$enc
            !! xmlMemoryParserCtxt.new: :$string;

            $ctx.input.filename = $_ with $URI;
            $handler.native = $ctx;
            $ctx.ParseDocument;
        };
        self!publish: :$handler;
    }

    multi method parse(Blob:D :$buf!,
                       Bool() :$html = $!html,
                       Str() :$URI = $!URI,
                       xmlEncodingStr :$enc = 'UTF-8',
                       *%opts,
                      ) {

        my parserCtxt:D $ctx = $html
           ?? htmlMemoryParserCtxt.new(:$buf, :$enc)
           !! xmlMemoryParserCtxt.new(:$buf, :$enc);

        $ctx.input.filename = $_ with $URI;

        my LibXML::Parser::Context $handler = self!make-handler: :native($ctx), :$html, |%opts;
        $handler.try: { $ctx.ParseDocument };
        self!publish: :$handler;
    }

    multi method parse(IO() :$file!,
                       Bool() :$html = $!html,
                       xmlEncodingStr :$enc,
                       Str :$URI = $!URI,
                       *%opts,
                      ) {
        my LibXML::Parser::Context $handler = self!make-handler: :$html, |%opts;

        $handler.try: {
            my parserCtxt $ctx = $html
               ?? htmlFileParserCtxt.new(:$file, :$enc)
               !! xmlFileParserCtxt.new(:$file);
            die "unable to load file: $file"
                without $ctx;
            $handler.native = $ctx;
            $ctx.ParseDocument;
        };

        self!publish: :$URI, :$handler;
    }

    multi method parse(UInt :$fd!,
                       Str :$URI = $!URI,
                       Bool() :$html = $!html,
                       xmlEncodingStr :$enc,
                       *%opts,
                      ) {

        my LibXML::Parser::Context $handler = self!make-handler: :$html, |%opts;
        my UInt $flags = self.get-flags(|%opts, :$html);
        my xmlDoc $native;

        $handler.try: {
            my parserCtxt $ctx = $html
               ?? htmlParserCtxt.new
               !! xmlParserCtxt.new;
            $handler.native = $ctx;
            $native = $ctx.ReadFd($fd, $URI, $enc, $flags);
        };

        self!publish: :$handler, :$native;
    }

    multi method parse(IO::Handle :$io!,
                       Str :$URI = $io.path.path,
                       |c) {
        my UInt:D $fd = $io.native-descriptor;
        self.parse( :$fd, :$URI, |c);
    }

    multi method parse(IO() :io($path)!, |c) {
        my IO::Handle $io = $path.open(:bin, :r);
        $.parse(:$io, |c);
    }

    multi method parse(Str() :location($file)!, |c) {
        $.parse(:$file, |c);
    }

    # parse from a Miscellaneous source
    multi method parse(Any:D $src, |c) is default {
        my Pair $in = do with $src {
            when UInt       { :fd($_) }
            when IO::Handle
            |    IO::Path   { :io($_) }
            when Blob       { :buf($_) }
            when Str  { m:i:s/^ '<'/ ?? :string($_) !! :file($_) }
            default { fail "Unrecognised parser input: {.perl}"; }
        }
        $.parse( |$in, |c );
    }

    has LibXML::PushParser $!push-parser;
    method init-push { $!push-parser = Nil }
    multi method push(Str() $chunk) {
        with $!push-parser {
            .push($chunk);
        }
        else {
            $_ .= new: :$chunk, :$!html, :$!flags, :$!line-numbers, :$.sax-handler;
        }
    }
    multi method push(@chunks) is default { self.push($_) for @chunks }
    method parse-chunk($chunk?, :$terminate) {
        $.push($_) with $chunk;
        $.finish-push
            if $terminate;
    }
    method finish-push (
        Str :$URI = $!URI,
        Bool :$recover = $.recover,
    )
    {
        with $!push-parser {
            my $doc := .finish-push(:$URI, :$recover);
            $_ = Nil;
            $doc;
        }
        else {
            die "no active push parser";
        }
    }

    method parse-balanced(Str() :$string!, LibXML::Document :$doc) {
        use LibXML::DocumentFragment;
        my LibXML::DocumentFragment $frag .= new: :$doc;
        my UInt $ret = $frag.parse: :balanced, :$string, :$.sax-handler, :$.keep-blanks;
        $frag;
    }

    method load-catalog(Str:D $filename) {
        xmlLoadCatalog($filename);
    }

    submethod TWEAK(Str :$catalog, :html($), :line-numbers($), :flags($) = 0, :URI($), :sax-handler($), :build-sax-handler($), :input-callbacks($), *%opts) {
        self.load-catalog($_) with $catalog;
        $!flags = self.get-flags(|%opts);
    }

    method FALLBACK($key, |c) is rw {
        $.option-exists($key)
            ?? $.option($key, |c)
            !! die X::Method::NotFound.new( :method($key), :typename(self.^name) );
    }

}

=begin pod
=head1 NAME

LibXML::Parser - Parsing XML Data with LibXML

=head1 SYNOPSIS



  use LibXML;

  # Parser constructor
  
  my LibXML $parser .= new: |%opts;
  
  # Parsing XML
  
  $dom = LibXML.load(
      location => $file-or-url
      # parser options ...
    );
  $dom = LibXML.load(
      string => $xml-string
      # parser options ...
    );
  $dom = LibXML.load-xml({
      io => $perl-file-handle
      # parser options ...
    );
  $dom = $parser.load-xml(...);
  			  
  # Parsing HTML
  
  $dom = LibXML.load-html(...);
  $dom = $parser.load-html(...);
  			  
  # Parsing well-balanced XML chunks
  			       
  $fragment = $parser.parse-balanced-chunk( $wbxmlstring, $encoding );
  
  # Processing XInclude
  
  $parser.process-xincludes( $doc );
  $parser.processXIncludes( $doc );
  
  # Old-style parser interfaces
  			       
  $doc = $parser.parse-file( $xmlfilename );
  $doc = $parser.parse-fh( $io-fh );
  $doc = $parser.parse-string( $xmlstring);
  $doc = $parser.parse-html-file( $htmlfile, \%opts );
  $doc = $parser.parse-html-fh( $io-fh, \%opts );
  $doc = $parser.parse-html-string( $htmlstring, \%opts );
  
  # Push parser
  			    
  $parser.parse-chunk($string, $terminate);
  $parser.init-push();
  $parser.push(@data);
  $doc = $parser.finish-push( $recover );
  
  # Set/query parser options
                      
  $parser.option-exists($name);
  $parser.get-option($name);
  $parser.set-option($name,$value);
  $parser.set-options({$name=>$value,...});
  
  # XML catalogs
                      
  $parser.load-catalog( $catalog-file );

=head1 PARSING

An XML document is read into a data structure such as a DOM tree by a piece of
software, called a parser. LibXML currently provides four different parser
interfaces:

=item1 * A DOM Pull-Parser

=item1 * A DOM Push-Parser

=item1 * A SAX Parser

=item1 * A DOM based SAX Parser.


=head2 Creating a Parser Instance

LibXML provides an OO interface to the libxml2 parser functions. Thus you have
to create a parser instance before you can parse any XML data.

=begin item1
new

  
  $parser = LibXML.new();
  $parser = LibXML.new(option=>value, ...);
  $parser = LibXML.new({option=>value, ...});

Create a new XML and HTML parser instance. Each parser instance holds default
values for various parser options. Optionally, one can pass a hash reference or
a list of option => value pairs to set a different default set of options.
Unless specified otherwise, the options C<<<<<< load-ext-dtd >>>>>>, and C<<<<<< expand-entities >>>>>> are set to 1. See L<<<<<< Parser Options >>>>>> for a list of libxml2 parser's options. 

=end item1


=head2 DOM Parser

One of the common parser interfaces of LibXML is the DOM parser. This parser
reads XML data into a DOM like data structure, so each tag can get accessed and
transformed.

LibXML's DOM parser is not only capable to parse XML data, but also (strict)
HTML files. There are three ways to parse documents - as a string, as a Perl
filehandle, or as a filename/URL. The return value from each is a L<<<<<< LibXML::Document >>>>>> object, which is a DOM object.

All of the functions listed below will throw an exception if the document is
invalid. To prevent this causing your program exiting, wrap the call in a
try {} block

=begin item1
load

  my LibXML::Document $dom;

  $dom = LibXML.load(
      location => $file-or-url,
      :$html, :$URI, :$enc,
      # parser options ...
    );
  $dom = LibXML.load(
      string => $xml-string,
      :$html, :$URI, :$enc,
      # parser options ...
    );
  $dom = LibXML.load(
      io => $perl-path-or-file-handle,
      :$html, :$URI, :$enc,
      # parser options ...
    );
  $dom = LibXML.load(
      buf => $perl-blob-or-buf,
      :$html, :$URI, :$enc,
      # parser options ...
    );
  $dom = LibXML.load(
      fd => $file-descriptor-num,
      :$html, :$URI, :$enc,
      # parser options ...
    );
  $dom = LibXML.load( $src, :$html, :$URI, :$enc,
      # parser options ...
  );
  $dom = $parser.load(...);
  			  

This function provides an easy to use interface
to the XML parser that parses given file (or URL), string, or input stream to a
DOM tree. The arguments can be passed in a HASH reference or as name => value
pairs. The function can be called as a class method or an object method. In
both cases it internally creates a new parser instance passing the specified
parser options; if called as an object method, it clones the original parser
(preserving its settings) and additionally applies the specified options to the
new parser. See the constructor C<<<<<< new >>>>>> and L<<<<<< Parser Options >>>>>> for more information. 

=end item1

=begin item1
load: :html

  
  $dom = LibXML.load: :html, ...;
  $dom = $parser.load: :html, ...;
  			  

The :html option provides an interface to the HTML parser.

=end item1

Parsing HTML may cause problems, especially if the ampersand ('&') is used.
This is a common problem if HTML code is parsed that contains links to
CGI-scripts. Such links cause the parser to throw errors. In such cases libxml2
still parses the entire document as there was no error, but the error causes
LibXML to stop the parsing process. However, the document is not lost. Such
HTML documents should be parsed using the I<<<<<< recover >>>>>> flag. By default recovering is deactivated.

The functions described above are implemented to parse well formed documents.
In some cases a program gets well balanced XML instead of well formed documents
(e.g. an XML fragment from a database). With LibXML it is not required to wrap
such fragments in the code, because LibXML is capable even to parse well
balanced XML fragments.

=begin item1
parse-balanced

  $fragment = $parser.parse-balanced( string => $wbxmlstring );

This function parses a well balanced XML string into a L<<<<<< LibXML::DocumentFragment >>>>>>. The string argument contains the input XML string.

=end item1

By default LibXML does not process XInclude tags within an XML Document (see
options section below). LibXML allows one to post-process a document to expand
XInclude tags.

=begin item1
process-xincludes

  $parser.process-xincludes( $doc );

After a document is parsed into a DOM structure, you may want to expand the
documents XInclude tags. This function processes the given document structure
and expands all XInclude tags (or throws an error) by using the flags and
callbacks of the given parser instance.

Note that the resulting Tree contains some extra nodes (of type
XML_XINCLUDE_START and XML_XINCLUDE_END) after successfully processing the
document. These nodes indicate where data was included into the original tree.
if the document is serialized, these extra nodes will not show up.

Remember: A Document with processed XIncludes differs from the original
document after serialization, because the original XInclude tags will not get
restored!

If the parser flag "expand-xincludes" is set to True, you need not to post process
the parsed document.

=end item1

=begin item1
processXIncludes

  $parser.processXIncludes( $doc );

This is an alias to process-xincludes, but through a JAVA like function name.

=end item1

=begin item1
parse: :file

  $doc = $parser.parse: :file( $xmlfilename );

The :file option parses an XML document from a file or network; $xmlfilename can be either a filename or an URL.

=end item1

=begin item1
parse: :io

  $doc = $parser.parse: :io( $io-fh );

parse: :io parses an IO::Handle object.

=end item1

=begin item1
parse: :string

  $doc = $parser.parse: :string( $xmlstring);

This function parses an XML document that is
available as a single string in memory. You can pass an optional base URI string to the function.



  my $doc = $parser.parse: :string($xmlstring);
  my $doc = $parser.parse: :string($xmlstring), :$URI;

=end item1

=begin item1
parse: :html

  $doc = $parser.parse: :html, :file( $htmlfile) , |%opts;
  $doc = $parser.parse: :html, :io($io-fh), |%opts;
  $doc = $parser.parse: :html: :string($htmlstring), |%opts;
  # etc..

=end item1

=head2 Push Parser

LibXML provides a push parser interface. Rather than pulling the data from a
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

In LibXML this is done by a single function:

=begin item1
parse-chunk

  $parser.parse-chunk($string?, :$terminate);

parse-chunk() tries to parse a given chunk of data, which isn't necessarily
well balanced data. The function takes two parameters: The chunk of data as a
string and optional a termination flag. If the termination flag is set to a
True, the parsing will be stopped and the resulting document
will be returned as the following example describes:



  my  LibXML $parser .= new;
  for "<", "foo", ' bar="hello world"', "/>" -> $string {
       $parser.parse-chunk( $string );
  }
  my $doc = $parser.parse-chunk(:$terminate); # terminate the parsing

=end item1

Internally LibXML provides three functions that control the push parser
process:

=begin item1
init-push

  $parser.init-push();

Initializes the push parser.

=end item1

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
  
  print $doc.St(); # returns "<foo>bar</foo>"

Of course finish-push() will return nothing if there was no data pushed to the
parser before.

=end item1


=head2 Pull Parser (Reader)

LibXML also provides a pull-parser interface similar to the XmlReader interface
in .NET. This interface is almost streaming, and is usually faster and simpler
to use than SAX. See L<<<<<< LibXML::Reader >>>>>>.


=head2 Direct SAX Parser

LibXML provides a direct SAX parser in the L<<<<<< LibXML::SAX >>>>>> module.


=head2 DOM based SAX Parser

LibXML also provides a DOM based SAX parser. The SAX parser is defined in the
module LibXML::SAX::Parser. As it is not a stream based parser, it parses
documents into a DOM and traverses the DOM tree instead.

The API of this parser is exactly the same as any other Perl SAX2 parser. See
XML::SAX::Intro for details.

Aside from the regular parsing methods, you can access the DOM tree traverser
directly, using the generate() method:



  my LibXML::Document $doc = build-yourself-a-document();
  my $saxparser = $LibXML::SAX::Parser.new( ... );
  $parser.generate( $doc );

This is useful for serializing DOM trees, for example that you might have done
prior processing on, or that you have as a result of XSLT processing.

I<<<<<< WARNING >>>>>>

This is NOT a streaming SAX parser. This parser reads the
entire document into a DOM and serialises it. If you want a streaming SAX
parser look at the L<<<<<< LibXML::SAX >>>>>> man page


=head1 SERIALIZATION

LibXML provides some functions to serialize nodes and documents. The
serialization functions are described on the L<<<<<< LibXML::Node >>>>>> manpage or the L<<<<<< LibXML::Document >>>>>> manpage. LibXML checks three global flags that alter the serialization process:

=item1 * skip-XML-Declaration

=item1 * skip-DTD

=item1 * tag-expansion

of that three functions only setTagCompression is available for all
serialization functions.

Because LibXML does these flags not itself, one has to define them locally as
the following example shows:



  temp LibXML.skip-xml-declaration = True;
  temp LibXML.skip-dtd = True;
  tmep LibXML.tag-expansion = False;

If skip-xml-declaration is defined and not False, the XML declaration is omitted
during serialization.

If skip-dtd is defined and not False, an existing DTD would not be serialized with
the document.

If tag-expansion is True empty tags are displayed as open
and closing tags rather than the shortcut. For example the empty tag I<<<<<< foo >>>>>> will be rendered as I<<<<<< &lt;foo&gt;&lt;/foo&gt; >>>>>> rather than I<<<<<< &lt;foo/&gt; >>>>>>.


=head1 PARSER OPTIONS

Handling of libxml2 parser options has been unified and improved in LibXML
1.70. You can now set default options for a particular parser instance by
passing them to the constructor as C<<<<<< LibXML-&gt;new({name=&gt;value, ...}) >>>>>> or C<<<<<< LibXML-&gt;new(name=&gt;value,...) >>>>>>. The options can be queried and changed using the following methods (pre-1.70
interfaces such as C<<<<<< $parser-&gt;load-ext-dtd(0) >>>>>> also exist, see below): 

=begin item1
option-exists

  $parser.option-exists($name);

Returns 1 if the current LibXML version supports the option C<<<<<< $name >>>>>>, otherwise returns 0 (note that this does not necessarily mean that the option
is supported by the underlying libxml2 library).

=end item1

=begin item1
get-option

  $parser.get-option($name);

Returns the current value of the parser option C<<<<<< $name >>>>>>.

=end item1

=begin item1
set-option

  $parser.set-option($name,$value);
  $parser.option($name) = $value;
  $parser."$name"() = $value;

Sets option C<<<<<< $name >>>>>> to value C<<<<<< $value >>>>>>.

=end item1

=begin item1
set-options

  $parser.set-options: |%options;

Sets multiple parsing options at once.

=end item1

IMPORTANT NOTE: This documentation reflects the parser flags available in
libxml2 2.7.3. Some options have no effect if an older version of libxml2 is
used. 

Each of the flags listed below is labeled

=begin item1
/parser/

if it can be used with a C<<<<<< LibXML >>>>>> parser object (i.e. passed to C<<<<<< LibXML-&gt;new >>>>>>, C<<<<<< LibXML-&gt;set-option >>>>>>, etc.) 

=end item1

=begin item1
/html/

if it can be used passed to the C<<<<<< parse-html-* >>>>>> methods

=end item1

=begin item1
/reader/

if it can be used with the C<<<<<< LibXML::Reader >>>>>>.

=end item1

Unless specified otherwise, the default for boolean valued options is 0
(false). 

The available options are:

=begin item1
URI

/parser, html, reader/

In case of parsing strings or file handles, LibXML doesn't know about the base
uri of the document. To make relative references such as XIncludes work, one
has to set a base URI, that is then used for the parsed document.

=end item1

=begin item1
line-numbers

/parser, html, reader/

If this option is activated, libxml2 will store the line number of each element
node in the parsed document. The line number can be obtained using the C<<<<<< line-number() >>>>>> method of the C<<<<<< LibXML::Node >>>>>> class (for non-element nodes this may report the line number of the containing
element). The line numbers are also used for reporting positions of validation
errors. 

IMPORTANT: Due to limitations in the libxml2 library line numbers greater than
65535 will be returned as 65535. Unfortunately, this is a long and sad story,
please see L<<<<<< http://bugzilla.gnome.org/show_bug.cgi?id=325533 >>>>>> for more details. 

=end item1

=begin item1
encoding

/html/

character encoding of the input

=end item1

=begin item1
recover

/parser, html, reader/

recover from errors; possible values are 0, 1, and 2

A true value turns on recovery mode which allows one to parse broken XML or
HTML data. The recovery mode allows the parser to return the successfully
parsed portion of the input document. This is useful for almost well-formed
documents, where for example a closing tag is missing somewhere. Still, LibXML
will only parse until the first fatal (non-recoverable) error occurs, reporting
recoverable parsing errors as warnings. To suppress even these warnings, use
recover=>2.

Note that validation is switched off automatically in recovery mode.

=end item1

=begin item1
expand-entities

/parser, reader/

substitute entities; possible values are 0 and 1; default is 1

Note that although this flag disables entity substitution, it does not prevent
the parser from loading external entities; when substitution of an external
entity is disabled, the entity will be represented in the document tree by an
XML_ENTITY_REF_NODE node whose subtree will be the content obtained by parsing
the external resource; Although this nesting is visible from the DOM it is
transparent to XPath data model, so it is possible to match nodes in an
unexpanded entity by the same XPath expression as if the entity were expanded.
See also ext-ent-handler. 

=end item1

=begin item1
ext-ent-handler

/parser/

Provide a custom external entity handler to be used when expand-entities is set
to 1. Possible value is a subroutine reference. 

This feature does not work properly in libxml2 < 2.6.27!

The subroutine provided is called whenever the parser needs to retrieve the
content of an external entity. It is called with two arguments: the system ID
(URI) and the public ID. The value returned by the subroutine is parsed as the
content of the entity. 

This method can be used to completely disable entity loading, e.g. to prevent
exploits of the type described at  (L<<<<<< http://searchsecuritychannel.techtarget.com/generic/0,295582,sid97_gci1304703,00.html >>>>>>), where a service is tricked to expose its private data by letting it parse a
remote file (RSS feed) that contains an entity reference to a local file (e.g. C<<<<<< /etc/fstab >>>>>>). 

A more granular solution to this problem, however, is provided by custom URL
resolvers, as in 

  my $c = LibXML::InputCallback.new();
  sub match {   # accept file:/ URIs except for XML catalogs in /etc/xml/
    my ($uri) = @_;
    return ($uri=~m{^file:/}
            and $uri !~ m{^file:///etc/xml/})
           ? 1 : 0;
  }
  $c.register-callbacks([ \&match, sub{}, sub{}, sub{} ]);
  $parser.input-callbacks($c);



=end item1

=begin item1
load-ext-dtd

/parser, reader/

load the external DTD subset while parsing; possible values are 0 and 1. Unless
specified, LibXML sets this option to 1.

This flag is also required for DTD Validation, to provide complete attribute,
and to expand entities, regardless if the document has an internal subset. Thus
switching off external DTD loading, will disable entity expansion, validation,
and complete attributes on internal subsets as well.

=end item1

=begin item1
complete-attributes

/parser, reader/

create default DTD attributes; possible values are 0 and 1

=end item1

=begin item1
validation

/parser, reader/

validate with the DTD; possible values are 0 and 1

=end item1

=begin item1
suppress-errors

/parser, html, reader/

suppress error reports; possible values are 0 and 1

=end item1

=begin item1
suppress-warnings

/parser, html, reader/

suppress warning reports; possible values are 0 and 1

=end item1

=begin item1
pedantic-parser

/parser, html, reader/

pedantic error reporting; possible values are 0 and 1

=end item1

=begin item1
no-blanks

/parser, html, reader/

remove blank nodes; possible values are 0 and 1

=end item1

=begin item1
no-defdtd

/html/

do not add a default DOCTYPE; possible values are 0 and 1

the default is (0) to add a DTD when the input html lacks one

=end item1

=begin item1
expand-xinclude or xinclude

/parser, reader/

Implement XInclude substitution; possible values are 0 and 1

Expands XInclude tags immediately while parsing the document. Note that the
parser will use the URI resolvers installed via C<<<<<< LibXML::InputCallback >>>>>> to parse the included document (if any).

=end item1

=begin item1
no-xinclude-nodes

/parser, reader/

do not generate XINCLUDE START/END nodes; possible values are 0 and 1

=end item1

=begin item1
no-network

/parser, html, reader/

Forbid network access; possible values are 0 and 1

If set to true, all attempts to fetch non-local resources (such as DTD or
external entities) will fail (unless custom callbacks are defined).

It may be necessary to use the flag C<<<<<< recover >>>>>> for processing documents requiring such resources while networking is off. 

=end item1

=begin item1
clean-namespaces

/parser, reader/

remove redundant namespaces declarations during parsing; possible values are 0
and 1. 

=end item1

=begin item1
no-cdata

/parser, html, reader/

merge CDATA as text nodes; possible values are 0 and 1

=end item1

=begin item1
no-basefix

/parser, reader/

not fixup XINCLUDE xml#base URIS; possible values are 0 and 1

=end item1

=begin item1
huge

/parser, html, reader/

relax any hardcoded limit from the parser; possible values are 0 and 1. Unless
specified, LibXML sets this option to 0.

Note: the default value for this option was changed to protect against denial
of service through entity expansion attacks. Before enabling the option ensure
you have taken alternative measures to protect your application against this
type of attack.

=end item1

=begin item1
gdome

/parser/

THIS OPTION IS EXPERIMENTAL!

Although quite powerful, LibXML's DOM implementation is incomplete with respect
to the DOM level 2 or level 3 specifications. XML::GDOME is based on libxml2 as
well, and provides a rather complete DOM implementation by wrapping libgdome.
This flag allows you to make use of LibXML's full parser options and
XML::GDOME's DOM implementation at the same time.

To make use of this function, one has to install libgdome and configure LibXML
to use this library. For this you need to rebuild LibXML!

Note: this feature was not seriously tested in recent LibXML releases.

=end item1

For compatibility with LibXML versions prior to 1.70, the following methods are
also supported for querying and setting the corresponding parser options (if
called without arguments, the methods return the current value of the
corresponding parser options; with an argument sets the option to a given
value): 



  $parser.validation();
  $parser.recover();
  $parser.pedantic-parser();
  $parser.line-numbers();
  $parser.load-ext-dtd();
  $parser.complete-attributes();
  $parser.expand-xinclude();
  $parser.gdome-dom();
  $parser.clean-namespaces();
  $parser.no-network();

The following obsolete methods trigger parser options in some special way:

=begin item1
recover-silently



  $parser.recover-silently(1);

If called without an argument, returns true if the current value of the C<<<<<< recover >>>>>> parser option is 2 and returns false otherwise. With a true argument sets the C<<<<<< recover >>>>>> parser option to 2; with a false argument sets the C<<<<<< recover >>>>>> parser option to 0. 

=end item1

=begin item1
expand-entities



  $parser.expand-entities(0);

Get/set the C<<<<<< expand-entities >>>>>> option. If called with a true argument, also turns the C<<<<<< load-ext-dtd >>>>>> option to 1. 

=end item1

=begin item1
keep-blanks



  $parser.keep-blanks(0);

This is actually the opposite of the C<<<<<< no-blanks >>>>>> parser option. If used without an argument retrieves negated value of C<<<<<< no-blanks >>>>>>. If used with an argument sets C<<<<<< no-blanks >>>>>> to the opposite value. 

=end item1

=begin item1
base-uri



  $parser.base-uri( $your-base-uri );

Get/set the C<<<<<< URI >>>>>> option.

=end item1


=head1 XML CATALOGS

C<<<<<< libxml2 >>>>>> supports XML catalogs. Catalogs are used to map remote resources to their local
copies. Using catalogs can speed up parsing processes if many external
resources from remote addresses are loaded into the parsed documents (such as
DTDs or XIncludes). 

Note that libxml2 has a global pool of loaded catalogs, so if you apply the
method C<<<<<< load-catalog >>>>>> to one parser instance, all parser instances will start using the catalog (in
addition to other previously loaded catalogs). 

Note also that catalogs are not used when a custom external entity handler is
specified. At the current state it is not possible to make use of both types of
resolving systems at the same time.

=begin item1
load-catalog

  $parser.load-catalog( $catalog-file );

Loads the XML catalog file $catalog-file.



  # Global external entity loader (similar to ext-ent-handler option
  # but this works really globally, also in XML::LibXSLT include etc..)
  
  LibXML::externalEntityLoader(\&my-loader);

=end item1


=head1 ERROR REPORTING

LibXML throws exceptions during parsing, validation or XPath processing (and
some other occasions). These errors can be caught by using I<<<<<< eval >>>>>> blocks. The error is stored in I<<<<<< $@ >>>>>>. There are two implementations: the old one throws $@ which is just a message
string, in the new one $@ is an object from the class LibXML::Error; this class
overrides the operator "" so that when printed, the object flattens to the
usual error message. 

LibXML throws errors as they occur. This is a very common misunderstanding in
the use of LibXML. If the eval is omitted, LibXML will always halt your script
by "croaking" (see Carp man page for details).

Also note that an increasing number of functions throw errors if bad data is
passed as arguments. If you cannot assure valid data passed to LibXML you
should eval these functions.

Note: since version 1.59, get-last-error() is no longer available in LibXML for
thread-safety reasons.

=head1 AUTHORS

Matt Sergeant, 
Christian Glahn, 
Petr Pajas, 

=head1 VERSION

2.0200

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
