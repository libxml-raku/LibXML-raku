#!/usr/bin/perl

# ensure operation of input callbacks with .load()

use LibXML;
use LibXML::InputCallback;
use Test;
plan 3;

{
    my $got-open = 0;
    my $got-read = 0;
    my $got-close = 0;

    my LibXML::InputCallback $input-callbacks .= new();
    $input-callbacks.register-callbacks(
            -> $ { 1 },
            -> $file { $got-open = 1; $file.IO.open(:r) },
            -> $fh, $n { $got-read = 1; $fh.read($n); },
            -> $fh { $got-close = 1; $fh.close },
        );

    my LibXML $xml-parser .= new();
    $xml-parser.input-callbacks($input-callbacks);

    my $location = 'samples/dromeds.xml';

    $xml-parser.load: :$location;

    ok $got-open, 'load_xml() encountered the open InputCallback';

    ok $got-read, 'load_xml() encountered the read InputCallback';

    ok $got-close, 'load_xml() encountered the close InputCallback';
}
