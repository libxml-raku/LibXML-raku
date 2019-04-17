#ifndef __XML6_H
#define __XML6_H

#ifdef _WIN32
#define DLLEXPORT __declspec(dllexport)
#else
#define DLLEXPORT extern
#endif

#define xml6_warn(msg) fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, (msg));
#define xml6_fail(msg) {xml6_warn(msg);return;}

#endif /* __XML6_H */
