
import neko.io.Process;


class Utils {
	
	
	private static var currentSeedNumber:Int = 0;
	private static var usedFlatNames:Hash <String> = new Hash <String> ();
	
	
	public static function generateFlatName (id:String):String {
		
		var chars:String = id.toLowerCase ();
		var flatName:String = "";
		
		for (i in 0...chars.length) {
			
			var code = chars.charCodeAt (i);
			
			if ((i > 0 && code >= "0".charCodeAt (0) && code <= "9".charCodeAt (0)) || (code >= "a".charCodeAt (0) && code <= "z".charCodeAt (0)) || (code == "_".charCodeAt (0))) {
				
				flatName += chars.charAt (i);
				
			} else {
				
				flatName += "_";
				
			}
			
		}
		
		if (flatName == "") {
			
			flatName = "_";
			
		}
		
		while (usedFlatNames.exists (flatName)) {
			
			flatName += "_";
		 
		}
		
		usedFlatNames.set (flatName, "1");
		
		return flatName;
		
	}
	
	
	public static function getHaxelib (library:String):String {
		
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
	
	
	public static function getUniqueID ():String {
		
		return StringTools.hex (currentSeedNumber++, 8);
		
   }
	
	
}