#include "xml6.h"
#include <string.h>
#include <assert.h>
#include "xml6_hash.h"

static void _xml6_get_key(void* value, const xmlChar*** keys, xmlChar* key) {
    **keys = key;
    (*keys)++;
}

static void _xml6_get_value(void* value, const void*** values, xmlChar* key) {
    **values = value;
    (*values)++;
}

static void** _xml6_scan(xmlHashTablePtr self, xmlHashScanner scanner) {
    assert(self != NULL);
    {
        int size = xmlHashSize(self);
        assert(size >= 0);
        {
            void** keys = (void **) malloc(sizeof(void*) * size + 1);
            void**p = keys;
            assert(keys != NULL);
            keys[size] = NULL;
            xmlHashScan(self, scanner, (void*) &p);
            return keys;
        }
    }
}

DLLEXPORT xmlChar** xml6_hash_keys(xmlHashTablePtr self) {
    return (xmlChar**) _xml6_scan(self, (xmlHashScanner) _xml6_get_key);
}

DLLEXPORT void** xml6_hash_values(xmlHashTablePtr self) {
    return _xml6_scan(self, (xmlHashScanner) _xml6_get_value);
}
