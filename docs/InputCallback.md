class LibXML::InputCallback
---------------------------

LibXML Input Callbacks

Example
-------

```raku
use LibXML::InputCallback;
my LibXML::InputCallback $icb .= new: :callbacks{
    match => -> Str $file --> Bool { $file.starts-with('file:') },
    open  => -> Str $file --> IO::Handle { $file.substr(5).IO.open(:r); },
    read  => -> IO::Handle:D $fh, UInt $n --> Blob { $fh.read($n); },
    close => -> IO::Handle:D $fh { $fh.close },
};
```

Description
-----------

You may get unexpected results if you are trying to load external documents during libxml2 parsing if the location of the resource is not a HTTP, FTP or relative location but a absolute path for example. To get around this limitation, you may add your own input handler to open, read and close particular types of locations or URI classes. Using this input callback handlers, you can handle your own custom URI schemes for example.

The input callbacks are used whenever LibXML has to get something other than externally parsed entities from somewhere. They are implemented using a callback stack on the Raku layer in analogy to libxml2's native callback stack.

The LibXML::InputCallback class transparently registers the input callbacks for the libxml2's parser processes.

How does LibXML::InputCallback work?
------------------------------------

The libxml2 library offers a callback implementation as global functions only. To work-around the troubles resulting in having only global callbacks - for example, if the same global callback stack is manipulated by different applications running together in a single Apache Web-server environment -, LibXML::InputCallback comes with a object-oriented interface.

Using the function-oriented part the global callback stack of libxml2 can be manipulated. Those functions can be used as interface to the callbacks on the C Layer. At the object-oriented part, operations for working with the "pseudo-localized" callback stack are implemented. Currently, you can register and de-register callbacks on the Raku layer and initialize them on a per parser basis.

### Callback Groups

The libxml2 input callbacks come in groups. Each group contains a URI matcher (*match*), a data stream constructor (*open*), a data stream reader (*read*), and a data stream destructor (*close*). The callbacks can be manipulated on a per group basis only.

### The Parser Process

The parser process works on an XML data stream, along which, links to other resources can be embedded. This can be links to external DTDs or XIncludes for example. Those resources are identified by URIs. The callback implementation of libxml2 assumes that one callback group can handle a certain amount of URIs and a certain URI scheme. Per default, callback handlers for *file://**, *file:://*.gz*, *http://** and *ftp://** are registered.

Callback groups in the callback stack are processed from top to bottom, meaning that callback groups registered later will be processed before the earlier registered ones.

While parsing the data stream, the libxml2 parser checks if a registered callback group will handle a URI - if they will not, the URI will be interpreted as *file://URI*. To handle a URI, the *match* callback will have to return True. If that happens, the handling of the URI will be passed to that callback group. Next, the URI will be passed to the *open* callback, which should return a defined data streaming object if it successfully opened the file, or an undefined value otherwise. If opening the stream was successful, the *read* callback will be called repeatedly until it returns an empty string. After the read callback, the *close* callback will be called to close the stream.

### Organisation of callback groups in LibXML::InputCallback

Callback groups are implemented as a stack (Array), each entry holds a an array of the callbacks. For the libxml2 library, the LibXML::InputCallback callback implementation appears as one single callback group. The Raku implementation however allows one to manage different callback stacks on a per libxml2-parser basis.

Using LibXML::InputCallback
---------------------------

After object instantiation using the parameter-less constructor, you can register callback groups.

```raku
my LibXML::InputCallback.$input-callbacks . = new(
  :&match, :&open, :&read, :&close);
# setup second callback group (named arguments)
$input-callbacks.register-callbacks(match => &match-cb2, open => &open-cb2,
                                    read => &read-cb2, close => &close-cb2);
# setup third callback group (positional arguments)
$input-callbacks.register-callbacks(&match-cb3, &open-cb3,
                                    &read-cb3, &close-cb3);

$parser.input-callbacks = $input-callbacks;
$parser.parse: :file( $some-xml-file );
```

Note that this Raku port does not currently support the old Perl Global Callback mechanism.

Methods
-------

### method new

```raku
    multi method new(Callable :%callbacks) returns LibXML::InoputCallback
    multi method new(Hash :@callbacks) returns LibXML::InoputCallback
```

A simple constructor.

A `:callbacks` Hash option can be provided with `match`, `open`, `read` and `close` members; these represent one callback group to be registered. Or a List of such hashes to register multiple callback groups.

### method register-callbacks

```raku
multi method register-callbacks(:&match!, :&open!, :&read!, :&close);
# Perl compatibility
multi method register-callbacks( &match, &open, &read, &close?);
multi method register-callbacks( @ (&match, &open, &read, &close?));
```

The four input callbacks in a group are supplied via the `:match`, `:open`, `:read`, and `:close` options.

For Perl compatibility, the four callbacks may be given as array, or positionally in the above order *match*, *open*, *read*, *close*!

### method unregister-callbacks

```raku
multi method unregister-callbacks(:&match, :&open, :&read, :&close);
# Perl compatibility
multi method unregister-callbacks( &match?, &open?, &read?, &close?);
multi method unregister-callbacks( @ (&match?, &open?, &read?, &close?));
```

With no arguments given, `unregister-callbacks()` will delete the last registered callback group from the stack. If four callbacks are passed as array, the callback group to unregister will be identified by supplied callbacks and deleted from the callback stack. Note that if several callback groups match, ALL of them will be deleted from the stack.

Example Callbacks
-----------------

The following example is a purely fictitious example that uses a minimal MyScheme::Handler stub object.

```raku
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
my LibXML $parser .= new;
$parser.input-callbacks = $input-callbacks;

# $some-xml-file will be parsed using our callbacks
$parser.parse: :file('myscheme:stub.xml')
```

Copyright
---------

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

License
-------

This program is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0 [http://www.perlfoundation.org/artistic_license_2_0](http://www.perlfoundation.org/artistic_license_2_0).

