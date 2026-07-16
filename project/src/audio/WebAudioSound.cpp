#ifdef EMSCRIPTEN
#include <emscripten.h>

#include <Sound.h>
#include <Utils.h>
#include "Audio.h"

namespace nme
{

// ---------------------------------------------------------------------------
// JavaScript glue — SFX path (AudioBufferSourceNode)
// ---------------------------------------------------------------------------
//
// All decoded audio (short sounds / SFX) is uploaded once as an AudioBuffer
// and played through AudioBufferSourceNode → StereoPannerNode → GainNode.
//
// Global state lives in Module._nme_wa = { ctx, buffers:{}, sources:{}, nextId:1 }
// ---------------------------------------------------------------------------

EM_JS(int, nme_webaudio_init, (), {
   if (Module._nme_wa && Module._nme_wa.ctx) return 1;
   try {
      var AudioContext = window.AudioContext || window.webkitAudioContext;
      if (!AudioContext) return 0;
      Module._nme_wa = Module._nme_wa || { buffers:{}, sources:{}, nextId:1 };
      var wa = Module._nme_wa;
      wa.ctx = new AudioContext();
      wa.pending = null;  // at most one pending music track at a time
      wa.unlockRegistered = false;
      wa.explicitlySuspended = false;

      // One-shot handler: resumes the AudioContext and starts any music entries
      // that were blocked by the browser's autoplay policy.
      wa.registerUnlock = function() {
         if (wa.unlockRegistered) return;
         wa.unlockRegistered = true;
         var events = ['click', 'keydown', 'touchstart', 'pointerdown'];
         var unlock = function() {
            if (wa.explicitlySuspended) return;
            events.forEach(function(ev) { document.removeEventListener(ev, unlock, true); });
            wa.unlockRegistered = false;
            wa.ctx.resume().then(function() {
               var pend = wa.pending;
               wa.pending = null;
               if (pend && !pend.stopped) pend.audio.play().catch(function(){});
            });
         };
         events.forEach(function(ev) { document.addEventListener(ev, unlock, true); });
      };

      // Chrome starts the context suspended before any playback attempt.
      if (wa.ctx.state === 'suspended') wa.registerUnlock();
      return 1;
   } catch(e) { return 0; }
});

// inData is a pointer into WASM memory holding interleaved int16 PCM.
// Web Audio requires planar float32, so we deinterleave here.
EM_JS(int, nme_webaudio_create_buffer, (const short *inData, int samplesPerChannel, int channels, int rate), {
   var wa = Module._nme_wa;
   var ab = wa.ctx.createBuffer(channels, samplesPerChannel, rate);
   var src = new Int16Array(HEAP16.buffer, inData, samplesPerChannel * channels);
   for (var ch = 0; ch < channels; ch++) {
      var dest = ab.getChannelData(ch);
      for (var i = 0; i < samplesPerChannel; i++)
         dest[i] = src[i * channels + ch] / 32768.0;
   }
   var id = wa.nextId++;
   wa.buffers[id] = ab;
   return id;
});

EM_JS(void, nme_webaudio_free_buffer, (int id), {
   delete Module._nme_wa.buffers[id];
});

// loops: -1 = infinite, 0 = play once, N>0 = play N+1 times total
EM_JS(int, nme_webaudio_play, (int bufferId, double offsetSec, double volume, double pan, int loops), {
   var wa = Module._nme_wa;
   var ctx = wa.ctx;
   if (ctx.state === 'suspended' && !wa.explicitlySuspended) { ctx.resume(); wa.registerUnlock(); }

   var ab = wa.buffers[bufferId];
   if (!ab) return 0;

   var gain   = ctx.createGain();
   var panner = ctx.createStereoPanner();
   gain.gain.value   = volume;
   panner.pan.value  = pan;
   gain.connect(ctx.destination);
   panner.connect(gain);

   var id = wa.nextId++;
   var entry = {
      ab: ab, gain: gain, panner: panner, node: null,
      startCtxTime: 0, startOffset: offsetSec,
      loops: loops, stopped: false
   };
   wa.sources[id] = entry;

   function startNode(offset) {
      var node = ctx.createBufferSource();
      node.buffer = ab;
      node.connect(panner);
      entry.node = node;
      entry.startCtxTime  = ctx.currentTime;
      entry.startOffset   = offset;
      if (loops < 0) {
         node.loop = true;
         node.start(0, offset);
      } else {
         node.loop = false;
         node.start(0, offset);
         node.onended = function() {
            if (entry.stopped) return;
            if (entry.loops > 0) {
               entry.loops--;
               startNode(0);
            } else {
               entry.stopped = true;
               entry.node = null;
            }
         };
      }
   }
   startNode(offsetSec);
   return id;
});

EM_JS(void, nme_webaudio_stop, (int id), {
   var wa = Module._nme_wa;
   var entry = wa.sources[id];
   if (!entry) return;
   entry.stopped = true;
   if (entry.node) { try { entry.node.stop(); } catch(e) {} entry.node = null; }
   delete wa.sources[id];
});

EM_JS(int, nme_webaudio_is_done, (int id), {
   var entry = Module._nme_wa.sources[id];
   if (!entry) return 1;
   return entry.stopped ? 1 : 0;
});

EM_JS(double, nme_webaudio_get_position, (int id), {
   var wa = Module._nme_wa;
   var entry = wa.sources[id];
   if (!entry || entry.stopped || !entry.node) return 0.0;
   return entry.startOffset + (wa.ctx.currentTime - entry.startCtxTime);
});

// Seeks by stopping the current node and restarting at the new offset.
EM_JS(double, nme_webaudio_set_position, (int id, double sec), {
   var wa = Module._nme_wa;
   var entry = wa.sources[id];
   if (!entry || entry.stopped) return 0.0;

   if (entry.node) { try { entry.node.stop(); } catch(e) {} entry.node = null; }

   var duration = entry.ab.duration;
   var offset = Math.max(0, Math.min(sec, duration));

   var node = wa.ctx.createBufferSource();
   node.buffer = entry.ab;
   node.connect(entry.panner);
   if (entry.loops < 0) {
      node.loop = true;
   } else {
      node.onended = function() {
         if (entry.stopped) return;
         if (entry.loops > 0) {
            entry.loops--;
            // restart from 0 via recursive set_position logic
            var n2 = wa.ctx.createBufferSource();
            n2.buffer = entry.ab;
            n2.connect(entry.panner);
            entry.node = n2;
            entry.startCtxTime = wa.ctx.currentTime;
            entry.startOffset  = 0;
            n2.onended = node.onended;
            n2.start(0, 0);
         } else {
            entry.stopped = true;
            entry.node = null;
         }
      };
   }
   entry.node = node;
   entry.startCtxTime = wa.ctx.currentTime;
   entry.startOffset  = offset;
   node.start(0, offset);
   return offset;
});

EM_JS(void, nme_webaudio_set_transform, (int id, double volume, double pan), {
   var entry = Module._nme_wa.sources[id];
   if (!entry) return;
   entry.gain.gain.value   = volume;
   entry.panner.pan.value  = pan;
});

EM_JS(void, nme_webaudio_suspend, (), {
   var wa = Module._nme_wa;
   if (wa && wa.ctx) {
      wa.explicitlySuspended = true;
      wa.ctx.suspend();
   }
});

EM_JS(void, nme_webaudio_resume, (), {
   var wa = Module._nme_wa;
   if (wa && wa.ctx) {
      wa.explicitlySuspended = false;
      wa.ctx.resume();
   }
});


// ---------------------------------------------------------------------------
// JavaScript glue — Music path (MediaElementAudioSourceNode)
// ---------------------------------------------------------------------------
//
// Compressed bytes are turned into a Blob URL and fed to an <audio> element.
// The browser handles decoding and streaming — no PCM ever lives in WASM.
//
// State lives in Module._nme_wa.music = {}
// ---------------------------------------------------------------------------

EM_JS(int, nme_webaudio_music_play, (const unsigned char *inData, int len,
      double offsetSec, double volume, double pan, int loops), {
   var wa = Module._nme_wa;
   var ctx = wa.ctx;
   if (ctx.state === 'suspended' && !wa.explicitlySuspended) ctx.resume();  // best-effort; unlock handler covers the async case

   var bytes   = new Uint8Array(HEAPU8.buffer, inData, len);
   var blob    = new Blob([bytes]);
   var blobUrl = URL.createObjectURL(blob);

   var audio = new Audio();
   audio.src = blobUrl;
   audio.currentTime = offsetSec;
   if (loops < 0) {
      audio.loop = true;
   }

   var gain   = ctx.createGain();
   var panner = ctx.createStereoPanner();
   gain.gain.value  = volume;
   panner.pan.value = pan;
   gain.connect(ctx.destination);
   panner.connect(gain);

   var src = ctx.createMediaElementSource(audio);
   src.connect(panner);

   var id = wa.nextId++;
   var entry = {
      audio: audio, blobUrl: blobUrl, src: src, gain: gain, panner: panner,
      loops: loops, stopped: false
   };
   wa.music = wa.music || {};
   wa.music[id] = entry;

   if (loops >= 0) {
      audio.addEventListener('ended', function() {
         if (entry.stopped) return;
         if (entry.loops > 0) {
            entry.loops--;
            audio.currentTime = 0;
            audio.play().catch(function(){});
         } else {
            entry.stopped = true;
         }
      });
   }

   audio.play().catch(function() {
      // Autoplay blocked — keep only the latest pending track.
      // Mark any previously pending entry as stopped so its C++ channel
      // sees isComplete() == true and gets cleaned up normally.
      if (wa.pending) wa.pending.stopped = true;
      wa.pending = entry;
      if (!wa.explicitlySuspended) wa.registerUnlock();
   });
   return id;
});

EM_JS(void, nme_webaudio_music_stop, (int id), {
   var wa = Module._nme_wa;
   if (!wa || !wa.music) return;
   var entry = wa.music[id];
   if (!entry) return;
   entry.stopped = true;
   entry.audio.pause();
   URL.revokeObjectURL(entry.blobUrl);
   entry.src.disconnect();
   delete wa.music[id];
});

EM_JS(int, nme_webaudio_music_is_done, (int id), {
   var wa = Module._nme_wa;
   if (!wa || !wa.music) return 1;
   var entry = wa.music[id];
   if (!entry) return 1;
   return entry.stopped ? 1 : 0;
});

EM_JS(double, nme_webaudio_music_get_position, (int id), {
   var wa = Module._nme_wa;
   if (!wa || !wa.music) return 0.0;
   var entry = wa.music[id];
   if (!entry) return 0.0;
   return entry.audio.currentTime;
});

EM_JS(double, nme_webaudio_music_set_position, (int id, double sec), {
   var wa = Module._nme_wa;
   if (!wa || !wa.music) return 0.0;
   var entry = wa.music[id];
   if (!entry) return 0.0;
   entry.audio.currentTime = sec;
   return entry.audio.currentTime;
});

EM_JS(void, nme_webaudio_music_set_transform, (int id, double volume, double pan), {
   var wa = Module._nme_wa;
   if (!wa || !wa.music) return;
   var entry = wa.music[id];
   if (!entry) return;
   entry.gain.gain.value  = volume;
   entry.panner.pan.value = pan;
});

EM_JS(void, nme_webaudio_music_pause, (int id), {
   var wa = Module._nme_wa;
   if (!wa || !wa.music) return;
   var entry = wa.music[id];
   if (entry) entry.audio.pause();
});

EM_JS(void, nme_webaudio_music_resume, (int id), {
   var wa = Module._nme_wa;
   if (!wa || !wa.music) return;
   var entry = wa.music[id];
   if (entry && !entry.stopped) entry.audio.play().catch(function(){});
});


// ---------------------------------------------------------------------------
// WebAudioBufferChannel — short SFX via AudioBufferSourceNode
// ---------------------------------------------------------------------------

class WebAudioBufferChannel : public SoundChannel
{
public:
   int    bufferId;   // JS AudioBuffer id (owned by the Sound, not this channel)
   int    sourceId;   // JS AudioBufferSourceNode id
   double pan;
   double savedPositionSec;
   bool   suspendedFlag;

   WebAudioBufferChannel(Object *inSound, int inBufferId,
                         double startTimeSec, int loops,
                         const SoundTransform &inTransform)
      : bufferId(inBufferId)
      , sourceId(0)
      , pan(inTransform.pan)
      , savedPositionSec(0.0)
      , suspendedFlag(false)
   {
      if (inSound) inSound->IncRef();
      soundObject = inSound;

      // Mirror OpenAL/SDL convention: inLoops=1 means "play once",
      // inLoops=2 means "play twice", inLoops<0 means infinite.
      int jsLoops = (loops > 0) ? loops - 1 : loops;
      sourceId = nme_webaudio_play(bufferId, startTimeSec,
                                   inTransform.volume, inTransform.pan, jsLoops);
      if (sourceId)
         clAddChannel(this, false);
   }

   ~WebAudioBufferChannel()
   {
      stop();
   }

   bool isComplete()
   {
      if (sourceId && nme_webaudio_is_done(sourceId))
      {
         clRemoveChannel(this);
         if (soundObject) { soundObject->DecRef(); soundObject = 0; }
         sourceId = 0;
      }
      return sourceId == 0;
   }

   void stop()
   {
      if (sourceId)
      {
         nme_webaudio_stop(sourceId);
         sourceId = 0;
         clRemoveChannel(this);
      }
      if (soundObject) { soundObject->DecRef(); soundObject = 0; }
   }

   double getLeft()     { return (1.0 - pan) * 0.5; }
   double getRight()    { return (pan + 1.0) * 0.5; }

   double getPosition()
   {
      if (!sourceId) return 0.0;
      return nme_webaudio_get_position(sourceId) * 1000.0;
   }

   double setPosition(const float &inMs)
   {
      if (!sourceId) return 0.0;
      return nme_webaudio_set_position(sourceId, inMs * 0.001) * 1000.0;
   }

   void setTransform(const SoundTransform &inTransform)
   {
      pan = inTransform.pan;
      if (sourceId)
         nme_webaudio_set_transform(sourceId, inTransform.volume, inTransform.pan);
   }

   void suspend()
   {
      if (suspendedFlag || !sourceId) return;
      suspendedFlag = true;
      savedPositionSec = nme_webaudio_get_position(sourceId);
      nme_webaudio_stop(sourceId);
      sourceId = 0;
   }

   void resume()
   {
      if (!suspendedFlag || !bufferId) return;
      suspendedFlag = false;
      // Restart from saved position; loops=-1 preserves original loop state
      // Pass loops=0 (play to end from offset) since this is a resume
      sourceId = nme_webaudio_play(bufferId, savedPositionSec, 1.0, pan, 0);
   }

   void asyncUpdate() { }

private:
   Object *soundObject;
};


// ---------------------------------------------------------------------------
// WebAudioMusicChannel — long/music audio via MediaElementAudioSourceNode
// ---------------------------------------------------------------------------

class WebAudioMusicChannel : public SoundChannel
{
public:
   int    sourceId;
   double pan;
   bool   suspendedFlag;

   WebAudioMusicChannel(Object *inSound,
                        const unsigned char *inData, int inLen,
                        double startTimeSec, int loops,
                        const SoundTransform &inTransform)
      : sourceId(0)
      , pan(inTransform.pan)
      , suspendedFlag(false)
   {
      if (inSound) inSound->IncRef();
      soundObject = inSound;

      // Mirror OpenAL/SDL convention: inLoops=1 means "play once",
      // inLoops=2 means "play twice", inLoops<0 means infinite.
      int jsLoops = (loops > 0) ? loops - 1 : loops;
      sourceId = nme_webaudio_music_play(inData, inLen, startTimeSec,
                                         inTransform.volume, inTransform.pan, jsLoops);
      if (sourceId)
         clAddChannel(this, false);
   }

   ~WebAudioMusicChannel()
   {
      stop();
   }

   bool isComplete()
   {
      if (sourceId && nme_webaudio_music_is_done(sourceId))
      {
         nme_webaudio_music_stop(sourceId);
         sourceId = 0;
         clRemoveChannel(this);
         if (soundObject) { soundObject->DecRef(); soundObject = 0; }
      }
      return sourceId == 0;
   }

   void stop()
   {
      if (sourceId)
      {
         nme_webaudio_music_stop(sourceId);
         sourceId = 0;
         clRemoveChannel(this);
      }
      if (soundObject) { soundObject->DecRef(); soundObject = 0; }
   }

   double getLeft()     { return (1.0 - pan) * 0.5; }
   double getRight()    { return (pan + 1.0) * 0.5; }

   double getPosition()
   {
      if (!sourceId) return 0.0;
      return nme_webaudio_music_get_position(sourceId) * 1000.0;
   }

   double setPosition(const float &inMs)
   {
      if (!sourceId) return 0.0;
      return nme_webaudio_music_set_position(sourceId, inMs * 0.001) * 1000.0;
   }

   void setTransform(const SoundTransform &inTransform)
   {
      pan = inTransform.pan;
      if (sourceId)
         nme_webaudio_music_set_transform(sourceId, inTransform.volume, inTransform.pan);
   }

   void suspend()
   {
      if (!suspendedFlag && sourceId)
      {
         suspendedFlag = true;
         nme_webaudio_music_pause(sourceId);
      }
   }

   void resume()
   {
      if (suspendedFlag && sourceId)
      {
         suspendedFlag = false;
         nme_webaudio_music_resume(sourceId);
      }
   }

   void asyncUpdate() { }

private:
   Object *soundObject;
};


// ---------------------------------------------------------------------------
// WebAudioSound
// ---------------------------------------------------------------------------

class WebAudioSound : public Sound
{
public:
   int      bufferId;   // >0 when decoded SFX path is used
   QuickVec<unsigned char> rawData;  // non-empty when streaming/music path is used
   double   duration;
   std::string mError;

   WebAudioSound(const unsigned char *inData, int inLen, bool inForceMusic)
      : bufferId(0)
      , duration(0.0)
   {
      IncRef();

      if (!nme_webaudio_init())
      {
         mError = "WebAudio: could not create AudioContext";
         return;
      }

      // Mirror OpenAL: force decode for SFX, keep compressed for music
      unsigned int flags = inForceMusic ? 0 : SoundForceDecode;
      INmeSoundData *soundData = INmeSoundData::create(inData, inLen, flags);

      // soundData may be null for formats NME can't decode natively (e.g. MP3).
      // In that case fall through to the raw-bytes path and let the browser decode.
      if (soundData && soundData->isValid() && soundData->getIsDecoded())
      {
         // Short SFX: decode to PCM and upload to an AudioBuffer
         duration = soundData->getDuration();
         int  channels          = soundData->getIsStereo() ? 2 : 1;
         int  samplesPerChannel = soundData->getChannelSampleCount();
         int  rate              = soundData->getRate();
         short *pcm             = soundData->decodeAll();

         if (pcm && samplesPerChannel > 0)
            bufferId = nme_webaudio_create_buffer(pcm, samplesPerChannel, channels, rate);
         else
            mError = "WebAudio: decodeAll() failed";

         soundData->release();
      }
      else
      {
         // Music, streaming formats, or formats NME cannot decode (e.g. MP3):
         // store the raw compressed bytes and let the browser handle them via
         // a Blob URL / MediaElementAudioSourceNode.
         if (soundData)
         {
            duration = soundData->getDuration();
            soundData->release();
         }
         rawData.Set(inData, (size_t)inLen);
      }
   }

   ~WebAudioSound()
   {
      if (bufferId)
         nme_webaudio_free_buffer(bufferId);
   }

   const char *getEngine()   { return "webaudio"; }
   bool ok()                 { return bufferId > 0 || rawData.size() > 0; }
   std::string getError()    { return mError; }
   double getLength()        { return duration * 1000.0; }
   int getBytesLoaded()      { return ok() ? 100 : 0; }
   int getBytesTotal()       { return ok() ? 100 : 0; }

   SoundChannel *openChannel(double startTime, int loops,
                              const SoundTransform &inTransform)
   {
      double startSec = startTime * 0.001;

      if (bufferId > 0)
         return new WebAudioBufferChannel(this, bufferId, startSec, loops, inTransform);

      if (rawData.size() > 0)
         return new WebAudioMusicChannel(this, rawData.mPtr, (int)rawData.size(),
                                         startSec, loops, inTransform);
      return 0;
   }
};


// ---------------------------------------------------------------------------
// External API
// ---------------------------------------------------------------------------

Sound *CreateWebAudioSound(const unsigned char *inData, int inLen, bool inForceMusic)
{
   WebAudioSound *s = new WebAudioSound(inData, inLen, inForceMusic);
   if (!s->ok())
   {
      ELOG("WebAudio: CreateWebAudioSound failed: %s", s->getError().c_str());
      s->DecRef();
      return 0;
   }
   return s;
}

SoundChannel *CreateWebAudioSyncChannel(const ByteArray &inData,
   const SoundTransform &inTransform,
   SoundDataFormat inDataFormat, bool inIsStereo, int inRate)
{
   // Not yet implemented — requires AudioWorklet for real-time streaming
   ELOG("WebAudio: CreateWebAudioSyncChannel not implemented");
   return 0;
}

void SuspendWebAudio()
{
   nme_webaudio_suspend();
}

void ResumeWebAudio()
{
   nme_webaudio_resume();
}

} // namespace nme

#endif // EMSCRIPTEN
