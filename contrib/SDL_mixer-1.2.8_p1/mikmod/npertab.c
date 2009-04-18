/*	MikMod sound library
	(c) 1998, 1999 Miodrag Vallat and others - see file AUTHORS for
	complete list.

	This library is free software; you can redistribute it and/or modify
	it under the terms of the GNU Library General Public License as
	published by the Free Software Foundation; either version 2 of
	the License, or (at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Library General Public License for more details.

	You should have received a copy of the GNU Library General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
	02111-1307, USA.
*/

/*==============================================================================

  $Id: npertab.c 32 1999-12-28 18:51:11Z hercules $

  MOD format period table.  Used by both the MOD and M15 (15-inst mod) Loaders.

==============================================================================*/

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "mikmod_internals.h"

UWORD npertab[7*OCTAVE]={
	/* -> Tuning 0 */
	1712,1616,1524,1440,1356,1280,1208,1140,1076,1016, 960, 906,
	 856, 808, 762, 720, 678, 640, 604, 570, 538, 508, 480, 453,
	 428, 404, 381, 360, 339, 320, 302, 285, 269, 254, 240, 226,
	 214, 202, 190, 180, 170, 160, 151, 143, 135, 127, 120, 113,
	 107, 101,  95,  90,  85,  80,  75,  71,  67,  63,  60,  56,

	  53,  50,  47,  45,  42,  40,  37,  35,  33,  31,  30,  28,
	  27,  25,  24,  22,  21,  20,  19,  18,  17,  16,  15,  14
};

/* ex:set ts=4: */
