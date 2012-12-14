package nme;
#if display


extern class Loader
{
	static function load(func:String, args:Int):Dynamic;
	static function loaderTrace(inStr:String):Void;
	static function tryLoad(inName:String, func:String, args:Int):Dynamic;
}


#elseif (cpp || neko)
typedef Loader = native.Loader;
#end
