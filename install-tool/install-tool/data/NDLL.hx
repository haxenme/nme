package data;


import neko.FileSystem;
import neko.Sys;


class NDLL {
	
	
	public var hash:String;
	public var haxelib:String;
	public var name:String;
	public var needsNekoApi:Bool;
	
	
	public function new (name:String, haxelib:String, needsNekoApi:Bool) {
		
		this.name = name;
		this.haxelib = haxelib;
		this.needsNekoApi = needsNekoApi;
		
		hash = Utils.getUniqueID ();
		
	}
	
	
	public function getSourcePath (directoryName:String, filename:String):String {
		
		if (haxelib == "" || haxelib == "hxcpp") {
			
			var path:String = Utils.getHaxelib ("hxcpp") + "/bin/" + directoryName + "/" + filename;
			
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
