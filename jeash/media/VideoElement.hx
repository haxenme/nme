package jeash.media;
/**
 * Copyright (c) 2010, Jeash contributors.
 * 
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
* Enums toolbox for HTMLVideoElement
*/
 
/**
 * @see http://dev.w3.org/html5/spec/video.html#mediaevents
 */
enum VideoElementEvents {
	loadstart;
	progress;
	suspend;
	abort;
	error;
	emptied;
	stalled;
	//----
	play;
	pause;
	//----
	loadedmetadata;
	loadeddata;
	waiting;
	playing;
	canplay;
	canplaythrough;
	//----
	seeking;
	seeked;
	timeupdate;
	ended;
	//----
	ratechange;
	durationchange;
	volumechange;
}

/**
 * htmlvideoelement readyStates 
 * @see http://dev.w3.org/html5/spec/video.html#dom-media-readystate
 */
enum ReadyState {
	HAVE_NOTHING; 		// (numeric value 0)    No information regarding the media resource is available. No data for the current playback position is available. Media elements whose networkState attribute are set to NETWORK_EMPTY are always in the HAVE_NOTHING state.
	HAVE_METADATA; 		// (numeric value 1)    Enough of the resource has been obtained that the duration of the resource is available. In the case of a video element, the dimensions of the video are also available. The API will no longer raise an exception when seeking. No media data is available for the immediate current playback position. The timed tracks are ready. 
	HAVE_CURRENT_DATA; 	// (numeric value 2)    Data for the immediate current playback position is available, but either not enough data is available that the user agent could successfully advance the current playback position in the direction of playback at all without immediately reverting to the HAVE_METADATA state, or there is no more data to obtain in the direction of playback. For example, in video this corresponds to the user agent having data from the current frame, but not the next frame; and to when playback has ended.
	HAVE_FUTURE_DATA; 	// (numeric value 3)    Data for the immediate current playback position is available, as well as enough data for the user agent to advance the current playback position in the direction of playback at least a little without immediately reverting to the HAVE_METADATA state. For example, in video this corresponds to the user agent having data for at least the current frame and the next frame. The user agent cannot be in this state if playback has ended, as the current playback position can never advance in this case.
	HAVE_ENOUGH_DATA; 	// (numeric value 4)    All the conditions described for the HAVE_FUTURE_DATA state are met, and, in addition, the user agent estimates that data is being fetched at a rate where the current playback position, if it were to advance at the rate given by the defaultPlaybackRate attribute, would not overtake the available data before playback reaches the end of the media resource. 	
}

enum NetworkState {
	NETWORK_EMPTY;		// (numeric value 0)    The element has not yet been initialized. All attributes are in their initial states.
	NETWORK_IDLE;		// (numeric value 1)    The element's resource selection algorithm is active and has selected a resource, but it is not actually using the network at this time.
	NETWORK_LOADING;	// (numeric value 2)    The user agent is actively trying to download data.
	NETWORK_NO_SOURCE;	// (numeric value 3)    The element's resource selection algorithm is active, but it has so not yet found a resource to use. 
}
