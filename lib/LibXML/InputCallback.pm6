use v6;

unit class LibXML::InputCallback;

use LibXML::Native;

my class CallbackGroup {
    has &.match is required;
    has &.open  is required;
    has &.read  is required;
    has &.close is required;
    has Str $.trace;
}

my class Context {
    use NativeCall;
    use LibXML::Native::Defs :CLIB;
    use LibXML::ErrorHandler;

    has CallbackGroup $.cb is required;
    has LibXML::ErrorHandler $.errors handles<flush-errors> .= new;

    method !catch(Exception $error) {
        CATCH { default { warn "error handling callback error: $_" } }
        $!errors.callback-error: X::LibXML::IO::AdHoc.new: :$error; 
    }

    my class Handle {
        has Pointer $.addr;
        method addr { do with self { $!addr } // Pointer }
        has $.fh is rw;
        has Blob $.buf is rw;
        sub malloc(size_t --> Pointer) is native(CLIB) {*}
        sub free(Pointer:D) is native(CLIB) {*}
        submethod TWEAK   { $!addr = malloc(1); }
        submethod DESTROY { free($_) with $!addr }
    }
    has Handle %.handles{UInt};

    sub memcpy(CArray[uint8], CArray[uint8], size_t --> CArray[uint8]) is native(CLIB) {*}

    method match {
        sub (Str:D $file --> Int) {
            CATCH { default { self!catch($_); return 0; } }
            my $rv := + $!cb.match.($file).so;
            note "$_: match $file --> $rv" with $!cb.trace;
            $rv;
        }
    }

    method open {
        sub (Str:D $file --> Pointer) {
            CATCH { default { self!catch($_); return Pointer; } }
            my $fh = $!cb.open.($file);
            with $fh {
                my Handle $handle .= new: :$fh;
                %!handles{+$handle.addr} = $handle;
                note "$_: open $file --> {+$handle.addr}" with $!cb.trace;
                $handle.addr;
            }
            else {
                note "$_: open $file --> 0" with $!cb.trace;
                Pointer;
            }
        }
    }

    method read {
        sub (Pointer $addr, CArray $out-arr, UInt $bytes --> UInt) {
            CATCH { default { self!catch($_); return 0; } }

            my Handle $handle = %!handles{+$addr}
                // die "read on unopen handle";

            given $handle.buf // $!cb.read.($handle.fh, $bytes) -> Blob $io-buf {
                my UInt:D $n-read := do with $io-buf {.bytes} else {0};
                if $n-read {
                    if $n-read > $bytes {
                        # read-buffer exceeds output buffer size;
                        # buffer the excess
                        $handle.buf = $io-buf.subbuf($bytes);
                        $io-buf .= subbuf(0, $bytes);
                        $n-read = $bytes;
                    }
                    else {
                        $handle.buf = Nil;
                    }

                    note "$_\[{+$addr}\]: read $bytes --> $n-read" with $!cb.trace;
                    my CArray[uint8] $io-arr := nativecast(CArray[uint8], $io-buf);
                    memcpy($out-arr, $io-arr, $n-read)
                }
                else {
                    note "$_\[{+$addr}\]: read $bytes --> EOF" with $!cb.trace;
                }

                $n-read;
            }
        }
    }

    method close {
        sub (Pointer:D $addr --> Int) {
            CATCH { default { self!catch($_); return -1 } }
            note "$_\[{+$addr}\]: close --> 0" with $!cb.trace;
            my Handle $handle = %!handles{+$addr}
                // die (+$addr).fmt("close on unopened input callback context: 0x%X");
            $!cb.close.($handle.fh);
            %!handles{+$addr}:delete;

            0;
        }
    }
}

has CallbackGroup @!callbacks;
method callbacks { @!callbacks }

multi method TWEAK( Hash :callbacks($_)! ) {
    @!callbacks = CallbackGroup.new(|$_)
}
multi method TWEAK( List :callbacks($_)! ) {
    self.register-callbacks: |$_;
}
multi method TWEAK is default {
}

multi method register-callbacks( @ (&match, &open, &read, &close = sub ($) {}), |c) {
    $.register-callbacks( :&match, :&open, :&read, :&close, |c);
}
multi method register-callbacks( &match, &open, &read, &close = sub ($) {}, |c) {
    $.register-callbacks( :&match, :&open, :&read, :&close, |c);
}
multi method register-callbacks(:&close = sub ($) {}, *%opts) is default {
    my CallbackGroup $cb .= new: :&close, |%opts;
    @!callbacks.push: $cb;
}


multi method unregister-callbacks( @ (&match, &open, &read, &close), |c) {
    $.unregister-callbacks( :&match, :&open, :&read, :&close, |c);
}
multi method unregister-callbacks( &match, &open, &read, &close, |c) {
    $.unregister-callbacks( :&match, :&open, :&read, :&close, |c);
}
multi method unregister-callbacks( :&match, :&open, :&read, :&close) is default {
    @!callbacks .= grep: {
        (!&match.defined || &match !=== .match)
           && (!&open.defined  || &open  !=== .open)
           && (!&read.defined  || &read  !=== .read)
           && (!&close.defined || &close !=== .close)
    }
}

method append(LibXML::InputCallback $icb) {
    @!callbacks.append: $icb.callbacks;
}

method prepend(LibXML::InputCallback $icb) {
    @!callbacks.prepend: $icb.callbacks;
}

method make-contexts {
    @!callbacks.map: -> $cb { Context.new: :$cb }
}

method activate {
    # just to make sure we've initialised
    xmlRegisterDefaultInputCallbacks();

    my @input-contexts = @.make-contexts();

    for @input-contexts {
        die "unable to register input callbacks"
            if xmlRegisterInputCallbacks(.match, .open, .read, .close) < 0;
    }
    @input-contexts;
}

method deactivate {
    for @!callbacks {
        warn "unable to remove input callbacks"
            if xmlPopInputCallbacks() < 0;
    }
}

=begin pod
=head1 NAME

LibXML::InputCallback - LibXML Class for Input Callbacks

=head1 SYNOPSIS



  use LibXML::InputCallback;
  my LibXML::InputCallback $icb .= new;
  $icb.register-callbacks(
            match => -> Str $file --> Bool { -e $file },
            open  => -> Str $file --> Any:D { $file.IO.open(:r); },
            read  => -> Any:D $fh, UInt $n --> Blob { $fh.read($n); },
            close => -> $fh { $fh.close },
        );


=head1 DESCRIPTION

You may get unexpected results if you are trying to load external documents
during libxml2 parsing if the location of the resource is not a HTTP, FTP or
relative location but a absolute path for example. To get around this
limitation, you may add your own input handler to open, read and close
particular types of locations or URI classes. Using this input callback
handlers, you can handle your own custom URI schemes for example.

The input callbacks are used whenever LibXML has to get something other than
externally parsed entities from somewhere. They are implemented using a
callback stack on the Perl layer in analogy to libxml2's native callback stack.

The LibXML::InputCallback class transparently registers the input callbacks for
the libxml2's parser processes.


=head2 How does LibXML::InputCallback work?

The libxml2 library offers a callback implementation as global functions only.
To work-around the troubles resulting in having only global callbacks - for
example, if the same global callback stack is manipulated by different
applications running together in a single Apache Web-server environment -,
LibXML::InputCallback comes with a object-oriented interface.

Using the function-oriented part the global callback stack of libxml2 can be
manipulated. Those functions can be used as interface to the callbacks on the
C- and XS Layer. At the object-oriented part, operations for working with the
"pseudo-localized" callback stack are implemented. Currently, you can register
and de-register callbacks on the Perl layer and initialize them on a per parser
basis.


=head3 Callback Groups

The libxml2 input callbacks come in groups. One group contains a URI matcher (I<<<<<< match >>>>>>), a data stream constructor (I<<<<<< open >>>>>>), a data stream reader (I<<<<<< read >>>>>>), and a data stream destructor (I<<<<<< close >>>>>>). The callbacks can be manipulated on a per group basis only.


=head3 The Parser Process

The parser process works on an XML data stream, along which, links to other
resources can be embedded. This can be links to external DTDs or XIncludes for
example. Those resources are identified by URIs. The callback implementation of
libxml2 assumes that one callback group can handle a certain amount of URIs and
a certain URI scheme. Per default, callback handlers for I<<<<<< file://* >>>>>>, I<<<<<< file:://*.gz >>>>>>, I<<<<<< http://* >>>>>> and I<<<<<< ftp://* >>>>>> are registered.

Callback groups in the callback stack are processed from top to bottom, meaning
that callback groups registered later will be processed before the earlier
registered ones.

While parsing the data stream, the libxml2 parser checks if a registered
callback group will handle a URI - if they will not, the URI will be
interpreted as I<<<<<< file://URI >>>>>>. To handle a URI, the I<<<<<< match >>>>>> callback will have to return True. If that happens, the handling of the URI will
be passed to that callback group. Next, the URI will be passed to the I<<<<<< open >>>>>> callback, which should return a defined data streaming object if it successfully opened the file, or an undefined value otherwise. If
opening the stream was successful, the I<<<<<< read >>>>>> callback will be called repeatedly until it returns an empty string. After the
read callback, the I<<<<<< close >>>>>> callback will be called to close the stream.


=head3 Organisation of callback groups in LibXML::InputCallback

Callback groups are implemented as a stack (Array), each entry holds a
an array of the callbacks. For the libxml2 library, the
LibXML::InputCallback callback implementation appears as one single callback
group. The Perl implementations however allows one to manage different callback
stacks on a per libxml2-parser basis.


=head2 Using LibXML::InputCallback

After object instantiation using the parameter-less constructor, you can
register callback groups.



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

Note that this Perl 6 port does not currently support the old Perl 5 Global Callback mechanism.

=head1 INTERFACE DESCRIPTION


=head2 Class methods

=begin item1
new()

A simple constructor.

=end item1

=begin item1
register-callbacks( &$match-cb, &open-cb, &read-cb, &close-cb);
register-callbacks( match => &$match-cb, open => &open-cb,
                    read => &read-cb, close => &close-cb);

The four callbacks I<<<<<< have >>>>>> to be given as array in the above order I<<<<<< match >>>>>>, I<<<<<< open >>>>>>, I<<<<<< read >>>>>>, I<<<<<< close >>>>>>!

=end item1

=begin item1
unregister-callbacks( $match-cb, $open-cb, $read-cb, $close-cb )

With no arguments given, C<<<<<< unregister-callbacks() >>>>>> will delete the last registered callback group from the stack. If four
callbacks are passed as array, the callback group to unregister will
be identified by the I<<<<<< match >>>>>> callback and deleted from the callback stack. Note that if several identical I<<<<<< match >>>>>> callbacks are defined in different callback groups, ALL of them will be deleted
from the stack.

=end item1


=head1 EXAMPLE CALLBACKS

The following example is a purely fictitious example that uses a
minimal MyScheme::Handler stub object.

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

=head1 COPYRIGHT

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=end pod
