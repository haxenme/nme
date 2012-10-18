package neash.media;


import neash.events.Event;
import neash.events.EventDispatcher;
import neash.events.SampleDataEvent;
import neash.Loader;


class SoundChannel extends EventDispatcher
{	
	
	public var leftPeak(nmeGetLeft, null):Float;
	public var rightPeak(nmeGetRight, null):Float;
	public var position(nmeGetPosition, null):Float;
	public var soundTransform(nmeGetTransform, nmeSetTransform):SoundTransform;

	public static var nmeDynamicSoundCount = 0;
	
	private static var nmeIncompleteList = new Array<SoundChannel>();
	
	/** @private */ private var nmeHandle:Dynamic;
	/** @private */ private var nmeTransform:SoundTransform;
	/** @private */ public var nmeDataProvider:EventDispatcher;
	/** @private */ private var nmeSoundComplete:Bool;	
	
	public function new(inSoundHandle:Dynamic, startTime:Float, loops:Int, sndTransform:SoundTransform)
	{
		super();
		
		if (sndTransform != null) {
			nmeTransform = sndTransform.clone();
		}
		
		if (inSoundHandle!=null) {
			nmeHandle = nme_sound_channel_create(inSoundHandle, startTime, loops, nmeTransform);
		}
		
		if (nmeHandle != null) {
			nmeIncompleteList.push(this);	
		}
			
		nmeSoundComplete = false;
	}

	public static function createDynamic(inSoundHandle:Dynamic, sndTransform:SoundTransform, dataProvider:EventDispatcher)
	{
		var result = new SoundChannel(null,0,0,sndTransform);
      	result.nmeDataProvider = dataProvider;
      	result.nmeHandle = inSoundHandle;
		nmeIncompleteList.push(result);
      	nmeDynamicSoundCount++;
      	return result;
   	}
		
	
	
	
	/** @private */ private function nmeCheckComplete():Bool
	{
		if (nmeSoundComplete == false) 
		{
			if (nmeDataProvider != null && nme_sound_channel_needs_data(nmeHandle))
			{
				var request = new SampleDataEvent(SampleDataEvent.SAMPLE_DATA);
				request.position = nme_sound_channel_get_data_position(nmeHandle);
				nmeDataProvider.dispatchEvent(request);
				if (request.data.length > 0) {
					nme_sound_channel_add_data(nmeHandle,request.data);
				}
			}

			nmeSoundComplete = nme_sound_channel_is_complete(nmeHandle);
			if (nmeSoundComplete == true)
			{
				#if android
				if (nme_sound_channel_is_music(nmeHandle)) {
					nmeHandle = null;
				}
				#else
				nmeHandle = null;
				#end
			
				if (nmeDataProvider != null) {
					nmeDynamicSoundCount--;
				}
				
				var complete = new Event(Event.SOUND_COMPLETE);
				dispatchEvent(complete);
			}
		}
		
		return nmeSoundComplete;
	}
	
	
	/** @private */ public static function nmeCompletePending()
	{	
		return nmeIncompleteList.length > 0;	
	}
	
	
	/** @private */ public static function nmePollComplete()
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
		if (nmeHandle != null) {
			nme_sound_channel_stop(nmeHandle);
			nmeHandle = null;
			nmeSoundComplete = true;
		}
	}
	
	
	
	// Getters & Setters
	
	
	
	/** @private */ private function nmeGetLeft():Float {	return nme_sound_channel_get_left(nmeHandle); }
	/** @private */ private function nmeGetRight():Float { return nme_sound_channel_get_right(nmeHandle); }
	/** @private */ private function nmeGetPosition():Float { return nme_sound_channel_get_position(nmeHandle); }
	
	
	/** @private */ private function nmeGetTransform():SoundTransform
	{
		if (nmeTransform == null)
		{
			nmeTransform = new SoundTransform();
		}
		
		return nmeTransform.clone();
	}
	
	
	/** @private */ private function nmeSetTransform(inTransform:SoundTransform):SoundTransform
	{
		nmeTransform = inTransform.clone();
		nme_sound_channel_set_transform(nmeHandle, nmeTransform);
		
		return inTransform;
	}
	
	
	
	// Native Methods
	
	
	
	#if android
	private static var nme_sound_channel_is_music = Loader.load("nme_sound_channel_is_music", 1);
	#end
	
	private static var nme_sound_channel_is_complete = Loader.load ("nme_sound_channel_is_complete", 1);
	private static var nme_sound_channel_get_left = Loader.load ("nme_sound_channel_get_left", 1);
	private static var nme_sound_channel_get_right = Loader.load ("nme_sound_channel_get_right", 1);
	private static var nme_sound_channel_get_position = Loader.load ("nme_sound_channel_get_position", 1);
	private static var nme_sound_channel_get_data_position = Loader.load ("nme_sound_channel_get_data_position", 1);
	private static var nme_sound_channel_stop = Loader.load ("nme_sound_channel_stop", 1);
	private static var nme_sound_channel_create = Loader.load ("nme_sound_channel_create", 4);
	private static var nme_sound_channel_set_transform = Loader.load ("nme_sound_channel_set_transform", 2);
	private static var nme_sound_channel_needs_data = Loader.load ("nme_sound_channel_needs_data", 1);
	private static var nme_sound_channel_add_data = Loader.load ("nme_sound_channel_add_data", 2);

}
