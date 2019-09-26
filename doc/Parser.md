NAME
====

LibXML::Parser - Parsing XML Data with LibXML

SYNOPSIS
========

    use LibXML;

    # Parser constructor

    my LibXML $parser .= new: |%opts;

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
        io => $perl-file-handle,
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
    $parser.push(@strings);
    $doc = $parser.finish-push( :$recover );

    # Set/query parser options
                        
    $parser.option-exists($name);
    $parser.get-option($name);
    $parser.set-option($name,$value);
    $parser.set-options(name => $value, ...);

    # XML catalogs
                        
    $parser.load-catalog( $catalog-file );

PARSING
=======

An XML document is read into a data structure such as a DOM tree by a piece of software, called a parser. LibXML currently provides four different parser interfaces:

  * * A DOM Pull-Parser

  * * A DOM Push-Parser

  * * A SAX Parser

  * * A DOM based SAX Parser.

Creating a Parser Instance
--------------------------

LibXML provides an OO interface to the libxml2 parser functions.

  * new

        my LibXML $parser .= new();
        my LibXML $parser .= new: :$opt1, :$opt2, ...;

    Create a new XML and HTML parser instance. Each parser instance holds default values for various parser options. Optionally, one can pass options to override default. Unless specified otherwise, the options `load-ext-dtd `, and `expand-entities ` are set to True. See [Parser Options ](Parser Options ) for a list of libxml2 parser's options. 

DOM Parser
----------

One of the common parser interfaces of LibXML is the DOM parser. This parser reads XML data into a DOM like data structure, so each tag can get accessed and transformed.

LibXML's DOM parser is not only capable to parse XML data, but also (strict) HTML files. There are three ways to parse documents - as a string, as a Perl filehandle, or as a filename/URL. The return value from each is a [LibXML::Document ](LibXML::Document ) object, which is a DOM object.

All of the functions listed below will throw an exception if the document is invalid. To prevent this causing your program exiting, wrap the call in a try {} block

  * parse

        my LibXML::Document::HTML $dom;

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
            io => $perl-path-or-file-handle,
            :$html, :$URI, :$enc,
            # parser options ...
          );
        $dom = LibXML.parse(
            buf => $perl-blob-or-buf,
            :$html, :$URI, :$enc,
            # parser options ...
          );
        $dom = LibXML.parse(
            fd => $file-descriptor-num,
            :$html, :$URI, :$enc,
            # parser options ...
          );
        $dom = LibXML.parse( $src, :$html, :$URI, :$enc,
            # parser options ...
        );
        $dom = $parser.parse(...);

    This function provides an interface to the XML parser that parses given file (or URL), string, or input stream to a DOM tree. The function can be called as a class method or an object method. In both cases it internally creates a new parser instance passing the specified parser options; if called as an object method, it clones the original parser (preserving its settings) and additionally applies the specified options to the new parser. See the constructor `new ` and [Parser Options ](Parser Options ) for more information. 

  * parse: :html

        use LibXML::Document :HTML;  
        my HTML $dom = LibXML.parse: :html, ...;
        my HTML $dom = $parser.parse: :html, ...;

    The :html option provides an interface to the HTML parser.

Parsing HTML may cause problems, especially if the ampersand ('&') is used. This is a common problem if HTML code is parsed that contains links to CGI-scripts. Such links cause the parser to throw errors. In such cases libxml2 still parses the entire document as there was no error, but the error causes LibXML to stop the parsing process. However, the document is not lost. Such HTML documents should be parsed using the *recover * flag. By default recovering is deactivated.

The functions described above are implemented to parse well formed documents. In some cases a program gets well balanced XML instead of well formed documents (e.g. an XML fragment from a database). With LibXML it is not required to wrap such fragments in the code, because LibXML is capable even to parse well balanced XML fragments.

  * parse-balanced

        my LibXML::DocumentFragment $chunk = $parser.parse-balanced( string => $wbxml );

    This function parses a well balanced XML string into a [LibXML::DocumentFragment ](LibXML::DocumentFragment ). The string argument contains the input XML string.

By default LibXML does not process XInclude tags within an XML Document (see options section below). LibXML allows one to post-process a document to expand XInclude tags.

  * process-xincludes

        $parser.process-xincludes( $doc );

    After a document is parsed into a DOM structure, you may want to expand the documents XInclude tags. This function processes the given document structure and expands all XInclude tags (or throws an error) by using the flags and callbacks of the given parser instance.

    Note that the resulting Tree contains some extra nodes (of type XML_XINCLUDE_START and XML_XINCLUDE_END) after successfully processing the document. These nodes indicate where data was included into the original tree. if the document is serialized, these extra nodes will not show up.

    Remember: A Document with processed XIncludes differs from the original document after serialization, because the original XInclude tags will not get restored!

    If the parser flag "expand-xinclude" is set to True, you need not to post process the parsed document.

  * processXIncludes

        $parser.processXIncludes( $doc );

    This is an alias to process-xincludes, but through a JAVA like function name.

  * parse: :file

        $doc = $parser.parse: :file( $xmlfilename );

    The :file option parses an XML document from a file or network; $xmlfilename can be either a filename or an URL.

  * parse: :io

        $doc = $parser.parse: :io( $io-fh );

    parse: :io parses an IO::Handle object.

  * parse: :string

        $doc = $parser.parse: :string( $xmlstring);

    This function parses an XML document that is available as a single string in memory. You can pass an optional base URI string to the function.

        my $doc = $parser.parse: :string($xmlstring);
        my $doc = $parser.parse: :string($xmlstring), :$URI;

  * parse: :html

        use LibXML::Document :HTML;
        my HTML $doc;
        $doc = $parser.parse: :html, :file( $htmlfile) , |%opts;
        $doc = $parser.parse: :html, :io($io-fh), |%opts;
        $doc = $parser.parse: :html: :string($htmlstring), |%opts;
        # etc..

Push Parser
-----------

LibXML provides a push parser interface. Rather than pulling the data from a given source the push parser waits for the data to be pushed into it.

Please see [LibXML::PushParser](LibXML::PushParser) for more details.

For Perl 5 compatibilty, the following methods are available to invoke a push-parser from a LibXML::Parser object.

  * init-push

        $parser.init-push();

    Initializes the push parser.

  * push

        $parser.push(@chunks);

    This function pushes the data stored inside the array to libxml2's parser. Each entry in @chunks may be a string or blob! This method can be called repeatedly.

  * finish-push

        $doc = $parser.finish-push( :$URI, :$recover );

    This function returns the result of the parsing process. If this function is called without a parameter it will complain about non well-formed documents. If :$recover is True, the push parser can be used to restore broken or non well formed (XML) documents.

Pull Parser (Reader)
--------------------

LibXML also provides a pull-parser interface similar to the XmlReader interface in .NET. This interface is almost streaming, and is usually faster and simpler to use than SAX. See [LibXML::Reader ](LibXML::Reader ).

Direct SAX Parser
-----------------

LibXML provides a direct SAX parser in the [LibXML::SAX ](LibXML::SAX ) module.

DOM based SAX Parser
--------------------

LibXML also provides a DOM based SAX parser. The SAX parser is defined in the module LibXML::SAX::Parser. As it is not a stream based parser, it parses documents into a DOM and traverses the DOM tree instead.

The API of this parser is exactly the same as any other Perl SAX2 parser. See XML::SAX::Intro for details.

Aside from the regular parsing methods, you can access the DOM tree traverser directly, using the reparse() method:

    my LibXML::Document $doc = build-yourself-a-document();
    my $saxparser = $LibXML::SAX::Parser.new( ... );
    $parser.reparse( $doc );

This is useful for serializing DOM trees, for example that you might have done prior processing on, or that you have as a result of XSLT processing.

*WARNING *

This is NOT a streaming SAX parser. This parser reads the entire document into a DOM and serialises it. If you want a streaming SAX parser look at the [LibXML::SAX ](LibXML::SAX ) man page

SERIALIZATION
=============

LibXML provides some functions to serialize nodes and documents. The serialization functions are described on the [LibXML::Node ](LibXML::Node ) or the [LibXML::Document ](LibXML::Document ) documentation. LibXML checks three global flags that alter the serialization process:

  * * skip-xml-declaration

  * * skip-dtd

  * * tag-expansion

of that three functions only setTagCompression is available for all serialization functions.

Because LibXML does these flags not itself, one has to define them locally as the following example shows:

    temp LibXML.skip-xml-declaration = True;
    temp LibXML.skip-dtd = True;
    tmep LibXML.tag-expansion = False;

If skip-xml-declaration is True, the XML declaration is omitted during serialization.

If skip-dtd is defined is True, an existing DTD would not be serialized with the document.

If tag-expansion is True empty tags are displayed as open and closing tags rather than the shortcut. For example the empty tag *foo * will be rendered as *&lt;foo&gt;&lt;/foo&gt; * rather than *&lt;foo/&gt; *.

PARSER OPTIONS
==============

Handling of libxml2 parser options has been unified and improved in LibXML 1.70. You can now set default options for a particular parser instance by passing them to the constructor as `LibXML-&gt;new({name=&gt;value, ...}) ` or `LibXML-&gt;new(name=&gt;value,...) `. The options can be queried and changed using the following methods (pre-1.70 interfaces such as `$parser-&gt;load-ext-dtd(0) ` also exist, see below): 

  * option-exists

        $parser.option-exists($name);

    Returns True if the current LibXML version supports the option `$name `, otherwise returns False (note that this does not necessarily mean that the option is supported by the underlying libxml2 library).

  * get-option

        $parser.get-option($name);

    Returns the current value of the parser option `$name `.

  * set-option

        $parser.set-option($name,$value);
        $parser.option($name) = $value;
        $parser."$name"() = $value;

    Sets option `$name ` to value `$value `.

  * set-options

        $parser.set-options: |%options;

    Sets multiple parsing options at once.

Each of the flags listed below is labeled

  * /parser/

    if it can be used with a `LibXML ` parser object (i.e. passed to `LibXML-&gt;new `, `LibXML-&gt;set-option `, etc.) 

  * /html/

    if it is applicable to HTML parsing

  * /reader/

    if it can be used with the `LibXML::Reader `.

Unless specified otherwise, the default for boolean valued options is False. 

The available options are:

  * URI

    /parser, html, reader/

    In case of parsing strings or file handles, LibXML doesn't know about the base uri of the document. To make relative references such as XIncludes work, one has to set a base URI, that is then used for the parsed document.

  * dtd

    /parser, html, reader/

    (Introduced with the Perl 6 port) This is a bundled option to enable DTD validation and processing. Setting `$parser.dtd = True` is equivalent to setting: `$parser.load-ext-dtd = True; $parser.validation = True; $parser.complete-attributes = True; $parser.expand-entities = True`.

  * line-numbers

    /parser/

    If this option is activated, libxml2 will store the line number of each element node in the parsed document. The line number can be obtained using the `line-number() ` method of the `LibXML::Node ` class (for non-element nodes this may report the line number of the containing element). The line numbers are also used for reporting positions of validation errors. 

    IMPORTANT: Due to limitations in the libxml2 library line numbers greater than 65535 will be returned as 65535. Please see [http://bugzilla.gnome.org/show_bug.cgi?id=325533 ](http://bugzilla.gnome.org/show_bug.cgi?id=325533 ) for more details. 

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

    substitute entities; default is True

    Note that although this flag disables entity substitution, it does not prevent the parser from loading external entities; when substitution of an external entity is disabled, the entity will be represented in the document tree by an XML_ENTITY_REF_NODE node whose subtree will be the content obtained by parsing the external resource; Although this nesting is visible from the DOM it is transparent to XPath data model, so it is possible to match nodes in an unexpanded entity by the same XPath expression as if the entity were expanded. See also [LibXML::Config](LibXML::Config).external-entity-loader. 

  * load-ext-dtd

    /parser, reader/

    load the external DTD subset while parsing. Unless specified, LibXML sets this option to True.

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

    keep blank nodes; default true

  * defdtd

    /html/

    add a default DOCTYPE DTD when the input html lacks one; default is True

  * expand-xinclude

    /parser, reader/

    Implement XInclude substitution; type Bool

    Expands XInclude tags immediately while parsing the document. Note that the parser will use the URI resolvers installed via `LibXML::InputCallback ` to parse the included document (if any).

  * xinclude-nodes

    /parser, reader/

    do not generate XINCLUDE START/END nodes; default True

  * network

    /parser, html, reader/

    Enable network access; default True

    If set to False, all attempts to fetch non-local resources (such as DTD or external entities) will fail (unless custom callbacks are defined).

    It may be necessary to use the flag `recover ` for processing documents requiring such resources while networking is off. 

  * clean-namespaces

    /parser, reader/

    remove redundant namespaces declarations during parsing; type Bool

  * cdata

    /parser, html, reader/

    merge CDATA as text nodes; default True

  * base-fix

    /parser, reader/

    fixup XINCLUDE xml#base URIS; default True

  * huge

    /parser, html, reader/

    relax any hardcoded limit from the parser; type Bool. Unless specified, LibXML sets this option to False.

    Note: the default value for this option was changed to protect against denial of service through entity expansion attacks. Before enabling the option ensure you have taken alternative measures to protect your application against this type of attack.

The following obsolete methods trigger parser options in some special way:

  * recover-silently

        $parser.recover-silently = True;

    If called without an argument, returns true if the current value of the `recover ` parser option is 2 and returns false otherwise. With a true argument sets the `recover ` parser option to 2; with a false argument sets the `recover ` parser option to 0. 

XML CATALOGS
============

`libxml2 ` supports XML catalogs. Catalogs are used to map remote resources to their local copies. Using catalogs can speed up parsing processes if many external resources from remote addresses are loaded into the parsed documents (such as DTDs or XIncludes). 

Note that libxml2 has a global pool of loaded catalogs, so if you apply the method `load-catalog ` to one parser instance, all parser instances will start using the catalog (in addition to other previously loaded catalogs). 

Note also that catalogs are not used when a custom external entity handler is specified. At the current state it is not possible to make use of both types of resolving systems at the same time.

  * load-catalog

        $parser.load-catalog( $catalog-file );

    Loads the XML catalog file $catalog-file.

        # Global external entity loader (similar to ext-ent-handler option
        # but this works really globally, also in XML::LibXSLT include etc..)

        LibXML::externalEntityLoader(\&my-loader);

ERROR REPORTING
===============

LibXML throws exceptions during parsing, validation or XPath processing (and some other occasions). These errors can be caught by using `try` or `CATCH` blocks.

LibXML throws errors as they occur. If the `try` is omitted, LibXML will always halt your script by throwing an exception.

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

