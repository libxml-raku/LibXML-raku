NAME
====

LibXML::InputCallback - LibXML Class for Input Callbacks

SYNOPSIS
========

    use LibXML::InputCallback;
    my LibXML::InputCallback $icb .= new;
    $icb.register-callbacks(
              match => -> Str $file --> Bool { -e $file },
              open  => -> Str $file --> Any:D { $file.IO.open(:r); },
              read  => -> Any:D $fh, UInt $n --> Blob { $fh.read($n); },
              close => -> $fh { $fh.close },
          );

DESCRIPTION
===========

You may get unexpected results if you are trying to load external documents during libxml2 parsing if the location of the resource is not a HTTP, FTP or relative location but a absolute path for example. To get around this limitation, you may add your own input handler to open, read and close particular types of locations or URI classes. Using this input callback handlers, you can handle your own custom URI schemes for example.

The input callbacks are used whenever LibXML has to get something other than externally parsed entities from somewhere. They are implemented using a callback stack on the Perl layer in analogy to libxml2's native callback stack.

The LibXML::InputCallback class transparently registers the input callbacks for the libxml2's parser processes.

How does LibXML::InputCallback work?
------------------------------------

The libxml2 library offers a callback implementation as global functions only. To work-around the troubles resulting in having only global callbacks - for example, if the same global callback stack is manipulated by different applications running together in a single Apache Web-server environment -, LibXML::InputCallback comes with a object-oriented interface.

Using the function-oriented part the global callback stack of libxml2 can be manipulated. Those functions can be used as interface to the callbacks on the C- and XS Layer. At the object-oriented part, operations for working with the "pseudo-localized" callback stack are implemented. Currently, you can register and de-register callbacks on the Perl layer and initialize them on a per parser basis.

### Callback Groups

The libxml2 input callbacks come in groups. One group contains a URI matcher (*match *), a data stream constructor (*open *), a data stream reader (*read *), and a data stream destructor (*close *). The callbacks can be manipulated on a per group basis only.

### The Parser Process

The parser process works on an XML data stream, along which, links to other resources can be embedded. This can be links to external DTDs or XIncludes for example. Those resources are identified by URIs. The callback implementation of libxml2 assumes that one callback group can handle a certain amount of URIs and a certain URI scheme. Per default, callback handlers for *file://* *, *file:://*.gz *, *http://* * and *ftp://* * are registered.

Callback groups in the callback stack are processed from top to bottom, meaning that callback groups registered later will be processed before the earlier registered ones.

While parsing the data stream, the libxml2 parser checks if a registered callback group will handle a URI - if they will not, the URI will be interpreted as *file://URI *. To handle a URI, the *match * callback will have to return True. If that happens, the handling of the URI will be passed to that callback group. Next, the URI will be passed to the *open * callback, which should return a *reference * to the data stream if it successfully opened the file, '0' otherwise. If opening the stream was successful, the *read * callback will be called repeatedly until it returns an empty string. After the read callback, the *close * callback will be called to close the stream.

### Organisation of callback groups in LibXML::InputCallback

Callback groups are implemented as a stack (Array), each entry holds a reference to an array of the callbacks. For the libxml2 library, the LibXML::InputCallback callback implementation appears as one single callback group. The Perl implementation however allows one to manage different callback stacks on a per libxml2-parser basis.

Using LibXML::InputCallback
---------------------------

After object instantiation using the parameter-less constructor, you can register callback groups.

my LibXML::InputCallback.$input-callbacks . = new( :&match, :&open, :&read, :&close); # setup second callback group (named arguments) $input-callbacks.register-callbacks(match => &match-cb2, open => &open-cb2, read => &read-cb2, close => &close-cb2); # setup third callback group (positional arguments) $input-callbacks.register-callbacks(&match-cb3, &open-cb3, &read-cb3, &close-cb3);

    $parser.input-callbacks = $input-callbacks;
    $parser.parse: :file( $some-xml-file );

Note that this Perl 6 port does not currently support the old Perl 5 Global Callback mechanism.

INTERFACE DESCRIPTION
=====================

Class methods
-------------

  * new()

    A simple constructor.

  * register-callbacks( &$match-cb, &open-cb, &read-cb, &close-cb); register-callbacks( match => &$match-cb, open => &open-cb, read => &read-cb, close => &close-cb);

    The four callbacks *have * to be given as array reference in the above order *match *, *open *, *read *, *close *!

  * unregister-callbacks( $match-cb, $open-cb, $read-cb, $close-cb )

    With no arguments given, `unregister-callbacks() ` will delete the last registered callback group from the stack. If four callbacks are passed as array reference, the callback group to unregister will be identified by the *match * callback and deleted from the callback stack. Note that if several identical *match * callbacks are defined in different callback groups, ALL of them will be deleted from the stack.

EXAMPLE CALLBACKS
=================

The following example is a purely fictitious example that uses a minimal MyScheme::Handler stub object.

    use LibXML::Parser;
    use LibXML::InputCallBack;

    my class MyScheme {
          subset URI of Str where .starts-with('myscheme:');
          our class Handler {
              has URI:D $.uri is required;
              has Bool $!first = True;

              method read($len) {
                  ($!first-- ?? '<helloworld/>' !! '').encode;
              }
              method close {$!first = True}
          }
    }
    # Define the four callback functions
    sub match-uri(Str $uri) {
        $uri ~~ MyScheme::URI:D; # trigger our callback group at a 'myscheme' URIs
    }

    sub open-uri(MyScheme::URI:D $uri) {
        MyScheme::Handler.new(:$uri);
    }

    # The returned $buffer will be parsed by the libxml2 parser
    sub read-uri(MyScheme::Handler:D $handler, UInt $n --> Blob) {
        $handler.read($n);
    }

    # Close the handle associated with the resource.
    sub close-uri(MyScheme::Handler:D $handler) {
        $handler.close;
    }

    # Register them with a instance of LibXML::InputCallback
    my LibXML::InputCallback $input-callbacks .= new;
    $input-callbacks.register-callbacks(&match-uri, &open-uri,
                                        &read-uri, &close-uri );

    # Register the callback group at a parser instance
    $parser.input-callbacks = $input-callbacks;

    # $some-xml-file will be parsed using our callbacks
    my LibXML $parser .= new;
    $parser.parse: :file('myscheme:stub.xml')

AUTHORS
=======

Matt Sergeant, Christian Glahn, Petr Pajas, 

VERSION
=======

2.0200

COPYRIGHT
=========

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

LICENSE
=======

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

