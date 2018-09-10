package nme.media;
#if (!flash)

import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.SampleDataEvent;
import nme.Loader;
import nme.NativeHandle;

@:nativeProperty
class SoundChannel extends EventDispatcher 
{
   public var leftPeak(get, null):Float;
   public var rightPeak(get, null):Float;
   public var position(get, set):Float;
   public var soundTransform(get, set):SoundTransform;
   // Does not do anything...
   public var pitch:Float;

   /** @private */ public static var nmeDynamicSoundCount = 0;
   private static var nmeIncompleteList = new Array<SoundChannel>();
   private static var nmeIsPolling = false;
   private var nmeStopped:Bool;

   /** @private */ public var nmeHandle:NativeHandle;
   /** @private */ private var nmeTransform:SoundTransform;
   /** @private */ public var nmeDataProvider:EventDispatcher;


   public function new(inSoundHandle:NativeHandle, startTime:Float, loops:Int, sndTransform:SoundTransform) 
   {
      super();

      pitch = 1.0;
      nmeStopped = false;
      if (sndTransform != null) 
      {
         nmeTransform = sndTransform.clone();
      }

       if (inSoundHandle != null)
         nmeHandle = nme_sound_channel_create(inSoundHandle, startTime, loops, nmeTransform);

      if (nmeHandle != null)
      {
         nme.NativeResource.lockHandler(this);
         nmeIncompleteList.push(this);
      }
   }


   public static function createAsync(inRate:SampleRate, inIsStereo:Bool, sampleFormat:AudioSampleFormat, asyncDataRequired:Void->Void, ?inEngine:String) : SoundChannel
   {
      var handle = nme_sound_channel_create_async(Type.enumIndex(inRate), inIsStereo, Type.enumIndex(sampleFormat), asyncDataRequired, inEngine);
      if (handle==null)
         return null;

      return new SoundChannel(handle, 0, 0, null);
   }


   public static function createDynamic(inSoundHandle:NativeHandle, sndTransform:SoundTransform, dataProvider:EventDispatcher) 
   {
      var result = new SoundChannel(null, 0, 0, sndTransform);

         result.nmeDataProvider = dataProvider;
         result.nmeHandle = inSoundHandle;
      nmeIncompleteList.push(result);
         nmeDynamicSoundCount ++;

         return result;
   }

   public function postBuffer(inData:nme.utils.ByteArray)
   {
      if (nmeHandle!=null)
         nme_sound_channel_post_buffer(nmeHandle, inData);
   }

   /** @private */ private function nmeCheckComplete():Bool
   {
      if (nmeHandle != null ) 
      {
         if (nmeDataProvider != null && nme_sound_channel_needs_data(nmeHandle)) 
         {
            var request = new SampleDataEvent(SampleDataEvent.SAMPLE_DATA);
            request.position = nme_sound_channel_get_data_position(nmeHandle);
            nmeDataProvider.dispatchEvent(request);

            if (request.data.length > 0) 
            {
               nme_sound_channel_add_data(nmeHandle, request.data);
            }
         }

         if (nme_sound_channel_is_complete(nmeHandle)) 
         {
            nmeHandle = null;
            if (nmeDataProvider != null) 
               nmeDynamicSoundCount--;

            return true;
         }
      }

      return false;
   }

   /** @private */ public static function nmeCompletePending() {
      return nmeIncompleteList.length > 0;
   }

   function dispatchComplete()
   {
      var complete = new Event(Event.SOUND_COMPLETE);
      dispatchEvent(complete);
      nme.NativeResource.disposeHandler(this);
   }

   public static function nmePollComplete()
   {
      if (nmeIsPolling)
      {
         // If developer calls stop from an onComplete listener, we will get back here
         return;
      }

      nmeIsPolling = true;
      var checkLength = nmeIncompleteList.length;
      if (checkLength > 0) 
      {
         var idx = 0;
         while(idx < checkLength)
         {
            var channel = nmeIncompleteList[idx];

            if (channel.nmeCheckComplete()) 
            {
               nmeIncompleteList.splice(idx,1);
               checkLength--;
               if (!channel.nmeStopped)
                  channel.dispatchComplete();
            }
            else
               idx++;
         }
      }
      nmeIsPolling = false;
   }

   public function stop() 
   {
      nmeStopped = true;
      nme_sound_channel_stop(nmeHandle);
      //nmeHandle = null;
      nmePollComplete();
   }

   // Getters & Setters
   private function get_leftPeak():Float { return nme_sound_channel_get_left(nmeHandle); }
   private function get_rightPeak():Float { return nme_sound_channel_get_right(nmeHandle); }
   private function get_position():Float { return nme_sound_channel_get_position(nmeHandle); }
   private function set_position(value:Float):Float { return nme_sound_channel_set_position(nmeHandle, position); }

   private function get_soundTransform():SoundTransform 
   {
      if (nmeTransform == null) 
      {
         nmeTransform = new SoundTransform();
      }

      return nmeTransform.clone();
   }

   private function set_soundTransform(inTransform:SoundTransform):SoundTransform 
   {
      nmeTransform = inTransform.clone();
      nme_sound_channel_set_transform(nmeHandle, nmeTransform);

      return inTransform;
   }


   // Native Methods
   private static var nme_sound_channel_is_complete = Loader.load("nme_sound_channel_is_complete", 1);
   private static var nme_sound_channel_get_left = Loader.load("nme_sound_channel_get_left", 1);
   private static var nme_sound_channel_get_right = Loader.load("nme_sound_channel_get_right", 1);
   private static var nme_sound_channel_get_position = Loader.load("nme_sound_channel_get_position", 1);
   private static var nme_sound_channel_set_position = Loader.load("nme_sound_channel_set_position", 2);
   private static var nme_sound_channel_get_data_position = Loader.load("nme_sound_channel_get_data_position", 1);
   private static var nme_sound_channel_stop = Loader.load("nme_sound_channel_stop", 1);
   private static var nme_sound_channel_create = Loader.load("nme_sound_channel_create", 4);
   private static var nme_sound_channel_set_transform = Loader.load("nme_sound_channel_set_transform", 2);
   private static var nme_sound_channel_needs_data = Loader.load("nme_sound_channel_needs_data", 1);
   private static var nme_sound_channel_add_data = Loader.load("nme_sound_channel_add_data", 2);
   private static var nme_sound_channel_create_async = Loader.load("nme_sound_channel_create_async", 5);
   private static var nme_sound_channel_post_buffer = Loader.load("nme_sound_channel_post_buffer", 2);
}

#else
typedef SoundChannel = flash.media.SoundChannel;
#end
