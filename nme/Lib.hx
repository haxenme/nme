package nme;
#if code_completion


extern class Lib
{
	static var FULLSCREEN;
	static var BORDERLESS;
	static var RESIZABLE;
	static var HARDWARE;
	static var VSYNC;
	static var HW_AA;
	static var HW_AA_HIRES;
	
	static var current(nmeGetCurrent, null):nme.display.MovieClip;
	static var initHeight(default, null):Int;
	static var initWidth(default, null):Int;
	static var stage(nmeGetStage, null):nme.display.Stage;
	
	static var company(default,null):String;
	static var version(default,null):String;
	static var packageName(default,null):String;
	static var file(default,null):String;
	
	static function close():Void;
	static function create(inOnLoaded:Void->Void, inWidth:Int, inHeight:Int, inFrameRate:Float = 60.0,  inColour:Int = 0xffffff, inFlags:Int = 0x0f, inTitle:String = "NME", ?inIcon:nme.display.BitmapData):Void;
	static function createManagedStage(inWidth:Int, inHeight:Int):nme.display.ManagedStage;
	static function exit():Void;
	static function forceClose():Void;
	static function getTimer():Int;
	static function getURL (url:nme.net.URLRequest, ?target:String):Void;
	static function postUICallback(inCallback:Void->Void):Void;
	static function setIcon(path:String):Void;
	static function setPackage(inCompany:String, inFile:String, inPack:String, inVersion:String):Void;
}


#elseif (cpp || neko)
typedef Lib = neash.Lib;
#elseif js
typedef Lib = jeash.Lib;
#else
typedef Lib = flash.Lib;
#end
