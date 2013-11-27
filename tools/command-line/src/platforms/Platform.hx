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


   public static inline var TYPE_DESKTOP = "DESKTOP";
   public static inline var TYPE_MOBILE = "MOBILE";
   public static inline var TYPE_WEB = "WEB";

   public var platform(get,null):String;
   public var type(get,null):String;

   public function new()
   {
   }

   private function generateContext(project:NMEProject):Dynamic 
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

   private function initialize(project:NMEProject):Void 
   {
   }


   public function build(project:NMEProject)
   {
   }

   public function clean(project:NMEProject)
   {
   }

   public function display(project:NMEProject)
   {
   }

   public function install(project:NMEProject)
   {
   }

   public function run(project:NMEProject, arguments:Array<String>)
   {
   }

   public function trace(project:NMEProject)
   {
   }

   public function uninstall(project:NMEProject)
   {
   }

   public function update(project:NMEProject)
   {
   }
}
