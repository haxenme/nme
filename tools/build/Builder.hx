
class Builder extends hxcpp.Builder
{
   override public function getBuildFile()
   {
      return "ToolkitBuild.xml";
   }

   public static function main()
   {
      new Builder( Sys.args() );
   }
}

