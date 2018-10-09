class WinrtCapability
{
   var capability:String;
   var namespace:String;

   public function new(inCapability:String, inNamespace:String)
   {
      capability = inCapability;
      namespace = inNamespace!="" && inNamespace!=null ? inNamespace+":": "";
   }
}
