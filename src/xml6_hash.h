#ifndef __XML6_HASH_H
#define __XML6_HASH_H

#include <libxml/hash.h>

DLLEXPORT xmlChar** xml6_hash_keys(xmlHashTablePtr self);
DLLEXPORT void** xml6_hash_values(xmlHashTablePtr self);

#endif /* __XML6_HASH_H */
