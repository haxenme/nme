#ifndef fooversionhfoo /*-*-C-*-*/
 #define fooversionhfoo
 
 /***
  This file is part of PulseAudio.
 
  Copyright 2004-2006 Lennart Poettering
  Copyright 2006 Pierre Ossman <ossman@cendio.se> for Cendio AB
 
  PulseAudio is free software; you can redistribute it and/or modify
  it under the terms of the GNU Lesser General Public License as published
  by the Free Software Foundation; either version 2 of the License,
  or (at your option) any later version.
 
  PulseAudio is distributed in the hope that it will be useful, but
  WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  General Public License for more details.
 
  You should have received a copy of the GNU Lesser General Public License
  along with PulseAudio; if not, see <http://www.gnu.org/licenses/>.
 ***/
 
 /* WARNING: Make sure to edit the real source file version.h.in! */
 
 #include <pulse/cdecl.h>
 
 PA_C_DECL_BEGIN
 
 #define pa_get_headers_version() ("11.0.0")
 
 const char* pa_get_library_version(void);
 
 #define PA_API_VERSION 12
 
 #define PA_PROTOCOL_VERSION 32
 
 #define PA_MAJOR 11
 
 #define PA_MINOR 0
 
 #define PA_MICRO 0
 
 #define PA_CHECK_VERSION(major,minor,micro) \
  ((PA_MAJOR > (major)) || \
  (PA_MAJOR == (major) && PA_MINOR > (minor)) || \
  (PA_MAJOR == (major) && PA_MINOR == (minor) && PA_MICRO >= (micro)))
 
 PA_C_DECL_END
 
 #endif

