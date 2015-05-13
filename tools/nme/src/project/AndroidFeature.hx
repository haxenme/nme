class AndroidFeature
{
   var feature:String;
   var required:String;

   public function new(inFeature:String, inRequired:String)
   {
      feature = inFeature;
      required = inRequired!="" && inRequired!=null ? inRequired : "true";
   }
}
