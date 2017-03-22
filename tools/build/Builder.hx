
class Builder extends hxcpp.Builder
{
   static var toolkitBuild = true;

   override public function getBuildFile()
   {
      if (toolkitBuild)
         return "ToolkitBuild.xml";
      else
         return "Build.xml";
   }

   public static function main()
   {
      var args = Sys.args();
      if (args.remove("-Dnme-dev"))
         toolkitBuild = false;

      new Builder( args );
   }
}

