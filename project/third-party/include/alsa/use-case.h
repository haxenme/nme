/**
 * \file include/use-case.h
 * \brief use case interface for the ALSA driver
 * \author Liam Girdwood <lrg@slimlogic.co.uk>
 * \author Stefan Schmidt <stefan@slimlogic.co.uk>
 * \author Jaroslav Kysela <perex@perex.cz>
 * \author Justin Xu <justinx@slimlogic.co.uk>
 * \date 2008-2010
 */
/*
 *
 *  This library is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as
 *  published by the Free Software Foundation; either version 2.1 of
 *  the License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
 *
 *  Copyright (C) 2008-2010 SlimLogic Ltd
 *  Copyright (C) 2010 Wolfson Microelectronics PLC
 *  Copyright (C) 2010 Texas Instruments Inc.
 *
 *  Support for the verb/device/modifier core logic and API,
 *  command line tool and file parser was kindly sponsored by
 *  Texas Instruments Inc.
 *  Support for multiple active modifiers and devices,
 *  transition sequences, multiple client access and user defined use
 *  cases was kindly sponsored by Wolfson Microelectronics PLC.
 */

#ifndef __ALSA_USE_CASE_H
#define __ALSA_USE_CASE_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 *  \defgroup Use Case Interface
 *  The ALSA Use Case manager interface.
 *  See \ref Usecase page for more details.
 *  \{
 */

/**
 * ALSA Use Case Interface
 *
 * The use case manager works by configuring the sound card ALSA kcontrols to
 * change the hardware digital and analog audio routing to match the requested
 * device use case. The use case manager kcontrol configurations are stored in
 * easy to modify text files.
 *
 * An audio use case can be defined by a verb and device parameter. The verb
 * describes the use case action i.e. a phone call, listening to music, recording
 * a conversation etc. The device describes the physical audio capture and playback
 * hardware i.e. headphones, phone handset, bluetooth headset, etc.
 *
 * It's intended clients will mostly only need to set the use case verb and
 * device for each system use case change (as the verb and device parameters
 * cover most audio use cases).
 *
 * However there are times when a use case has to be modified at runtime. e.g.
 *
 *  o Incoming phone call when the device is playing music
 *  o Recording sections of a phone call
 *  o Playing tones during a call.
 *
 * In order to allow asynchronous runtime use case adaptations, we have a third
 * optional modifier parameter that can be used to further configure
 * the use case during live audio runtime.
 *
 * This interface allows clients to :-
 *
 *  o Query the supported use case verbs, devices and modifiers for the machine.
 *  o Set and Get use case verbs, devices and modifiers for the machine.
 *  o Get the ALSA PCM playback and capture device PCMs for use case verb and
 *     modifier.
 *  o Get the TQ parameter for each use case verb and modifier.
 *  o Get the ALSA master playback and capture volume/switch kcontrols
 *     for each use case.
 */


/*
 * Use Case Verb.
 *
 * The use case verb is the main device audio action. e.g. the "HiFi" use
 * case verb will configure the audio hardware for HiFi Music playback
 * and capture.
 */
#define SND_USE_CASE_VERB_INACTIVE		"Inactive"
#define SND_USE_CASE_VERB_HIFI			"HiFi"
#define SND_USE_CASE_VERB_HIFI_LOW_POWER	"HiFi Low Power"
#define SND_USE_CASE_VERB_VOICE			"Voice"
#define SND_USE_CASE_VERB_VOICE_LOW_POWER	"Voice Low Power"
#define SND_USE_CASE_VERB_VOICECALL		"Voice Call"
#define SND_USE_CASE_VERB_IP_VOICECALL		"Voice Call IP"
#define SND_USE_CASE_VERB_ANALOG_RADIO		"FM Analog Radio"
#define SND_USE_CASE_VERB_DIGITAL_RADIO		"FM Digital Radio"
/* add new verbs to end of list */


/*
 * Use Case Device.
 *
 * Physical system devices the render and capture audio. Devices can be OR'ed
 * together to support audio on similtanious devices.
 */
#define SND_USE_CASE_DEV_NONE		"None"
#define SND_USE_CASE_DEV_SPEAKER	"Speaker"
#define SND_USE_CASE_DEV_LINE		"Line"
#define SND_USE_CASE_DEV_HEADPHONES	"Headphones"
#define SND_USE_CASE_DEV_HEADSET	"Headset"
#define SND_USE_CASE_DEV_HANDSET	"Handset"
#define SND_USE_CASE_DEV_BLUETOOTH	"Bluetooth"
#define SND_USE_CASE_DEV_EARPIECE	"Earpiece"
#define SND_USE_CASE_DEV_SPDIF		"SPDIF"
#define SND_USE_CASE_DEV_HDMI		"HDMI"
/* add new devices to end of list */


/*
 * Use Case Modifiers.
 *
 * The use case modifier allows runtime configuration changes to deal with
 * asynchronous events.
 *
 * e.g. to record a voice call :-
 *  1. Set verb to SND_USE_CASE_VERB_VOICECALL (for voice call)
 *  2. Set modifier SND_USE_CASE_MOD_CAPTURE_VOICE when capture required.
 *  3. Call snd_use_case_get("_pcm_/_cdevice") to get ALSA source PCM name
 *     with captured voice pcm data.
 *
 * e.g. to play a ring tone when listenin to MP3 Music :-
 *  1. Set verb to SND_USE_CASE_VERB_HIFI (for MP3 playback)
 *  2. Set modifier to SND_USE_CASE_MOD_PLAY_TONE when incoming call happens.
 *  3. Call snd_use_case_get("_pcm_/_pdevice") to get ALSA PCM sink name for
 *     ringtone pcm data.
 */
#define SND_USE_CASE_MOD_CAPTURE_VOICE		"Capture Voice"
#define SND_USE_CASE_MOD_CAPTURE_MUSIC		"Capture Music"
#define SND_USE_CASE_MOD_PLAY_MUSIC		"Play Music"
#define SND_USE_CASE_MOD_PLAY_VOICE		"Play Voice"
#define SND_USE_CASE_MOD_PLAY_TONE		"Play Tone"
#define SND_USE_CASE_MOD_ECHO_REF		"Echo Reference"
/* add new modifiers to end of list */


/**
 * TQ - Tone Quality
 *
 * The interface allows clients to determine the audio TQ required for each
 * use case verb and modifier. It's intended as an optional hint to the
 * audio driver in order to lower power consumption.
 *
 */
#define SND_USE_CASE_TQ_MUSIC		"Music"
#define SND_USE_CASE_TQ_VOICE		"Voice"
#define SND_USE_CASE_TQ_TONES		"Tones"

/** use case container */
typedef struct snd_use_case_mgr snd_use_case_mgr_t;

/**
 * \brief Create an identifier
 * \param fmt Format (sprintf like)
 * \param ... Optional arguments for sprintf like format
 * \return Allocated string identifier or NULL on error
 */
char *snd_use_case_identifier(const char *fmt, ...);

/**
 * \brief Free a string list
 * \param list The string list to free
 * \param items Count of strings
 * \return Zero if success, otherwise a negative error code
 */
int snd_use_case_free_list(const char *list[], int items);

/**
 * \brief Obtain a list of entries
 * \param uc_mgr Use case manager (may be NULL - card list)
 * \param identifier (may be NULL - card list)
 * \param list Returned allocated list
 * \return Number of list entries if success, otherwise a negative error code
 *
 * Defined identifiers:
 *   NULL 		- get card list
 *			  (in pair cardname+comment)
 *   _verbs		- get verb list
 *			  (in pair verb+comment)
 *   _devices[/<verb>]	- get list of supported devices
 *			  (in pair device+comment)
 *   _modifiers[/<verb>]- get list of supported modifiers
 *			  (in pair modifier+comment)
 *   TQ[/<verb>]	- get list of TQ identifiers
 *   _enadevs		- get list of enabled devices
 *   _enamods		- get list of enabled modifiers
 *
 */
int snd_use_case_get_list(snd_use_case_mgr_t *uc_mgr,
                          const char *identifier,
                          const char **list[]);


/**
 * \brief Get current - string
 * \param uc_mgr Use case manager
 * \param identifier 
 * \param value Value pointer
 * \return Zero if success, otherwise a negative error code
 *
 * Note: String is dynamically allocated, use free() to
 * deallocate this string.
 *
 * Known identifiers:
 *   NULL 				- return current card
 *   _verb				- return current verb
 *   TQ[/<modifier>]			- Tone Quality [for given modifier]
 *   PlaybackPCM[/<modifier>]		- full PCM playback device name
 *   CapturePCM[/<modifier>]		- full PCM capture device name
 *   PlaybackCTL[/<modifier>]		- playback control device name
 *   PlaybackVolume[/<modifier>]	- playback control volume ID string
 *   PlaybackSwitch[/<modifier>]	- playback control switch ID string
 *   CaptureCTL[/<modifier>]		- capture control device name
 *   CaptureVolume[/<modifier>]		- capture control volume ID string
 *   CaptureSwitch[/<modifier>]		- capture control switch ID string
 *   PlaybackMixer[/<modifier>]		- name of playback mixer
 *   PlaybackMixerID[/<modifier>]	- mixer playback ID
 *   CaptureMixer[/<modifier>]		- name of capture mixer
 *   CaptureMixerID[/<modifier>]	- mixer capture ID
 */
int snd_use_case_get(snd_use_case_mgr_t *uc_mgr,
                     const char *identifier,
                     const char **value);

/**
 * \brief Get current - integer
 * \param uc_mgr Use case manager
 * \param identifier 
 * \param value result 
 * \return Zero if success, otherwise a negative error code
 *
 * Known identifiers:
 *   _devstatus/<device>	- return status for given device
 *   _modstatus/<modifier>	- return status for given modifier
 */
int snd_use_case_geti(snd_use_case_mgr_t *uc_mgr,
		      const char *identifier,
		      long *value);

/**
 * \brief Set new
 * \param uc_mgr Use case manager
 * \param identifier
 * \param value Value
 * \return Zero if success, otherwise a negative error code
 *
 * Known identifiers:
 *   _verb 		- set current verb = value
 *   _enadev		- enable given device = value
 *   _disdev		- disable given device = value
 *   _swdev/<old_device> - new_device = value
 *			- disable old_device and then enable new_device
 *			- if old_device is not enabled just return
 *			- check transmit sequence firstly
 *   _enamod		- enable given modifier = value
 *   _dismod		- disable given modifier = value
 *   _swmod/<old_modifier> - new_modifier = value
 *			- disable old_modifier and then enable new_modifier
 *			- if old_modifier is not enabled just return
 *			- check transmit sequence firstly
 */
int snd_use_case_set(snd_use_case_mgr_t *uc_mgr,
                     const char *identifier,
                     const char *value);

/**
 * \brief Open and initialise use case core for sound card
 * \param uc_mgr Returned use case manager pointer
 * \param card_name Sound card name.
 * \return zero if success, otherwise a negative error code
 */
int snd_use_case_mgr_open(snd_use_case_mgr_t **uc_mgr, const char *card_name);


/**
 * \brief Reload and re-parse use case configuration files for sound card.
 * \param uc_mgr Use case manager
 * \return zero if success, otherwise a negative error code
 */
int snd_use_case_mgr_reload(snd_use_case_mgr_t *uc_mgr);

/**
 * \brief Close use case manager
 * \param uc_mgr Use case manager
 * \return zero if success, otherwise a negative error code
 */
int snd_use_case_mgr_close(snd_use_case_mgr_t *uc_mgr);

/**
 * \brief Reset use case manager verb, device, modifier to deafult settings.
 * \param uc_mgr Use case manager
 * \return zero if success, otherwise a negative error code
 */
int snd_use_case_mgr_reset(snd_use_case_mgr_t *uc_mgr);

/*
 * helper functions
 */

/**
 * \brief Obtain a list of cards
 * \param list Returned allocated list
 * \return Number of list entries if success, otherwise a negative error code
 */
static inline int snd_use_case_card_list(const char **list[])
{
	return snd_use_case_get_list(NULL, NULL, list);
}

/**
 * \brief Obtain a list of verbs
 * \param uc_mgr Use case manager
 * \param list Returned list of verbs
 * \return Number of list entries if success, otherwise a negative error code
 */
static inline int snd_use_case_verb_list(snd_use_case_mgr_t *uc_mgr,
					 const char **list[])
{
	return snd_use_case_get_list(uc_mgr, "_verbs", list);
}

/**
 *  \}
 */

#ifdef __cplusplus
}
#endif

#endif /* __ALSA_USE_CASE_H */
