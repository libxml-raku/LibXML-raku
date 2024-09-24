[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [Parser](https://libxml-raku.github.io/LibXML-raku/Parser)

class LibXML::Parser
--------------------

Parse XML with LibXML

Synopsis
--------

```raku
use LibXML;

# Parser constructor

my LibXML $parser .= new: :$catalog, |%opts;

# Parsing XML

$dom = LibXML.parse(
    location => $file-or-url,
    # parser options ...
  );
$dom = LibXML.parse(
    file => $file-or-url,
    # parser options ...
  );
$dom = LibXML.parse(
    string => $xml-string,
    # parser options ...
  );
$dom = LibXML.parse(
    io => $raku-file-handle,
    # parser options ...
  );
# dispatch to above depending on type
$dom = $parser.parse($src ...);

# Parsing HTML

$dom = LibXML.parse(..., :html);
$dom = $parser.parse(..., :html);
$parser.html = True; $parser.parse(...);

# Parsing well-balanced XML chunks
my LibXML::DocumentFragment $chunk = $parser.parse-balanced( string => $wbxml);

# Processing XInclude
$parser.process-xincludes( $doc );
$parser.processXIncludes( $doc );

# Push parser
$parser.parse-chunk($string, :$terminate);
$parser.init-push();
$parser.push($chunk);
$parser.append(@chunks);
$doc = $parser.finish-push( :$recover );

# Set/query parser options

my LibXML $parser .= new: name => $value, ...;
# -OR-
$parser.option-exists($name);
$parser.get-option($name);
$parser.set-option($name, $value);
$parser.set-options(name => $value, ...);

# XML catalogs
my LibXML $parser .= new: catalog => $catalog-file, |%opts
# -OR-
$parser.load-catalog( $catalog-file );
```

Parsing
-------

An XML document is read into a data structure such as a DOM tree by a piece of software, called a parser. LibXML currently provides four different parser interfaces:

  * A DOM Pull-Parser

  * A DOM Push-Parser

  * A SAX Parser

  * A DOM based SAX Parser.

Creating a Parser Instance
--------------------------

LibXML provides an OO interface to the libxml2 parser functions.

### method new

    method new(Str :$catalog, *%opts) returns LibXML
    my LibXML $parser .= new: :$opt1, :$opt2, ...;

Create a new XML and HTML parser instance. Each parser instance holds default values for various parser options. Optionally, one can pass options to override default.

DOM Parser
----------

One of the common parser interfaces of LibXML is the DOM parser. This parser reads XML data into a DOM like data structure, so each tag can get accessed and transformed.

LibXML's DOM parser is not only able to parse XML data, but also (strict) HTML files. There are three ways to parse documents - as a string, as a Raku filehandle, or as a filename/URL. The return value from each is a [LibXML::Document](https://libxml-raku.github.io/LibXML-raku/Document) object, which is a DOM object.

All of the functions listed below will throw an exception if the document is invalid. To prevent this causing your program exiting, wrap the call in a try {} block

### method parse

    method parse(*%opts) returns LibXML::Document

    my LibXML::Document $dom;

    $dom = LibXML.parse(
        location => $file-or-url,
        :$html, :$URI, :$enc,
        # parser options ...
      );
    $dom = LibXML.parse(
        string => $xml-string,
        :$html, :$URI, :$enc,
        # parser options ...
      );
    $dom = LibXML.parse(
        io => $raku-path-or-file-handle,
        :$html, :$URI, :$enc,
        # parser options ...
      );
    $dom = LibXML.parse(
        buf => $raku-blob-or-buf,
        :$html, :$URI, :$enc,
        # parser options ...
      );
    $dom = LibXML.parse( $src, :$html, :$URI, :$enc,
        # parser options ...
    );
    $dom = $parser.parse(...);

This method provides an interface to the XML parser that parses given file (or URL), string, or input stream to a DOM tree. The function can be called as a class method or an object method. In both cases it internally creates a new parser instance passing the specified parser options; if called as an object method, it clones the original parser (preserving its settings) and additionally applies the specified options to the new parser. See the constructor `new` and [Parser Options](Parser Options) for more information.

Note: Although this method usually returns a `LibXML::Document` object. It can be requisitioned to return other document types by providing a `:sax-handler` that returns an alternate document via a `publish()` method. See [LibXML::SAX::Builder](https://libxml-raku.github.io/LibXML-raku/SAX/Builder). [LibXML::SAX::Handler::XML](https://libxml-raku.github.io/LibXML-raku/SAX/Handler/XML), for example produces pure Raku XML document objects.

#### method parse - `:html` option

    use LibXML::Document :HTML;
    my HTML $dom = LibXML.parse: :html, ...;
    my HTML $dom = $parser.parse: :html, ...;

The :html option provides an interface to the HTML parser.

Parsing HTML may cause problems, especially if the ampersand ('&') is used. This is a common problem if HTML code is parsed that contains links to CGI-scripts. Such links cause the parser to throw errors. In such cases libxml2 still parses the entire document as there was no error, but the error causes LibXML to stop the parsing process. However, the document is not lost. Such HTML documents should be parsed using the *recover* flag. By default recovering is deactivated.

The functions described above are implemented to parse well formed documents. In some cases a program gets well balanced XML instead of well formed documents (e.g. an XML fragment from a database). With LibXML it is not required to wrap such fragments in the code, because LibXML is capable even to parse well balanced XML fragments.

#### method parse `:file` option

    $doc = $parser.parse: :file( $xmlfilename );

The :file option parses an XML document from a file or network; $xmlfilename can be either a filename or an URL.

#### method parse `:io` option

    $doc = $parser.parse: :io( $io-fh );

parse: :io parses an IO::Handle object.

#### method parse `:string` option

    $doc = $parser.parse: :string( $xmlstring);

This function parses an XML document that is available as a single string in memory. You can pass an optional base URI string to the function.

    my $doc = $parser.parse: :string($xmlstring);
    my $doc = $parser.parse: :string($xmlstring), :$URI;

#### method parse `:location` option

    my $location = "http://www.cpan.org/authors/00whois.xml";
    $doc = $parser.parse: :$location, :network;

This option accepts a simple filename, a file URL with a `file:` prefix, or a HTTP URL with a `http:` prefix.

The file is streamed as it is loaded, which may may be faster than fetching and loading from the URL in two stages. Please note:

  * The `network` option (disabled by default) needs to enable fetching from HTTP address locations.

  * HTTPS (`https:`) is currently not supported

#### method parse `:html` option

    use LibXML::Document :HTML;
    my HTML $doc;
    $doc = $parser.parse: :html, :file( $htmlfile) , |%opts;
    $doc = $parser.parse: :html, :io($io-fh), |%opts;
    $doc = $parser.parse: :html: :string($htmlstring), |%opts;
    # etc..

### method parse-balanced

    method parse-balanced(
        Str() string => $string,
        LibXML::Document :$doc
    ) returns LibXML::DocumentFragment;

This function parses a well balanced XML string into a [LibXML::DocumentFragment](https://libxml-raku.github.io/LibXML-raku/DocumentFragment) object. The string argument contains the input XML string.

### method process-xincludes (alias processXIncludes)

    method process-xincludes( LibXML::Document $doc ) returns UInt;

By default LibXML does not process XInclude tags within an XML Document (see options section below). LibXML allows one to post-process a document to expand XInclude tags.

After a document is parsed into a DOM structure, you may want to expand the documents XInclude tags. This function processes the given document structure and expands all XInclude tags (or throws an error) by using the flags and callbacks of the given parser instance.

Note that the resulting Tree contains some extra nodes (of type XML_XINCLUDE_START and XML_XINCLUDE_END) after successfully processing the document. These nodes indicate where data was included into the original tree. if the document is serialized, these extra nodes will not show up.

Remember: A Document with processed XIncludes differs from the original document after serialization, because the original XInclude tags will not get restored!

If the parser flag "expand-xinclude" is set to True, you need not to post process the parsed document.

Push Parser
-----------

LibXML provides a push parser interface. Rather than pulling the data from a given source the push parser waits for the data to be pushed into it.

Please see [LibXML::PushParser](https://libxml-raku.github.io/LibXML-raku/PushParser) for more details.

For Perl compatibilty, the following methods are available to invoke a push-parser from a [LibXML::Parser](https://libxml-raku.github.io/LibXML-raku/Parser) object.

### method init-push

    method init-push($first-chunk?) returns Mu

Initializes the push parser.

### method push

    method push($chunks) returns Mu

This function pushes a chunk to libxml2's parser. `$chunk` may be a string or blob. This method can be called repeatedly.

### method append

    method append(@chunks) returns Mu

This function pushes the data stored inside the array to libxml2's parser. Each entry in @chunks may be a string or blob. This method can be called repeatedly.

### method finish-push

    method finish-push(
        Str :$URI, Bool :$recover
    ) returns LibXML::Document

This function returns the result of the parsing process. If this function is called without a parameter it will complain about non well-formed documents. If :$recover is True, the push parser can be used to restore broken or non well formed (XML) documents.

Pull Parser (Reader)
--------------------

LibXML also provides a pull-parser interface similar to the XmlReader interface in .NET. This interface is almost streaming, and is usually faster and simpler to use than SAX. See [LibXML::Reader](https://libxml-raku.github.io/LibXML-raku/Reader).

Direct SAX Parser
-----------------

LibXML provides a direct SAX parser in the [LibXML::SAX](https://libxml-raku.github.io/LibXML-raku/SAX) module.

DOM based SAX Parser
--------------------

Aside from the regular parsing methods, you can access the DOM tree traverser directly, using the reparse() method:

    my LibXML::Document $doc = build-yourself-a-document();
    my $saxparser = $LibXML::SAX::Parser.new( ... );
    $parser.reparse( $doc );

This is useful for serializing DOM trees, for example that you might have done prior processing on, or that you have as a result of XSLT processing.

*WARNING*

This is NOT a streaming SAX parser. This parser reads the entire document into a DOM and serialises it. If you want a streaming SAX parser look at the [LibXML::SAX](https://libxml-raku.github.io/LibXML-raku/SAX) man page

Serialization Options
---------------------

LibXML provides some functions to serialize nodes and documents. The serialization functions are described on the [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node) or the [LibXML::Document](https://libxml-raku.github.io/LibXML-raku/Document) documentation. LibXML checks three global flags that alter the serialization process:

  * skip-xml-declaration

  * skip-dtd

  * tag-expansion

They are defined globally, but can be overriden by options to the `Str` or `Blob` methods on nodes. For example:

    say $doc.Str: :skip-xml-declaration, :skip-dtd, :tag-expansion;

If `skip-xml-declaration` is True, the XML declaration is omitted during serialization.

If `skip-dtd` is defined is True, the document is serialized with the internal DTD removed.

If `tag-expansion` is True empty tags are displayed as open and closing tags rather than the shortcut. For example the empty tag *foo* will be rendered as *&lt;foo&gt;&lt;/foo&gt;* rather than *&lt;foo/&gt;*.

Parser Options
--------------

### method option-exists

    method option-exists(Str $name) returns Bool

Returns True if the current LibXML version supports the option `$name`, otherwise returns False (note that this does not necessarily mean that the option is supported by the underlying libxml2 library).

### method get-option

    method get-option(Str $name) returns Mu

Returns the current value of the parser option, where `$name` is both case and snake/kebab-case independent.

Note also that boolean options can be negated via a `no-` prefix.

    $parser.recover = False;
    $parser.no-recover = True;
    $parser.set-option(:!recover);
    $parser.set-option(:no-recover);

### method set-option

    $parser.set-option($name, $value);
    $parser.option($name) = $value;
    $parser."$name"() = $value;

Sets option `$name` to value `$value`.

### method set-options

    $parser.set-options: |%options;

Sets multiple parsing options at once.

Each of the flags listed below is labeled

  * /parser/

    if it can be used with a [LibXML](https://libxml-raku.github.io/LibXML-raku) parser object (i.e. passed to `LibXML.new`, `LibXML.set-option`, etc.)

  * /html/

    if it is applicable to HTML parsing

  * /reader/

    if it can be used with the [LibXML::Reader](https://libxml-raku.github.io/LibXML-raku/Reader).

Unless specified otherwise, the default for boolean valued options is False.

The available options are:

  * dtd

    /parser, html, reader/ (Introduced with the Raku port)

    This enables local DTD loading and validation, as well as entity expansion.

    This is a bundled option. Setting `$parser.dtd = True` is equivalent to setting: `$parser.load-ext-dtd = True; $parser.validation = True; $parser.expand-entities = True`.

    The `network` option or a custom entity-loader also needs to be set to allow loading of remote DTD files.

  * URI

    /parser, html, reader/

    In case of parsing strings or file handles, LibXML doesn't know about the base URI of the document. To make relative references such as XIncludes work, one has to set a base URI, that is then used for the parsed document.

  * line-numbers

    /parser/

    If this option is activated, libxml2 will store the line number of each element node in the parsed document. The line number can be obtained using the `line-number()` method of the [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node) class (for non-element nodes this may report the line number of the containing element). The line numbers are also used for reporting positions of validation errors.

    IMPORTANT: Due to limitations in the libxml2 library line numbers greater than 65535 will be returned as 65535. Please see [http://bugzilla.gnome.org/show_bug.cgi?id=325533](http://bugzilla.gnome.org/show_bug.cgi?id=325533) for more details.

  * enc

    /parser(*), html, reader(*)/

    character encoding of the input.

    (*) This is applicable to all HTML parsing modes and XML parsing from files, or file descriptors. (*) `:enc` is a read-only Reader option.

  * recover

    /parser, html, reader/

    recover from errors; possible values are 0, 1, and 2

    A True value turns on recovery mode which allows one to parse broken XML or HTML data. The recovery mode allows the parser to return the successfully parsed portion of the input document. This is useful for almost well-formed documents, where for example a closing tag is missing somewhere. Still, LibXML will only parse until the first fatal (non-recoverable) error occurs, reporting recoverable parsing errors as warnings. To suppress even these warnings, use recover=>2.

    Note that validation is switched off automatically in recovery mode.

  * expand-entities

    /parser, reader/

    substitute entities; default is False

    Note that although unsetting this flag disables entity substitution, it does not prevent the parser from loading external entities; when substitution of an external entity is disabled, the entity will be represented in the document tree by an XML_ENTITY_REF_NODE node whose subtree will be the content obtained by parsing the external resource; Although this nesting is visible from the DOM it is transparent to XPath data model, so it is possible to match nodes in an unexpanded entity by the same XPath expression as if the entity were expanded. See also `.external-entity-loader()` method in [LibXML::Config](https://libxml-raku.github.io/LibXML-raku/Config).

  * load-ext-dtd

    /parser, reader/

    load the external DTD subset while parsing. Unless specified, LibXML sets this option to False.

    This flag is also required for DTD Validation, to provide complete attribute, and to expand entities, regardless if the document has an internal subset. Thus switching off external DTD loading, will disable entity expansion, validation, and complete attributes on internal subsets as well.

  * complete-attributes

    /parser, reader/

    create default DTD attributes; type Bool

  * validation

    /parser, reader/

    validate with the DTD; type Bool

  * suppress-errors

    /parser, html, reader/

    suppress error reports; type Bool

  * suppress-warnings

    /parser, html, reader/

    suppress warning reports; type Bool

  * pedantic-parser

    /parser, html, reader/

    pedantic error reporting; type Bool

  * blanks

    /parser, html, reader/

    keep blank nodes; default True

  * defdtd

    /html/

    add a default DOCTYPE DTD when the input html lacks one; default is True

  * expand-xinclude

    /parser, reader/

    Implement XInclude substitution; type Bool

    Expands XInclude tags immediately while parsing the document. Note that the parser will use the URI resolvers installed via [LibXML::InputCallback](https://libxml-raku.github.io/LibXML-raku/InputCallback) to parse the included document (if any).

    It is recommended to use `input-callbacks` to restrict access when `expand-xinclude` is enabled on untrusted input files, otherwise it's trivial to inject arbitrary content from the file-system, as in:

        <foo xmlns:xi="http://www.w3.org/2001/XInclude">
            <xi:include parse="text" href="file:///etc/passwd"/>
        </foo>

  * xinclude-nodes

    /parser, reader/

    do not generate XINCLUDE START/END nodes; default True

  * network

    /parser, html, reader/

    Enable network access; default False

    All attempts to fetch non-local resources (such as DTD or external entities) will fail unless set to True (or custom input-callbacks are defined).

    It may be necessary to use the flag `recover` for processing documents requiring such resources while networking is off.

  * clean-namespaces

    /parser, reader/

    remove redundant namespaces declarations during parsing; type Bool

  * cdata

    /parser, html, reader/

    merge CDATA as text nodes; default True

  * base-fix

    /parser, reader/

    fix-up XINCLUDE xml#base URIS; default True

  * huge

    /parser, html, reader/

    relax any hardcoded limit from the parser; type Bool. Unless specified, LibXML sets this option to False.

    Note: the default value for this option was changed to protect against denial of service through entity expansion attacks. Before enabling the option ensure you have taken alternative measures to protect your application against this type of attack.

The following obsolete methods trigger parser options in some special way:

  * recover-silently

        $parser.recover-silently = True;

    If called without an argument, returns true if the current value of the `recover` parser option is 2 and returns false otherwise. With a true argument sets the `recover` parser option to 2; with a false argument sets the `recover` parser option to 0.

XML Catalogs
------------

`libxml2` supports XML catalogs. Catalogs are used to map remote resources to their local copies. Using catalogs can speed up parsing processes if many external resources from remote addresses are loaded into the parsed documents (such as DTDs or XIncludes).

Note that libxml2 has a global pool of loaded catalogs, so if you apply the method `load-catalog` to one parser instance, all parser instances will start using the catalog (in addition to other previously loaded catalogs).

Note also that catalogs are not used when a custom external entity handler is specified. At the current state it is not possible to make use of both types of resolving systems at the same time.

### method load-catalog

    method load-catalog( Str $catalog-file ) returns Mu;

Loads the XML catalog file $catalog-file.

    # Global external entity loader (similar to ext-ent-handler option
    # but this works really globally, also in XML::LibXSLT include etc..)
    LibXML.external-entity-loader = &my-loader;

Error Reporting
---------------

LibXML throws exceptions during parsing, validation or XPath processing (and some other occasions). These errors can be caught by using `try` or `CATCH` blocks.

LibXML throws errors as they occur. If the `try` is omitted, LibXML will always halt your script by throwing an exception.

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

