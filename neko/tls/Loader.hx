package neko.tls;

import sys.io.Process;

class Loader {
	
	public static function load( f : String, args : Int ) : Dynamic {
		
		if (neko.Lib.load("std","sys_is64",0)()) {
				
			return neko.Lib.load ("tls64", f, args);
			
		} else {
			
			return neko.Lib.load ("tls", f, args);
			
		}
	}
	
}
