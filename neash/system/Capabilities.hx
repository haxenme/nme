package neash.system;


import neash.Loader;


/**
 * ...
 * @author Joshua Granick
 */
class Capabilities
{
	
	public static var pixelAspectRatio(nmeGetPixelAspectRatio, null):Float;
	public static var screenDPI(nmeGetScreenDPI, null):Float;
	public static var screenResolutionX(nmeGetScreenResolutionX, null):Float;
	public static var screenResolutionY(nmeGetScreenResolutionY, null):Float;
	public static var screenResolutions(nmeGetScreenResolutions, null):Array<Array<Int>>;
	public static var language(nmeGetLanguage, null):String;
	
	
	// Getters & Setters
	
	
	
	/** @private */ private static function nmeGetPixelAspectRatio():Float { return nme_capabilities_get_pixel_aspect_ratio(); }
	/** @private */ private static function nmeGetScreenDPI():Float { return nme_capabilities_get_screen_dpi(); }
	/** @private */ private static function nmeGetScreenResolutionX():Float { return nme_capabilities_get_screen_resolution_x(); }
	/** @private */ private static function nmeGetScreenResolutionY():Float { return nme_capabilities_get_screen_resolution_y(); }
	
	
	/** @private */ private static function nmeGetLanguage():String
	{
		var locale:String = nme_capabilities_get_language();
		
		if (locale == null || locale == "" || locale == "C" || locale == "POSIX") {
			
			return "en-US";
			
		} else {
			
			var formattedLocale = "";
			var length = locale.length;
			
			if (length > 5) {
				
				length = 5;
				
			}
			
			for (i in length) {
				
				var char = locale.charAt (i);
				
				if (i < 2) {
					
					formattedLocale += char.toLowerCase ();
					
				} else if (i == 2) {
					
					formattedLocale += "-";
					
				} else {
					
					formattedLocale += char.toUpperCase ();
					
				}
				
			}
			
			return formattedLocale;
			
		}
		
	}
	
	
	/** @private */ private static function nmeGetScreenResolutions():Array<Array<Int>>
	{
		var res:Array<Int> = nme_capabilities_get_screen_resolutions();
		
		if (res == null) 
			return new Array<Array<Int>>();
		
		var out:Array<Array<Int>> = new Array<Array<Int>>();
		
		for (c in 0...Std.int(res.length / 2))
		{
			out.push( [ res[ c * 2 ], res[ c * 2 + 1 ] ] );
		}
		
		return out;
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_capabilities_get_pixel_aspect_ratio = Loader.load("nme_capabilities_get_pixel_aspect_ratio", 0);
	private static var nme_capabilities_get_screen_dpi = Loader.load("nme_capabilities_get_screen_dpi", 0);
	private static var nme_capabilities_get_screen_resolution_x = Loader.load("nme_capabilities_get_screen_resolution_x", 0);
	private static var nme_capabilities_get_screen_resolution_y = Loader.load("nme_capabilities_get_screen_resolution_y", 0);
	private static var nme_capabilities_get_screen_resolutions = Loader.load("nme_capabilities_get_screen_resolutions", 0 );
	private static var nme_capabilities_get_language = Loader.load("nme_capabilities_get_language", 0);
	
}