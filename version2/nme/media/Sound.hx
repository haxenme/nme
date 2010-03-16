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
   var nmeLoading:Bool;


   public function new(?stream:URLRequest, ?context:SoundLoaderContext)
   {
      super();
      bytesLoaded = bytesTotal = 0;
      nmeLoading = false;
      if (stream!=null)
         load(stream,context);
   }

   public function close()
   {
      if (nmeHandle!=null)
         nme_sound_close(nmeHandle);
      nmeHandle = 0;
      nmeLoading = false;
   }

   public function load(stream:URLRequest, ?context:SoundLoaderContext)
   {
      bytesLoaded = bytesTotal = 0;
      nmeHandle = nme_sound_from_file(stream.url);
      if (nmeHandle==null)
      {
         throw ("Could not load:" + stream.url );
      }
      else
      {
         nmeLoading = true;
         nmeCheckLoading();
      }
   }

   function nmeIsBuffering() : Bool
   {
      nmeCheckLoading();
      return (nmeLoading && nmeHandle==null);
   }

   function nmeCheckLoading()
   {
      if (nmeLoading && nmeHandle!=null)
      {
         var status:Dynamic = nme_sound_get_status(nmeHandle);
         bytesLoaded = status.bytesLoaded;
         bytesTotal = status.bytesTotal;
         nmeLoading = bytesLoaded < bytesTotal;
         if (status.error!=null)
         {
            throw(status.error);
         }
      }
   }

   function nmeGetID3() : ID3Info
   {
      nmeCheckLoading();
      if (nmeHandle==null || nmeLoading)
         return null;
      var id3 = new ID3Info();
      nme_sound_get_id3(nmeHandle,id3);
      return id3;
   }
   function nmeGetLength() : Float
   {
      if (nmeHandle==null || nmeLoading)
         return 0;
      return nme_sound_get_length(nmeHandle);
   }

   function nmeOnError(msg:String) :Void
   {
       dispatchEvent( new nme.events.IOErrorEvent(nme.events.IOErrorEvent.IO_ERROR, true, false, msg) );
      nmeHandle = null;
      nmeLoading = true;
   }

   public function play(startTime:Float = 0, loops:Int = 0, ?sndTransform:SoundTransform):SoundChannel
   {
      nmeCheckLoading();
      if (nmeHandle==null || nmeLoading)
		{
         return null;
		}
      return new SoundChannel(nmeHandle,startTime,loops,sndTransform);
   }

   static var nme_sound_from_file = nme.Loader.load("nme_sound_from_file",1);
   static var nme_sound_get_id3 = nme.Loader.load("nme_sound_get_id3",2);
   static var nme_sound_get_length = nme.Loader.load("nme_sound_get_length",1);
   static var nme_sound_close = nme.Loader.load("nme_sound_close",1);
   static var nme_sound_get_status = nme.Loader.load("nme_sound_get_status",1);

}
