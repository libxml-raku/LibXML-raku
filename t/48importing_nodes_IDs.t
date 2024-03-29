use v6;
=begin pod

=head1 DESCRIPTION

Ensure IDs of elements are not lost when importing nodes from another document.
=end pod

use Test;
plan 4;

use LibXML;
use LibXML::Document;
use LibXML::Element;

{
    my LibXML::Document:D $doc = LibXML.load(string => q:to<EOT>);
    <root>
        <item xml:id="id1">item1</item>
    </root>
    EOT

    my LibXML::Element $elem = $doc.getElementById('id1');
    ok $elem.defined, 'Orig doc has id1';

    is $elem.textContent(), 'item1', 'Content of orig doc elem id1';

    my LibXML::Document:D $doc2 = LibXML.createDocument( "1.0", "UTF-8" );
    $doc2.setDocumentElement( $doc2.importNode( $doc.documentElement() ) );

    my LibXML::Element $elem2 = $doc2.getElementById('id1');
    ok defined($elem2), 'Doc2 after importNode has id1';

    is $elem2.textContent(), 'item1', 'Doc2 after importNode has id1';
}

=begin pod

=head1 COPYRIGHT & LICENSE

Copyright 2011 by Shlomi Fish

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=end pod
