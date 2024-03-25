import BootType;


class ApplicationData
{
   // Name of generated application file/directory
   public var file:String;

   // Haxe main class
   public var main:String;
   public var preloader:String;
   public var bootType = BootTypeAuto;

   // Build directory base
   public var binDir:String;

   // The build package name - this is the android process name
   // Should have at least 3 parts, like a.b.c.  It should uniquely identify your app
   public var packageName:String;
   // Shows up in title bar
   public var title:String;

   // Version display string
   public var version:String;
   // Unique app store build number
   public var buildNumber:String;
   public var company:String;
   public var companyID:String;
   public var description:String;
   public var url:String;
   // Target versionm
   public var swfVersion:Float;



   public function new()
   {
      file = "MyApplication";

      title = "MyApplication";
      description = "application";
      packageName = "com.nmehost.myapp";
      version = "1.0.0";
      company = "HaxeNme, Inc.";
      buildNumber = "1";
      companyID = "";

      main = "Main";
      binDir = "bin";
      preloader = "nme.preloader.Basic";
      swfVersion = 11;
      url = "";
   }
}
