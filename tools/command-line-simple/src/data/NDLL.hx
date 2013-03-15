package data;


import sys.FileSystem;
import Sys;


class NDLL {
   public static var nekoMode = true;
	
	
	public var extension:String;
	public var hash:String;
	public var haxelib:String;
	public var name:String;
	public var path:String;
	public var registerStatics:Bool;
	
	
	public function new (inName:String, inHaxelib:String, inRegisterStatics=true) {
		
		name = inName;
		
		path = "";
		extension = "";
		
		if (inName == "nme" && inHaxelib == "") {
			
			haxelib = "nme";
			
		} else {

         if (inName=="std" || inName=="regexp" || inName=="zlib")
            haxelib = "";
         else
			   haxelib = inHaxelib;
			
		}
		
		registerStatics = inRegisterStatics;
		
		hash = Utils.getUniqueID ();
		
	}
	
	
	public function getSourcePath (directoryName:String, filename:String):String {
		
		if (path != "") {
			
			return path;
			
		} else if (extension != "") {
			
			return extension + "/ndll/" + directoryName + "/" + filename;
			
		} else if (haxelib == "" ) {
			
			var path:String =
           (nekoMode ? Sys.getEnv("NEKO_INSTPATH") :
            Utils.getHaxelib ("hxcpp") + "/bin/" +directoryName) 
          + "/" + filename;
			
			if (FileSystem.exists (path)) {
				
				return path;
				
			} else {
				
				return filename;
				
			}
			
		} else {
			
			return Utils.getHaxelib (haxelib) + "/ndll/" + directoryName + "/" + filename;
			
		}
		
	}
	
	
}
