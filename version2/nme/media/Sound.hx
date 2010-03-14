package nme.media;

class Sound extends nme.events.EventDispatcher
{
   public var bytesLoaded(nmeSoundGetBytesLoaded,null) : Int;
   public var bytesTotal(nmeSoundGetBytesTotal,null) : Int;
   public var id3(nmeSoundGetBytesTotal,null) : Int;
   public var id3(nmeSoundIsBuffering,null) : Int;
   public var length(nmeSoundGetLength,null) : Int;
   public var url(default,null) : String;

   var nmeHandle:Dynamic;
   var nmeLoader:nme.net.URLLoader;

   public function new(?stream:URLRequest, ?context:SoundLoaderContext)
   {
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

      nmeLoader = new nme.net.Loader();
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
      DispatchCompleteEvent();
   }

   function nmeOnError (msg) :Void
   {
      DispatchIOErrorEvent();
   }

   public function play(startTime:Float = 0, loops:Int = 0, ?sndTransform:SoundTransform):SoundChannel
   {
      var channel = new SoundChannel( );
   }

}
