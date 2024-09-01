class AndroidPermission
{
   public var permission:String;
   public var required:String;
   public var maxSdkVersion:String;
   public var usesPermissionFlags:String;
   public var permissionXml:String;

   public function new(inPermission:String)
   {
      permission = inPermission;
      required = "true";
      maxSdkVersion = null;
      usesPermissionFlags = null;
   }

   public function update() { permissionXml = getXml(); }

  public function getXml() {
    var req = required!=null ? ' android:required="$required" ' : "";
    var flag = usesPermissionFlags!=null ? ' android:usesPermissionFlags="$usesPermissionFlags" ' : "";
    return '<uses-permission android:name="$permission" $req $flag />';
 }
}
