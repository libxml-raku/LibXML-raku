[[Raku LibXML Project]](https://libxml-raku.github.io)
 / [[LibXML Module]](https://libxml-raku.github.io/LibXML-raku)
 / [DOM](https://libxml-raku.github.io/LibXML-raku/DOM)

Raku LibXML DOM Interface
=========================

The [W3C Level 2 Core DOM](https://www.w3.org/TR/2000/REC-DOM-Level-2-Core-20001113/core.html) a platform and language independent interface for accessing and manipulating documents.

[LibXML](https://libxml-raku.github.io/LibXML-raku) uses the [W3C::DOM](https://libxml-raku.github.io/W3C-DOM-raku) module to map classes and methods.

A quick summary of the Raku DOM implementation follows:

<table class="pod-table">
<thead><tr>
<th>W3C::DOM Role</th> <th>W3C::DOM Parent</th> <th>LibXML Class</th> <th>L1 Methods</th> <th>L2 Methods</th> <th>NYI</th>
</tr></thead>
<tbody>
<tr> <td>Node</td> <td></td> <td>LibXML::Node</td> <td>nodeName nodeValue parentNode childNodes firstChild lastChild previousSibling nextSibling ownerDocument insertBefore replaceChild removeChild appendChild hasChildNodes cloneNode</td> <td>normalize isSupported namespaceURI prefix localName hasAttributes</td> <td></td> </tr> <tr> <td>CharacterData</td> <td>Node</td> <td></td> <td>data length substringData appendData insertData deleteData replaceData</td> <td></td> <td></td> </tr> <tr> <td>Attr</td> <td>Node</td> <td>LibXML::Attr</td> <td>name value</td> <td>ownerElement</td> <td>specified</td> </tr> <tr> <td>CDATASection</td> <td>Text</td> <td>LibXML::CDATA</td> <td></td> <td></td> <td></td> </tr> <tr> <td>Comment</td> <td>CharacterData</td> <td>LibXML::Comment</td> <td></td> <td></td> <td></td> </tr> <tr> <td>Document</td> <td>Node</td> <td>LibXML::Document</td> <td>doctype implementation documentElement createElement createDocumentFragment createTextNode createComment createCDATASection createProcessingInstruction createAttribute createEntityReference getElementsByTagName</td> <td>importNode createElementNS createAttributeNS getElementsByTagNameNS getElementById</td> <td></td> </tr> <tr> <td>DocumentFragment</td> <td>Node</td> <td>LibXML::DocumentFragment</td> <td></td> <td></td> <td></td> </tr> <tr> <td>DocumentType</td> <td>Node</td> <td>LibXML::Dtd</td> <td>name publicId systemId</td> <td></td> <td>entities notations</td> </tr> <tr> <td>Element</td> <td>Node</td> <td>LibXML::Element</td> <td>attributes getAttribute setAttribute removeAttribute getAttributeNode setAttributeNode removeAttributeNode getElementsByTagName</td> <td>getAttributeNS setAttributeNS removeAttributeNS getAttributeNodeNS setAttributeNodeNS getElementsByTagNameNS hasAttribute hasAttributeNS</td> <td></td> </tr> <tr> <td>Entity</td> <td>Node</td> <td>LibXML::Entity</td> <td>publicId systemId notationName</td> <td></td> <td></td> </tr> <tr> <td>EntityReference</td> <td>Node</td> <td>LibXML::EntityRef</td> <td></td> <td></td> <td></td> </tr> <tr> <td>Implementation</td> <td></td> <td>LibXML</td> <td>createDocument createDocumentType hasFeature</td> <td></td> <td></td> </tr> <tr> <td>NamedNodeMap</td> <td></td> <td>LibXML::Attr::Map</td> <td>getNamedItem setNamedItem removeNamedItem item length</td> <td>getNamedItemNS setNamedItemNS removeNamedItemNS</td> <td></td> </tr> <tr> <td>Notation</td> <td>Node</td> <td>LibXML::Dtd::Notation</td> <td>nodeName publicId systemId</td> <td>N/A [1]</td> <td></td> </tr> <tr> <td>ProcessingInstruction</td> <td>Node</td> <td>LibXML::PI</td> <td>target data</td> <td></td> <td></td> </tr> <tr> <td>Text</td> <td>CharacterData</td> <td>LibXML::Text</td> <td>splitText</td> <td></td> <td></td> </tr>
</tbody>
</table>

  * [1] This object is stored in a LibXML hash-table, so most DOM manipulation methods are not applicable

