package neko.tls;

import sys.io.Process;

class Loader {
	
	public static function load( f : String, args : Int ) : Dynamic {
		var process = new Process("uname", ["-m"]);
		var ret = process.stdout.readAll().toString();
		process.exitCode(); //you need this to wait till the process is closed!
		process.close();
		
		if (ret.indexOf ("64") > -1) {
				
			return neko.Lib.load ("tls64", f, args);
			
		} else {
			
			return neko.Lib.load ("tls64", f, args);
			
		}
	}
	
}
