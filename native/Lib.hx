package native;


import haxe.Timer;
import native.display.BitmapData;
import native.display.ManagedStage;
import native.display.MovieClip;
import native.display.Stage;
import native.net.URLRequest;
import native.Lib;
import native.Loader;

#if cpp
import cpp.Sys;
#else
import neko.Sys;
#end


class Lib {
	
	
	static public var FULLSCREEN      = 0x0001;
	static public var BORDERLESS      = 0x0002;
	static public var RESIZABLE       = 0x0004;
	static public var HARDWARE        = 0x0008;
	static public var VSYNC           = 0x0010;
	static public var HW_AA           = 0x0020;
	static public var HW_AA_HIRES     = 0x0060;
	static public var ALLOW_SHADERS   = 0x0080;
	static public var REQUIRE_SHADERS = 0x0100;
	static public var DEPTH_BUFFER    = 0x0200;
	static public var STENCIL_BUFFER  = 0x0400;

	public static var current(get_current, null):MovieClip;
	public static var initHeight(default, null):Int;
	public static var initWidth(default, null):Int;
	public static var stage(get_stage, null):Stage;

	private static var nmeCurrent:MovieClip = null;
	private static var nmeMainFrame:Dynamic = null;
	private static var nmeStage:Stage = null;
	private static var sIsInit = false;

	static public var company(default,null):String;
	static public var version(default,null):String;
	static public var packageName(default,null):String;
	static public var file(default,null):String;
	
	
	public static function close () {
		
		var close = Loader.load ("nme_close", 0);
		close ();
		
	}
	
	
	public static function create (inOnLoaded:Void->Void, inWidth:Int, inHeight:Int, inFrameRate:Float = 60.0, inColour:Int = 0xffffff, inFlags:Int = 0x0f, inTitle:String = "NME", ?inIcon:BitmapData) {
		
		if (sIsInit) {
			
			throw ("nme.Lib.create called multiple times. This function is automatically called by the project code.");
			
		}
		
		sIsInit = true;
		initWidth = inWidth;
		initHeight = inHeight;
		
		var create_main_frame = Loader.load ("nme_create_main_frame", -1);
		
		create_main_frame (function (inFrameHandle:Dynamic) {
			
			#if android try { #end
			nmeMainFrame = inFrameHandle;
			var stage_handle = nme_get_frame_stage (nmeMainFrame);
			
			Lib.nmeStage = new Stage (stage_handle, inWidth, inHeight);
			Lib.nmeStage.frameRate = inFrameRate;
			Lib.nmeStage.opaqueBackground = inColour;
			Lib.nmeStage.onQuit = close;
			
			if (nmeCurrent != null) // Already created...
				Lib.nmeStage.addChild (nmeCurrent);
			
			inOnLoaded ();
			#if android } catch (e:Dynamic) { trace("ERROR: " +  e); } #end
			
		},
		inWidth, inHeight, inFlags, inTitle, inIcon == null ? null : inIcon.nmeHandle);
		
	}
	
	
	public static function createManagedStage (inWidth:Int, inHeight:Int, inFlags:Int = 0) {
		
		initWidth = inWidth;
		initHeight = inHeight;
		
		var result = new ManagedStage (inWidth, inHeight, inFlags);
		nmeStage = result;
		
		return result;
		
	}
   
   
	public static function exit () {
		
		var quit = stage.onQuit;
		
		if (quit != null) {
			
			#if android
			if (quit == close) {
				
				Sys.exit (0);
				
			}
			#end
			
			quit ();
			
		}
		
	}
	
	
	public static function forceClose () {
		
		// Terminates the process straight away, bypassing graceful shutdown
		var terminate = Loader.load ("nme_terminate", 0);
		terminate ();
		
	}
	
	
	static public function getTimer ():Int {
		
		// Be careful not to blow precision, since storing ms since 1970 can overflow...
		return Std.int (Timer.stamp () * 1000.0);
		
	}
	
	
	public static function getURL (url:URLRequest, ?target:String):Void {
		
		nme_get_url (url.url);
		
	}
   
   
   /** @private */ public static function nmeSetCurrentStage (inStage:Stage) {
	   
		nmeStage = inStage;
		
	}
	
	
	public static function pause () {
		
		nme_pause_animation ();
		
	}
	
	
	public static function postUICallback (inCallback:Void->Void) {
		
		#if android
		nme_post_ui_callback (inCallback);
		#else
		// May still be worth posting event to come back with the next UI event loop...
		//  (or use timer?)
		inCallback ();
		#end
		
	}
	
	
	public static function resume () {
		
		nme_resume_animation ();
		
	}
   
	
	// Is this still used?
	//static public function setAssetBase(inBase:String)
	//{
	  //nme_set_asset_base(inBase);
	//}
	//private static var nme_set_asset_base = Loader.load("nme_set_asset_base", 1);
   
   
	public static function setIcon (path:String) {
		
		//Useful only on SDL platforms. Sets the title bar's icon, based on the path given.
		var set_icon = Loader.load ("nme_set_icon", 1);
		set_icon (path);
		
	}
	
	
	public static function setPackage (inCompany:String, inFile:String, inPack:String, inVersion:String) {
		
		company = inCompany;
		file = inFile;
		packageName = inPack;
		version = inVersion;
		
		nme_set_package (inCompany, inFile, inPack, inVersion);
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	static function get_current ():MovieClip {
		
		if (nmeCurrent == null) {
			
			nmeCurrent = new MovieClip ();
			
			if (nmeStage != null)
				nmeStage.addChild (nmeCurrent);
			
		}
		
		return nmeCurrent;
		
	}
	
	
	private static function get_stage () {
		
		if (nmeStage == null)
			throw ("Error : stage can't be accessed until init is called");
		
		return nmeStage;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if android
	private static var nme_post_ui_callback = Loader.load ("nme_post_ui_callback", 1);
	#end
	private static var nme_set_package = Loader.load ("nme_set_package", 4);
	private static var nme_get_frame_stage = Loader.load ("nme_get_frame_stage", 1);
	private static var nme_get_url = Loader.load ("nme_get_url", 1);
	private static var nme_pause_animation = Loader.load ("nme_pause_animation", 0);
	private static var nme_resume_animation = Loader.load ("nme_resume_animation", 0);
	
	
}