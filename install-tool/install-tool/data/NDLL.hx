package data;


import neko.io.Process;
import neko.FileSystem;
import neko.Sys;


class NDLL {
	
	
	public var haxelib:String;
	public var name:String;
	public var needsNekoApi:Bool;
	
	
	public function new (name:String, haxelib:String, needsNekoApi:Bool) {
		
		this.name = name;
		this.haxelib = haxelib;
		this.needsNekoApi = needsNekoApi;
		
	}
	
	
	private function getHaxelib (library:String) {
		
		var proc = new Process ("haxelib", ["path", library ]);
		var result = "";
		
		try {
			
			while (true) {
				
				var line = proc.stdout.readLine ();
				
				if (line.substr (0,1) != "-") {
					
					result = line;
					
				}
				
			}
			
		} catch (e:Dynamic) { };
		
		proc.close();
		
		//trace("Found " + haxelib + " at " + srcDir );
		
		if (result == "") {
			
			throw ("Could not find haxelib path  " + library + " - perhaps you need to install it?");
			
		}
		
		return result;
		
	}
	
	
	public function getSourcePath (directoryName:String, filename:String):String {
		
		if (haxelib == "") {
			
			var path:String = getHaxelib ("hxcpp") + "/bin/" + directoryName + "/" + filename;
			
			if (FileSystem.exists (path)) {
				
				return path;
				
			} else {
				
				return filename;
				
			}
			
		} else {
			
			return getHaxelib (haxelib) + "/ndll/" + directoryName + "/" + filename;
			
		}
		
	}
	
	
}
