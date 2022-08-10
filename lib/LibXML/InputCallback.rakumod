#| LibXML Input Callbacks
unit class LibXML::InputCallback;

=begin pod
    =head2 Example

      use LibXML::InputCallback;
      use LibXML::Config;
      my LibXML::InputCallback $icb .= new: :callbacks{
          match => -> Str $file --> Bool { $file.starts-with('file:') },
          open  => -> Str $file --> IO::Handle { $file.substr(5).IO.open(:r); },
          read  => -> IO::Handle:D $fh, UInt $n --> Blob { $fh.read($n); },
          close => -> IO::Handle:D $fh { $fh.close },
      };
      LibXML::Config.input-callbacks = $icb;

    =head2 Description

    You may get unexpected results if you are trying to load external documents
    during libxml2 parsing if the location of the resource is not a HTTP, FTP or
    relative location but a absolute path for example. To get around this
    limitation, you may add your own input handler to open, read and close
    particular types of locations or URI classes. Using this input callback
    handlers, you can handle your own custom URI schemes for example.

    The input callbacks are used whenever LibXML has to get something other than
    externally parsed entities from somewhere. They are implemented using a
    callback stack on the Raku layer in analogy to libxml2's native callback stack.

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
    C Layer. At the object-oriented part, operations for working with the
    "pseudo-localized" callback stack are implemented. Currently, you can register
    and de-register callbacks on the Raku layer and initialize them on a per parser
    basis.


    =head3 Callback Groups

    The libxml2 input callbacks come in groups. Each group contains a URI matcher (I<match>), a data stream constructor (I<open>), a data stream reader (I<read>), and a data stream destructor (I<close>). The callbacks can be manipulated on a per group basis only.


    =head3 The Parser Process

    The parser process works on an XML data stream, along which, links to other
    resources can be embedded. This can be links to external DTDs or XIncludes for
    example. Those resources are identified by URIs. The callback implementation of
    libxml2 assumes that one callback group can handle a certain amount of URIs and
    a certain URI scheme. Per default, callback handlers for I<file://*>, I<file:://*.gz>, I<http://*> and I<ftp://*> are registered.

    Callback groups in the callback stack are processed from top to bottom, meaning
    that callback groups registered later will be processed before the earlier
    registered ones.

    While parsing the data stream, the libxml2 parser checks if a registered
    callback group will handle a URI - if they will not, the URI will be
    interpreted as I<file://URI>. To handle a URI, the I<match> callback will have to return True. If that happens, the handling of the URI will
    be passed to that callback group. Next, the URI will be passed to the I<open> callback, which should return a defined data streaming object if it successfully opened the file, or an undefined value otherwise. If
    opening the stream was successful, the I<read> callback will be called repeatedly until it returns an empty string. After the
    read callback, the I<close> callback will be called to close the stream.


    =head3 Organisation of callback groups in LibXML::InputCallback

    Callback groups are implemented as a stack (Array), each entry holds a
    an array of the callbacks. For the libxml2 library, the
    LibXML::InputCallback callback implementation appears as one single callback
    group. The Raku implementation however allows one to manage different callback
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

      # set up global input callbacks for the process
      LibXML::Config.input-callbacks = $input-callbacks;
      # -- OR --
      # set up parser specific callbacks
      LibXML::Config.parser-locking = True;
      $parser.input-callbacks = $input-callbacks;
      $parser.parse: :file( $some-xml-file );

=end pod

use LibXML::Raw;
use LibXML::_Configurable;

also does LibXML::_Configurable;

my class CallbackGroup {
    has &.match is required;
    has &.open  is required;
    has &.read  is required;
    has &.close is required;
    has Str $.trace;
}

my class Context {
    use NativeCall;
    use LibXML::Raw::Defs :$CLIB;
    use LibXML::_Configurable;
    use LibXML::_Options;
    use LibXML::ErrorHandling;
    use Method::Also;

    has CallbackGroup $.cb is required;
    # for the LibXML::ErrorHandling role
    has $.sax-handler is rw;
    has Bool ($.recover, $.suppress-errors, $.suppress-warnings) is rw;
    also does LibXML::_Options[%( :sax-handler, :recover, :suppress-errors, :suppress-warnings)];
    also does LibXML::ErrorHandling;
    also does LibXML::_Configurable;

    method !catch(Exception $error) {
        CATCH { default { note "input callback error handling error: $_" } }
        self.callback-error: $error;
    }

    my class Handle {
        has CArray[uint8] $.addr .= new(42); # get a unique address
        method addr { do with self { nativecast(Pointer, $!addr) } }
        has $.fh is rw;
        has Blob $.buf is rw;
    }
    has Handle %.handles{UInt};
    has Lock $!lock .= new;

    sub memcpy(CArray[uint8], Blob, size_t --> CArray[uint8]) is native($CLIB) {*}

    method match {
        -> Str:D $file --> Int {
            CATCH { default { self!catch($_); 0; } }
            my $rv := + $!cb.match.($file).so.Int;
            note "$_: match $file --> $rv" with $!cb.trace;
            $rv;
        }
    }

    method open {
        -> Str:D $file --> Pointer {
            CATCH { default { self!catch($_); Pointer; } }
            my $fh = $!cb.open.($file);
            with $fh {
                my Handle $handle .= new: :$fh;
                $!lock.protect: { %!handles{+$handle.addr} = $handle };
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
        -> Pointer $addr, CArray $out-arr, UInt $bytes --> UInt {
            CATCH { default { self!catch($_); 0; } }

            my Handle $handle = $!lock.protect({ %!handles{+$addr} })
                // die "read on unopen handle";

            given $handle.buf // $!cb.read.($handle.fh, $bytes) -> Blob $io-buf is copy {
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
                    memcpy($out-arr, $io-buf, $n-read)
                }
                else {
                    note "$_\[{+$addr}\]: read $bytes --> EOF" with $!cb.trace;
                }

                $n-read;
            }
        }
    }

    method close {
        -> Pointer:D $addr --> Int {
            CATCH { default { self!catch($_); -1 } }
            note "$_\[{+$addr}\]: close --> 0" with $!cb.trace;
            $!lock.protect: {
                my Handle $handle = %!handles{+$addr}
                    // die (+$addr).fmt("close on unopened input callback context: 0x%X");
                $!cb.close.($handle.fh);
                %!handles{+$addr}:delete;
            }
            0;
        }
    }
}

has CallbackGroup @!callbacks;
has $!active;
method callbacks { @!callbacks }

multi method COERCE(%callbacks) { self.new: :%callbacks }
multi method COERCE(@callbacks) { self.new: :@callbacks }

method !active-check is hidden-from-backtrace {
    die "input callbacks cannot be reconfigured while active"
        if $!active;
}

=head2 Methods

multi submethod TWEAK( Hash :callbacks($_)! ) {
    @!callbacks = CallbackGroup.new(|$_)
}
multi submethod TWEAK( List :callbacks($_)! ) {
    self.register-callbacks: |$_;
}
multi submethod TWEAK { }

=begin pod
    =head3 method new

        multi method new(Callable :%callbacks) returns LibXML::InputCallback
        multi method new(Hash :@callbacks) returns LibXML::InputCallback

    A simple constructor.

    A `:callbacks` Hash option can be provided with `match`, `open`, `read` and `close`
    members; these represent one callback group to be registered. Or a List of such
    hashes to register multiple callback groups.
=end pod

multi method register-callbacks( @ (&match, &open, &read, &close = sub ($) {}), |c) {
    $.register-callbacks( :&match, :&open, :&read, :&close, |c);
}
multi method register-callbacks( &match, &open, &read, &close = sub ($) {}, |c) {
    $.register-callbacks( :&match, :&open, :&read, :&close, |c);
}
multi method register-callbacks(:&match!, :&open!, :&read!, :&close = sub ($) {}, Str :$trace) is default {
    self!active-check;
    my CallbackGroup $cb .= new: :&match, :&open, :&read, :&close, :$trace;
    @!callbacks.push: $cb;
}
=begin pod
=head3 method register-callbacks

  multi method register-callbacks(:&match!, :&open!, :&read!, :&close);
  # Perl compatibility
  multi method register-callbacks( &match, &open, &read, &close?);
  multi method register-callbacks( @ (&match, &open, &read, &close?));

The four input callbacks in a group are supplied via the `:match`, `:open`, `:read`, and `:close` options.

For Perl compatibility, the four callbacks may be given as array, or positionally in the above order I<match>, I<open>, I<read>, I<close>!

=end pod


multi method unregister-callbacks( @ (&match, &open?, &read?, &close?), |c) {
    $.unregister-callbacks( :&match, :&open, :&read, :&close, |c);
}
multi method unregister-callbacks( &match, &open?, &read?, &close?, |c) {
    $.unregister-callbacks( :&match, :&open, :&read, :&close, |c);
}
multi method unregister-callbacks( :&match, :&open, :&read, :&close) is default {
    self!active-check;
    with &match // &open // &read // &close {
        @!callbacks .= grep: {
            (!&match.defined || &match !=== .match)
            && (!&open.defined  || &open  !=== .open)
            && (!&read.defined  || &read  !=== .read)
            && (!&close.defined || &close !=== .close)
        }
    }
    elsif @!callbacks -> $_ {
        .pop;
    }
}
=begin pod
    =head3 method unregister-callbacks

        multi method unregister-callbacks(:&match, :&open, :&read, :&close);
        # Perl compatibility
        multi method unregister-callbacks( &match?, &open?, &read?, &close?);
        multi method unregister-callbacks( @ (&match?, &open?, &read?, &close?));

    With no arguments given, C<unregister-callbacks()> will delete the last registered callback group from the stack. If four
    callbacks are passed as array, the callback group to unregister will
    be identified by supplied callbacks and deleted from the callback stack. Note that if several callback groups match, ALL of them will be deleted
    from the stack.
=end pod



method append(LibXML::InputCallback $icb) {
    self!active-check;
    @!callbacks.append: $icb.callbacks;
}

method prepend(LibXML::InputCallback $icb) {
    self!active-check;
    @!callbacks.prepend: $icb.callbacks;
}

method make-contexts {
    @!callbacks.map: -> $cb { self.create: Context, :$cb }
}

method activate {
    # just to make sure we've initialised
    xmlInputCallbacks::RegisterDefault();

    my @input-contexts = @.make-contexts;

    for @input-contexts {
        die "unable to register input callbacks"
            if xmlInputCallbacks::Register(.match, .open, .read, .close) < 0;
    }
    $!active = True;
    @input-contexts;
}

method deactivate {
    for @!callbacks {
        warn "unable to remove input callbacks"
            if xmlInputCallbacks::Pop() < 0;
    }
    $!active = False;
}

=begin pod

=head2 Example Callbacks

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

=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
