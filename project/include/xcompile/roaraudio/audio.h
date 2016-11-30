//audio.h:

/*
 *      Copyright (C) Philipp 'ph3-der-loewe' Schafft - 2008-2013
 *
 *  This file is part of RoarAudio,
 *  a cross-platform sound system for both, home and professional use.
 *  See README for details.
 *
 *  This file is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License version 3
 *  as published by the Free Software Foundation.
 *
 *  RoarAudio is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this software; see the file COPYING.  If not, write to
 *  the Free Software Foundation, 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301, USA.
 *
 *  NOTE: Even though this file is LGPLed it (may) include GPLed files
 *  so the license of this file is/may therefore downgraded to GPL.
 *  See HACKING for details.
 */

#ifndef _ROARAUDIO_AUDIO_H_
#define _ROARAUDIO_AUDIO_H_

// TODO: move this block to a more logical location.
#define ROAR_CODEC_PCM_LE  ROAR_CODEC_PCM_S_LE
#define ROAR_CODEC_PCM_BE  ROAR_CODEC_PCM_S_BE
#define ROAR_CODEC_PCM_PDP ROAR_CODEC_PCM_S_PDP


/*
 Bits:
 76543210
 |||||||\---\ byte-
 ||||||\----/ order
 |||||\-----> unsigned?
 ||||\------> PCM(0) or MIDI(1)?
 |||\-------> PCM/MIDI(0) or hi-level codecs(1)
 ||\--------> MISC(0) or RIFF/WAVE like(1)
 |\---------> first set(0) or second set(1)
 \----------> (0)

 BB = Byte order / MSB/LSB

 -- First Set:

 MIDI 0x08:
 76543210
      000 0x08 -> MIDI File

 hi-level 0x10:
  76543210
      0000 0x10 -> Ogg Vorbis
      0001 0x11 -> Native FLAC
      0010 0x12 -> Ogg Speex
      0011 0x13 -> Reserved for CELT
      0100 0x14 -> Ogg FLAC
      0101 0x15 -> Ogg General
      0110 0x16 -> Ogg CELT
      0111 0x17 -> Ogg
      [...]
      **** 0x1a -> ROAR CELT
      **** 0x1b -> ROAR SPEEX
      **** 0x1c -> RAUM
      **** 0x1d -> RAUM Vorbis
      **** 0x1e -> RAUM FLAC

 RIFF/WAVE like 0x20:
  76543210
      0000 0x20 -> RIFF/WAVE

 LOG Codecs 0x30:
  76543210
      00BB 0x30 -> A-Law (base)
      01BB 0x34 -> mu-Law (base)

 -- Second Set:

 Bits:
 76543210
 |||||||\---\ byte-
 ||||||\----/ order
 |||||\-----> unsigned? (or other flags)
 ||||\------> META: text(0) or binary(1)
 |||\-------> META(0)/CONTAINER(1)
 ||\--------> Specal codecs(0)
 |\---------> second set(1)
 \----------> (0)

 Meta Codecs 0x40:
  76543210
      0000 0x40 -> Meta Text: Vorbis Comment Like
      [...]
      0100 0x44 -> Meta Text: RoarAudio Like
      [...]
      11BB 0x4c -> Meta Binary: RoarAudio Like

 Container 0x50:
  76543210
      0000 0x50 -> Null container: pass
      0001 0x51 -> Gzip
      0010 0x52 -> Bzip2
      0011 0x53 -> OpenPGP bin
      0100 0x54 -> OpenPGP asc
      0101 0x55 -> TAR

 Bits:
 76543210
 |||||||\---\ byte-
 ||||||\----/ order
 |||||\-----> unsigned? (or other flags)
 ||||\------> (0)
 |||\-------> MIDI(0)/Light(1)
 ||\--------> MIDI and Light(1)
 |\---------> second set(1)
 \----------> (0)

 MIDI 0x60:
  76543210
      0000 -> MIDI

 Light 0x70:
  76543210
      0000 -> DMX512
      0001 -> RoarDMX

 Bits:
 76543210
 |||||||\---\ byte-
 ||||||\----/ order
 |||||\-----> unsigned? (or other flags)
 ||||\------> ID
 |||\-------> RDTCS(0) / User/Vendor Specific(1)
 ||\--------> first subset(0)
 |\---------> first set(0)
 \----------> (1)

 RDTCS 0x80:
  76543210
      0000 -> RDS

 User  0x90:
  76543210
      0000 -> USER0
      [...]
      1111 -> USER15

*/

#define ROAR_CODEC_IS_SIGNED(x)  (((x) & ROAR_CODEC_UNSIGNED) == 0 ? 1 : 0)
#define ROAR_CODEC_BYTE_ORDER(x) ((x) & 0x03)

#define ROAR_CODEC_UNSIGNED    (1 << 2)
#define ROAR_CODEC_LE          0x01
#define ROAR_CODEC_BE          0x02
#define ROAR_CODEC_PDP         0x03

#define ROAR_CODEC_MSB         0x00
#define ROAR_CODEC_LSB         0x01

#define ROAR_CODEC_PCM       0x00
#define ROAR_CODEC_PCM_S_LE  (ROAR_CODEC_PCM | ROAR_CODEC_LE )
#define ROAR_CODEC_PCM_S_BE  (ROAR_CODEC_PCM | ROAR_CODEC_BE )
#define ROAR_CODEC_PCM_S_PDP (ROAR_CODEC_PCM | ROAR_CODEC_PDP)

#define ROAR_CODEC_PCM_U_LE  (ROAR_CODEC_PCM_S_LE  | ROAR_CODEC_UNSIGNED)
#define ROAR_CODEC_PCM_U_BE  (ROAR_CODEC_PCM_S_BE  | ROAR_CODEC_UNSIGNED)
#define ROAR_CODEC_PCM_U_PDP (ROAR_CODEC_PCM_S_PDP | ROAR_CODEC_UNSIGNED)

#define ROAR_CODEC_MIDI_FILE    0x08

#define ROAR_CODEC_OGG_VORBIS   0x10
#define ROAR_CODEC_FLAC         0x11 /* native FLAC without Ogg container */
#define ROAR_CODEC_OGG_SPEEX    0x12
/* #define ROAR_CODEC_CELT/OGG_CELT 0x13 Reserved for CELT */
#define ROAR_CODEC_OGG_FLAC     0x14
#define ROAR_CODEC_OGG_GENERAL  0x15
#define ROAR_CODEC_OGG_CELT     0x16
#define ROAR_CODEC_OGG          0x17
#define ROAR_CODEC_OGG_OPUS     0x18

#define ROAR_CODEC_ROAR_OPUS    0x19
#define ROAR_CODEC_ROAR_CELT    0x1a
#define ROAR_CODEC_ROAR_SPEEX   0x1b

#define ROAR_CODEC_RAUM         0x1c
#define ROAR_CODEC_RAUM_VORBIS  0x1d
#define ROAR_CODEC_RAUM_FLAC    0x1e

#define ROAR_CODEC_RIFF_WAVE    0x20
#define ROAR_CODEC_RIFX         (ROAR_CODEC_RIFF_WAVE | ROAR_CODEC_BE)
#define ROAR_CODEC_AU           0x24
#define ROAR_CODEC_AIFF         0x28

#define ROAR_CODEC_ALAW         0x30
#define ROAR_CODEC_AUTLAW_LE    (ROAR_CODEC_ALAW|ROAR_CODEC_LE)
#define ROAR_CODEC_AUTLAW_BE    (ROAR_CODEC_ALAW|ROAR_CODEC_BE)
#define ROAR_CODEC_AUTLAW       ROAR_CODEC_AUTLAW_BE
#define ROAR_CODEC_MULAW        0x34
#define ROAR_CODEC_MUUTLAW_LE   (ROAR_CODEC_MULAW|ROAR_CODEC_LE)
#define ROAR_CODEC_MUUTLAW_BE   (ROAR_CODEC_MULAW|ROAR_CODEC_BE)
#define ROAR_CODEC_MUUTLAW      ROAR_CODEC_MUUTLAW_BE
#define ROAR_CODEC_GSM          0x38
#define ROAR_CODEC_GSM49        0x39
#define ROAR_CODEC_BRR          0x3c /* SPC-700 Bit Rate Reduction of              */
                                     /* Super Nintendo Entertainment System (SNES) */

// Meta Codecs:
#define ROAR_CODEC_META_VCLT    0x40 /* VCLT = Vorbis Comment Like Text */
#define ROAR_CODEC_META_RALT    0x44 /* RALT = RoarAudio Like Text      */
#define ROAR_CODEC_META_RALB    0x4c /* RALB = RoarAudio Like Binary    */
                                     /* if no byte order is given then you
                                        should assume BE as it is network
                                        byte order                     */
#define ROAR_CODEC_META_RALB_LE  (ROAR_CODEC_META_RALB | ROAR_CODEC_LE )
#define ROAR_CODEC_META_RALB_BE  (ROAR_CODEC_META_RALB | ROAR_CODEC_BE )
#define ROAR_CODEC_META_RALB_PDP (ROAR_CODEC_META_RALB | ROAR_CODEC_PDP)

// Container Codecs:
/*
 Container 0x50:
  76543210
      0000 0x50 -> Null container: pass
      0001 0x51 -> Gzip
      0010 0x52 -> Bzip2
      0011 0x53 -> OpenPGP bin
      0100 0x54 -> OpenPGP asc
      0101 0x55 -> TAR
*/
#define ROAR_CODEC_CONT_NULL    0x50
#define ROAR_CODEC_CONT_BASE    ROAR_CODEC_CONT_NULL
#define ROAR_CODEC_CONT_GZIP    0x51
#define ROAR_CODEC_CONT_BZIP2   0x52
#define ROAR_CODEC_CONT_OPGPBIN 0x53
#define ROAR_CODEC_CONT_OPGPASC 0x54
#define ROAR_CODEC_CONT_TAR     0x55


// MIDI:
#define ROAR_CODEC_MIDI         0x60
#define ROAR_CODEC_ROARMIDI     0x64

// Light Control:
#define ROAR_CODEC_DMX512       0x70
#define ROAR_CODEC_ROARDMX      0x71

// RDTCS:
#define ROAR_CODEC_RDS          0x80

// User specific:
#define ROAR_CODEC_USER0        0x90
#define ROAR_CODEC_USER1        0x91
#define ROAR_CODEC_USER2        0x92
#define ROAR_CODEC_USER3        0x93
#define ROAR_CODEC_USER4        0x94
#define ROAR_CODEC_USER5        0x95
#define ROAR_CODEC_USER6        0x96
#define ROAR_CODEC_USER7        0x97
#define ROAR_CODEC_USER8        0x98
#define ROAR_CODEC_USER9        0x99
#define ROAR_CODEC_USER10       0x9a
#define ROAR_CODEC_USER11       0x9b
#define ROAR_CODEC_USER12       0x9c
#define ROAR_CODEC_USER13       0x9d
#define ROAR_CODEC_USER14       0x9e
#define ROAR_CODEC_USER15       0x9f

#if BYTE_ORDER == BIG_ENDIAN

#define ROAR_CODEC_NATIVE_ENDIAN ROAR_CODEC_BE

#define ROAR_CODEC_PCM_S   ROAR_CODEC_PCM_S_BE
#define ROAR_CODEC_PCM_U   ROAR_CODEC_PCM_U_BE
#define ROAR_BE2DEF(x) (x)

#elif BYTE_ORDER == LITTLE_ENDIAN

#define ROAR_CODEC_NATIVE_ENDIAN ROAR_CODEC_LE

#define ROAR_CODEC_PCM_S   ROAR_CODEC_PCM_S_LE
#define ROAR_CODEC_PCM_U   ROAR_CODEC_PCM_U_LE
#define ROAR_LE2DEF(x) (x)

#else

#define ROAR_CODEC_NATIVE_ENDIAN ROAR_CODEC_PDP

#define ROAR_CODEC_PCM_S   ROAR_CODEC_PCM_S_PDP
#define ROAR_CODEC_PCM_U   ROAR_CODEC_PCM_U_PDP
#define ROAR_PDP2DEF(x) (x)

#endif

#define ROAR_CODEC_DEFAULT ROAR_CODEC_PCM_S


#define ROAR_CODEC_NATIVE ROAR_CODEC_DEFAULT

#define ROAR_BITS_MAX             32

#ifndef ROAR_BITS_DEFAULT
#define ROAR_BITS_DEFAULT         16
#endif
#ifndef ROAR_CHANNELS_DEFAULT
#define ROAR_CHANNELS_DEFAULT      2
#endif
#ifndef ROAR_RATE_DEFAULT
#define ROAR_RATE_DEFAULT      44100
#endif

#define ROAR_MIDI_TICKS_PER_BEAT  96
#define ROAR_MIDI_BITS             8
#define ROAR_MIDI_CHANNELS_DEFAULT 16

#define ROAR_MAX_CHANNELS         64

#define ROAR_SET_VOL_ALL           1
#define ROAR_SET_VOL_ONE           2
#define ROAR_SET_VOL_MS            3
#define ROAR_SET_VOL_UNMAPPED      4


#define ROAR_SPEEX_MAX_CC          256
#define ROAR_SPEEX_MAGIC           "RoarSpeex"
#define ROAR_SPEEX_MAGIC_LEN       9
#define ROAR_SPEEX_MODE_NB         1
#define ROAR_SPEEX_MODE_WB         2
#define ROAR_SPEEX_MODE_UWB        3

#define ROAR_CELT_MAGIC_0          "RoarCELT0"
#define ROAR_CELT_MAGIC_1          "RoarCELT1"
#define ROAR_CELT_MAGIC_LEN        9

#ifdef ROAR_HAVE_CELT_VERSION_0_7_1
#define ROAR_CELT_MAGIC            ROAR_CELT_MAGIC_1
#else
#define ROAR_CELT_MAGIC            ROAR_CELT_MAGIC_0
#endif

#define ROAR_AUDIO_INFO_TYPE    uint32_t
#define ROAR_AUDIO_INFO_INVALID ((ROAR_AUDIO_INFO_TYPE)-1)

struct roar_audio_info {
 ROAR_AUDIO_INFO_TYPE rate;
 ROAR_AUDIO_INFO_TYPE bits;
 ROAR_AUDIO_INFO_TYPE channels;
 ROAR_AUDIO_INFO_TYPE codec;
};

struct roar_mixer_settings {
 //unsigned      channels;
 uint16_t   scale;
 uint16_t   rpg_mul; // rpg = ReplayGain
 uint16_t   rpg_div;
 uint16_t   mixer[ROAR_MAX_CHANNELS];
};

#define ROAR_MIXER(x) ((struct roar_mixer_settings *)x)

#endif

//ll
