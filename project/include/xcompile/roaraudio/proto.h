//proto.h:

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

#ifndef _ROARAUDIO_PORTO_H_
#define _ROARAUDIO_PORTO_H_

#define ROAR_CMD_EOL           -1 /* end of list */
#define ROAR_CMD_NOOP           0 /* do nothing */
#define ROAR_CMD_IDENTIFY       1 /* after connect we have to identify ourself */
#define ROAR_CMD_AUTH           2 /* send an auth cookie */
#define ROAR_CMD_NEW_STREAM     3 /* request a new stream id */
#define ROAR_CMD_SET_META       4 /* update meta data of streamed data */
#define ROAR_CMD_EXEC_STREAM    5 /* close all data channels and make the controll socket a raw data socket */
#define ROAR_CMD_QUIT           6 /* quits the connection */

#define ROAR_CMD_GET_STANDBY    7
#define ROAR_CMD_SET_STANDBY    8

#define ROAR_CMD_SERVER_INFO    9 /* Server version ... */
#define ROAR_CMD_SERVER_STATS  10 /* Server stats: number of clients, streams,.. */
#define ROAR_CMD_SERVER_OINFO  11 /* Output info, roar_audio_info sa */

#define ROAR_CMD_ADD_DATA      12 /* add some data to the input buffer */

//#define ROAR_CMD_

#define ROAR_CMD_EXIT          13 /* make the server quit */
#define ROAR_CMD_LIST_STREAMS  14 /* list all streams (not only playback streams like esd does) */
#define ROAR_CMD_LIST_CLIENTS  15 /* list all clients */

#define ROAR_CMD_GET_CLIENT    16 /* get infos about a client */
#define ROAR_CMD_GET_STREAM    17 /* get infos about a stream */

#define ROAR_CMD_KICK          18 /* kick a client, stream, sample or source */

#define ROAR_CMD_SET_VOL       19 /* change volume */
#define ROAR_CMD_GET_VOL       20 /* get volume */

#define ROAR_CMD_CON_STREAM    21 /* let the server connect to something to get data for a new stream */

#define ROAR_CMD_GET_META      22 /* get meta data of streamed data */
#define ROAR_CMD_LIST_META     23 /* get list of meta data of streamed data */

#define ROAR_CMD_BEEP          24 /* send an beep */

#define ROAR_AUTHCTL           25
#define ROAR_ACLCTL            26

#define ROAR_CMD_GET_STREAM_PARA   27 /* Get addition stream parameters like blocksizes */
#define ROAR_CMD_SET_STREAM_PARA   28 /* set special stream parameter */

#define ROAR_CMD_ATTACH        29 /* attach a OUTPUT or source */
#define ROAR_CMD_DETACH        ROAR_CMD_KICK /* just to have an alias */

#define ROAR_CMD_PASSFH        30 /* send an fh via UNIX Domain Socket to the roard */

#define ROAR_CMD_GETTIMEOFDAY  31 /* get time of day from server */

#define ROAR_CMD_WHOAMI        32 /* returns the ID of the current client */

#define ROAR_CMD_DEVCTL        33 /* send control messages to devices */
#define ROAR_CMD_CAPS          34 /* send caps */
#define ROAR_CMD_WAIT          35 /* wait for an event */
#define ROAR_CMD_NOTIFY        36 /* asyncronus notify of events */
#define ROAR_CMD_SEEK          37 /* seek in stream */
#define ROAR_CMD_CLIENTCTL     38 /* like stream ctl, just for client connections */
#define ROAR_CMD_LOOKUP        39 /* lookup??? */
#define ROAR_CMD_CONCTL        40 /* change parameter for current connection */

#define ROAR_CMD_SHIFT_DATA    41 /* get some data from the stream */

// Reserved for RAUM project:
#define ROAR_CMD_RAUM_SEEKTABLE 201 /* contains a seektable */
#define ROAR_CMD_RAUM_PICTURE   202 /* contains a picture block */
#define ROAR_CMD_RAUM_SYNC      203 /* used for raw-seeking, contains a magic pattern */
// End of reserved block

#define ROAR_CMD_EPERM        252 /* error: permition denided */
#define ROAR_CMD_OK_STOP      253 /* used internaly in the serveer: */
                                  // ROAR_CMD_OK but do not queue the client again within the block
#define ROAR_CMD_OK           254 /* return value OK */
#define ROAR_CMD_ERROR        255 /* return value ERROR */


#define ROAR_STANDBY_ACTIVE     1
#define ROAR_STANDBY_INACTIVE   0

// object types...
#define ROAR_OT_CLIENT    1
#define ROAR_OT_STREAM    2
#define ROAR_OT_SOURCE    3
#define ROAR_OT_SAMPLE    4
#define ROAR_OT_OUTPUT    5
#define ROAR_OT_MIXER     6
#define ROAR_OT_BRIDGE    7
#define ROAR_OT_LISTEN    8
#define ROAR_OT_ACTION    9
#define ROAR_OT_MSGQUEUE 10
#define ROAR_OT_MSGBUS   11

// filter:
#define ROAR_CTL_FILTER_ANY   0
#define ROAR_CTL_FILTER_DIR   1

#define ROAR_CTL_CMP_ANY      ROAR_CTL_FILTER_ANY
#define ROAR_CTL_CMP_EQ       1
#define ROAR_CTL_CMP_NE       2

// auth types...
#define ROAR_AUTH_T_AUTO               -1
#define ROAR_AUTH_T_NONE                0 /* do not auth */
#define ROAR_AUTH_T_COOKIE              1 /* use cookie */
#define ROAR_AUTH_T_TRUST               2 /* trust: used for UNIX Domain sockets, */
                                          /* same uid = trusted, diffrent uid = public */
#define ROAR_AUTH_T_PASSWORD            3 /* use password */
#define ROAR_AUTH_T_SYSUSER             4 /* use local/NIS/PAM userdatabase */
#define ROAR_AUTH_T_OPENPGP_SIGN        5
#define ROAR_AUTH_T_OPENPGP_ENCRYPT     6
#define ROAR_AUTH_T_OPENPGP_AUTH        7
#define ROAR_AUTH_T_KERBEROS            8
#define ROAR_AUTH_T_RHOST               9
#define ROAR_AUTH_T_XAUTH              10
#define ROAR_AUTH_T_IDENT              11


// attach types...
#define ROAR_ATTACH_SIMPLE  1 /* move a stream from one to another client (attach the stream to it) */
#define ROAR_ATTACH_SOURCE  2 /* attach a new source to the server */
#define ROAR_ATTACH_OUTPUT  3 /* attach a new output stream to the server */
#define ROAR_ATTACH_MIXER   4 /* attach a new hwmixer stream to the server */
#define ROAR_ATTACH_BRIDGE  5 /* attach a new bridge stream to the server */

// modes for ROAR_CMD_?ET_STREAM_PARA...
#define ROAR_STREAM_PARA_INFO       1
#define ROAR_STREAM_PARA_FLAGS      2
#define ROAR_STREAM_PARA_NAME       3
#define ROAR_STREAM_PARA_CHANMAP    4
#define ROAR_STREAM_PARA_ROLE       5
#define ROAR_STREAM_PARA_HASHTABLE  6
#define ROAR_STREAM_PARA_WININFO    7
#define ROAR_STREAM_PARA_PROPTABLE  8
#define ROAR_STREAM_PARA_LTM        9
#define ROAR_STREAM_PARA_USAGE     10 /* used by RAUM */
#define ROAR_STREAM_PARA_RADIO     11 /* used by RDTCS */
#define ROAR_STREAM_PARA_RPG       12

// modes for ROAR_STREAM_PARA_RPG:
#define ROAR_RPGMODE_DEFAULT       -1
#define ROAR_RPGMODE_NONE           0
#define ROAR_RPGMODE_USER           1
#define ROAR_RPGMODE_ALBUM          2
#define ROAR_RPGMODE_TRACK          3
#define ROAR_RPGMODE_ALBUMTRACK     4
#define ROAR_RPGMODE_TRACKALBUM     5

// Message flags:
#define ROAR_MF_NONE                0x00000000 /* No flags set              | Versions: *ALL* */
#define ROAR_MF_SID                 0x00000001 /* Stream ID                 | Versions: 1   */
#define ROAR_MF_SPOS                0x00000002 /* Stream Possition          | Versions: 1   */
#define ROAR_MF_DL                  0x00000004 /* Data Length               | Versions: 1   */
#define ROAR_MF_LSID                0x00000008 /* Long Stream ID            | Versions: 1   */
#define ROAR_MF_LSPOS               0x00000010 /* Long Stream Possition     | Versions: 1,2 */
#define ROAR_MF_LDL                 0x00000020 /* Long Data Length          | Versions: 1   */
#define ROAR_MF_ED                  0x00000040 /* Error Detection           | Versions: 1,2 */
#define ROAR_MF_MF                  0x00000080 /* Meta Framing              | Versions: 1   */
#define ROAR_MF_UNIID               0x00000100 /* Stream ID is Universal ID | Versions: 2   */
#define ROAR_MF_ANNOUNCE            0x00000200 /* This is an announcement   | Versions: 2   */
#define ROAR_MF_CLOUD               0x00000400 /* To cloud                  | Versions: 2   */

// Types for SERVER_INFO:
#define ROAR_IT_SERVER              1
#define ROAR_IT_COUNTERS            2
//#define ROAR_IT_LISTEN 3

// Types for ROAR_IT_SERVER (Information Type Server Type = ITST)
#define ROAR_ITST_VERSION           0
#define ROAR_ITST_LOCATION          1
#define ROAR_ITST_DESCRIPTION       2
#define ROAR_ITST_CONTACT           3
#define ROAR_ITST_UN_SYSNAME        4
#define ROAR_ITST_UN_NODENAME       5
#define ROAR_ITST_UN_RELEASE        6
#define ROAR_ITST_UN_MACHINE        7
#define ROAR_ITST_SERIAL            8
#define ROAR_ITST_ADDRESS           9
#define ROAR_ITST_UIURL             10
#define ROAR_ITST_HOSTID            11
#define ROAR_ITST_LICENSE           12
#define ROAR_ITST_BUILD             13

// IDs for diffrent clocks:
#define ROAR_CLOCK_DEFAULT          -2
#define ROAR_CLOCK_UNKNOWN          -1
#define ROAR_CLOCK_REALTIME          1
#define ROAR_CLOCK_MONOTONIC         2
#define ROAR_CLOCK_UPTIME            3

// old: do not use.
struct roar_timeofday {
 int64_t  t_sec;   // secund part of system time
 uint64_t t_nsec;  // nano-secund part of system time // we use a int64 here so all types are int64...
 uint64_t c_nhz;   // system hi res timer freq in nHz
 uint64_t d_nsps;  // clock drift in nano secs per sec
};

#endif

//ll
