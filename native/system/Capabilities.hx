package native.system;


import native.Loader;


class Capabilities {
	
	
	public static var pixelAspectRatio (get_pixelAspectRatio, null):Float;
	public static var screenDPI (get_screenDPI, null):Float;
	public static var screenResolutionX (get_screenResolutionX, null):Float;
	public static var screenResolutionY (get_screenResolutionY, null):Float;
	public static var screenResolutions (get_screenResolutions, null):Array<Array<Int>>;
	public static var language (get_language, null):String;
	
	
	
	
	// Getters & Setters
	
	
	
	
	private static function get_pixelAspectRatio ():Float { return nme_capabilities_get_pixel_aspect_ratio (); }
	private static function get_screenDPI ():Float { return nme_capabilities_get_screen_dpi (); }
	private static function get_screenResolutionX ():Float { return nme_capabilities_get_screen_resolution_x (); }
	private static function get_screenResolutionY ():Float { return nme_capabilities_get_screen_resolution_y (); }
	
	
	private static function get_language ():String {
		
		var locale:String = nme_capabilities_get_language ();
		
		if (locale == null || locale == "" || locale == "C" || locale == "POSIX") {
			
			return "en-US";
			
		} else {
			
			var formattedLocale = "";
			var length = locale.length;
			
			if (length > 5) {
				
				length = 5;
				
			}
			
			for (i in 0...length) {
				
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
	
	
	private static function get_screenResolutions ():Array<Array<Int>> {
		
		var res:Array<Int> = nme_capabilities_get_screen_resolutions ();
		
		if (res == null) 
			return new Array<Array<Int>> ();
		
		var out = new Array<Array<Int>> ();
		
		for (c in 0...Std.int (res.length / 2)) {
			
			out.push ([ res[ c * 2 ], res[ c * 2 + 1 ] ]);
			
		}
		
		return out;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var nme_capabilities_get_pixel_aspect_ratio = Loader.load ("nme_capabilities_get_pixel_aspect_ratio", 0);
	private static var nme_capabilities_get_screen_dpi = Loader.load ("nme_capabilities_get_screen_dpi", 0);
	private static var nme_capabilities_get_screen_resolution_x = Loader.load ("nme_capabilities_get_screen_resolution_x", 0);
	private static var nme_capabilities_get_screen_resolution_y = Loader.load ("nme_capabilities_get_screen_resolution_y", 0);
	private static var nme_capabilities_get_screen_resolutions = Loader.load ("nme_capabilities_get_screen_resolutions", 0 );
	private static var nme_capabilities_get_language = Loader.load ("nme_capabilities_get_language", 0);
	
	
}