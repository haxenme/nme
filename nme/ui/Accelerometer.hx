package nme.ui;
#if display


extern class Accelerometer
{
	static function get():Acceleration;
}

#elseif (cpp || neko)
typedef Accelerometer = native.ui.Accelerometer;
#elseif js
typedef Accelerometer = browser.ui.Accelerometer;
#end