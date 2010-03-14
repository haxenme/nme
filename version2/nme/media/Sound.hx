package nme.media;

import nme.net.URLRequest;

class Sound extends nme.events.EventDispatcher
{
   public var bytesLoaded(default,null) : Int;
   public var bytesTotal(default,null) : Int;
   public var isBuffering(nmeIsBuffering,null) : Bool;
   public var id3(nmeGetID3,null) :  ID3Info;
   public var length(nmeGetLength,null) : Float;
   public var url(default,null) : String;

   var nmeHandle:Dynamic;
   var nmeLoader:nme.net.URLLoader;

   public function new(?stream:URLRequest, ?context:SoundLoaderContext)
   {
		super();
		bytesLoaded = bytesTotal = 0;
      if (stream!=null)
         load(stream,context);
   }

   public function close()
   {
      if (nmeLoader!=null)
         nmeLoader.close();
      nmeHandle = 0;
   }

   public function load(stream:URLRequest, ?context:SoundLoaderContext)
   {
		nmeHandle = null;
		if (nmeLoader!=null)
		{
			nmeLoader.onData = function(_) {};
			nmeLoader.onError = function(_) {};
		}
      nmeLoader = new nme.net.URLLoader();
      nmeLoader.dataFormat = nme.net.URLLoaderDataFormat.BINARY;
      nmeLoader.onData = nmeOnData;
      nmeLoader.onError = nmeOnError;
      url = stream.url;
      nmeLoader.load(stream);
   }

   function nmeOnData(inDataString:String) :Void
   {
      var data = haxe.io.Bytes.ofString( inDataString );
      nmeHandle = nme_sound_from_data(data);
		this.bytesLoaded = this.bytesTotal = data.length;
		nmeLoader = null;
		dispatchEvent( new nme.events.Event(nme.events.Event.COMPLETE) );
   }

	function nmeIsBuffering() : Bool
	{
		return (nmeLoader!=null && nmeHandle==null);
	}

	function nmeGetID3() : ID3Info
	{
	   if (nmeHandle==null)
			return null;
		var id3 = new ID3Info();
		nme_sound_get_id3(nmeHandle,id3);
		return id3;
	}
	function nmeGetLength() : Float
	{
		if (nmeHandle==null)
			return 0;
		return nme_sound_get_length(nmeHandle);
	}

   function nmeOnError(msg:String) :Void
   {
	 	dispatchEvent( new nme.events.IOErrorEvent(nme.events.IOErrorEvent.IO_ERROR, true, false, msg) );
		nmeHandle = null;
   }

   public function play(startTime:Float = 0, loops:Int = 0, ?sndTransform:SoundTransform):SoundChannel
   {
      return new SoundChannel(nmeHandle,startTime,loops,sndTransform);
   }

	static var nme_sound_from_data = nme.Loader.load("nme_sound_from_data",1);
	static var nme_sound_get_id3 = nme.Loader.load("nme_sound_get_id3",2);
	static var nme_sound_get_length = nme.Loader.load("nme_sound_get_length",1);

}
