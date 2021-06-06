#!/usr/bin/perl

# ensure operation of input callbacks with .load()

use LibXML;
use LibXML::InputCallback;
use Test;
plan 3;

{
    my $got_open = 0;
    my $got_read = 0;
    my $got_close = 0;

    my $input_callbacks = LibXML::InputCallback.new();
    $input_callbacks.register-callbacks(
            -> $ { 1 },
            -> $file { $got_open = 1; $file.IO.open(:r) },
            -> $fh, $n { $got_read = 1; $fh.read($n); },
            -> $fh { $got_close = 1; $fh.close },
        );

    my $xml_parser = LibXML.new();
    $xml_parser.input-callbacks($input_callbacks);

    my $TEST_FILENAME = 'example/dromeds.xml';

    $xml_parser.load: location => $TEST_FILENAME;

    ok($got_open, 'load_xml() encountered the open InputCallback');

    ok($got_read, 'load_xml() encountered the read InputCallback');

    ok($got_close, 'load_xml() encountered the close InputCallback');
}
