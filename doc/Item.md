NAME
====

LibXML::Item - LibXML Nodes and Namespaces interface role

SYNOPSIS
========

    use LibXML::Item;
    for $elem.findnodes('namespace::*|attribute::*') -> LibXML::Item $_ {
       when LibXML::Namespace { say "namespace: " ~ .Str }
       when LibXML::Attr      { say "attribute: " ~ .Str }
    }

DESCRIPTON
==========

LibXML::Item is a role performed by LibXML::Namespace and LibXML::Node based classes.

This is a containing role for XPath queries with may return either namespaces or other nodes.

The LibXML::Namespace class is distinct from LibXML::Node classes. It cannot itself contain namespaces and lacks parent or child nodes.

Both nodes and namespaces support the following common methods: getNamespaceURI, localname(prefix), name(nodeName), type (nodeType), string-value, URI.

Please see [LibXML::Node](LibXML::Node) and [LibXML::Namespace](LibXML::Namespace).

FUNCTIONS AND METHODS
=====================

  * ast-to-xml()

    This function can be useful when it's getting a bit long-winded to create and manipulate data via the DOM API. For example:

        use LibXML::Elemnt;
        use LibXML::Item :&ast-to-xml;
        my LibXML::Element $elem = ast-to-xml(
            :dromedaries[
                     "\n  ", # white-space
                     '#comment' => ' Element Construction. ',
                     "\n  ", :species[:name<Camel>, :humps["1 or 2"], :disposition["Cranky"]],
                     "\n  ", :species[:name<Llama>, :humps["1 (sort of)"], :disposition["Aloof"]],
                     "\n  ", :species[:name<Alpaca>, :humps["(see Llama)"], :disposition["Friendly"]],
             "\n",
             ]);
         say $elem;

    Produces:

        <dromedaries>
          <!-- Element Construction. -->
          <species name="Camel"><humps>1 or 2</humps><disposition>Cranky</disposition></species>
          <species name="Llama"><humps>1 (sort of)</humps><disposition>Aloof</disposition></species>
          <species name="Alpaca"><humps>(see Llama)</humps><disposition>Friendly</disposition></species>
        </dromedaries>

    All DOM nodes have an `.ast()` method that can be used to output an intermediate dump of data. In the above example `$elem.ast()` would reproduce thw original data that was used to construct the element.

    Possible terms that can be used are:

    <table class="pod-table">
    <tbody>
    <tr> <td>*Term*</td> <td>*Description*</td> </tr> <tr> <td>name =&gt; [term, term, ...]</td> <td>Construct an element and its child items</td> </tr> <tr> <td>name =&gt; str-val</td> <td>Construct an attribute</td> </tr> <tr> <td>&#39;xmlns:prefix&#39; =&gt; str-val</td> <td>Construct a namespace</td> </tr> <tr> <td>&#39;text content&#39;</td> <td>Construct text node</td> </tr> <tr> <td>&#39;?name&#39; =&gt; str-val</td> <td>Construct a processing instruction</td> </tr> <tr> <td>&#39;#cdata&#39; =&gt; str-val</td> <td>Construct a CData node</td> </tr> <tr> <td>&#39;#comment&#39; =&gt; str-val</td> <td>Construct a comment node</td> </tr> <tr> <td>[elem, elem, ..]</td> <td>Construct a document fragment</td> </tr> <tr> <td>&#39;#xml&#39; =&gt; [root-elem]</td> <td>Construct an XML document</td> </tr> <tr> <td>&#39;#html&#39; =&gt; [root-elem]</td> <td>Construct an HTML document</td> </tr> <tr> <td>&#39;&amp;name&#39; =&gt; []</td> <td>Construct an entity reference</td> </tr>
    </tbody>
    </table>

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

