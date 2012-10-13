package;


import neko.Lib;
import nme.Loader;


class LogHelper {
	
	
	public static var mute:Bool;
	public static var verbose:Bool = false;
	
	
	public static function error (message:String, verboseMessage:String = "", e:Dynamic = null):Void {
		
		if (message != "") {
			
			try {
				
				if (verbose && verboseMessage != "") {
					
					nme_error_output ("Error: " + verboseMessage + "\n");
					
				} else {
					
					nme_error_output ("Error: " + message + "\n");
					
				}
				
			} catch (e:Dynamic) {}
			
		}
		
		if (verbose && e != null) {
			
			Lib.rethrow (e);
			
		}
		
		Sys.exit (1);
		
	}
	
	
	public static function info (message:String, verboseMessage:String = ""):Void {
		
		if (verbose && verboseMessage != "") {
			
			Sys.println (verboseMessage);
			
		} else if (message != "") {
			
			Sys.println (message);
			
		}
		
	}
	
	
	public static function warn (message:String, verboseMessage:String = ""):Void {
		
		if (verbose && verboseMessage != "") {
			
			Sys.println ("Warning: " + verboseMessage);
			
		} else if (message != "") {
			
			Sys.println ("Warning: " + message);
			
		}
		
	}
	
	
	private static var nme_error_output = Loader.load ("nme_error_output", 1);
		

}
