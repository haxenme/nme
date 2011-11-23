package nme.media;
#if (cpp || neko)


import nme.events.EventDispatcher;
import nme.events.IOErrorEvent;
import nme.net.URLRequest;
import nme.Loader;


class Sound extends EventDispatcher
{
	
	public var bytesLoaded(default,null):Int;
	public var bytesTotal(default,null):Int;
	public var id3(nmeGetID3, null):ID3Info;
	public var isBuffering(nmeGetIsBuffering, null):Bool;
	public var length(nmeGetLength, null):Float;
	public var url(default, null):String;

	private var nmeHandle:Dynamic;
	private var nmeLoading:Bool;
	
	
	public function new(?stream:URLRequest, ?context:SoundLoaderContext, forcePlayAsMusic:Bool = false)
	{
		super();
		bytesLoaded = bytesTotal = 0;
		nmeLoading = false;
		if (stream != null)
			load(stream, context, forcePlayAsMusic);
	}
	
	
	public function close()
	{
		if (nmeHandle != null)
			nme_sound_close(nmeHandle);
		nmeHandle = 0;
		nmeLoading = false;
	}
	
	
	public function load(stream:URLRequest, ?context:SoundLoaderContext, forcePlayAsMusic:Bool = false)
	{
		bytesLoaded = bytesTotal = 0;
		nmeHandle = nme_sound_from_file(stream.url, forcePlayAsMusic);
		if (nmeHandle == null)
		{
			throw ("Could not load:" + stream.url );
		}
		else
		{
			nmeLoading = true;
			nmeLoading = false;
			nmeCheckLoading();
		}
	}
	
	
	private function nmeCheckLoading()
	{
		if (nmeLoading && nmeHandle != null)
		{
			var status:Dynamic = nme_sound_get_status(nmeHandle);
			if (status == null)
				throw "Could not get sound status";
			bytesLoaded = status.bytesLoaded;
			bytesTotal = status.bytesTotal;
			nmeLoading = bytesLoaded < bytesTotal;
			if (status.error != null)
			{
				throw(status.error);
			}
		}
	}
	
	
	private function nmeOnError(msg:String):Void
	{
		dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, true, false, msg));
		nmeHandle = null;
		nmeLoading = true;
	}
	
	
	public function play(startTime:Float = 0, loops:Int = 0, ?sndTransform:SoundTransform):SoundChannel
	{
		nmeCheckLoading();
		if (nmeHandle == null || nmeLoading)
		{
			return null;
		}
		return new SoundChannel(nmeHandle, startTime, loops, sndTransform);
	}
	
	
	
	// Getters & Setters
	
	
	
	private function nmeGetID3():ID3Info
	{
		nmeCheckLoading();
		if (nmeHandle == null || nmeLoading)
			return null;
		var id3 = new ID3Info();
		nme_sound_get_id3(nmeHandle, id3);
		return id3;
	}
	
	
	private function nmeGetIsBuffering():Bool
	{
		nmeCheckLoading();
		return (nmeLoading && nmeHandle == null);
	}
	
	
	private function nmeGetLength():Float
	{
		if (nmeHandle == null || nmeLoading)
			return 0;
		return nme_sound_get_length(nmeHandle);
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_sound_from_file = Loader.load("nme_sound_from_file", 2);
	private static var nme_sound_get_id3 = Loader.load("nme_sound_get_id3", 2);
	private static var nme_sound_get_length = Loader.load("nme_sound_get_length", 1);
	private static var nme_sound_close = Loader.load("nme_sound_close", 1);
	private static var nme_sound_get_status = Loader.load("nme_sound_get_status", 1);

}


#else
typedef Sound = flash.media.Sound;
#end