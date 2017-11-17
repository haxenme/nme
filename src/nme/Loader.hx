package nme;
#if (cpp || neko || jsprime)

#if neko
import neko.Lib;
import sys.io.Process;
#elseif cpp
import cpp.Lib;
import sys.io.Process;
#end

@:nativeProperty
class Loader 
{
   public static var foundNdll = false;
   private static var moduleInit = false;
   private static var moduleName = "";

   #if (iphone || android || emscripten)
   public static function load(func:String, args:Int):Dynamic 
   {
      return Lib.load("nme", func, args);
   }
   #elseif jsprime

   public static function load(func:String, args:Int):Dynamic 
   {
      return untyped Module[func];
   }

   #else

   static public function findHaxeLib(inLib:String) 
   {
      try 
      {
         var proc = new Process("haxelib", ["path", inLib]);

         if (proc != null) 
         {
            var stream = proc.stdout;

            try 
            {
               while(true) 
               {
                  var s = stream.readLine();

                  if (s.substr(0, 1) != "-") 
                  {
                     stream.close();
                     proc.close();

                     var parts = s.split("\\").join("/");
                     var parts = parts.split("/");
                     while(parts.length>1)
                     {
                        var test = parts.join("/")+"/ndll";
                        if (sys.FileSystem.exists(test))
                        {
                           s = parts.join("/");
                           break;
                        }
                        parts.pop();
                     }

                     loaderTrace("Found haxelib " + s);
                     return s;
                  }
               }

            } catch(e:Dynamic) { }

            stream.close();
            proc.close();
         }

      } catch(e:Dynamic) { }

      return "";
   }

   public static function load(func:String, args:Int):Dynamic 
   {
      #if nme_static_link
      return Lib.load(moduleName, func, args);
      #end

      if (moduleInit) 
      {
         if (!foundNdll)
            return null;
         #if ndll_silent_fail
         try {
            return Lib.load(moduleName, func, args);
         }
         catch(e:Dynamic)
         {
            return function() trace("Error using undefined function. " + e + " - Maybe you need to rebuild nme.ndll");
         }
         #else
         return Lib.load(moduleName, func, args);
         #end
      }

      #if waxe
      wx.Loader.load("wx_boot",1);
      #end

      moduleInit = true;
      moduleName = "nme";

      // Look in current directory first(for installed apps)
      var result:Dynamic = tryLoad("./nme", func, args);
      if (result == null)
         result = tryLoad(".\\nme", func, args);

      // Try standard neko path(NEKOPATH variable, system path/library paths)
      if (result == null)
         result = tryLoad("nme", func, args);

      // Try haxelib
      if (result == null) 
      {
         var slash =(sysName().substr(7).toLowerCase() == "windows") ? "\\" : "/";
         var haxelib = findHaxeLib("nme");

         if (haxelib != "") 
         {
            result = tryLoad(haxelib + slash + "ndll" + slash + sysName() + slash + "nme", func, args);
            // Try haxelib64 ...
            if (result == null)
               result = tryLoad(haxelib + slash + "ndll" + slash + sysName() + "64" + slash + "nme", func, args);
         }
      }
	  
      loaderTrace("Result : " + result );

      foundNdll = result!=null;

      #if neko
      loadNekoAPI();
      #end

      return result;
   }

   #if neko
   public static function loadNekoAPI() 
   {
      var init =  load("neko_init", 5);

      if (init != null) 
      {
         loaderTrace("Found nekoapi @ " + moduleName);
         init(function(s) return new String(s), function(len:Int) { var r = []; if (len > 0) r[len - 1] = null; return r; }, null, true, false);

      }
      else
      {
         #if !ndll_silent_fail
         throw("Could not find NekoAPI interface.");
         #end
      }
   }
   #end

   public static function loaderTrace(inStr:String) 
   {
      // Problems with initialization order in cpp...
      #if (cpp && hxcpp_api_level<331)
      var get_env = Lib.load("std", "get_env", 1);
      var debug =(get_env("NME_LOAD_DEBUG") != null);
      #else
      var debug =(Sys.getEnv("NME_LOAD_DEBUG") !=null);
      #end

      if (debug)
         Lib.println(inStr);
   }

   static function sysName() 
   {
      // Problems with initialization order in cpp...
      #if (cpp && hxcpp_api_level<331)
      var sys_string = Lib.load("std", "sys_string", 0);
      return sys_string();
      #else
      return Sys.systemName();
      #end
   }

   public static function tryLoad(inName:String, func:String, args:Int):Dynamic 
   {
      try 
      {
         var result =  Lib.load(inName, func, args);

         if (result != null) 
         {
            loaderTrace("Got result " + inName);
            moduleName = inName;
            return result;
         }

      } catch(e:Dynamic) 
      {
         loaderTrace("Failed to load : " + inName);
      }

      return null;
   }

   #end
}

#elseif (html5)
class Loader 
{
   static var html5Implementation:Dynamic;
   public static function load(func:String, args:Int):Dynamic 
   {
      if (html5Implementation==null)
         html5Implementation = nme.html5.Lib.init();
      var val = Reflect.field(html5Implementation, func);
      if (val==null)
         return function() trace(func + " not implemented");
      return val;
   }
}

#end
