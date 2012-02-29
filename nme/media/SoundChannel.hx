package nme.media;
#if (cpp || neko)


import nme.events.Event;
import nme.events.EventDispatcher;
import nme.Loader;


class SoundChannel extends EventDispatcher
{	
	
	public var leftPeak(nmeGetLeft, null):Float;
	public var rightPeak(nmeGetRight, null):Float;
	public var position(nmeGetPosition, null):Float;
	public var soundTransform(nmeGetTransform, nmeSetTransform):SoundTransform;
	
	private static var nmeIncompleteList = new Array<SoundChannel>();
	
	private var nmeHandle:Dynamic;
	private var nmeTransform:SoundTransform;
	
	
	public function new (inSoundHandle:Dynamic, startTime:Float, loops:Int, sndTransform:SoundTransform)
	{
		super();
		
		if (sndTransform != null)
		{
			nmeTransform = sndTransform.clone();
		}
		
		nmeHandle = nme_sound_channel_create(inSoundHandle, startTime, loops, nmeTransform);
		
		if (nmeHandle != null)
		{	
			nmeIncompleteList.push(this);	
		}
	}
	
	
	private function nmeCheckComplete():Bool
	{
		if (nmeHandle != null && nme_sound_channel_is_complete(nmeHandle))
		{
			nmeHandle = null;
			var complete = new Event(Event.SOUND_COMPLETE);
			dispatchEvent(complete);
			
			return true;
		}
		
		return false;
	}
	
	
	/**
	 * @private
	 */
	public static function nmeCompletePending()
	{	
		return nmeIncompleteList.length > 0;	
	}
	
	
	/**
	 * @private
	 */
	public static function nmePollComplete()
	{	
		if (nmeIncompleteList.length > 0)
		{
			var incomplete = new Array<SoundChannel>();
			
			for (channel in nmeIncompleteList)
			{
				if (!channel.nmeCheckComplete ())
				{
					incomplete.push (channel);
				}
			}
			
			nmeIncompleteList = incomplete;
		}
	}
	
	
	public function stop()
	{ 
		nme_sound_channel_stop(nmeHandle);
	}
	
	
	
	// Getters & Setters
	
	
	
	private function nmeGetLeft():Float {	return nme_sound_channel_get_left(nmeHandle); }
	private function nmeGetRight():Float { return nme_sound_channel_get_right(nmeHandle); }
	private function nmeGetPosition():Float { return nme_sound_channel_get_position(nmeHandle); }
	
	
	private function nmeGetTransform():SoundTransform
	{
		if (nmeTransform == null)
		{
			nmeTransform = new SoundTransform();
		}
		
		return nmeTransform.clone();
	}
	
	
	function nmeSetTransform(inTransform:SoundTransform):SoundTransform
	{
		nmeTransform = inTransform.clone();
		nme_sound_channel_set_transform(nmeHandle, nmeTransform);
		
		return inTransform;
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_sound_channel_is_complete = Loader.load ("nme_sound_channel_is_complete", 1);
	private static var nme_sound_channel_get_left = Loader.load ("nme_sound_channel_get_left", 1);
	private static var nme_sound_channel_get_right = Loader.load ("nme_sound_channel_get_right", 1);
	private static var nme_sound_channel_get_position = Loader.load ("nme_sound_channel_get_position", 1);
	private static var nme_sound_channel_stop = Loader.load ("nme_sound_channel_stop", 1);
	private static var nme_sound_channel_create = Loader.load ("nme_sound_channel_create", 4);
	private static var nme_sound_channel_set_transform = Loader.load ("nme_sound_channel_set_transform", 2);

}


#else
typedef SoundChannel = flash.media.SoundChannel;
#end