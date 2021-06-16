use LibXML::Node;
use W3C::DOM;

#| LibXML Attribute nodes
unit class LibXML::Attr
    is repr('CPointer')
    is LibXML::Node
    does W3C::DOM::Attr;

=begin pod
    =head2 Synopsis

        use LibXML::Attr;
        use LibXML::Element;
        # Only methods specific to Attribute nodes are listed here,
        # see the LibXML::Node documentation for other methods

        my LibXML::Attr $attr .= new(:$name, :$value);
        my Str $value = $attr.value;
        $att.value = $value;
        my LibXML::Element $node = $attr.getOwnerElement();
        $attr.setNamespace($nsURI, $prefix);
        my Bool $is-id = $attr.isId;
        my Str $content = $attr.serializeContent;

    =head2 Description

    This is the interface to handle Attributes like ordinary nodes. The naming of
    the class relies on the W3C DOM documentation.
=end pod

use LibXML::Raw;
use LibXML::Types :QName;
use Method::Also;
use NativeCall;

=begin pod
    =head2 Methods

    The class inherits from L<LibXML::Node>. The documentation for Inherited methods is not listed here.

    Many functions listed here are extensively documented in the DOM Level 3 specification (L<http://www.w3.org/TR/DOM-Level-3-Core/>). Please refer to the specification for extensive documentation.
=end pod

method new(LibXML::Node :doc($owner), QName:D :$name!, Str :$value!) {
    my xmlDoc $doc = .raw with $owner;
    my xmlAttr:D $raw := xmlAttr.new( :$name, :$value, :$doc );
    self.box: $raw;
}
=begin pod
    =head3 method new

        method new(QName :$name!, Str :$value!, LibXML::Document :$doc) returns LibXML::Attribue

    Class constructor.
=end pod

method raw handles <atype name serializeContent> {
    nativecast(xmlAttr, self);
}

#| Gets or sets the attribute stored for the value
method value is rw returns Str { $.nodeValue }
=para Str:U is returned if the attribute has no value

#| Determine whether an attribute is of type ID.
method isId returns Bool { $.raw.isId.so }
=begin pod
    =para For documents with a DTD, this
    information is only available if DTD loading/validation has been requested. For
    HTML documents parsed with the HTML parser ID detection is done automatically.
    In XML documents, all "xml:id" attributes are considered to be of type ID.
=end pod

method Str is also<getValue> { $.nodeValue}
method setValue(Str $_) { $.nodeValue = $_ }
method gist(|c) { $.raw.Str(|c).trim }
method ast { self.nodeName => self.nodeValue }

method validate($elem) { self.ownerDocument.validate($elem, self) }
method is-valid($elem) { self.ownerDocument.is-valid($elem, self) }

=begin pod
    =head3 method getOwnerElement

        method getOwnerElement() returns LibXML::Element;

    Returns the node the attribute belongs to. If the attribute is not bound to a
    node, LibXML::Element:U will be returned.

    =head3 method setNamespace

        method setNamespace(Str $nsURI, NCName $prefix);

    This function tries to bound the attribute to a given namespace. If C<$nsURI> is undefined or empty, the function discards any previous association of the
    attribute with a namespace. If the namespace was not previously declared in the
    context of the attribute, this function will fail. In this case you may wish to
    call setNamespace() on the ownerElement. If the namespace URI is non-empty and
    declared in the context of the attribute, but only with a different (non-empty)
    prefix, then the attribute is still bound to the namespace but gets a different
    prefix than C<$prefix>. The function also fails if the prefix is empty but the namespace URI is not
    (because unprefixed attributes should by definition belong to no namespace).
    This function returns True on success, Failure otherwise.

    If you don't want the overheads of managing namespaces, a quick way of ensuring
    that the namespace is not rejected is to call the `requireNamespace` method on
    the containing node:

        # re-use any existing definitions in the current scope, or add to the
        # parent with a generated prefix
        my $prefix = $att.parent.requireNamespace($uri);
        $att.setNamespace($uri, $prefix);

    =head3 method serializeContent

        method serializeContent() returns Bool

    This function is not part of DOM API. It returns attribute content in the form
    in which it serializes into XML, that is with all meta-characters properly
    quoted and with raw entity references (except for entities expanded during
    parse time).
=end pod

#| DOM level-2 method NYI
method specified { die X::NYI.new }

=begin pod
=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
