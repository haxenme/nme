package browser.ui;


import browser.display.Stage;


class Accelerometer {
	
	
	public static function get ():Acceleration {
		
		return Stage.nmeAcceleration;
		
	}
	
	
}