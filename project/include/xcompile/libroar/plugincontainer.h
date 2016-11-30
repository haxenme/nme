//plugincontainer.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2008-2013
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

#ifndef _LIBROARPLUGINCONTAINER_H_
#define _LIBROARPLUGINCONTAINER_H_

#include "libroar.h"

struct roar_plugincontainer;

struct roar_plugincontainer_callbacks {
 /* prefree() is called before the container is freed.
  */
 int (*prefree)(struct roar_plugincontainer * cont, void ** userdata);

 /* freeuserdata() is called when the userdata needs to be freed.
  * This is the case then the container is freed.
  * It is not called when the current userdata is NULL.
  * If not set or userdata is still non-NULL after this call the userdata
  * is freed using roar_mm_free().
  */
 int (*freeuserdata)(struct roar_plugincontainer * cont, void ** userdata);

 /* freecontext() is called when the context needs to be freed.
  * It is not called when the current context is NULL.
  * If not set or context is still non-NULL after this call the context
  * is freed using roar_mm_free().
  */
 int (*freecontext)(struct roar_plugincontainer * cont, void ** context);

 /* preload() and postload() are called before and after a plugin is loaded.
  */
 int (*preload) (struct roar_plugincontainer * cont, void ** context,
                 const char * name, int flags, struct roar_dl_librarypara * para);
 int (*postload)(struct roar_plugincontainer * cont, void ** context, struct roar_dl_lhandle * lhandle,
                 const char * name, int flags, struct roar_dl_librarypara * para);

 /* preunload() and postunload() are called before and after a plugin is unloaded.
  * Those functions are also called if the plugin was loaded but ra_init was not yet done or failed.
  */
 int (*preunload) (struct roar_plugincontainer * cont, void ** context, struct roar_dl_lhandle * lhandle);
 int (*postunload)(struct roar_plugincontainer * cont, void ** context);

 /* prera_init() and postra_init() are called before and after a plugin is ra_init-ed.
  * This is also true if the plugin is ra_init-ed while being loaded.
  * Note the limits of roar_plugincontainer_ra_init() if this is used
  * with roar_plugincontainer_ra_init().
  * postra_init() is also called in case the ra_init failed.
  */
 int (*prera_init) (struct roar_plugincontainer * cont, void ** context, struct roar_dl_lhandle * lhandle,
                    struct roar_dl_librarypara * para);
 int (*postra_init)(struct roar_plugincontainer * cont, void ** context, struct roar_dl_lhandle * lhandle,
                    struct roar_dl_librarypara * para);
};

struct roar_plugincontainer_plugininfo {
 /* The name of the plugin.
  */
 const char * libname;
 /* The roardl's library handle.
  */
 struct roar_dl_lhandle * handle;
 /* The number of librarys/plugins depending on this plugin.
  */
 size_t rdepends;
 /* A pointer to the current user context.
  */
 void ** context;
};

/* Create a new plugin container.
 * Takes a default parameter set.
 */
struct roar_plugincontainer * roar_plugincontainer_new(struct roar_dl_librarypara * default_para);

/* Create a new plugin container.
 * Takes host application's appname and abiversion.
 */
struct roar_plugincontainer * roar_plugincontainer_new_simple(const char * appname, const char * abiversion);

// Increment the refrence counter.
int roar_plugincontainer_ref(struct roar_plugincontainer * cont);
/* Decrement the refrence counter.
 * Unloads all plugins and frees all resources when there are no refreneces left.
 */
int roar_plugincontainer_unref(struct roar_plugincontainer * cont);

/* Set Autoappsched.
 * If set the INIT and FREE appsched events are send automatically.
 */
int roar_plugincontainer_set_autoappsched(struct roar_plugincontainer * cont, int val);

/* Set callbacks.
 */
int roar_plugincontainer_set_callbacks(struct roar_plugincontainer * cont,
                                       const struct roar_plugincontainer_callbacks * callbacks);

/* Set container's userdata.
 */
int roar_plugincontainer_set_userdata(struct roar_plugincontainer * cont, void * userdata);

/* Get container's userdata.
 */
void * roar_plugincontainer_get_userdata(struct roar_plugincontainer * cont);

/* Get a lhandle by name of the loaded plugin.
 */
struct roar_dl_lhandle * roar_plugincontainer_get_lhandle_by_name (struct roar_plugincontainer * cont,
                                                                   const char * name);

/* Get infos about current state of plugin.
 */
struct roar_plugincontainer_plugininfo roar_plugincontainer_get_info_by_name (struct roar_plugincontainer * cont,
                                                                              const char * name);

// plugin loading and unloading:

// Load a plugin by name.
int                      roar_plugincontainer_load            (struct roar_plugincontainer * cont,
                                                               const char * name,
                                                               struct roar_dl_librarypara * para);

/* Load a plugin by name with extra options.
 * This is for advanced applications only.
 * NOTE: Using this handle after the plugin has been unloaded from the
 *       container results in undefind behavior.
 */
struct roar_dl_lhandle * roar_plugincontainer_load_lhandle    (struct roar_plugincontainer * cont,
                                                               const char * name,
                                                               int flags,
                                                               int ra_init,
                                                               struct roar_dl_librarypara * para);
/* Unload a plugin by name.
 * NOTE: The name here is from the plugin and may not match the name you load
 *       the plugin with.
 */
int                      roar_plugincontainer_unload          (struct roar_plugincontainer * cont,
                                                               const char * name);
/* Load a plugin by roardl handle.
 * This is for advanced applications only.
 */
int                      roar_plugincontainer_unload_lhandle  (struct roar_plugincontainer * cont,
                                                               struct roar_dl_lhandle * lhandle);
/* Post ra_init plugins not yet inited.
 * NOTE: This uses the default para,
 *       not the one given with roar_plugincontainer_load_lhandle().
 * This is for advanced applications only.
 */
int                      roar_plugincontainer_ra_init         (struct roar_plugincontainer * cont);

// appsched:
// Trigger an application schedule event on all plugins.
int                      roar_plugincontainer_appsched_trigger(struct roar_plugincontainer * cont, enum roar_dl_appsched_trigger trigger);

#endif

//ll
