#ifndef __XML6_HASH_H
#define __XML6_HASH_H

#include <libxml/hash.h>

DLLEXPORT void xml6_hash_keys(xmlHashTablePtr, void**);
DLLEXPORT void xml6_hash_values(xmlHashTablePtr, void**);
DLLEXPORT void xml6_hash_key_values(xmlHashTablePtr, void**);
DLLEXPORT void xml6_hash_add_pairs(xmlHashTablePtr, void**, uint, xmlHashDeallocator);

#endif /* __XML6_HASH_H */
