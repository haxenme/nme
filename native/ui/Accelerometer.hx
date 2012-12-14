package native.ui;


import native.Loader;


class Accelerometer {
	
	
	public static function get ():Acceleration {
		
		// returns null if device not supported
		return nme_input_get_acceleration ();
		
	}
	
	
	private static var nme_input_get_acceleration = Loader.load ("nme_input_get_acceleration", 0);
	
	
}