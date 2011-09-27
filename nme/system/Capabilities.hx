package nme.system;
#if (cpp || neko)


import nme.Loader;


/**
 * ...
 * @author Joshua Granick
 */
class Capabilities {

	
	public static var pixelAspectRatio (nmeGetPixelAspectRatio, null):Float;
	public static var screenDPI (nmeGetScreenDPI, null):Float;
	public static var screenResolutionX (nmeGetScreenResolutionX, null):Float;
	public static var screenResolutionY (nmeGetScreenResolutionY, null):Float;
	
	
	private static function nmeGetPixelAspectRatio ():Float {
		
		return nme_capabilities_get_pixel_aspect_ratio ();
		
	}
	
	
	private static function nmeGetScreenDPI ():Float {
		
		return nme_capabilities_get_screen_dpi ();
		
	}
	
	
	private static function nmeGetScreenResolutionX ():Float {
		
		return nme_capabilities_get_screen_resolution_x ();
		
	}
	
	
	private static function nmeGetScreenResolutionY ():Float {
		
		return nme_capabilities_get_screen_resolution_y ();
		
	}
	
	
	static var nme_capabilities_get_pixel_aspect_ratio = Loader.load ("nme_capabilities_get_pixel_aspect_ratio", 0);
	static var nme_capabilities_get_screen_dpi = Loader.load ("nme_capabilities_get_screen_dpi", 0);
	static var nme_capabilities_get_screen_resolution_x = Loader.load ("nme_capabilities_get_screen_resolution_x", 0);
	static var nme_capabilities_get_screen_resolution_y = Loader.load ("nme_capabilities_get_screen_resolution_y", 0);
	
	
}


#else
typedef Capabilities = flash.system.Capabilities;
#end