package nme.script;
import nme.utils.ByteArray;
import haxe.io.Bytes;

using StringTools;

class Nme
{
   static function inflate(data:haxe.io.Bytes)
   {
       var result = new ByteArray();

       var bufSize = 65536;
       var tmp = haxe.io.Bytes.alloc(bufSize);
       var z = new haxe.zip.InflateImpl(new haxe.io.BytesInput(data), false, false);
       while( true ) {
         var n = z.readBytes(tmp, 0, bufSize);
         result.writeHaxeBytes(tmp, 0, n);
         if( n < bufSize )
            break;
         }
       return result;
   }

   public static function getHeader(input:haxe.io.Input)
   {
      var magic = input.readString(4);
      if (magic!="NME!")
         throw "NME - bad magic";
      input.bigEndian = false;
      var headerLen = input.readInt32();
      var zipLen = input.readInt32();
      return haxe.Json.parse( input.readString(headerLen) );
   }


   public static function getFileHeader(inFilename:String) : Dynamic
   {
      if (inFilename.endsWith(".nme"))
      {
         try
         {
            var file = sys.io.File.read(inFilename);
            var result = getHeader(file);
            file.close();
            return result;
         }
         catch(e:Dynamic) { trace(e); }
      }
      return null;
   }



   public static function runInput(input:haxe.io.Input, ?verify:Dynamic->Bytes->Void)
   {
      var magic = input.readString(4);
      if (magic!="NME!")
         throw "NME - bad magic";
      input.bigEndian = false;
      var headerLen = input.readInt32();
      var zipLen = input.readInt32();
      var header = haxe.Json.parse( input.readString(headerLen) );

      if (verify!=null)
      {
         var bytes = haxe.io.Bytes.alloc(zipLen);
         input.readBytes(bytes,0,zipLen);
         verify(header, bytes);
         input = new haxe.io.BytesInput(bytes);
      }

      var zip = new haxe.zip.Reader( input );
      var entries = zip.read();
      var script:String = null;
      for(entry in entries)
      {
         if (entry.fileName=="ScriptMain.cppia")
         {
            var data = entry.data;
            if (entry.compressed)
            {
               var byteArray = inflate(data);
               script = byteArray.getString(0,byteArray.length);
            }
            else
               script = data.getString(0,data.length);
         }
         else if (entry.fileName.startsWith("assets/"))
         {
            nme.Assets.byteFactory.set(entry.fileName.substr(7), function() return inflate(entry.data)  );
         }
         else
         {
            // Ignore this entry?
         }
      }
      #if (cpp && !cppia)
         if (script==null)
            throw "Could not find script in input";
         #if ((hxcpp_api_level>=320) && scriptable)
            cpp.cppia.Host.run(script);
         #end
      #else
         throw "Script not available on this platform";
      #end
   }

   public static function runBytes(inBytes:Bytes,?verify:Dynamic->Bytes->Void)
   {
       runInput( new haxe.io.BytesInput(inBytes), verify );
   }

   public static function runFile(inFilename:String,?verify:Dynamic->Bytes->Void)
   {
      #if (cpp && !cppia)
      if (inFilename.endsWith(".nme"))
      {
         nme.Assets.scriptBase = "";
         var bytes = sys.io.File.getBytes(inFilename);
         runInput( new haxe.io.BytesInput(bytes), verify );
      }
      else
      {
         nme.Assets.scriptBase = haxe.io.Path.directory(inFilename) + "/assets/";
         var contents = sys.io.File.getContent(inFilename);
         #if ((hxcpp_api_level>=320) && scriptable)
         cpp.cppia.Host.run(contents);
         #end
      }
      #else
      throw "Script not available on this platform";
      #end
   }


   public static function getBytesHeader(inBytes:Bytes) : Dynamic
   {
      var input = new haxe.io.BytesInput(inBytes);
      return getHeader(input);
   }


   public static function getResourceHeader(inResource:String) : Dynamic
   {
      var bytes = haxe.Resource.getBytes(inResource);
      if (bytes==null)
          return null;

      var input = new haxe.io.BytesInput(bytes);
      return getHeader(input);
   }

   public static function runResource(?inResource:String,?verify:Dynamic->Bytes->Void)
   {
      #if (cpp && !cppia)
         if (inResource==null)
             inResource = "ScriptMain.cppia"; 

         if (inResource.endsWith(".nme"))
         {
            var bytes = haxe.Resource.getBytes(inResource);
            if (bytes==null)
                return;
            var input = new haxe.io.BytesInput(bytes);
            nme.Assets.scriptBase = "";
            runInput(input,verify);
         }
         else
         {
            var script = nme.Assets.getString(inResource);
            if (script==null)
               throw "Could not find resource script " + inResource;
            #if ((hxcpp_api_level>=320) && scriptable)
               cpp.cppia.Host.run(script);
            #end
         }
      #else
         throw "Script not available on this platform";
      #end
   }
}



