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
	
	
	/**
	 * Closes the application.
	 * This is method is ignored in the Flash and HTML5 targets.
	 */
	public static function close():Void
	{
		#if (cpp || neko)
		neash.Lib.close();
		#end
	}
	
	
	/**
	 * Creates a new application window. If you are using the NME
	 * command-line tools, this method will be called automatically
	 * as a part of the default platform templates.
	 * This is method is ignored in the Flash and HTML5 targets.
	 * @param	onLoaded		A method callback that is called once the window is created.
	 * @param	width		The requested width of the window. Use a width and height of 0 to request the full screen size.
	 * @param	height		The requested height of the window. Use a width and height of 0 to request the full screen size.
	 * @param	frameRate		The requested frame rate for the application.
	 * @param	color		An RGB color to use for the application background.
	 * @param	flags		A series of bit flags which can specify windowing options, like FULLSCREEN or HARDWARE
	 * @param	title		The title to use when creating the application window.
	 * @param	icon		An icon to use for the created application window.
	 */
	public static function create(onLoaded:Void->Void, width:Int, height:Int, frameRate:Float = 60.0, color:Int = 0xffffff, flags:Int = 0x0f, title:String = "NME", icon:BitmapData = null):Void
	{
		#if (cpp || neko)
		neash.Lib.create(onLoaded, width, height, frameRate, color, flags, title, icon);
		#end
	}
	
	
	/**
	 * Creates a managed stage, for greater control customization and control
	 * of application events.
	 * This method is ignored in the Flash and HTML5 targets.
	 * @param	width		The requested width of the managed stage.
	 * @param	height		The requested width of the managed stage.
	 */
	public static function createManagedStage(width:Int, height:Int)
	{
		#if (cpp || neko)
		return neash.Lib.createManagedStage(width, height);
		#end
		return null;
	}
	
	
	/**
	 * Similar to the <code>close()</code> method, but the current 
	 * <code>Stage</code> object is given an opportunity to handle 
	 * the quit event before the application process is ended.
	 * This method is ignored in the Flash and HTML5 targets.
	 */
	public static function exit():Void
	{
		#if (cpp || neko)
		neash.Lib.exit();
		#end
	}
	
	
	/**
	 * Terminates the application process immediately without
	 * performing a clean shutdown.
	 * This method is ignored in the Flash and HTML5 targets.
	 */
	public static function forceClose():Void
	{
		#if (cpp || neko)
		neash.Lib.forceClose();
		#end
	}
	
	
	/**
	 * Returns the time in milliseconds, relative to the start of
	 * the application. This is a high performance call in order to 
	 * help regulate time-based operations. Depending upon the
	 * target platform, this value may or may not be an absolute
	 * timestamp. If you need an exact time, you should use the
	 * <code>Date</code> object.
	 * @return		A relative time value in milliseconds.
	 */
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
	
	
	/**
	 * Opens a browser window with the specified URL. 
	 * @param	url		The URL to open.
	 * @param	target		An optional window target value.
	 */
	public static function getURL(url:URLRequest, target:String = null):Void
	{
		#if (cpp || neko)
		neash.Lib.getURL(url, target);
		#elseif js
		jeash.Lib.getURL(url, target);
		#else
		flash.Lib.getURL(url, target);
		#end
	}
	
	
	/**
	 * For some target platforms, NME operates on a separate thread
	 * than the native application UI. In these cases, you can use this
	 * method to make thread-safe calls to the native UI.
	 * 
	 * If the platform does not require thread-safe callbacks, the 
	 * handler method will be called immediately.
	 * @param	handler		The method handler you wish to call when the UI is available. 
	 */
	public static function postUICallback(handler:Void->Void)
	{
		#if (cpp || neko)
		neash.Lib.postUICallback(handler);
		#else
		handler();
		#end
	}
	
	
	/**
	 * Specifies meta-data for the running application. If you are using 
	 * the NME command-line tools, this method will be called automatically
	 * as a part of the default platform templates.
	 * This method is ignored in the Flash and HTML5 targets.
	 * @param	company		The company name for the application.
	 * @param	file		The file name for the application.
	 * @param	packageName		The package name of the application.
	 * @param	version		The version string of the application.
	 */
	public static function setPackage(company:String, file:String, packageName:String, version:String):Void
	{
		#if (cpp || neko)
		neash.Lib.setPackage(company, file, packageName, version);
		#end
	}
	
	
	/**
	 * Sends a <code>trace</code> call for the current platform.
	 * @param	arg
	 */
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