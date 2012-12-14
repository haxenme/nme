package native.media;


import native.events.Event;
import native.events.EventDispatcher;
import native.events.SampleDataEvent;
import native.Loader;


class SoundChannel extends EventDispatcher {
	
	
	public var leftPeak (get_leftPeak, null):Float;
	public var rightPeak (get_rightPeak, null):Float;
	public var position (get_position, null):Float;
	public var soundTransform (get_soundTransform, set_soundTransform):SoundTransform;
	
	/** @private */ public static var nmeDynamicSoundCount = 0;
	
	private static var nmeIncompleteList = new Array<SoundChannel> ();
	
	/** @private */ private var nmeHandle:Dynamic;
	/** @private */ private var nmeTransform:SoundTransform;
	/** @private */ public var nmeDataProvider:EventDispatcher;
	
	
	public function new (inSoundHandle:Dynamic, startTime:Float, loops:Int, sndTransform:SoundTransform) {
		
		super ();
		
		if (sndTransform != null) {
			
			nmeTransform = sndTransform.clone ();
			
		}
		
	    if (inSoundHandle != null)
		   nmeHandle = nme_sound_channel_create (inSoundHandle, startTime, loops, nmeTransform);
		
		if (nmeHandle != null)
			nmeIncompleteList.push (this);
		
	}
	
	
	public static function createDynamic (inSoundHandle:Dynamic, sndTransform:SoundTransform, dataProvider:EventDispatcher) {
		
		var result = new SoundChannel (null, 0, 0, sndTransform);
		
      	result.nmeDataProvider = dataProvider;
      	result.nmeHandle = inSoundHandle;
		nmeIncompleteList.push (result);
      	nmeDynamicSoundCount ++;
		
      	return result;
		
   	}
	
	
	/** @private */ private function nmeCheckComplete ():Bool {
		
		if (nmeHandle != null ) {
			
			if (nmeDataProvider != null && nme_sound_channel_needs_data (nmeHandle)) {
				
				var request = new SampleDataEvent (SampleDataEvent.SAMPLE_DATA);
				request.position = nme_sound_channel_get_data_position (nmeHandle);
				nmeDataProvider.dispatchEvent (request);
				
				if (request.data.length > 0) {
					
					nme_sound_channel_add_data (nmeHandle, request.data);
					
				}
				
			}
			
			if (nme_sound_channel_is_complete (nmeHandle)) {
				
				nmeHandle = null;
				if (nmeDataProvider != null) {
					
					nmeDynamicSoundCount--;
					
				}
				
				var complete = new Event (Event.SOUND_COMPLETE);
				dispatchEvent (complete);
				return true;
				
			}
			
		}
		
		return false;
		
	}
	
	
	/** @private */ public static function nmeCompletePending () {
		
		return nmeIncompleteList.length > 0;
		
	}
	
	
	/** @private */ public static function nmePollComplete () {
		
		if (nmeIncompleteList.length > 0) {
			
			var incomplete = new Array<SoundChannel> ();
			
			for (channel in nmeIncompleteList) {
				
				if (!channel.nmeCheckComplete ()) {
					
					incomplete.push (channel);
					
				}
				
			}
			
			nmeIncompleteList = incomplete;
			
		}
		
	}
	
	
	public function stop () {
		
		nme_sound_channel_stop (nmeHandle);
		nmeHandle = null;
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private function get_leftPeak ():Float { return nme_sound_channel_get_left (nmeHandle); }
	private function get_rightPeak ():Float { return nme_sound_channel_get_right (nmeHandle); }
	private function get_position ():Float { return nme_sound_channel_get_position (nmeHandle); }
	
	
	private function get_soundTransform ():SoundTransform {
		
		if (nmeTransform == null) {
			
			nmeTransform = new SoundTransform ();
			
		}
		
		return nmeTransform.clone ();
		
	}
	
	
	private function set_soundTransform (inTransform:SoundTransform):SoundTransform {
		
		nmeTransform = inTransform.clone ();
		nme_sound_channel_set_transform (nmeHandle, nmeTransform);
		
		return inTransform;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
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