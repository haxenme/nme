//roardl.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2010-2013
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

#ifndef _LIBROARROARDL_H_
#define _LIBROARROARDL_H_

#include "libroar.h"

#define ROAR_DL_FLAG_DEFAULTS          -1
#define ROAR_DL_FLAG_PLUGIN            -2
#define ROAR_DL_FLAG_NONE               0x0000
#define ROAR_DL_FLAG_STATIC             0x0001 /* plugins are linked statically -lfoo */
#define ROAR_DL_FLAG_LAZY               0x0002
#define ROAR_DL_FLAG_PLUGINPATH         0x0004 /* Use plugin search path */

#define ROAR_DL_HANDLE_DEFAULT          ((struct roar_dl_lhandle*)(void*)0)
#define ROAR_DL_HANDLE_NEXT             ((struct roar_dl_lhandle*)(void*)1)
#define ROAR_DL_HANDLE_LIBROAR          ((struct roar_dl_lhandle*)(void*)2)
#define ROAR_DL_HANDLE_APPLICATION      ((struct roar_dl_lhandle*)(void*)3)
#define ROAR_DL_HANDLE_LIB              ((struct roar_dl_lhandle*)(void*)4)

#define LIBROAR_DL_APPNAME              "libroar " ROAR_VSTR_ROARAUDIO
#define LIBROAR_DL_ABIVERSION           "1.0beta9"

#define ROAR_DL_FN_DSTR                 0 /* VIO and DSTR drivers */
#define ROAR_DL_FN_CDRIVER              1 /* Client drivers, libroareio */
#define ROAR_DL_FN_TRANSCODER           2 /* Transcoder, libroardsp */
#define ROAR_DL_FN_DRIVER               3 /* Driver, roard? */
#define ROAR_DL_FN_SOURCE               4 /* Sources, roard? */
#define ROAR_DL_FN_FILTER               5 /* Filter, libroardsp */
#define ROAR_DL_FN_FF                   6 /* file format??? */
#define ROAR_DL_FN_AUTH                 7 /* Auth */
#define ROAR_DL_FN_BRIDGE               8 /* Bridges, roard? */
#define ROAR_DL_FN_ROARDSCHED           9 /* legacy, roard: Like appsched, but roard specific, old */
#define ROAR_DL_FN_APPSCHED            10 /* legacy: AppSched, old interface */
#define ROAR_DL_FN_PROTO               11 /* CPI, roard: Protocols */
#define ROAR_DL_FN_NOTIFY              12 /* ??? */
#define ROAR_DL_FN_INIT                13 /* global plugin instance init. should be avoided */
#define ROAR_DL_FN_REGFN               14 /* FN Registrations */
#define ROAR_DL_FN_APPLICATION         15 /* Application specific stuff */
#define ROAR_DL_FN_SERVICE             16 /* CSI: Services */
//#define ROAR_DL_FN_               9
#define ROAR_DL_FN_MAX                 24

#define ROAR_DL_LIBPARA_VERSION         1
#define ROAR_DL_LIBNAME_VERSION         0
#define ROAR_DL_LIBINST_VERSION         1
#define ROAR_DL_LIBDEP_VERSION          0

#define ROAR_DL_PLUGIN(lib) struct roar_dl_libraryinst *                                          \
                             _##lib##_roaraudio_library_init(struct roar_dl_librarypara * para);  \
                            struct roar_dl_libraryinst *                                          \
                             _roaraudio_library_init(struct roar_dl_librarypara * para) {         \
                              return _##lib##_roaraudio_library_init(para);                       \
                            }                                                                     \
                            struct roar_dl_libraryinst *                                          \
                             _##lib##_roaraudio_library_init(struct roar_dl_librarypara * para)   \

#define ROAR_DL_PLUGIN_START(xlib) ROAR_DL_PLUGIN(xlib) {                                         \
                                     static int _inited = 0;                                      \
                                     static struct roar_dl_libraryinst lib;                       \
                                     static struct roar_dl_libraryname libname;                   \
                                     (void)para;                                                  \
                                     if ( _inited )                                               \
                                      return &lib;                                                \
                                     if ( para != NULL &&                                         \
                                          (para->version != ROAR_DL_LIBPARA_VERSION ||            \
                                           para->len < sizeof(struct roar_dl_librarypara)) ) {    \
                                      /* we should set ROAR_ERROR_NSVERSION here but can not */   \
                                      /* because that would require the plugin to be linked */    \
                                      /* aginst libroar */                                        \
                                      return NULL;                                                \
                                     }                                                            \
                                     memset(&lib, 0, sizeof(lib));                                \
                                     lib.version = ROAR_DL_LIBINST_VERSION;                       \
                                     lib.len     = sizeof(lib);                                   \
                                     memset(&libname, 0, sizeof(libname));                        \
                                     libname.version = ROAR_DL_LIBNAME_VERSION;                   \
                                     libname.len     = sizeof(libname);                           \
                                     libname.name = #xlib;                                        \
                                     lib.libname  = &libname;                                     \
                                     do

#define ROAR_DL_PLUGIN_END          while(0);                                                     \
                                    _inited = 1;                                                  \
                                    return &lib;                                                  \
                                   }

// general stuff:
#define ROAR_DL_PLUGIN_ABORT_LOADING(err) roar_err_set((err)); return NULL
#define ROAR_DL_PLUGIN_CHECK_VERSIONS(app,abi) (((lib.host_appname = (app))    != NULL) | \
                                                ((lib.host_abiversion = (abi)) != NULL) )
// should we keep this macro at all? Is it helpfull at all?
// if a plugin can handle multiple hosts it needs to call roar_dl_para_check_version() itself anyway.
#define ROAR_DL_PLUGIN_CHECK_VERSIONS_NOW(app,abi) if ( roar_dl_para_check_version(para, (app), (abi)) == -1 ) return NULL

// register stuff:
#define ROAR_DL_PLUGIN_REG(fn, funcptr) (lib.func[(fn)] = (funcptr))
#define ROAR_DL_PLUGIN_REG_UNLOAD(func) (lib.unload = (func))
#define ROAR_DL_PLUGIN_REG_APPSCHED(sched) (lib.appsched = (sched))
#define ROAR_DL_PLUGIN_REG_GLOBAL_DATA(ptr,init) lib.global_data_len = sizeof((init)); \
                                                 lib.global_data_init = &(init);       \
                                                 lib.global_data_pointer = (void*)&(ptr)
#define ROAR_DL_PLUGIN_REG_LIBDEP(deps) (((lib.libdep = (deps)) == NULL) ? \
                                           (ssize_t)-1 : \
                                           (ssize_t)(lib.libdep_len = sizeof((deps))/sizeof(struct roar_dl_librarydep)))

// register objects using FN:
#define ROAR_DL_PLUGIN_REG_FN(subtype,obj,version)  roar_dl_register_fn(NULL, -1, (subtype), &(obj), sizeof((obj)), (version), ROAR_DL_FNREG_OPT_NONE)
#define ROAR_DL_PLUGIN_REG_FNFUNC(fn) ROAR_DL_PLUGIN_REG((fn), _roaraudio_library_ ## fn)

// Do a FN reg callback registration:
#define ROAR_DL_RFNREG(lhandle,obj)  roar_dl_register_fn((lhandle), ROAR_DL_FN_REGFN, ROAR_DL_FNREG_SUBTYPE, &(obj), sizeof((obj)), ROAR_DL_FNREG_VERSION, ROAR_DL_FNREG_OPT_NONE)

// meta data stuff:
#define ROAR_DL_PLUGIN_META_PRODUCT(x)      (libname.libname     = (x))
#define ROAR_DL_PLUGIN_META_PRODUCT_NV(name,vendor)      ROAR_DL_PLUGIN_META_PRODUCT(name " <" vendor ">")
#define ROAR_DL_PLUGIN_META_PRODUCT_NIV_REAL(name,id,vendor)  ROAR_DL_PLUGIN_META_PRODUCT(name " <" #id "/" vendor ">")
#define ROAR_DL_PLUGIN_META_PRODUCT_NIV(name,id,vendor)  ROAR_DL_PLUGIN_META_PRODUCT_NIV_REAL(name,id,vendor)
#define ROAR_DL_PLUGIN_META_VERSION(x)      (libname.libversion  = (x))
#define ROAR_DL_PLUGIN_META_ABI(x)          (libname.abiversion  = (x))
#define ROAR_DL_PLUGIN_META_DESC(x)         (libname.description = (x))
#define ROAR_DL_PLUGIN_META_CONTACT(x)      (libname.contact = (x))
#define ROAR_DL_PLUGIN_META_CONTACT_FL(first,last)        ROAR_DL_PLUGIN_META_CONTACT(first " " last)
#define ROAR_DL_PLUGIN_META_CONTACT_FLE(first,last,email) ROAR_DL_PLUGIN_META_CONTACT(first " " last " <" email ">")
#define ROAR_DL_PLUGIN_META_CONTACT_FLNE(first,last,nick,email) ROAR_DL_PLUGIN_META_CONTACT(first " \"" nick "\" " last " <" email ">")
#define ROAR_DL_PLUGIN_META_AUTHORS(x)      (libname.authors = (x))
#define ROAR_DL_PLUGIN_META_LICENSE(x)      (libname.license = (x))
#define ROAR_DL_PLUGIN_META_LICENSE_TAG(x)  ROAR_DL_PLUGIN_META_LICENSE(ROAR_LICENSE_ ## x)

enum roar_dl_loadercmd {
 ROAR_DL_LOADER_NOOP = 0,
 ROAR_DL_LOADER_PRELOAD,
 ROAR_DL_LOADER_LOAD,
 ROAR_DL_LOADER_POSTLOAD,
 ROAR_DL_LOADER_PREUNLOAD,
 ROAR_DL_LOADER_UNLOAD,
 ROAR_DL_LOADER_POSTUNLOAD
};

struct roar_plugincontainer;

struct roar_dl_librarypara {
 int version;               // version of this struct type (must be ROAR_DL_LIBPARA_VERSION)
 size_t len;                // Length of this struct type (must be sizeof(struct roar_dl_librarypara)

 size_t refc;               // Reference counter.

 size_t argc;               // number of elements in argv
 struct roar_keyval * argv; // Parameter for the plugin
 void * args_store;         // Storage area for argv's data.
                            // If not NULL this and argv will be freed.
                            // If NULL argv will be left untouched.

 void * binargv;            // A pointer with binary data arguments.
                            // This can be used to pass any non-string data to
                            // the plugin. Normally this is NULL or the pointer
                            // to a struct with members of whatever is needed.

 const char * appname;      // application name in common format:
                            // Product/Version <VendorID/VendorName> (comments)
                            // Version and comment are optional and should be avoided.
                            // When no vendor ID is registered use <VendorName>.
                            // The VendorName MUST NOT contain a slash and SHOULD
                            // be as unique as possible.
                            // Examples: roard <0/RoarAudio>, MyAPP <myapp.org>,
                            //           AnAPP <Musterman GbR>
 const char * abiversion;   // The ABI version. For libraries this should be the SONAME.
                            // For applications this should be the version of the release
                            // which introduced the current ABI.
                            // Examples: libroar2, 0.5.1
 struct roar_notify_core * notifycore;
 struct roar_plugincontainer * container;
 int (*loader)(struct roar_dl_librarypara * lhandle, void * loader_userdata, enum roar_dl_loadercmd cmd, void * argp);
 void * loader_userdata;
};

struct roar_dl_libraryname {
 int      version;
 size_t   len;
 const char * name;        //Format: shortname
 const char * libname;     //This is the same as appname in struct roar_dl_librarypara.
                           //Format: Product <VendorID/VendorName> (comments)
 const char * libversion;  //This is the pure version number of the library.
 const char * abiversion;  //This is the same as abiversion in struct roar_dl_librarypara.
                           //Format: Version
 const char * description; //Free form.
 const char * contact;     //Format: first ["']nick["'] last (comment) <email>/OpenPGPkey/Phone/Room
 const char * authors;     //Other authors as free form.
 const char * license;     //Format: LicenseName-Version (options)
                           //Examples: GPL-3.0, LGPL-2.1, LGPL-3.0 (or later).
};

struct roar_dl_librarydep {
 int      version;
 size_t   len;
 uint32_t flags;
 const char * name;
 const char * libname;
 const char * abiversion;
};

#define ROAR_DL_DEP(__flags,__name,__libname,__abiversion) \
                                                   {.version    = ROAR_DL_LIBDEP_VERSION,            \
                                                    .len        = sizeof(struct roar_dl_librarydep), \
                                                    .flags      = __flags,                           \
                                                    .name       = __name,                            \
                                                    .libname    = __libname,                         \
                                                    .abiversion = __abiversion}

struct roar_dl_libraryinst {
 int      version;
 size_t   len;
 int    (*unload)(struct roar_dl_librarypara * para, struct roar_dl_libraryinst * lib);
 int    (*func[ROAR_DL_FN_MAX])(struct roar_dl_librarypara * para, struct roar_dl_libraryinst * lib);
 struct roar_dl_libraryname * libname;
 size_t  global_data_len;
 void *  global_data_init;
 void ** global_data_pointer;
 struct roar_dl_librarydep * libdep;
 size_t libdep_len;
 struct roar_dl_appsched * appsched;
 const char * host_appname;
 const char * host_abiversion;
};

struct roar_dl_appsched {
 int (*init)  (struct roar_dl_librarypara * para);
 int (*free)  (struct roar_dl_librarypara * para);
 int (*update)(struct roar_dl_librarypara * para);
 int (*tick)  (struct roar_dl_librarypara * para);
 int (*wait)  (struct roar_dl_librarypara * para);
};

enum roar_dl_appsched_trigger {
 ROAR_DL_APPSCHED_INIT = 1,
#define ROAR_DL_APPSCHED_INIT ROAR_DL_APPSCHED_INIT
 ROAR_DL_APPSCHED_FREE,
#define ROAR_DL_APPSCHED_FREE ROAR_DL_APPSCHED_FREE
 ROAR_DL_APPSCHED_UPDATE,
#define ROAR_DL_APPSCHED_UPDATE ROAR_DL_APPSCHED_UPDATE
 ROAR_DL_APPSCHED_TICK,
#define ROAR_DL_APPSCHED_TICK ROAR_DL_APPSCHED_TICK
 ROAR_DL_APPSCHED_WAIT,
#define ROAR_DL_APPSCHED_WAIT ROAR_DL_APPSCHED_WAIT
 ROAR_DL_APPSCHED_ABOUT,
#define ROAR_DL_APPSCHED_ABOUT ROAR_DL_APPSCHED_ABOUT
 ROAR_DL_APPSCHED_HELP,
#define ROAR_DL_APPSCHED_HELP ROAR_DL_APPSCHED_HELP
 ROAR_DL_APPSCHED_PREFERENCES
#define ROAR_DL_APPSCHED_PREFERENCES ROAR_DL_APPSCHED_PREFERENCES
};

// parameter functions:
struct roar_dl_librarypara * roar_dl_para_new(const char * args, void * binargv,
                                              const char * appname, const char * abiversion);
int roar_dl_para_ref                    (struct roar_dl_librarypara * para);
int roar_dl_para_unref                  (struct roar_dl_librarypara * para);
int roar_dl_para_check_version          (struct roar_dl_librarypara * para,
                                         const char * appname, const char * abiversion);

// 'core' dynamic loader functions.
struct roar_dl_lhandle * roar_dl_open   (const char * filename, int flags,
                                         int ra_init, struct roar_dl_librarypara * para);
int                      roar_dl_ref    (struct roar_dl_lhandle * lhandle);
int                      roar_dl_unref  (struct roar_dl_lhandle * lhandle);
#define roar_dl_close(x) roar_dl_unref((x))

void                   * roar_dl_getsym (struct roar_dl_lhandle * lhandle, const char * sym, int type);

int                      roar_dl_ra_init(struct roar_dl_lhandle * lhandle,
                                         const char * prefix,
                                         struct roar_dl_librarypara * para);

const char *             roar_dl_errstr (struct roar_dl_lhandle * lhandle);

// getting meta data:
struct roar_dl_librarypara       * roar_dl_getpara(struct roar_dl_lhandle * lhandle);
const struct roar_dl_libraryname * roar_dl_getlibname(struct roar_dl_lhandle * lhandle);

// context switching:
// _restore() is to switch from main to library context. _store() is to store library context
// and switch back to main context.
int                      roar_dl_context_restore(struct roar_dl_lhandle * lhandle);
int                      roar_dl_context_store(struct roar_dl_lhandle * lhandle);

// appsched:
int                      roar_dl_appsched_trigger(struct roar_dl_lhandle * lhandle, enum roar_dl_appsched_trigger trigger);

// FN Registration:

// Actions objects can emit:
enum roar_dl_fnreg_action {
 ROAR_DL_FNREG   = 1, // The object is being registered
 ROAR_DL_FNUNREG = 2  // The object is being unregistered
};

// Callback for registering/unregistering objects:
struct roar_dl_fnreg {
 int fn;          // Filter: The FN of the registering object or -1 for any.
 int subtype;     // Filter: The subtype of the registering object or -1 for any.
 int version;     // Filter: The version of the registering object or -1 for any.
 int (*callback)( // Callback to call on register/unregister.
   enum roar_dl_fnreg_action action, // The action happening
   int fn,                           // The FN of the object
   int subtype,                      // The subtype of the object
   const void * object,              // Pointer to the object
   size_t objectlen,                 // Length of the object
   int version,                      // Version of the object
   int options,                      // Object Options.
   void * userdata,                  // User data for the callback.
   struct roar_dl_lhandle * lhandle  // The registering handle.
                                     // This is valid until the object is unregistered.
                                     // Only roar_dl_context_restore(), roar_dl_context_store()
                                     // and roar_dl_getpara() may be used on this object.
                                     // Result of all other functions is undefined.
 );
 void * userdata; // The user data pointer passed to the callback.
};

// Parameters for FNREG registration:
#define ROAR_DL_FNREG_SUBTYPE  0
#define ROAR_DL_FNREG_VERSION  0
#define ROAR_DL_FNREG_SIZE     sizeof(struct roar_dl_fnreg)


// Common protocol interface (CPI):
struct roar_dl_proto {
 const int proto;
 const char * description;
 const int flags;
 int (*set_proto)(int client, struct roar_vio_calls * vio, struct roar_buffer ** obuffer, void ** userdata, const struct roar_keyval * protopara, ssize_t protoparalen, struct roar_dl_librarypara * pluginpara);
 int (*unset_proto)(int client, struct roar_vio_calls * vio, struct roar_buffer ** obuffer, void ** userdata, const struct roar_keyval * protopara, ssize_t protoparalen, struct roar_dl_librarypara * pluginpara);
 int (*handle)(int client, struct roar_vio_calls * vio, struct roar_buffer ** obuffer, void ** userdata, const struct roar_keyval * protopara, ssize_t protoparalen, struct roar_dl_librarypara * pluginpara);
 int (*flush)(int client, struct roar_vio_calls * vio, struct roar_buffer ** obuffer, void ** userdata, const struct roar_keyval * protopara, ssize_t protoparalen, struct roar_dl_librarypara * pluginpara);
 int (*flushed)(int client, struct roar_vio_calls * vio, struct roar_buffer ** obuffer, void ** userdata, const struct roar_keyval * protopara, ssize_t protoparalen, struct roar_dl_librarypara * pluginpara);
 int (*status)(int client, struct roar_vio_calls * vio, struct roar_buffer ** obuffer, void ** userdata, const struct roar_keyval * protopara, ssize_t protoparalen, struct roar_dl_librarypara * pluginpara);
};

#define ROAR_DL_PROTO_FLAGS_NONE         0

#define ROAR_DL_PROTO_STATUS_RX_READY    0x0001
#define ROAR_DL_PROTO_STATUS_TX_READY    0x0002
#define ROAR_DL_PROTO_STATUS_WAIT_NOTIFY 0x0004

// Parameters for FNREG registration:
#define ROAR_DL_PROTO_SUBTYPE  1 /* 0 = roard */
#define ROAR_DL_PROTO_VERSION  0
#define ROAR_DL_PROTO_SIZE     sizeof(struct roar_dl_proto)


// Common Service Interface (CSI):
struct roar_dl_service {
 // Name and ABI version of the application:
 // if appname is NULL this is a /universal/ service.
 // Such services MUST use APIs defined by the RoarAudio Project.
 // If a random Vendor needs a API universal to own applications
 // it should define a virtual application name for this.
 const char * appname;
 const char * appabi;
 // Name and ABI/API version of service:
 const char * servicename;
 const char * serviceabi;
 // Description:
 const char * description;
 // Flags (see below for defined flags):
 const int    flags;
 // Userdata:
 // This is some kind of constant data.
 // It can bed used by the functions below for internal stuff.
 const void * userdata;
 // Functions:
 // get_api returns a pointer to a struct with the API.
 // The api is specific to [appname, appabi, servicename, serviceabi].
 const void * (*get_api)(const struct roar_dl_service * service, struct roar_dl_librarypara * para);
};

#define ROAR_DL_SERVICE_FLAGS_NONE         0x0000

#define ROAR_DL_SERVICE_SUBTYPE  0
#define ROAR_DL_SERVICE_VERSION  0
#define ROAR_DL_SERVICE_SIZE     sizeof(struct roar_dl_service)

#define ROAR_DL_PLUGIN_REG_SERVICES(obj) \
static int _roaraudio_library_ROAR_DL_FN_SERVICE(struct roar_dl_librarypara * para, struct roar_dl_libraryinst * lib) { \
 size_t i; \
 (void)para, (void)lib; \
 for (i = 0; i < (sizeof((obj))/sizeof(*(obj))); i++) { \
  ROAR_DL_PLUGIN_REG_FN(ROAR_DL_SERVICE_SUBTYPE, (obj)[i], ROAR_DL_SERVICE_VERSION); \
 } \
 return 0; \
}
#define ROAR_DL_PLUGIN_REG_SERVICES_GET_API(name,obj) \
static const void * name(const struct roar_dl_service * service, struct roar_dl_librarypara * para) { \
 (void)service, (void)para; \
 return &(obj); \
}

struct roar_dl_service_api {
 const void * api;
 struct roar_dl_lhandle * lhandle;
 const struct roar_dl_service * service;
};

#define libroar_dl_service_apitype(type) \
union { \
 struct roar_dl_service_api apiinterface; \
 const struct type * api; \
}

int libroar_dl_service_get_api_real(struct roar_dl_librarypara * para, const char * appname, const char * appabi, const char * servicename, const char * serviceabi, int universal, struct roar_dl_service_api * api, int retry);
#define libroar_dl_service_get_api(para,appname,appabi,servicename,serviceabi,universal,api) libroar_dl_service_get_api_real((para),(appname),(appabi),(servicename),(serviceabi),(universal),(struct roar_dl_service_api *)(api), 1)
#define roar_dl_service_get_api(para,servicename,serviceabi,api) libroar_dl_service_get_api((para), (para) == NULL ? NULL : ((struct roar_dl_librarypara *)(para))->appname, (para) == NULL ? NULL : ((struct roar_dl_librarypara *)(para))->abiversion, (servicename), (serviceabi), 1, (api))

int libroar_dl_service_free_api_real(struct roar_dl_service_api * api);
#define libroar_dl_service_free_api(api) libroar_dl_service_free_api_real((struct roar_dl_service_api *)&(api))

#define libroar_dl_service_run_func(obj,name,type,...) ((type[3]){(type)roar_dl_context_restore((obj).apiinterface.lhandle), ((obj).api->name(__VA_ARGS__)), (type)roar_dl_context_store((obj).apiinterface.lhandle)})[1]
#define libroar_dl_service_run_func_void(obj,name,...) do { roar_dl_context_restore((obj).apiinterface.lhandle); (obj).api->name(__VA_ARGS__); roar_dl_context_store((obj).apiinterface.lhandle); } while (0)
#define libroar_dl_service_check_func(obj,name) ((obj).api->name != NULL)

// Reg FN:

// Options:
#define ROAR_DL_FNREG_OPT_NONE 0   /* no options */

// Register an FN.
int                      roar_dl_register_fn(struct roar_dl_lhandle * lhandle, int fn, int subtype, const void * object, size_t objectlen, int version, int options);

// Unregister an FN.
int                      roar_dl_unregister_fn2(struct roar_dl_lhandle * lhandle, int fn, int subtype, const void * object, size_t objectlen, int version, int options);

// Unregister FN for the given plugin.
// This should not be called directly and is called internally when needed.
int                      roar_dl_unregister_fn(struct roar_dl_lhandle * lhandle);

#endif

//ll
