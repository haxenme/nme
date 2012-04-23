package nme.feedback;
#if code_completion


extern class Haptic
{
	static function vibrate(period:Int = 0, duration:Int = 1000):Void;
}


#elseif (cpp || neko)
typedef Haptic = neash.feedback.Haptic;
#end