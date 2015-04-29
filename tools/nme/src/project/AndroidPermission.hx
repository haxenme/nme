class AndroidPermission
{
   var permission:String;
   var required:String;

   public function new(inPermission:String, inRequired:String)
   {
      permission = inPermission;
      required = inRequired!="" && inRequired!=null ? inRequired : "true";
   }
}
