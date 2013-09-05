
import neko.Lib;
import sys.io.Process;


class Utils {
	
	
	private static var currentSeedNumber:Int = 0;

	
	
	public static function getHaxelib (library:String):String {
		
		var proc = new Process ("haxelib", ["path", library ]);
		var result = "";
		
		try {
			
			while (true) {
				
				var line = proc.stdout.readLine ();
				
				if (line.substr (0,1) != "-") {
					
					result = line;
					break;
					
				}
				
			}
			
		} catch (e:Dynamic) { };
		
		proc.close();
		
		//Lib.println ("Found " + library + " at " + result );
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
