#include "xml6.h"
#include "xml6_doc_frag.h"

// adapted from Perl 5's LibXML.xs _parse_xml_chunk()
DLLEXPORT void xml6_doc_frag_set_nodes(xmlNodePtr self, xmlNodePtr nv) {

  if (self == NULL) xml6_fail("unable to initialize undefined document-fragment self");
  if (self->type != XML_DOCUMENT_FRAG_NODE) xml6_warn("node type is not document fragment");

  /* set the node list to the self */
  self->children = nv;

  if ( nv != NULL ) {
    xmlNodePtr nv_node   = NULL;

    /* now we append the nodelist to a document
       self which is unbound to a Document!!!! */
    nv_node = nv;
    while ( nv_node->next != NULL ) {
      nv_node->parent = self;
      nv_node = nv_node->next;
    }
    /* the following line is important, otherwise we'll have
       occasional segmentation faults
    */
    nv_node->parent = self;
    self->last = nv_node;
  }
}

