#ifndef foopulseproplisthfoo
#define foopulseproplisthfoo

/***
  This file is part of PulseAudio.

  Copyright 2007 Lennart Poettering

  PulseAudio is free software; you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as
  published by the Free Software Foundation; either version 2.1 of the
  License, or (at your option) any later version.

  PulseAudio is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with PulseAudio; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
  USA.
***/

#include <sys/types.h>

#include <pulse/cdecl.h>
#include <pulse/gccmacro.h>
#include <pulse/version.h>

PA_C_DECL_BEGIN

/** For streams: localized media name, formatted as UTF-8. e.g. "Guns'N'Roses: Civil War".*/
#define PA_PROP_MEDIA_NAME                     "media.name"

/** For streams: localized media title if applicable, formatted as UTF-8. e.g. "Civil War" */
#define PA_PROP_MEDIA_TITLE                    "media.title"

/** For streams: localized media artist if applicable, formatted as UTF-8. e.g. "Guns'N'Roses" */
#define PA_PROP_MEDIA_ARTIST                   "media.artist"

/** For streams: localized media copyright string if applicable, formatted as UTF-8. e.g. "Evil Record Corp." */
#define PA_PROP_MEDIA_COPYRIGHT                "media.copyright"

/** For streams: localized media generator software string if applicable, formatted as UTF-8. e.g. "Foocrop AudioFrobnicator" */
#define PA_PROP_MEDIA_SOFTWARE                 "media.software"

/** For streams: media language if applicable, in standard POSIX format. e.g. "de_DE" */
#define PA_PROP_MEDIA_LANGUAGE                 "media.language"

/** For streams: source filename if applicable, in URI format or local path. e.g. "/home/lennart/music/foobar.ogg" */
#define PA_PROP_MEDIA_FILENAME                 "media.filename"

/** \cond fulldocs */
/** For streams: icon for the media. A binary blob containing PNG image data */
#define PA_PROP_MEDIA_ICON                     "media.icon"
/** \endcond */

/** For streams: an XDG icon name for the media. e.g. "audio-x-mp3" */
#define PA_PROP_MEDIA_ICON_NAME                "media.icon_name"

/** For streams: logic role of this media. One of the strings "video", "music", "game", "event", "phone", "animation", "production", "a11y", "test" */
#define PA_PROP_MEDIA_ROLE                     "media.role"

/** For event sound streams: XDG event sound name. e.g. "message-new-email" (Event sound streams are those with media.role set to "event") */
#define PA_PROP_EVENT_ID                       "event.id"

/** For event sound streams: localized human readable one-line description of the event, formatted as UTF-8. e.g. "Email from lennart@example.com received." */
#define PA_PROP_EVENT_DESCRIPTION              "event.description"

/** For event sound streams: absolute horizontal mouse position on the screen if the event sound was triggered by a mouse click, integer formatted as text string. e.g. "865" */
#define PA_PROP_EVENT_MOUSE_X                  "event.mouse.x"

/** For event sound streams: absolute vertical mouse position on the screen if the event sound was triggered by a mouse click, integer formatted as text string. e.g. "432" */
#define PA_PROP_EVENT_MOUSE_Y                  "event.mouse.y"

/** For event sound streams: relative horizontal mouse position on the screen if the event sound was triggered by a mouse click, float formatted as text string, ranging from 0.0 (left side of the screen) to 1.0 (right side of the screen). e.g. "0.65" */
#define PA_PROP_EVENT_MOUSE_HPOS               "event.mouse.hpos"

/** For event sound streams: relative vertical mouse position on the screen if the event sound was triggered by a mouse click, float formatted as text string, ranging from 0.0 (top of the screen) to 1.0 (bottom of the screen). e.g. "0.43" */
#define PA_PROP_EVENT_MOUSE_VPOS               "event.mouse.vpos"

/** For event sound streams: mouse button that triggered the event if applicable, integer formatted as string with 0=left, 1=middle, 2=right. e.g. "0" */
#define PA_PROP_EVENT_MOUSE_BUTTON             "event.mouse.button"

/** For streams that belong to a window on the screen: localized window title. e.g. "Totem Music Player" */
#define PA_PROP_WINDOW_NAME                    "window.name"

/** For streams that belong to a window on the screen: a textual id for identifying a window logically. e.g. "org.gnome.Totem.MainWindow" */
#define PA_PROP_WINDOW_ID                      "window.id"

/** \cond fulldocs */
/** For streams that belong to a window on the screen: window icon. A binary blob containing PNG image data */
#define PA_PROP_WINDOW_ICON                    "window.icon"
/** \endcond */

/** For streams that belong to a window on the screen: an XDG icon name for the window. e.g. "totem" */
#define PA_PROP_WINDOW_ICON_NAME               "window.icon_name"

/** For streams that belong to a window on the screen: absolute horizontal window position on the screen, integer formatted as text string. e.g. "865". \since 0.9.17 */
#define PA_PROP_WINDOW_X                       "window.x"

/** For streams that belong to a window on the screen: absolute vertical window position on the screen, integer formatted as text string. e.g. "343". \since 0.9.17 */
#define PA_PROP_WINDOW_Y                       "window.y"

/** For streams that belong to a window on the screen: window width on the screen, integer formatted as text string. e.g. "365". \since 0.9.17 */
#define PA_PROP_WINDOW_WIDTH                   "window.width"

/** For streams that belong to a window on the screen: window height on the screen, integer formatted as text string. e.g. "643". \since 0.9.17 */
#define PA_PROP_WINDOW_HEIGHT                  "window.height"

/** For streams that belong to a window on the screen: relative position of the window center on the screen, float formatted as text string, ranging from 0.0 (left side of the screen) to 1.0 (right side of the screen). e.g. "0.65". \since 0.9.17 */
#define PA_PROP_WINDOW_HPOS                    "window.hpos"

/** For streams that belong to a window on the screen: relative position of the window center on the screen, float formatted as text string, ranging from 0.0 (top of the screen) to 1.0 (bottom of the screen). e.g. "0.43". \since 0.9.17 */
#define PA_PROP_WINDOW_VPOS                    "window.vpos"

/** For streams that belong to a window on the screen: if the windowing system supports multiple desktops, a comma seperated list of indexes of the desktops this window is visible on. If this property is an empty string, it is visible on all desktops (i.e. 'sticky'). The first desktop is 0. e.g. "0,2,3" \since 0.9.18 */
#define PA_PROP_WINDOW_DESKTOP                 "window.desktop"

/** For streams that belong to an X11 window on the screen: the X11 display string. e.g. ":0.0" */
#define PA_PROP_WINDOW_X11_DISPLAY             "window.x11.display"

/** For streams that belong to an X11 window on the screen: the X11 screen the window is on, an integer formatted as string. e.g. "0" */
#define PA_PROP_WINDOW_X11_SCREEN              "window.x11.screen"

/** For streams that belong to an X11 window on the screen: the X11 monitor the window is on, an integer formatted as string. e.g. "0" */
#define PA_PROP_WINDOW_X11_MONITOR             "window.x11.monitor"

/** For streams that belong to an X11 window on the screen: the window XID, an integer formatted as string. e.g. "25632" */
#define PA_PROP_WINDOW_X11_XID                 "window.x11.xid"

/** For clients/streams: localized human readable application name. e.g. "Totem Music Player" */
#define PA_PROP_APPLICATION_NAME               "application.name"

/** For clients/streams: a textual id for identifying an application logically. e.g. "org.gnome.Totem" */
#define PA_PROP_APPLICATION_ID                 "application.id"

/** For clients/streams: a version string e.g. "0.6.88" */
#define PA_PROP_APPLICATION_VERSION            "application.version"

/** \cond fulldocs */
/** For clients/streams: application icon. A binary blob containing PNG image data */
#define PA_PROP_APPLICATION_ICON               "application.icon"
/** \endcond */

/** For clients/streams: an XDG icon name for the application. e.g. "totem" */
#define PA_PROP_APPLICATION_ICON_NAME          "application.icon_name"

/** For clients/streams: application language if applicable, in standard POSIX format. e.g. "de_DE" */
#define PA_PROP_APPLICATION_LANGUAGE           "application.language"

/** For clients/streams on UNIX: application process PID, an integer formatted as string. e.g. "4711" */
#define PA_PROP_APPLICATION_PROCESS_ID         "application.process.id"

/** For clients/streams: application process name. e.g. "totem" */
#define PA_PROP_APPLICATION_PROCESS_BINARY     "application.process.binary"

/** For clients/streams: application user name. e.g. "lennart" */
#define PA_PROP_APPLICATION_PROCESS_USER       "application.process.user"

/** For clients/streams: host name the application runs on. e.g. "omega" */
#define PA_PROP_APPLICATION_PROCESS_HOST       "application.process.host"

/** For clients/streams: the D-Bus host id the application runs on. e.g. "543679e7b01393ed3e3e650047d78f6e" */
#define PA_PROP_APPLICATION_PROCESS_MACHINE_ID "application.process.machine_id"

/** For clients/streams: an id for the login session the application runs in. On Unix the value of $XDG_SESSION_COOKIE. e.g. "543679e7b01393ed3e3e650047d78f6e-1235159798.76193-190367717" */
#define PA_PROP_APPLICATION_PROCESS_SESSION_ID "application.process.session_id"

/** For devices: device string in the underlying audio layer's format. e.g. "surround51:0" */
#define PA_PROP_DEVICE_STRING                  "device.string"

/** For devices: API this device is access with. e.g. "alsa" */
#define PA_PROP_DEVICE_API                     "device.api"

/** For devices: localized human readable device one-line description, e.g. "Foobar Industries USB Headset 2000+ Ultra" */
#define PA_PROP_DEVICE_DESCRIPTION             "device.description"

/** For devices: bus path to the device in the OS' format. e.g. "/sys/bus/pci/devices/0000:00:1f.2" */
#define PA_PROP_DEVICE_BUS_PATH                "device.bus_path"

/** For devices: serial number if applicable. e.g. "4711-0815-1234" */
#define PA_PROP_DEVICE_SERIAL                  "device.serial"

/** For devices: vendor ID if applicable. e.g. 1274 */
#define PA_PROP_DEVICE_VENDOR_ID               "device.vendor.id"

/** For devices: vendor name if applicable. e.g. "Foocorp Heavy Industries" */
#define PA_PROP_DEVICE_VENDOR_NAME             "device.vendor.name"

/** For devices: product ID if applicable. e.g. 4565 */
#define PA_PROP_DEVICE_PRODUCT_ID              "device.product.id"

/** For devices: product name if applicable. e.g. "SuperSpeakers 2000 Pro" */
#define PA_PROP_DEVICE_PRODUCT_NAME            "device.product.name"

/** For devices: device class. One of "sound", "modem", "monitor", "filter" */
#define PA_PROP_DEVICE_CLASS                   "device.class"

/** For devices: form factor if applicable. One of "internal", "speaker", "handset", "tv", "webcam", "microphone", "headset", "headphone", "hands-free", "car", "hifi", "computer", "portable" */
#define PA_PROP_DEVICE_FORM_FACTOR             "device.form_factor"

/** For devices: bus of the device if applicable. One of "isa", "pci", "usb", "firewire", "bluetooth" */
#define PA_PROP_DEVICE_BUS                     "device.bus"

/** \cond fulldocs */
/** For devices: icon for the device. A binary blob containing PNG image data */
#define PA_PROP_DEVICE_ICON                    "device.icon"
/** \endcond */

/** For devices: an XDG icon name for the device. e.g. "sound-card-speakers-usb" */
#define PA_PROP_DEVICE_ICON_NAME               "device.icon_name"

/** For devices: access mode of the device if applicable. One of "mmap", "mmap_rewrite", "serial" */
#define PA_PROP_DEVICE_ACCESS_MODE             "device.access_mode"

/** For filter devices: master device id if applicable. */
#define PA_PROP_DEVICE_MASTER_DEVICE           "device.master_device"

/** For devices: buffer size in bytes, integer formatted as string. */
#define PA_PROP_DEVICE_BUFFERING_BUFFER_SIZE   "device.buffering.buffer_size"

/** For devices: fragment size in bytes, integer formatted as string. */
#define PA_PROP_DEVICE_BUFFERING_FRAGMENT_SIZE "device.buffering.fragment_size"

/** For devices: profile identifier for the profile this devices is in. e.g. "analog-stereo", "analog-surround-40", "iec958-stereo", ...*/
#define PA_PROP_DEVICE_PROFILE_NAME            "device.profile.name"

/** For devices: intended use. A comma seperated list of roles (see PA_PROP_MEDIA_ROLE) this device is particularly well suited for, due to latency, quality or form factor. \since 0.9.16 */
#define PA_PROP_DEVICE_INTENDED_ROLES          "device.intended_roles"

/** For devices: human readable one-line description of the profile this device is in. e.g. "Analog Stereo", ... */
#define PA_PROP_DEVICE_PROFILE_DESCRIPTION     "device.profile.description"

/** For modules: the author's name, formatted as UTF-8 string. e.g. "Lennart Poettering" */
#define PA_PROP_MODULE_AUTHOR                  "module.author"

/** For modules: a human readable one-line description of the module's purpose formatted as UTF-8. e.g. "Frobnicate sounds with a flux compensator" */
#define PA_PROP_MODULE_DESCRIPTION             "module.description"

/** For modules: a human readable usage description of the module's arguments formatted as UTF-8. */
#define PA_PROP_MODULE_USAGE                   "module.usage"

/** For modules: a version string for the module. e.g. "0.9.15" */
#define PA_PROP_MODULE_VERSION                 "module.version"

/** A property list object. Basically a dictionary with ASCII strings
 * as keys and arbitrary data as values. \since 0.9.11 */
typedef struct pa_proplist pa_proplist;

/** Allocate a property list. \since 0.9.11 */
pa_proplist* pa_proplist_new(void);

/** Free the property list. \since 0.9.11 */
void pa_proplist_free(pa_proplist* p);

/** Append a new string entry to the property list, possibly
 * overwriting an already existing entry with the same key. An
 * internal copy of the data passed is made. Will accept only valid
 * UTF-8. \since 0.9.11 */
int pa_proplist_sets(pa_proplist *p, const char *key, const char *value);

/** Append a new string entry to the property list, possibly
 * overwriting an already existing entry with the same key. An
 * internal copy of the data passed is made. Will accept only valid
 * UTF-8. The string passed in must contain a '='. Left hand side of
 * the '=' is used as key name, the right hand side as string
 * data. \since 0.9.16 */
int pa_proplist_setp(pa_proplist *p, const char *pair);

/** Append a new string entry to the property list, possibly
 * overwriting an already existing entry with the same key. An
 * internal copy of the data passed is made. Will accept only valid
 * UTF-8. The data can be passed as printf()-style format string with
 * arguments. \since 0.9.11 */
int pa_proplist_setf(pa_proplist *p, const char *key, const char *format, ...) PA_GCC_PRINTF_ATTR(3,4);

/** Append a new arbitrary data entry to the property list, possibly
 * overwriting an already existing entry with the same key. An
 * internal copy of the data passed is made. \since 0.9.11 */
int pa_proplist_set(pa_proplist *p, const char *key, const void *data, size_t nbytes);

/** Return a string entry for the specified key. Will return NULL if
 * the data is not valid UTF-8. Will return a NUL-terminated string in
 * an internally allocated buffer. The caller should make a copy of
 * the data before accessing the property list again. \since 0.9.11 */
const char *pa_proplist_gets(pa_proplist *p, const char *key);

/** Return the the value for the specified key. Will return a
 * NUL-terminated string for string entries. The pointer returned will
 * point to an internally allocated buffer. The caller should make a
 * copy of the data before the property list is accessed again. \since
 * 0.9.11 */
int pa_proplist_get(pa_proplist *p, const char *key, const void **data, size_t *nbytes);

/** Update mode enum for pa_proplist_update(). \since 0.9.11 */
typedef enum pa_update_mode {
    PA_UPDATE_SET
    /**< Replace the entire property list with the new one. Don't keep
     *  any of the old data around */,

    PA_UPDATE_MERGE
    /**< Merge new property list into the existing one, not replacing
     *  any old entries if they share a common key with the new
     *  property list. */,

    PA_UPDATE_REPLACE
    /**< Merge new property list into the existing one, replacing all
     *  old entries that share a common key with the new property
     *  list. */
} pa_update_mode_t;

/** \cond fulldocs */
#define PA_UPDATE_SET PA_UPDATE_SET
#define PA_UPDATE_MERGE PA_UPDATE_MERGE
#define PA_UPDATE_REPLACE PA_UPDATE_REPLACE
/** \endcond */

/** Merge property list "other" into "p", adhering the merge mode as
 * specified in "mode". \since 0.9.11 */
void pa_proplist_update(pa_proplist *p, pa_update_mode_t mode, pa_proplist *other);

/** Removes a single entry from the property list, identified be the
 * specified key name. \since 0.9.11 */
int pa_proplist_unset(pa_proplist *p, const char *key);

/** Similar to pa_proplist_remove() but takes an array of keys to
 * remove. The array should be terminated by a NULL pointer. Return -1
 * on failure, otherwise the number of entries actually removed (which
 * might even be 0, if there where no matching entries to
 * remove). \since 0.9.11 */
int pa_proplist_unset_many(pa_proplist *p, const char * const keys[]);

/** Iterate through the property list. The user should allocate a
 * state variable of type void* and initialize it with NULL. A pointer
 * to this variable should then be passed to pa_proplist_iterate()
 * which should be called in a loop until it returns NULL which
 * signifies EOL. The property list should not be modified during
 * iteration through the list -- except for deleting the current
 * looked at entry. On each invication this function will return the
 * key string for the next entry. The keys in the property list do not
 * have any particular order. \since 0.9.11 */
const char *pa_proplist_iterate(pa_proplist *p, void **state);

/** Format the property list nicely as a human readable string. This
 * works very much like pa_proplist_to_string_sep() and uses a newline
 * as seperator and appends one final one. Call pa_xfree() on the
 * result. \since 0.9.11 */
char *pa_proplist_to_string(pa_proplist *p);

/** Format the property list nicely as a human readable string and
 * choose the seperator. Call pa_xfree() on the result. \since
 * 0.9.15 */
char *pa_proplist_to_string_sep(pa_proplist *p, const char *sep);

/** Allocate a new property list and assign key/value from a human
 * readable string. \since 0.9.15 */
pa_proplist *pa_proplist_from_string(const char *str);

  /** Returns 1 if an entry for the specified key is existant in the
 * property list. \since 0.9.11 */
int pa_proplist_contains(pa_proplist *p, const char *key);

/** Remove all entries from the property list object. \since 0.9.11 */
void pa_proplist_clear(pa_proplist *p);

/** Allocate a new property list and copy over every single entry from
 * the specific list. \since 0.9.11 */
pa_proplist* pa_proplist_copy(pa_proplist *t);

/** Return the number of entries on the property list. \since 0.9.15 */
unsigned pa_proplist_size(pa_proplist *t);

/** Returns 0 when the proplist is empty, positive otherwise \since 0.9.15 */
int pa_proplist_isempty(pa_proplist *t);

PA_C_DECL_END

#endif
