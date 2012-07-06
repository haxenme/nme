package nme;


import nme.display.BitmapData;
import nme.display.MovieClip;
import nme.display.Stage;
import nme.net.URLRequest;


class Lib
{	
	
	public static var FULLSCREEN = 0x0001;
	public static var BORDERLESS = 0x0002;
	public static var RESIZABLE = 0x0004;
	public static var HARDWARE = 0x0008;
	public static var VSYNC = 0x0010;
	public static var HW_AA = 0x0020;
	public static var HW_AA_HIRES = 0x0060;
	
	public static var company(nmeGetCompany, null):String;
	public static var current (nmeGetCurrent, null):MovieClip;
	public static var file(nmeGetFile, null):String;
	public static var initHeight(nmeGetInitHeight, null):Int;
	public static var initWidth(nmeGetInitWidth, null):Int;
	public static var packageName(nmeGetPackageName, null):String;
	public static var stage(nmeGetStage, null):Stage;
	public static var version(nmeGetVersion, null):String;
	
	
	public static function close():Void
	{
		#if (cpp || neko)
		neash.Lib.close();
		#end
	}
	
	
	public static function create(inOnLoaded:Void->Void, inWidth:Int, inHeight:Int, inFrameRate:Float = 60.0,  inColour:Int = 0xffffff, inFlags:Int = 0x0f, inTitle:String = "NME", ?inIcon:BitmapData):Void
	{
		#if (cpp || neko)
		neash.Lib.create(inOnLoaded, inWidth, inHeight, inFrameRate, inColour, inFlags, inTitle, inIcon);
		#end
	}
	
	
	public static function createManagedStage(inWidth:Int, inHeight:Int):Void
	{
		#if (cpp || neko)
		neash.Lib.createManagedStage(inWidth, inHeight);
		#end
	}
	
	
	public static function exit():Void
	{
		#if (cpp || neko)
		neash.Lib.exit();
		#end
	}
	
	
	public static function forceClose():Void
	{
		#if (cpp || neko)
		neash.Lib.forceClose();
		#end
	}
	
	
	public inline static function getTimer():Int
	{
		#if (cpp || neko)
		return neash.Lib.getTimer();
		#elseif js
		return jeash.Lib.getTimer();
		#else
		return flash.Lib.getTimer();
		#end
	}
	
	
	public static function getURL(url:URLRequest, ?target:String):Void
	{
		#if (cpp || neko)
		neash.Lib.getURL(url, target);
		#elseif js
		jeash.Lib.getURL(url, target);
		#else
		flash.Lib.getURL(url, target);
		#end
	}
	
	
	public static function postUICallback(inCallback:Void->Void)
	{
		#if (cpp || neko)
		neash.Lib.postUICallback(inCallback);
		#end
	}
	
	
	public static function setPackage(inCompany:String, inFile:String, inPack:String, inVersion:String):Void
	{
		#if (cpp || neko)
		neash.Lib.setPackage(inCompany, inFile, inPack, inVersion);
		#end
	}
	
	
	public static function trace(arg:Dynamic):Void
	{
		#if (cpp || neko)
		trace(arg);
		#elseif js
		jeash.Lib.trace(arg);
		#else
		flash.Lib.trace(arg);
		#end
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	private static function nmeGetCompany():String
	{
		#if (cpp || neko)
		return neash.Lib.company;
		#else
		return "";
		#end
	}
	
	
	private static function nmeGetCurrent ():MovieClip
	{	
		#if (cpp || neko)
		return neash.Lib.current;
		#elseif js
		return jeash.Lib.current;
		#else
		return flash.Lib.current;
		#end	
	}
	
	
	private static function nmeGetFile():String
	{
		#if (cpp || neko)
		return neash.Lib.file;
		#else
		return "";
		#end
	}
	
	
	private static function nmeGetInitHeight():Int
	{
		#if (cpp || neko)
		return neash.Lib.initHeight;
		#else
		return 0;
		#end
	}
	
	
	private static function nmeGetInitWidth():Int
	{
		#if (cpp || neko)
		return neash.Lib.initWidth;
		#else
		return 0;
		#end
	}
	
	
	private static function nmeGetPackageName():String
	{
		#if (cpp || neko)
		return neash.Lib.packageName;
		#else
		return "";
		#end
	}
	
	
	private static function nmeGetStage():Stage
	{
		#if (cpp || neko)
		return neash.Lib.stage;
		#else
		return current.stage;
		#end
	}
	
	
	private static function nmeGetVersion():String
	{
		#if (cpp || neko)
		return neash.Lib.version;
		#else
		return "";
		#end
	}
	
}