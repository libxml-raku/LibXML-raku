#!/usr/bin/perl

# ensure operation of input callbacks with .load()
use Test;
plan 3;

use LibXML;
use LibXML::InputCallback;
use LibXML::Config;

LibXML::Config.parser-locking = True;

{
    my Bool $got-open;
    my Bool $got-read;
    my Bool $got-close;

    my LibXML::InputCallback $input-callbacks .= new();
    $input-callbacks.register-callbacks(
            -> $ { 1 },
            -> $file { $got-open++; $file.IO.open(:r) },
            -> $fh, $n { $got-read++; $fh.read($n); },
            -> $fh { $got-close++; $fh.close },
        );

    my LibXML $xml-parser .= new();
    $xml-parser.input-callbacks($input-callbacks);

    my $location = 'samples/dromeds.xml';

    $xml-parser.load: :$location;

    ok $got-open, 'load_xml() encountered the open InputCallback';

    ok $got-read, 'load_xml() encountered the read InputCallback';

    ok $got-close, 'load_xml() encountered the close InputCallback';
}
