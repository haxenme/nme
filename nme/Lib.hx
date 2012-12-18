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
	public static var ALLOW_SHADERS = 0x0080;
	public static var REQUIRE_SHADERS = 0x0100;
	public static var DEPTH_BUFFER = 0x0200;
	public static var STENCIL_BUFFER = 0x0400;
	
	#if flash
	public static var MIN_FLOAT_VALUE:Float = untyped __global__ ["Number"].MIN_VALUE;
	public static var MAX_FLOAT_VALUE:Float = untyped __global__ ["Number"].MAX_VALUE;
	#elseif js
	public static var MIN_FLOAT_VALUE:Float = untyped __js__ ("Number.MIN_VALUE");
	public static var MAX_FLOAT_VALUE:Float = untyped __js__ ("Number.MAX_VALUE");
	#else
    public static inline var MIN_FLOAT_VALUE:Float = 2.2250738585072014e-308;
    public static inline var MAX_FLOAT_VALUE:Float = 1.7976931348623158e+308;
	#end
	
	public static var company (get_company, null):String;
	public static var current (get_current, null):MovieClip;
	public static var file (get_file, null):String;
	public static var initHeight (get_initHeight, null):Int;
	public static var initWidth (get_initWidth, null):Int;
	public static var packageName (get_packageName, null):String;
	public static var stage (get_stage, null):Stage;
	public static var version (get_version, null):String;
	
	
	/**
	 * Closes the application.
	 * This is method is ignored in the Flash and HTML5 targets.
	 */
	public static function close():Void
	{
		#if display
		#elseif (cpp || neko)
		native.Lib.close();
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
		#if display
		#elseif (cpp || neko)
		native.Lib.create(onLoaded, width, height, frameRate, color, flags, title, icon);
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
		#if display
		#elseif (cpp || neko)
		return native.Lib.createManagedStage(width, height);
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
		#if display
		#elseif (cpp || neko)
		native.Lib.exit();
		#end
	}
	
	
	/**
	 * Terminates the application process immediately without
	 * performing a clean shutdown.
	 * This method is ignored in the Flash and HTML5 targets.
	 */
	public static function forceClose():Void
	{
		#if display
		#elseif (cpp || neko)
		native.Lib.forceClose();
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
		#if display
		return 0;
		#elseif (cpp || neko)
		return native.Lib.getTimer();
		#elseif js
		return browser.Lib.getTimer();
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
		#if display
		#elseif (cpp || neko)
		native.Lib.getURL(url, target);
		#elseif js
		browser.Lib.getURL(url, target);
		#else
		flash.Lib.getURL(url, target);
		#end
	}
	
	
	/**
	 * For supported platforms, the NME application will be
	 * paused. This can help improve response times if fullscreen
	 * native UI element is being used temporarily.
	 * This method is ignored in the Flash and HTML5 targets.
	 */
	public static function pause():Void
	{
		#if display
		#elseif (cpp || neko)
		native.Lib.pause();
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
		#if display
		#elseif (cpp || neko)
		native.Lib.postUICallback(handler);
		#else
		handler();
		#end
	}
	
	
	/**
	 * Resumes the NME application. For certain platforms,
	 * pausing the application can improve response times when
	 * a fullscreen native UI element is being displayed.
	 * This method is ignored in the Flash and HTML5 targets.
	 */
	public static function resume():Void
	{
		#if display
		#elseif (cpp || neko)
		native.Lib.resume();
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
		#if display
		#elseif (cpp || neko)
		native.Lib.setPackage(company, file, packageName, version);
		#end
	}
	
	
	/**
	 * Sends a <code>trace</code> call for the current platform.
	 * @param	arg
	 */
	public static function trace(arg:Dynamic):Void
	{
		#if display
		#elseif (cpp || neko)
		trace(arg);
		#elseif js
		browser.Lib.trace(arg);
		#else
		flash.Lib.trace(arg);
		#end
	}
	
	
	
	
	// Getters & Setters
	
	
	
	private static function get_company():String
	{
		#if display
		#elseif (cpp || neko)
		return native.Lib.company;
		#end
		return "";
	}
	
	
	private static function get_current ():MovieClip
	{
		#if display
		return null;
		#elseif (cpp || neko)
		return cast native.Lib.current;
		#elseif js
		return cast browser.Lib.current;
		#else
		return cast flash.Lib.current;
		#end	
	}
	
	
	private static function get_file():String
	{
		#if display
		#elseif (cpp || neko)
		return native.Lib.file;
		#end
		return "";
	}
	
	
	private static function get_initHeight():Int
	{
		#if display
		#elseif (cpp || neko)
		return native.Lib.initHeight;
		#end
		return 0;
	}
	
	
	private static function get_initWidth():Int
	{
		#if display
		#elseif (cpp || neko)
		return native.Lib.initWidth;
		#end
		return 0;
	}
	
	
	private static function get_packageName():String
	{
		#if display
		#elseif (cpp || neko)
		return native.Lib.packageName;
		#end
		return "";
	}
	
	
	private static function get_stage():Stage
	{
		#if display
		return null;
		#elseif (cpp || neko)
		return cast native.Lib.stage;
		#else
		return current.stage;
		#end
	}
	
	
	private static function get_version():String
	{
		#if display
		#elseif (cpp || neko)
		return native.Lib.version;
		#end
		return "";
	}
	
}
