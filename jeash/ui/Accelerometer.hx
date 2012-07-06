package jeash.ui;

class Accelerometer
{
	public static function get():Acceleration {
		return jeash.display.Stage.jeashAcceleration;
	}
}