#include <libxml/xpath.h>
#include <libxml/hash.h>
#include <string.h>
#include <assert.h>

#include "xml6.h"
#include "xml6_node.h"
#include "xml6_hash.h"
#include "dom.h"
#include "domXPath.h"

static xmlChar* _xml6_make_ns_key(xmlChar* name, xmlChar *pfx) {
    xmlChar* key;
    if (pfx != NULL && *pfx != 0) {
        key = xmlStrdup(pfx);
        key = xmlStrcat(key, (const xmlChar*) ":" );
        key = xmlStrcat(key, name );
    }
    else {
        key = xmlStrdup(name);
    }
    return key;
}

static void _xml6_get_key(void*, const xmlChar*** keys, xmlChar* name, xmlChar* pfx, xmlChar*) {
    *((*keys)++) = _xml6_make_ns_key(name, pfx);
}

static void _xml6_get_value(void* value, const void*** values, xmlChar*, xmlChar*, xmlChar*) {
    *((*values)++) = value;
}

static void _xml6_get_pair(void* value, const void*** pairs, xmlChar* name, xmlChar *pfx, xmlChar*) {
    *((*pairs)++) = (void*) _xml6_make_ns_key(name, pfx);
    *((*pairs)++) = value;
}

static void _xml6_scan(xmlHashTablePtr self, xmlHashScannerFull scanner, int n, void** buf) {
    void** p;
    assert(self != NULL);
    assert(buf != NULL);
    p = buf;
    xmlHashScanFull(self, scanner, (void*) &p);
    assert(p == &(buf[xmlHashSize(self) * n]));
}

DLLEXPORT void xml6_hash_keys(xmlHashTablePtr self, void** buf) {
    _xml6_scan(self, (xmlHashScannerFull) _xml6_get_key, 1, buf);
}

DLLEXPORT void xml6_hash_values(xmlHashTablePtr self, void** buf) {
    _xml6_scan(self, (xmlHashScannerFull) _xml6_get_value, 1, buf);
}

DLLEXPORT void xml6_hash_key_values(xmlHashTablePtr self, void** buf) {
    _xml6_scan(self, (xmlHashScannerFull) _xml6_get_pair, 2, buf);
}

DLLEXPORT int xml6_hash_update_entry_ns(xmlHashTablePtr self, xmlChar* name, void* value, xmlHashDeallocator deallocator) {
    xmlChar* pfx = NULL;
    xmlChar* uqname = xmlSplitQName2(name, &pfx);
    int rv = 0;

    if (uqname != NULL) {
        rv = xmlHashUpdateEntry2(self, uqname, pfx, value, deallocator);
        xmlFree(uqname);
        xmlFree(pfx);
    }
    else {
        rv = xmlHashUpdateEntry(self, name, value, deallocator);
    }

    return rv;
}

DLLEXPORT int xml6_hash_remove_entry_ns(xmlHashTablePtr self, xmlChar* name, xmlHashDeallocator deallocator) {
    xmlChar* pfx = NULL;
    xmlChar* uqname = xmlSplitQName2(name, &pfx);
    int rv = 0;

    if (uqname != NULL) {
        rv = xmlHashRemoveEntry2(self, uqname, pfx, deallocator);
        xmlFree(uqname);
        xmlFree(pfx);
    }
    else {
        rv = xmlHashRemoveEntry(self, name, deallocator);
    }

    return rv;
}

DLLEXPORT void xml6_hash_add_pairs(xmlHashTablePtr self, void** pairs, unsigned int n, xmlHashDeallocator deallocator) {
    assert(self != NULL);
    assert((n % 2) == 0);

    if (n) {
        unsigned int i = 0;
        assert(pairs != NULL);
        for (i = 0; i < n; i += 2) {
            xmlChar* name = (xmlChar*) pairs[i];
            void* value  = pairs[i+1];
            xml6_hash_update_entry_ns(self, name, value, deallocator);
        }
    }
}

static void _hash_xpath_node(xmlHashTablePtr self, xmlNodePtr node) {
    assert(self != NULL);

    if (node != NULL) {
        // todo
        xmlChar* key = xmlStrdup(domGetXPathKey(node));
        xmlNodeSetPtr bucket = (xmlNodeSetPtr) xmlHashLookup(self, key);

        if (bucket == NULL) {
            bucket = xmlXPathNodeSetCreate(NULL);
            xmlHashAddEntry(self, key, (void*) bucket);
        }

        domPushNodeSet(bucket, node, 0);
    }
}

static void _hash_xpath_node_siblings(xmlHashTablePtr self, xmlNodePtr node, int keep_blanks) {
    assert(self != NULL);

    if (node != NULL) {
        // todo
        xmlChar* key = xmlStrdup(domGetXPathKey(node));
        xmlNodeSetPtr bucket = (xmlNodeSetPtr) xmlHashLookup(self, key);
        xmlNodePtr next = (node->type == XML_NAMESPACE_DECL)
            ? (xmlNodePtr) ((xmlNsPtr) node)->next
            : xml6_node_next(node, keep_blanks);

        if (bucket == NULL) {
            bucket = xmlXPathNodeSetCreate(NULL);
            xmlHashAddEntry(self, key, (void*) bucket);
        }

        domPushNodeSet(bucket, node, 1);
        xmlFree(key);

        _hash_xpath_node_siblings(self, next, keep_blanks);
    }
}

static void _hash_xpath_node_children(xmlHashTablePtr self, xmlNodePtr node, int keep_blanks) {
    assert(self != NULL);

    _hash_xpath_node_siblings(self, node->children, keep_blanks);

    if (node->type == XML_ELEMENT_NODE) {
        _hash_xpath_node_siblings(self, (xmlNodePtr) node->properties, keep_blanks);
    }
}

DLLEXPORT xmlHashTablePtr xml6_hash_xpath_node_children(xmlNodePtr node, int keep_blanks) {
    xmlHashTablePtr rv = xmlHashCreate(0);
    assert(rv != NULL);
    _hash_xpath_node_children(rv, node, keep_blanks);
    return rv;
}

DLLEXPORT xmlHashTablePtr xml6_hash_xpath_nodeset(xmlNodeSetPtr nodes, int deref) {
    xmlHashTablePtr rv = xmlHashCreate(0);
    assert(rv != NULL);

    if (nodes != NULL) {
        int i;
        for (i = 0; i < nodes->nodeNr; i++) {
            xmlNodePtr node = nodes->nodeTab[i];

            if (deref) {
                _hash_xpath_node_children(rv, node, 1);
            }
            else {
                _hash_xpath_node(rv, node);
            }
        }
    }
    return rv;
}

static void _xml6_build_hash_attrs(void* value, const void* _self, xmlChar* attr_name, xmlChar *attr_pfx, xmlChar *elem_qname) {
    xmlHashTablePtr self = (xmlHashTablePtr) _self;
    xmlHashTablePtr bucket = (xmlHashTablePtr) xml6_hash_lookup_ns(self, elem_qname);

    if (bucket == NULL) {
        xmlChar* pfx = NULL;
        xmlChar* uqname = xmlSplitQName2(elem_qname, &pfx);
        // Vivify sub-hash
        bucket = xmlHashCreate(0);
        if (uqname != NULL) {
            xmlHashAddEntry2(self, uqname, pfx, (void*) bucket);
            xmlFree(uqname);
            xmlFree(pfx);
        }
        else {
            xmlHashAddEntry(self, elem_qname, (void*) bucket);
        }
    }

    xmlHashAddEntry2(bucket, attr_name, attr_pfx, value);
}

// Build a HoH mapping from the dtd->attributes hash
DLLEXPORT xmlHashTablePtr xml6_hash_build_attr_decls(xmlHashTablePtr self) {
    xmlHashTablePtr rv = xmlHashCreate(0);
    assert(self != NULL);
    assert(rv != NULL);

    xmlHashScanFull(self, (xmlHashScannerFull) _xml6_build_hash_attrs, (void *) rv);
    return rv;
}

DLLEXPORT void* xml6_hash_lookup_ns(xmlHashTablePtr self, xmlChar* name) {
    xmlChar* pfx = NULL;
    void* rv = NULL;
    xmlChar* uqname = xmlSplitQName2(name, &pfx);

    if (uqname != NULL) {
        rv = xmlHashLookup2(self, uqname, pfx);
        xmlFree(uqname);
        xmlFree(pfx);
    }
    else {
        rv = xmlHashLookup(self, name);
    }

    return rv;
}

// Free the hash, leave contents intact
static void _keep_hash_contents(void* _, const xmlChar* __) {
    (void)_; /* unused parameter */
    (void)__; /* unused parameter */
    // do nothing
}
DLLEXPORT void xml6_hash_discard(xmlHashTablePtr self) {
    xmlHashFree(self, (xmlHashDeallocator) _keep_hash_contents );
}
