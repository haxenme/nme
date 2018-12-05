package nme.system;
#if (!flash)

import nme.PrimeLoader;

@:nativeProperty
class Capabilities 
{
   public static var pixelAspectRatio(get, null):Float;
   public static var screenDPI(get, null):Float;
   public static var screenResolutionX(get, null):Float;
   public static var screenResolutionY(get, null):Float;
   public static var screenResolutions(get, null):Array<Array<Int>>;
   public static var language(get, null):String;

   // Getters & Setters
   private static function get_pixelAspectRatio():Float { return nme_capabilities_get_pixel_aspect_ratio(); }
   private static function get_screenDPI():Float { return nme_capabilities_get_screen_dpi(); }
   private static function get_screenResolutionX():Float { return nme_capabilities_get_screen_resolution_x(); }
   private static function get_screenResolutionY():Float { return nme_capabilities_get_screen_resolution_y(); }

   private static function get_language():String 
   {
      var locale:String = nme_capabilities_get_language();

      if (locale == null || locale == "" || locale == "C" || locale == "POSIX") 
      {
         return "en-US";

      } else 
      {
         var formattedLocale = "";
         var length = locale.length;

         if (length > 5) 
         {
            length = 5;
         }

         for(i in 0...length) 
         {
            var char = locale.charAt(i);

            if (i < 2) 
            {
               formattedLocale += char.toLowerCase();

            } else if (i == 2) 
            {
               formattedLocale += "-";

            } else 
            {
               formattedLocale += char.toUpperCase();
            }
         }

         return formattedLocale;
      }
   }

   private static function get_screenResolutions():Array<Array<Int>> 
   {
      var res:Array<Int> = nme_capabilities_get_screen_resolutions();

      if (res == null) 
         return new Array<Array<Int>>();

      var out = new Array<Array<Int>>();

      for(c in 0...Std.int(res.length / 2)) 
      {
         out.push([ res[ c * 2 ], res[ c * 2 + 1 ] ]);
      }

      return out;
   }

   // Native Methods
   private static var nme_capabilities_get_pixel_aspect_ratio = PrimeLoader.load("nme_capabilities_get_pixel_aspect_ratio", "d");
   private static var nme_capabilities_get_screen_dpi = PrimeLoader.load("nme_capabilities_get_screen_dpi", "d");
   private static var nme_capabilities_get_screen_resolution_x = PrimeLoader.load("nme_capabilities_get_screen_resolution_x", "d");
   private static var nme_capabilities_get_screen_resolution_y = PrimeLoader.load("nme_capabilities_get_screen_resolution_y", "d");
   private static var nme_capabilities_get_screen_resolutions = PrimeLoader.load("nme_capabilities_get_screen_resolutions", "o" );
   private static var nme_capabilities_get_language = nme.Loader.load("nme_capabilities_get_language", 0);
}

#else
typedef Capabilities = flash.system.Capabilities;
#end
