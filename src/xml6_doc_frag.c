#include "xml6.h"
#include "xml6_doc_frag.h"

// adapted from Perl 5's LibXML.xs _parse_xml_chunk()
DLLEXPORT void xml6_doc_frag_set_nodes(xmlNodePtr fragment, xmlNodePtr nv) {

  if (fragment == NULL) {
    fprintf(stderr, "%s:%d: unable to initialize document fragment\n", __FILE__, __LINE__);
    return;
  }

  if ( nv != NULL ) {
    xmlNodePtr nv_node   = NULL;

    /* now we append the nodelist to a document
       fragment which is unbound to a Document!!!! */

    /* set the node list to the fragment */
    fragment->children = nv;
    nv_node = nv;
    while ( nv_node->next != NULL ) {
      nv_node->parent = fragment;
      nv_node = nv_node->next;
    }
    /* the following line is important, otherwise we'll have
       occasional segmentation faults
    */
    nv_node->parent = fragment;
    fragment->last = nv_node;
  }
}

