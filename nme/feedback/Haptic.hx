package nme.feedback;


/**
 * Creates tactile feedback, where supported
 * @author Joshua Granick
 */
class Haptic {

	
	/**
	 * Causes the target device to vibrate. Ignored if the device or platform does not support this feature
	 * @param	period		Controls the vibration frequency. A higher value will result in more "gaps" between vibrations (0-1000) 
	 * @param	duration	The length of the vibration in milliseconds
	 */
	public static function vibrate (period:Int = 0, duration:Int = 1000):Void {
		
		#if cpp
		nme_haptic_vibrate (period, duration);
		#end
		
	}
	
	
	#if cpp
	static var nme_haptic_vibrate = Loader.load ("nme_haptic_vibrate", 2);
	#end
	
	
}