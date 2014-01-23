
class MetaData
{
   public var buildNumber:String;
   public var company:String;
   public var companyID:String;
   public var description:String;
   public var packageName:String;
   public var title:String;
   public var version:String;

   public function new()
   {
      title = "MyApplication";
      description = "";
      packageName = "com.example.myapp";
      version = "1.0.0";
      company = "Example, Inc.";
      buildNumber = "1";
      companyID = "";
   }
}
