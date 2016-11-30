//genre.h:

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

#ifndef _ROARAUDIO_GENRE_H_
#define _ROARAUDIO_GENRE_H_

// Meta genres:
#define ROAR_META_GENRE_META_NONE              0x0000
#define ROAR_META_GENRE_META_OTHER             0x0001
#define ROAR_META_GENRE_META_MUSIC             0x0002
#define ROAR_META_GENRE_META_MODERATION        0x0003
#define ROAR_META_GENRE_META_TEXT              0x0004
#define ROAR_META_GENRE_META_COMMERCIAL        0x0005

// EU:
#define ROAR_META_GENRE_RDS_EU_NONE            0x0020
#define ROAR_META_GENRE_RDS_EU_NEWS            0x0021
#define ROAR_META_GENRE_RDS_EU_CURRENT_AFFAIRS 0x0022
#define ROAR_META_GENRE_RDS_EU_INFORMATION     0x0023
#define ROAR_META_GENRE_RDS_EU_SPORT           0x0024
#define ROAR_META_GENRE_RDS_EU_EDUCATION       0x0025
#define ROAR_META_GENRE_RDS_EU_DRAMA           0x0026
#define ROAR_META_GENRE_RDS_EU_CULTURE         0x0027
#define ROAR_META_GENRE_RDS_EU_SCIENCE         0x0028
#define ROAR_META_GENRE_RDS_EU_VARIED          0x0029
#define ROAR_META_GENRE_RDS_EU_POP_MUSIC       0x002a
#define ROAR_META_GENRE_RDS_EU_ROCK_MUSIC      0x002b
#define ROAR_META_GENRE_RDS_EU_EASY_LISTENING  0x002c
#define ROAR_META_GENRE_RDS_EU_LIGHT_CLASSICAL 0x002d
#define ROAR_META_GENRE_RDS_EU_SERIOUS_CLASSICAL 0x002e
#define ROAR_META_GENRE_RDS_EU_OTHER_MUSIC     0x002f
#define ROAR_META_GENRE_RDS_EU_WEATHER         0x0030
#define ROAR_META_GENRE_RDS_EU_FINANCE         0x0031
#define ROAR_META_GENRE_RDS_EU_CHILDREN_S_PROGRAMMES 0x0032
#define ROAR_META_GENRE_RDS_EU_SOCIAL_AFFAIRS  0x0033
#define ROAR_META_GENRE_RDS_EU_RELIGION        0x0034
#define ROAR_META_GENRE_RDS_EU_PHONE_IN        0x0035
#define ROAR_META_GENRE_RDS_EU_TRAVEL          0x0036
#define ROAR_META_GENRE_RDS_EU_LEISURE         0x0037
#define ROAR_META_GENRE_RDS_EU_JAZZ_MUSIC      0x0038
#define ROAR_META_GENRE_RDS_EU_COUNTRY_MUSIC   0x0039
#define ROAR_META_GENRE_RDS_EU_NATIONAL_MUSIC  0x003a
#define ROAR_META_GENRE_RDS_EU_OLDIES_MUSIC    0x003b
#define ROAR_META_GENRE_RDS_EU_FOLK_MUSIC      0x003c
#define ROAR_META_GENRE_RDS_EU_DOCUMENTARY     0x003d
#define ROAR_META_GENRE_RDS_EU_ALARM_TEST      0x003e
#define ROAR_META_GENRE_RDS_EU_ALARM           0x003f
#define ROAR_META_GENRE_RDS_EU_EMERGENCY_TEST  ROAR_META_GENRE_RDS_EU_ALARM_TEST
#define ROAR_META_GENRE_RDS_EU_EMERGENCY       ROAR_META_GENRE_RDS_EU_ALARM

// North America:
#define ROAR_META_GENRE_RDS_NA_NONE            0x0040
#define ROAR_META_GENRE_RDS_NA_NEWS            0x0041
#define ROAR_META_GENRE_RDS_NA_INFORMATION     0x0042
#define ROAR_META_GENRE_RDS_NA_SPORTS          0x0043
#define ROAR_META_GENRE_RDS_NA_TALK            0x0044
#define ROAR_META_GENRE_RDS_NA_ROCK            0x0045
#define ROAR_META_GENRE_RDS_NA_CLASSIC_ROCK    0x0046
#define ROAR_META_GENRE_RDS_NA_ADULT_HITS      0x0047
#define ROAR_META_GENRE_RDS_NA_SOFT_ROCK       0x0048
#define ROAR_META_GENRE_RDS_NA_TOP_40          0x0049
#define ROAR_META_GENRE_RDS_NA_COUNTRY         0x004a
#define ROAR_META_GENRE_RDS_NA_OLDIES          0x004b
#define ROAR_META_GENRE_RDS_NA_SOFT            0x004c
#define ROAR_META_GENRE_RDS_NA_NOSTALGIA       0x004d
#define ROAR_META_GENRE_RDS_NA_JAZZ            0x004e
#define ROAR_META_GENRE_RDS_NA_CLASSICAL       0x004f
#define ROAR_META_GENRE_RDS_NA_RHYTHM_AND_BLUES 0x0050
#define ROAR_META_GENRE_RDS_NA_SOFT_RHYTHM_AND_BLUES 0x0051
#define ROAR_META_GENRE_RDS_NA_LANGUAGE        0x0052
#define ROAR_META_GENRE_RDS_NA_RELIGIOUS_MUSIC 0x0053
#define ROAR_META_GENRE_RDS_NA_RELIGIOUS_TALK  0x0054
#define ROAR_META_GENRE_RDS_NA_PERSONALITY     0x0055
#define ROAR_META_GENRE_RDS_NA_PUBLIC          0x0056
#define ROAR_META_GENRE_RDS_NA_COLLEGE         0x0057
#define ROAR_META_GENRE_RDS_NA_UNASSIGNED_0    0x0058
#define ROAR_META_GENRE_RDS_NA_UNASSIGNED_1    0x0059
#define ROAR_META_GENRE_RDS_NA_UNASSIGNED_2    0x005a
#define ROAR_META_GENRE_RDS_NA_UNASSIGNED_3    0x005b
#define ROAR_META_GENRE_RDS_NA_UNASSIGNED_4    0x005c
#define ROAR_META_GENRE_RDS_NA_WEATHER         0x005d
#define ROAR_META_GENRE_RDS_NA_EMERGENCY_TEST  0x005e
#define ROAR_META_GENRE_RDS_NA_EMERGENCY       0x005f
#define ROAR_META_GENRE_RDS_NA_ALARM_TEST      ROAR_META_GENRE_RDS_NA_EMERGENCY_TEST
#define ROAR_META_GENRE_RDS_NA_ALARM           ROAR_META_GENRE_RDS_NA_EMERGENCY

// ID3, standard + winamp ext:
#define ROAR_META_GENRE_ID3_BLUES              0x0100
#define ROAR_META_GENRE_ID3_CLASSIC_ROCK       0x0101
#define ROAR_META_GENRE_ID3_COUNTRY            0x0102
#define ROAR_META_GENRE_ID3_DANCE              0x0103
#define ROAR_META_GENRE_ID3_DISCO              0x0104
#define ROAR_META_GENRE_ID3_FUNK               0x0105
#define ROAR_META_GENRE_ID3_GRUNGE             0x0106
#define ROAR_META_GENRE_ID3_HIP_HOP            0x0107
#define ROAR_META_GENRE_ID3_JAZZ               0x0108
#define ROAR_META_GENRE_ID3_METAL              0x0109
#define ROAR_META_GENRE_ID3_NEW_AGE            0x010a
#define ROAR_META_GENRE_ID3_OLDIES             0x010b
#define ROAR_META_GENRE_ID3_OTHER              0x010c
#define ROAR_META_GENRE_ID3_POP                0x010d
#define ROAR_META_GENRE_ID3_R_AND_B            0x010e
#define ROAR_META_GENRE_ID3_RAP                0x010f
#define ROAR_META_GENRE_ID3_REGGAE             0x0110
#define ROAR_META_GENRE_ID3_ROCK               0x0111
#define ROAR_META_GENRE_ID3_TECHNO             0x0112
#define ROAR_META_GENRE_ID3_INDUSTRIAL         0x0113
#define ROAR_META_GENRE_ID3_ALTERNATIVE        0x0114
#define ROAR_META_GENRE_ID3_SKA                0x0115
#define ROAR_META_GENRE_ID3_DEATH_METAL        0x0116
#define ROAR_META_GENRE_ID3_PRANKS             0x0117
#define ROAR_META_GENRE_ID3_SOUNDTRACK         0x0118
#define ROAR_META_GENRE_ID3_EURO_TECHNO        0x0119
#define ROAR_META_GENRE_ID3_AMBIENT            0x011a
#define ROAR_META_GENRE_ID3_TRIP_HOP           0x011b
#define ROAR_META_GENRE_ID3_VOCAL              0x011c
#define ROAR_META_GENRE_ID3_JAZZ_FUNK          0x011d
#define ROAR_META_GENRE_ID3_FUSION             0x011e
#define ROAR_META_GENRE_ID3_TRANCE             0x011f
#define ROAR_META_GENRE_ID3_CLASSICAL          0x0120
#define ROAR_META_GENRE_ID3_INSTRUMENTAL       0x0121
#define ROAR_META_GENRE_ID3_ACID               0x0122
#define ROAR_META_GENRE_ID3_HOUSE              0x0123
#define ROAR_META_GENRE_ID3_GAME               0x0124
#define ROAR_META_GENRE_ID3_SOUND_CLIP         0x0125
#define ROAR_META_GENRE_ID3_GOSPEL             0x0126
#define ROAR_META_GENRE_ID3_NOISE              0x0127
#define ROAR_META_GENRE_ID3_ALTERNROCK         0x0128
#define ROAR_META_GENRE_ID3_BASS               0x0129
#define ROAR_META_GENRE_ID3_SOUL               0x012a
#define ROAR_META_GENRE_ID3_PUNK               0x012b
#define ROAR_META_GENRE_ID3_SPACE              0x012c
#define ROAR_META_GENRE_ID3_MEDITATIVE         0x012d
#define ROAR_META_GENRE_ID3_INSTRUMENTAL_POP   0x012e
#define ROAR_META_GENRE_ID3_INSTRUMENTAL_ROCK  0x012f
#define ROAR_META_GENRE_ID3_ETHNIC             0x0130
#define ROAR_META_GENRE_ID3_GOTHIC             0x0131
#define ROAR_META_GENRE_ID3_DARKWAVE           0x0132
#define ROAR_META_GENRE_ID3_TECHNO_INDUSTRIAL  0x0133
#define ROAR_META_GENRE_ID3_ELECTRONIC         0x0134
#define ROAR_META_GENRE_ID3_POP_FOLK           0x0135
#define ROAR_META_GENRE_ID3_EURODANCE          0x0136
#define ROAR_META_GENRE_ID3_DREAM              0x0137
#define ROAR_META_GENRE_ID3_SOUTHERN_ROCK      0x0138
#define ROAR_META_GENRE_ID3_COMEDY             0x0139
#define ROAR_META_GENRE_ID3_CULT               0x013a
#define ROAR_META_GENRE_ID3_GANGSTA            0x013b
#define ROAR_META_GENRE_ID3_TOP_40             0x013c
#define ROAR_META_GENRE_ID3_CHRISTIAN_RAP      0x013d
#define ROAR_META_GENRE_ID3_POP_FUNK           0x013e
#define ROAR_META_GENRE_ID3_JUNGLE             0x013f
#define ROAR_META_GENRE_ID3_NATIVE_AMERICAN    0x0140
#define ROAR_META_GENRE_ID3_CABARET            0x0141
#define ROAR_META_GENRE_ID3_NEW_WAVE           0x0142
#define ROAR_META_GENRE_ID3_PSYCHADELIC        0x0143
#define ROAR_META_GENRE_ID3_RAVE               0x0144
#define ROAR_META_GENRE_ID3_SHOWTUNES          0x0145
#define ROAR_META_GENRE_ID3_TRAILER            0x0146
#define ROAR_META_GENRE_ID3_LO_FI              0x0147
#define ROAR_META_GENRE_ID3_TRIBAL             0x0148
#define ROAR_META_GENRE_ID3_ACID_PUNK          0x0149
#define ROAR_META_GENRE_ID3_ACID_JAZZ          0x014a
#define ROAR_META_GENRE_ID3_POLKA              0x014b
#define ROAR_META_GENRE_ID3_RETRO              0x014c
#define ROAR_META_GENRE_ID3_MUSICAL            0x014d
#define ROAR_META_GENRE_ID3_ROCK_AND_ROLL      0x014e
#define ROAR_META_GENRE_ID3_HARD_ROCK          0x014f

#endif

//ll
