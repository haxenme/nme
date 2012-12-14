package nme.feedback;
#if display


extern class Haptic
{
	static function vibrate(period:Int = 0, duration:Int = 1000):Void;
}


#elseif (cpp || neko)
typedef Haptic = native.feedback.Haptic;
#end
