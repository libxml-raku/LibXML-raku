#| XInclude Processing Context
unit class LibXML::XInclude::Context;

use LibXML::_Configurable;
also does LibXML::_Configurable;

use LibXML::ErrorHandling;
also does LibXML::ErrorHandling;

use LibXML::_Options;
use LibXML::Parser::Context;
constant %Opts = %(
    %LibXML::Parser::Context::Opts, %(:config);
);
also does LibXML::_Options[%Opts];

use NativeCall;

=begin pod
    =head2 Synopsis

      use LibXML::XInclude::Context;
      my LibXML::XInclude::Context $xic .= new();
      $xic.process-xincludes($doc);

    =head2 Description

    XInclude processing context.

=end pod

use LibXML::Config;
use LibXML::Document;    
use LibXML::Raw;

has LibXML::Document:D $.doc is required;
has xmlXIncludeCtxt:D $.raw .= new: :doc($!doc.raw);
has uint32 $.flags = self.config.parser-flags;

# for the LibXML::ErrorHandling role
has Bool ($.recover, $.suppress-errors, $.suppress-warnings) is rw;

=head2 Methods


submethod TWEAK(:raw($), *%opts) is hidden-from-backtrace {
    
    fail "This version of libxml ({self.config.version}) is too old to use XInclude contexts"
        unless self.config.version >= v2.13.00;

    $!raw.SetFlags($!flags);
    self.init-local-error-handling;
}

submethod DESTROY {
    .Free with $!raw;
}

multi method process-xincludes(::?CLASS:U: LibXML::Document:D :$doc!, *%opts --> Int) is hidden-from-backtrace {
    self.new(:$doc, |%opts).process-xincludes;
}

multi method process-xincludes(::?CLASS:D: LibXML::Element:D :$elem = $!doc.root --> Int) is hidden-from-backtrace {
    self.do: :$!raw, {
        $!raw.ProcessNode($elem.raw);
    }
}

=begin pod

=head2 Copyright

2001-2007, AxKit.com Ltd.

2002-2006, Christian Glahn.

2006-2009, Petr Pajas.

=head2 License

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>.

=end pod
