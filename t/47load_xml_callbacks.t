#!/usr/bin/perl

# Fix the handling of XML::LibXML::InputCallbacks at load_xml().
# - https://rt.cpan.org/Ticket/Display.html?id=58190
# - The problem was that the input callbacks were not cloned in
# _clone().

use LibXML;
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

    $xml_parser.load: :xml, location => $TEST_FILENAME;

    # TEST
    ok($got_open, 'load_xml() encountered the open InputCallback');

    # TEST
    ok($got_read, 'load_xml() encountered the read InputCallback');

    # TEST
    todo "not being called";
    ok($got_close, 'load_xml() encountered the close InputCallback');
}
