class WinrtPackageDependency
{
   var dependency:String;
   var minversion:String;
   var publisher:String;

   public function new(inDependency:String, inMinVersion:String, inPublisher:String)
   {
      dependency = inDependency;
      minversion = inMinVersion;
      publisher = inPublisher;
   }
}
