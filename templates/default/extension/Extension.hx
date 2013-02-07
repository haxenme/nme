package;

#if cpp
import cpp.Lib;
#elseif neko
import neko.Lib;
#end

class ::title:: {
	
	public static function sampleMethod (inputValue:Int):Int {
		
		return ::name::_sample_method(inputValue);
		
	}
	
	private static var ::name::_sample_method = Lib.load ("::title::", "::name::_sample_method", 1);
	
}