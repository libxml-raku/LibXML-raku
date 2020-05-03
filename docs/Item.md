NAME
====

LibXML::Item - LibXML Nodes and Namespaces interface role

DESCRIPTON
==========

LibXML::Item is a role performed by [LibXML::Namespace](https://libxml-raku.github.io/LibXML-raku/Namespace) and [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node) based classes.

These are distinct classes in libxml2, but do share common methods: getNamespaceURI, localname(prefix), name(nodeName), type (nodeType), string-value, URI.

Also note that the [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node) `findnodes` method can sometimes return either [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node) or [LibXML::Namespace](https://libxml-raku.github.io/LibXML-raku/Namespace) items, e.g.:

```raku
use LibXML::Item;
for $elem.findnodes('namespace::*|attribute::*') -> LibXML::Item $_ {
   when LibXML::Namespace { say "namespace: " ~ .Str }
   when LibXML::Attr      { say "attribute: " ~ .Str }
}
```

Please see [LibXML::Node](https://libxml-raku.github.io/LibXML-raku/Node) and [LibXML::Namespace](https://libxml-raku.github.io/LibXML-raku/Namespace).

FUNCTIONS AND METHODS
=====================

  * ast-to-xml()

    This function can be useful when it's getting a bit long-winded to create and manipulate data via the DOM API. For example:

    ```raku
    use LibXML::Element;
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
    ```

    Produces:

    ```xml
    <dromedaries>
      <!-- Element Construction. -->
      <species name="Camel"><humps>1 or 2</humps><disposition>Cranky</disposition></species>
      <species name="Llama"><humps>1 (sort of)</humps><disposition>Aloof</disposition></species>
      <species name="Alpaca"><humps>(see Llama)</humps><disposition>Friendly</disposition></species>
    </dromedaries>
    ```

    All DOM nodes have an `.ast()` method that can be used to output an intermediate dump of data. In the above example `$elem.ast()` would reproduce thw original data that was used to construct the element.

    Possible terms that can be used are:

    <table class="pod-table">
    <thead><tr>
    <th>Term</th> <th>Description</th>
    </tr></thead>
    <tbody>
    <tr> <td>name =&gt; [term, term, ...]</td> <td>Construct an element and its child items</td> </tr> <tr> <td>name =&gt; str-val</td> <td>Construct an attribute</td> </tr> <tr> <td>&#39;xmlns:prefix&#39; =&gt; str-val</td> <td>Construct a namespace</td> </tr> <tr> <td>&#39;text content&#39;</td> <td>Construct text node</td> </tr> <tr> <td>&#39;?name&#39; =&gt; str-val</td> <td>Construct a processing instruction</td> </tr> <tr> <td>&#39;#cdata&#39; =&gt; str-val</td> <td>Construct a CData node</td> </tr> <tr> <td>&#39;#comment&#39; =&gt; str-val</td> <td>Construct a comment node</td> </tr> <tr> <td>[elem, elem, ..]</td> <td>Construct a document fragment</td> </tr> <tr> <td>&#39;#xml&#39; =&gt; [root-elem]</td> <td>Construct an XML document</td> </tr> <tr> <td>&#39;#html&#39; =&gt; [root-elem]</td> <td>Construct an HTML document</td> </tr> <tr> <td>&#39;&amp;name&#39; =&gt; []</td> <td>Construct an entity reference</td> </tr>
    </tbody>
    </table>

  * box

    By convention native classes in the LibXML module are not directly exposed, but have a containing class that holds the object in a `$.native` attribute and provides an API interface for it. The `box` method is used to stantiate a containing object, of an appropriate class. The containing object will in-turn reference-count or copy the object to ensure that the underlying native object is not destroyed while it is still alive.

    For example to create an xmlElem native object then a [LibXML::Element](https://libxml-raku.github.io/LibXML-raku/Element) containing class.

    ```raku
    use LibXML::Native;
    use LibXML::Node;
    use LibXML::Element;

    my xmlElem $native .= new: :name<Foo>;
    say $native.type; # 1 (element)
    my LibXML::Element $elem .= box($native);
    $!native := Nil;
    say $elem.Str; # <Foo/>
    ```

    A containing object of the correct type (LibXML::Element) has been created for the native object.

  * keep

    ```raku
    $item.keep(xmlItem $rv);
    ```

    Utility method that verifies that `$rv` is the same native struct as that help by `$item`.

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

