package platforms;

class Platform
{
   public static inline var ANDROID = "ANDROID";
   public static inline var BLACKBERRY = "BLACKBERRY";
   public static inline var FLASH = "FLASH";
   public static inline var HTML5 = "HTML5";
   public static inline var IOS = "IOS";
   public static inline var IOSVIEW = "IOSVIEW";
   public static inline var LINUX = "LINUX";
   public static inline var MAC = "MAC";
   public static inline var WINDOWS = "WINDOWS";
   public static inline var WEBOS = "WEBOS";
   public static inline var ANDROIDVIEW = "ANDROIDVIEW";


   public static inline var TYPE_DESKTOP = "DESKTOP";
   public static inline var TYPE_MOBILE = "MOBILE";
   public static inline var TYPE_WEB = "WEB";

   public var platform(get,null):String;
   public var type(get,null):String;

   public var project:NMEProject;

   public function new(inProject:NMEProject)
   {
      project = inProject;
   }

   private function generateContext():Dynamic 
   {
      return {};
   }

   public function get_platform() : String
   {
      return null;
   }

   public function get_type() : String
   {
      return null;
   }


   public function build()
   {
   }

   public function clean()
   {
   }

   public function display()
   {
   }

   public function install()
   {
   }

   public function run(arguments:Array<String>)
   {
   }

   public function trace()
   {
   }

   public function uninstall()
   {
   }

   public function update()
   {
   }
}
