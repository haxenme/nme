//memmgr.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2009-2013
 *
 *  This file is part of libroar a part of RoarAudio,
 *  a cross-platform sound system for both, home and professional use.
 *  See README for details.
 *
 *  This file is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 3
 *  as published by the Free Software Foundation.
 *
 *  libroar is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this software; see the file COPYING.  If not, write to
 *  the Free Software Foundation, 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 *
 *  NOTE for everyone want's to change something and send patches:
 *  read README and HACKING! There a addition information on
 *  the license of this document you need to read before you send
 *  any patches.
 *
 *  NOTE for uses of non-GPL (LGPL,...) software using libesd, libartsc
 *  or libpulse*:
 *  The libs libroaresd, libroararts and libroarpulse link this lib
 *  and are therefore GPL. Because of this it may be illigal to use
 *  them with any software that uses libesd, libartsc or libpulse*.
 */

#ifndef _LIBROARMEMMGR_H_
#define _LIBROARMEMMGR_H_

#include "libroar.h"

#ifndef ROAR_USE_MEMMGR
#if !defined(ROAR_HAVE_MALLOC) || !defined(ROAR_HAVE_CALLOC) || !defined(ROAR_HAVE_REALLOC) || !defined(ROAR_HAVE_FREE)
#define ROAR_USE_MEMMGR
#endif
#endif

#ifdef ROAR_USE_MEMMGR
// those functions are currently not implemeted:

int     roar_mm_reset(void);

ssize_t roar_mm_sizeof(void * buf);

void * roar_mm_calloc(size_t nmemb, size_t size);
void * roar_mm_malloc(size_t size);
int    roar_mm_free(void *ptr);
void * roar_mm_realloc(void *ptr, size_t size);

/*
 * TODO: we need some functions to control the pre-alloc
 *       of memory.
 */

#else
#define roar_mm_reset()             (0)
#define roar_mm_sizeof(ptr)         ((ssize_t)-1)
#define roar_mm_calloc(nmemb, size) calloc((nmemb), (size))
#define roar_mm_malloc(size)        malloc((size))
#define roar_mm_free(ptr)           free((ptr))
#define roar_mm_realloc(ptr, size)  realloc((ptr), (size))
#endif

// dummy function doing the same as roar_mm_free() but return void.
// this should only be used in case a function pointer of this type is required.
void roar_mm_free_retvoid(void *ptr);

// memory locking:

#if defined(ROAR_HAVE_MLOCK) && defined(__linux__)
#define roar_mm_mlock(addr, len) mlock((addr), (len))
#elif defined(ROAR_TARGET_MICROCONTROLLER)
#define roar_mm_mlock(addr, len) 0
#else
int roar_mm_mlock(const void *addr, size_t len);
#endif

#if defined(ROAR_HAVE_MUNLOCK) && defined(__linux__)
#define roar_mm_munlock(addr, len) munlock((addr), (len))
#elif defined(ROAR_TARGET_MICROCONTROLLER)
#define roar_mm_munlock(addr, len) 0
#else
int roar_mm_munlock(const void *addr, size_t len);
#endif

#if defined(ROAR_HAVE_MLOCKALL)
#define roar_mm_mlockall(flags) mlockall((flags))
#elif defined(ROAR_TARGET_MICROCONTROLLER)
#define roar_mm_mlockall(flags) 0
#else
#define roar_mm_mlockall(flags) (-1)
#endif

#if defined(ROAR_HAVE_MUNLOCKALL)
#define roar_mm_munlockall() munlockall()
#elif defined(ROAR_TARGET_MICROCONTROLLER)
#define roar_mm_munlockall() 0
#else
#define roar_mm_munlockall() (-1)
#endif

// for compatibility with old versions:
#define ROAR_MLOCK _ROAR_MLOCK

// aux functions:
void * roar_mm_memdup(const void * s, size_t len);

// string functions:
#ifndef ROAR_HAVE_STRLEN
ssize_t roar_mm_strlen(const char *s);
#else
#define roar_mm_strlen(str) strlen((str))
#endif

ssize_t roar_mm_strnlen(const char *s, size_t maxlen);

#if defined(ROAR_USE_MEMMGR) || !defined(ROAR_HAVE_STRDUP)
char * roar_mm_strdup(const char *s);
#else
#define roar_mm_strdup(str)         strdup((str))
#endif

char * roar_mm_strdup2(const char *s, const char *def);

#if defined(ROAR_USE_MEMMGR) || !defined(ROAR_HAVE_STRNDUP)
char *roar_mm_strndup(const char *s, size_t n);
#else
#define roar_mm_strndup(str, size)         strdup((str), (size))
#endif

#ifndef ROAR_HAVE_STRLCPY
ssize_t roar_mm_strlcpy(char *dst, const char *src, size_t size);
#else
#define roar_mm_strlcpy(dst,src,size) strlcpy((dst),(src),(size))
#endif

#define roar_mm_strscpy(dst,src) roar_mm_strlcpy((dst),(src),sizeof((dst)))

#ifndef ROAR_HAVE_STRLCAT
ssize_t roar_mm_strlcat(char *dst, const char *src, size_t size);
#else
#define roar_mm_strlcat(dst,src,size) strlcat((dst),(src),(size))
#endif

#define roar_mm_strscat(dst,src) roar_mm_strlcat((dst),(src),sizeof((dst)))

#ifndef ROAR_HAVE_STRTOK_R
char * roar_mm_strtok_r(char *str, const char *delim, char **saveptr);
#else
#define roar_mm_strtok_r(str,delim,saveptr) strtok_r((str),(delim),(saveptr))
#endif


// Selector parsing.
int roar_mm_strselcmp(const char *s1, const char *s2);
ssize_t roar_mm_strseltok(const char *s1, char *s2, char ** tok, size_t toks);

#endif

//ll
