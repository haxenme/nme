package nme.media;
#if (cpp || neko)


import nme.events.Event;


class SoundChannel extends nme.events.EventDispatcher
{
   public var leftPeak(nmeGetLeft,null) : Float;
   public var rightPeak(nmeGetRight,null) : Float;
   public var position(nmeGetPosition,null) : Float;
   public var soundTransform(nmeGetTransform,nmeSetTransform) : SoundTransform;

   var nmeHandle:Dynamic;
   var nmeTransform:SoundTransform;
   static var nmeIncompleteList = new Array<SoundChannel>();


   public function new(inSoundHandle:Dynamic,startTime:Float, loops:Int, sndTransform:SoundTransform)
   {
      super();
      nmeTransform = sndTransform==null ? null : sndTransform.clone();
      nmeHandle = nme_sound_channel_create(inSoundHandle,startTime,loops,nmeTransform);
		if (nmeHandle!=null)
			nmeIncompleteList.push(this);
   }

   public function stop() { nme_sound_channel_stop(nmeHandle); }

   function nmeGetTransform() : SoundTransform
   {
      return nmeTransform.clone();
   }
   function nmeSetTransform(inTransform:SoundTransform) : SoundTransform
   {
      nmeTransform = inTransform.clone();
      nme_sound_channel_set_transform(nmeHandle,nmeTransform);
      return inTransform;
   }

   function nmeGetLeft() : Float { return nme_sound_channel_get_left(nmeHandle); }
   function nmeGetRight() : Float { return nme_sound_channel_get_right(nmeHandle); }
   function nmeGetPosition() : Float { return nme_sound_channel_get_position(nmeHandle); }

   function nmeCheckComplete() : Bool
   {
      if (nmeHandle!=null && nme_sound_channel_is_complete(nmeHandle))
      {
         nmeHandle = null;
			var complete = new Event( Event.SOUND_COMPLETE );
			dispatchEvent(complete);
         return true;
      }
      return false;
   }

   public static function nmePollComplete()
   {
		if (nmeIncompleteList.length>0)
		{
         var incomplete = new Array<SoundChannel>();
         for(channel in nmeIncompleteList)
            if (!channel.nmeCheckComplete())
               incomplete.push(channel);
         nmeIncompleteList = incomplete;
		}
   }

   public static function nmeCompletePending()
	{
		return nmeIncompleteList.length > 0;
	}


   static var nme_sound_channel_is_complete = nme.Loader.load("nme_sound_channel_is_complete",1);
   static var nme_sound_channel_get_left = nme.Loader.load("nme_sound_channel_get_left",1);
   static var nme_sound_channel_get_right = nme.Loader.load("nme_sound_channel_get_right",1);
   static var nme_sound_channel_get_position = nme.Loader.load("nme_sound_channel_get_position",1);
   static var nme_sound_channel_stop = nme.Loader.load("nme_sound_channel_stop",1);
   static var nme_sound_channel_create = nme.Loader.load("nme_sound_channel_create",4);
   static var nme_sound_channel_set_transform = nme.Loader.load("nme_sound_channel_set_transform",2);
}


#else
typedef SoundChannel = flash.media.SoundChannel;
#end