#include "xml6.h"
#include <string.h>
#include <assert.h>
#include "xml6_hash.h"

static void _xml6_get_key(void* data, const xmlChar*** keys, xmlChar* key) {
    **keys = key;
    (*keys)++;
}

DLLEXPORT xmlChar** xml6_hash_keys(xmlHashTablePtr self) {
    assert(self != NULL);
    {
        int size = xmlHashSize(self);
        assert(size >= 0);
        {
            xmlChar** keys = (xmlChar **) malloc(sizeof(xmlChar*) * size + 1);
            xmlChar**p = keys;
            assert(keys != NULL);
            keys[size] = NULL;
            xmlHashScan(self, (xmlHashScanner) _xml6_get_key, (void*) &p);
            return keys;
        }
    }
}
