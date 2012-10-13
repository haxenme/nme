package;


import sys.FileSystem;


class NDLL {
	
	
	public var haxelib:String;
	public var name:String;
	public var path:String;
	
	public function new (name:String, haxelib:String = "") {
		
		this.name = name;
		this.haxelib = haxelib;
		
	}
	
	
	//should this be removed?
	
	public function getSourcePath (directoryName:String, filename:String):String {
		
		/*if (path != "") {
			
			return path;
			
		} else if (extension != "" && haxelib == "nme-extension") {
			
			return extension + "/ndll/" + directoryName + "/" + filename;
			
		} else*/ if (haxelib == "" || haxelib == "hxcpp") {
			
			var path = PathHelper.getHaxelib ("hxcpp") + "/bin/" + directoryName + "/" + filename;
			
			if (FileSystem.exists (path)) {
				
				return path;
				
			} else {
				
				return filename;
				
			}
			
		} else {
			
			return PathHelper.getHaxelib (haxelib) + "/ndll/" + directoryName + "/" + filename;
			
		}
		
	}
	
}