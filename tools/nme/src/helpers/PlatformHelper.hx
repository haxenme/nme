package;

import sys.io.Process;
import platforms.Platform;

class PlatformHelper 
{
   public static var hostArchitecture(get, null):Architecture;
   public static var hostPlatform(get, null):String;

   private static var _hostArchitecture:Architecture;
   private static var _hostPlatform:String;

   private static function get_hostArchitecture():Architecture 
   {
      if (_hostArchitecture == null) 
      {
         switch(hostPlatform) 
         {
            case Platform.WINDOWS, Platform.LINUX, Platform.MAC:
               var bits = nme.Lib.bits;
               _hostArchitecture = bits==64 ? Architecture.X64 : Architecture.X86;

            default:
               _hostArchitecture = Architecture.ARMV6;
         }

         Log.verbose(" - Detected host architecture: " + StringHelper.formatEnum(_hostArchitecture));
      }

      return _hostArchitecture;
   }

   private static function get_hostPlatform():String 
   {
      if (_hostPlatform == null) 
      {
         if (new EReg("window", "i").match(Sys.systemName())) 
         {
            _hostPlatform = Platform.WINDOWS;

         } else if (new EReg("linux", "i").match(Sys.systemName())) 
         {
            _hostPlatform = Platform.LINUX;

         } else if (new EReg("mac", "i").match(Sys.systemName())) 
         {
            _hostPlatform = Platform.MAC;
         }

         LogHelper.info("", " - Detected host platform: " + _hostPlatform);
      }

      return _hostPlatform;
   }
}
