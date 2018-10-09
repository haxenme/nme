package nme.media;

class SoundEngine
{
   // Types you can request
   public static inline var FLASH = "flash";
   public static inline var SDL = "sdl";
   public static inline var OPENSL = "opensl";
   public static inline var OPENAL = "openal";
   public static inline var ANDROID = "android";
   public static inline var AVPLAYER = "avplayer";

   // Depends on what the engine decides to do
   public static inline var SDL_MUSIC = "sdl music";
   public static inline var SDL_SOUND = "sdl sound";
   public static inline var SDL_NATIVE_MIDI = "sdl native midi";
   public static inline var ANDROID_SOUND = "android sound";
   public static inline var ANDROID_MEDIAPLAYER = "android mediaplayer";

   public static function getAvailableEngines() : Array<String>
   {
      #if flash
      return [FLASH];
      #else
         // TODO - query binary
         #if android
            return [ ANDROID, OPENSL ];
         #elseif iphone
            return [ AVPLAYER, OPENAL ];
         #elseif mac
            return [ SDL, OPENAL ];
         #else
            return [ SDL ];
         #end
      #end
   }

   public static function getEngine(sound:Sound) : String
   {
      #if flash
      return FLASH;
      #else
      return sound.getEngine();
      #end
   }
}



