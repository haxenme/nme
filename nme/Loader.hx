package nme;


#if neko
import neko.Lib;
import neko.Sys;
import neko.io.Process;
#elseif cpp
import cpp.Lib;
import cpp.Sys;
import cpp.io.Process;
#elseif js
import import js.Lib;
import import js.Sys;
#else
#error "unsupported platform";
#end
 

class Loader
{
   #if (iphone||android)
   public static function load(func:String, args:Int) : Dynamic
   {
      return Lib.load("nme",func,args);
   }
   #else

   static var moduleInit = false;
   static var moduleName = "";

   public static function tryLoad(inName:String, func:String, args:Int) : Dynamic
   {
      try
      {
         var result =  Lib.load(inName,func,args);
         if (result!=null)
         {
            loaderTrace("Got result " + inName);
            moduleName = inName;
            return result;
         }
      }
      catch (e:Dynamic) {
         loaderTrace("Failed to load : " + inName);
      }
      return null;
   }

   static public function findHaxeLib(inLib:String)
   {
       try
       {
          var proc = new Process("haxelib",["path",inLib]);
          if (proc!=null)
          {
              var stream = proc.stdout;
              try
              {
                 while(true)
                 {
                    var s = stream.readLine();
                    if (s.substr(0,1)!="-")
                    {
                       stream.close();
                       proc.close();
                       loaderTrace("Found haxelib " + s);
                       return s;
                    }
                 }
              }
              catch (e:Dynamic) { }
              stream.close();
              proc.close();
          }
       }
       catch (e:Dynamic) { }

       return "";
   }
   public static function loaderTrace(inStr:String)
   {
      if (Sys.getEnv("NME_LOAD_DEBUG")!=null)
         Lib.println(inStr);
   }

   public static function loadNekoAPI(slash:String)
   {
      var func = "neko_api_init2";
      var args = 2;
      
      // Try local file first ...
      var init = tryLoad("." + slash + "nekoapi",func, args);
      // Try neko rules ...
      if (init==null)
         init = tryLoad("nekoapi",func, args);
      // Try haxelib ...
      if (init==null)
      {
         var haxelib = findHaxeLib("hxcpp");
         if (haxelib!="")
         {
            init = tryLoad(haxelib + slash + "bin" + slash + Sys.systemName() + slash + "nekoapi",func,args);
            // Try 64 bit ...
            if (init==null)
               init = tryLoad(haxelib + slash + "bin" + slash + Sys.systemName() + "64" + slash + "nekoapi",func,args);
         }
      }

      if (init!=null)
      {
         loaderTrace("Found nekoapi @ " + moduleName );
         init(function(s) return new String(s),
           function(len:Int) { var r=[]; if (len>0) r[len-1]=null; return r; } );
      }
      else
         throw("Could not find NekoAPI ndll.");
   }


   public static function load(func:String, args:Int) : Dynamic
   {

      if (moduleInit)
      {
         return Lib.load(moduleName,func,args);
      }

      var slash = (Sys.systemName().substr(7).toLowerCase()=="windows") ? "\\" : "/";
      moduleInit = true;

      #if neko
      loadNekoAPI(slash);
      #end

      moduleName = "nme";

      // Look in current directory first (for installed apps)
      var result:Dynamic = tryLoad("." + slash + "nme",func,args);
      // Try standard neko path (NEKOPATH variable, system path/library paths)
      if (result==null)
          result = tryLoad("nme",func,args);
      // Try haxelib
      if (result==null)
      {
         var haxelib = findHaxeLib("nme");
         if (haxelib!="")
         {
            result = tryLoad(haxelib + slash + "ndll" + slash + Sys.systemName() + slash + "nme",func,args);
            // Try haxelib64 ...

            if (result==null)
               result = tryLoad(haxelib + slash + "ndll" + slash + Sys.systemName() + "64" + slash + "nme",func,args);
         }
      }

      loaderTrace("Result : " + result );

      return result;
   }
   #end
}


