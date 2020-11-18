package nme.media;
#if (!flash)

import nme.events.IEventDispatcher;
import nme.events.EventDispatcher;
import nme.events.IOErrorEvent;
import nme.events.SampleDataEvent;
import nme.net.URLRequest;
import nme.Loader;
import nme.errors.Error;
import nme.utils.ByteArray;
import nme.utils.Endian;
import nme.NativeHandle;

@:nativeProperty
@:autoBuild(nme.macros.Embed.embedAsset("NME_sound_",":sound"))
class Sound extends EventDispatcher 
{
   public var bytesLoaded(default, null):Int;
   public var bytesTotal(default, null):Int;
   public var id3(get, null):ID3Info;
   public var isBuffering(get, null):Bool;
   public var length(get, null):Float;
   public var url(default, null):String;

   public var nmeHandle:NativeHandle;
   private var nmeLoading:Bool;
   private var nmeDynamicSound:Bool;

   public function new(?stream:URLRequest, ?context:SoundLoaderContext, forcePlayAsMusic:Bool = false, ?inEngine:String) 
   {
      super();

      if (stream==null)
      {
         var className = Type.getClass(this);
         if (Reflect.hasField(className, "resourceName"))
         {
            stream = new URLRequest(Reflect.field(className, "resourceName"));
            forcePlayAsMusic = true;
         }
      }

      bytesLoaded = bytesTotal = 0;
      nmeLoading = false;
      nmeDynamicSound = false;

      if (stream != null)
         load(stream, context, forcePlayAsMusic, inEngine);
   }
   public function getEngine()
   {
      // TODO
      return nme_sound_get_engine(nmeHandle);
   }

   public static function suspend(inSuspend:Bool, inFlags:Int=0x02)
   {
      nme_sound_suspend(inSuspend,inFlags);
   }

   override public function addEventListener(type:String, listener:Function, useCapture:Bool = false, priority:Int = 0, useWeakReference:Bool = false):Void 
   {
      super.addEventListener(type, listener, useCapture, priority, useWeakReference);

      if (type == SampleDataEvent.SAMPLE_DATA) 
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
      {
         nme_sound_close(nmeHandle);
      }
      nme.NativeResource.disposeHandler(this);
      nmeLoading = false;
   }

   public function load(stream:URLRequest, ?context:SoundLoaderContext, forcePlayAsMusic:Bool = false, ?inEngine:String) 
   {
      bytesLoaded = bytesTotal = 0;
      nmeHandle = nme_sound_from_file(stream.url, forcePlayAsMusic, inEngine);

      if (nmeHandle == null) 
      {
         throw("Could not load " + (forcePlayAsMusic ? "music" : "sound") + ":" + stream.url);

      }
      else 
      {
         nme.NativeResource.lockHandler(this);
         url = stream.url;
         nmeLoading = false;
         nmeCheckLoading();
      }
   }

   public function loadCompressedDataFromByteArray(bytes:ByteArray, length:Int, forcePlayAsMusic:Bool = false, ?inEngine:String):Void 
   {
      bytesLoaded = bytesTotal = length;
      nmeHandle = nme_sound_from_data(bytes, length, forcePlayAsMusic, inEngine);

      if (nmeHandle == null) 
      {
         throw("Could not load buffer with length: " + length);
      }
      else
      {
         nme.NativeResource.lockHandler(this);
      }
   }

   public function loadPCMFromByteArray(Bytes:ByteArray, samples:Int, format:String = "float", stereo:Bool = true, sampleRate:Float = 44100.0, ?inEngine:String):Void 
   {
      // http://www-mmsp.ece.mcgill.ca/Documents/AudioFormats/WAVE/WAVE.html
      var wav:ByteArray = new ByteArray();
      wav.endian = Endian.LITTLE_ENDIAN;

      var AudioFormat:Int = switch(format) 
      {
         case "float": 3;
         case "short": 1;
         default: throw(new Error('Unsupported format $format'));
      }

      var NumChannels:Int = stereo ? 2 : 1;
      var SampleRate:Int = Std.int(sampleRate);
      var BitsPerSample:Int = switch(format) 
      {
         case "float": 32;
         case "short": 16;
         default: throw(new Error('Unsupported format $format'));
      };

      var ByteRate:Int = Std.int(SampleRate * NumChannels * BitsPerSample / 8);
      var BlockAlign:Int = Std.int(NumChannels * BitsPerSample / 8);
      var NumSamples:Int = Std.int(Bytes.length / BlockAlign);

      wav.writeUTFBytes("RIFF");
      wav.writeInt(36 + Bytes.length);
      wav.writeUTFBytes("WAVE");
      wav.writeUTFBytes("fmt ");
      wav.writeInt(16); // Subchunk1Size
      wav.writeShort((AudioFormat)); // AudioFormat
      wav.writeShort((NumChannels));
      wav.writeInt((SampleRate));
      wav.writeInt((ByteRate));
      wav.writeShort((BlockAlign));
      wav.writeShort((BitsPerSample));
      wav.writeUTFBytes("data");
      wav.writeInt((Bytes.length));
      wav.writeBytes(Bytes, 0, Bytes.length);

      wav.position = 0;
      loadCompressedDataFromByteArray(wav, wav.length);
   }

   private function nmeCheckLoading()
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

   private function nmeOnError(msg:String):Void
   {
      dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, true, false, msg));
      close();
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
            nmeHandle = nme_sound_channel_create_dynamic(request.data, sndTransform);
         }

         if (nmeHandle == null)
            return null;

         var result = SoundChannel.createDynamic(nmeHandle, sndTransform, this);

         #if js
            nme.NativeResource.lockHandler(this);
         #else
            nmeHandle = null;
         #end
         return result;

      }
      else 
      {
         if (nmeHandle == null || nmeLoading)
            return null;

         var result = new SoundChannel(nmeHandle, startTime, loops, sndTransform);
         if (result.nmeHandle==null)
            return null;
         return result;
      }
   }

   // Getters & Setters
   private function get_id3():ID3Info
   {
      nmeCheckLoading();

      if (nmeHandle == null || nmeLoading)
         return null;

      var id3 = new ID3Info();
      nme_sound_get_id3(nmeHandle, id3);
      return id3;
   }

   private function get_isBuffering():Bool
   {
      nmeCheckLoading();
      return(nmeLoading && nmeHandle == null);
   }

   private function get_length():Float
   {
      if (nmeHandle == null || nmeLoading)
         return 0;

      return nme_sound_get_length(nmeHandle);
   }

   // Native Methods
   private static var nme_sound_from_file = Loader.load("nme_sound_from_file", 3);
   private static var nme_sound_from_data = Loader.load("nme_sound_from_data", 4);
   private static var nme_sound_get_id3 = nme.PrimeLoader.load("nme_sound_get_id3", "oov");
   private static var nme_sound_get_length = nme.PrimeLoader.load("nme_sound_get_length", "od");
   private static var nme_sound_close = nme.PrimeLoader.load("nme_sound_close", "ov");
   private static var nme_sound_get_status = nme.PrimeLoader.load("nme_sound_get_status", "oo");
   private static var nme_sound_suspend = nme.PrimeLoader.load("nme_sound_suspend", "biv");
   private static var nme_sound_get_engine = Loader.load("nme_sound_get_engine", 1);
   private static var nme_sound_channel_create_dynamic = nme.PrimeLoader.load("nme_sound_channel_create_dynamic", "ooo");
}

#else
typedef Sound = flash.media.Sound;
#end
