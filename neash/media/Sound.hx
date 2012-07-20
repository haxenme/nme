package neash.media;


import neash.events.IEventDispatcher;
import neash.events.EventDispatcher;
import neash.events.IOErrorEvent;
import neash.events.SampleDataEvent;
import neash.net.URLRequest;
import neash.Loader;


class Sound extends EventDispatcher
{
	
	public var bytesLoaded(default,null):Int;
	public var bytesTotal(default,null):Int;
	public var id3(nmeGetID3, null):ID3Info;
	public var isBuffering(nmeGetIsBuffering, null):Bool;
	public var length(nmeGetLength, null):Float;
	public var url(default, null):String;

	/** @private */ private var nmeHandle:Dynamic;
	/** @private */ private var nmeLoading:Bool;
	/** @private */ private var nmeDynamicSound:Bool;
	
	
	public function new(?stream:URLRequest, ?context:SoundLoaderContext, forcePlayAsMusic:Bool = false)
	{
		super();
		bytesLoaded = bytesTotal = 0;
		nmeLoading = false;
      	nmeDynamicSound = false;
		if (stream != null)
			load(stream, context, forcePlayAsMusic);
	}

   override public function addEventListener(type:String, listener:Function, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void
   {
      super.addEventListener(type,listener,useCapture,priority,useWeakReference);
      if (type==SampleDataEvent.SAMPLE_DATA)
      {
         if (nmeHandle != null)
            throw "Can't use dynamic sound once file loaded";
         nmeDynamicSound = true;
         nmeLoading = false;
      }
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
			url = stream.url;
			nmeLoading = true;
			nmeLoading = false;
			nmeCheckLoading();
		}
	}

	public function loadCompressedDataFromByteArray(bytes:nme.utils.ByteArray, length:Int, forcePlayAsMusic:Bool = false):Void {
		bytesLoaded = bytesTotal = length;
		nmeHandle = nme_sound_from_data(bytes.getData(), length, forcePlayAsMusic);
		if (nmeHandle == null)
		{
			throw ("Could not load buffer with length: " + length);
		}
	}
	
	
	/** @private */ private function nmeCheckLoading()
	{
		if (!nmeDynamicSound && nmeLoading && nmeHandle != null)
		{
			var status:Dynamic = nme_sound_get_status(nmeHandle);
			if (status == null)
				throw "Could not get sound status";
			bytesLoaded = status.bytesLoaded;
			bytesTotal = status.bytesTotal;
			//trace(bytesLoaded + "/" + bytesTotal);
			nmeLoading = bytesLoaded < bytesTotal;
			if (status.error != null)
			{
				throw(status.error);
			}
		}
	}
	
	
	/** @private */ private function nmeOnError(msg:String):Void
	{
		dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, true, false, msg));
		nmeHandle = null;
		nmeLoading = true;
	}
	
	
	public function play(startTime:Float = 0, loops:Int = 0, ?sndTransform:SoundTransform):SoundChannel
	{
		nmeCheckLoading();
      if (nmeDynamicSound)
      {
         var request = new SampleDataEvent(SampleDataEvent.SAMPLE_DATA);
         dispatchEvent(request);
         if (request.data.length > 0)
         {
            nmeHandle = nme_sound_channel_create_dynamic(request.data,sndTransform);
         }
         if (nmeHandle==null)
            return null;
		   var result =  SoundChannel.createDynamic(nmeHandle, sndTransform, this);
         nmeHandle = null;
         return result;
      }
      else
      {
		   if (nmeHandle == null || nmeLoading)
			   return null;
		   return new SoundChannel(nmeHandle, startTime, loops, sndTransform);
      }
	}
	
	
	
	// Getters & Setters
	
	
	
	/** @private */ private function nmeGetID3():ID3Info
	{
		nmeCheckLoading();
		if (nmeHandle == null || nmeLoading)
			return null;
		var id3 = new ID3Info();
		nme_sound_get_id3(nmeHandle, id3);
		return id3;
	}
	
	
	/** @private */ private function nmeGetIsBuffering():Bool
	{
		nmeCheckLoading();
		return (nmeLoading && nmeHandle == null);
	}
	
	
	/** @private */ private function nmeGetLength():Float
	{
		if (nmeHandle == null || nmeLoading)
			return 0;
		return nme_sound_get_length(nmeHandle);
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_sound_from_file = Loader.load("nme_sound_from_file", 2);
	private static var nme_sound_from_data = Loader.load("nme_sound_from_data", 3);
	private static var nme_sound_get_id3 = Loader.load("nme_sound_get_id3", 2);
	private static var nme_sound_get_length = Loader.load("nme_sound_get_length", 1);
	private static var nme_sound_close = Loader.load("nme_sound_close", 1);
	private static var nme_sound_get_status = Loader.load("nme_sound_get_status", 1);
	private static var nme_sound_channel_create_dynamic = Loader.load("nme_sound_channel_create_dynamic", 2);

}