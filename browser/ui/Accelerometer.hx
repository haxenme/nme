package browser.ui;
#if js


import browser.display.Stage;


class Accelerometer {
	
	
	public static function get():Acceleration {
		
		return Stage.nmeAcceleration;
		
	}
	
	
}


#end