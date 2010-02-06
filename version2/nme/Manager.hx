package nme2;

class Manager
{
	static public var FULLSCREEN = 0x0001;
	static public var BORDERLESS = 0x0002;
	static public var RESIZABLE  = 0x0004;
	static public var HARDWARE   = 0x0008;
	static public var VSYNC      = 0x0010;

   static var mMainFrame: Dynamic;
   public static var stage(default,null): nme2.display.Stage;


   public static function init(inWidth:Int, inHeight:Int, inFlags:Int = 0x0f,
                       inTitle:String = "NME", inIcon : String="")
	{
		var create_main_frame = nme2.Loader.load("nme_create_main_frame",5);
		mMainFrame = create_main_frame(inWidth,inHeight,inFlags,inTitle,inIcon);
		var stage_handle = nme_get_frame_stage(mMainFrame);
		stage = new nme2.display.Stage(stage_handle);
		stage.onQuit = close;
	}

	public static function mainLoop()
	{
		var main_loop = nme2.Loader.load("nme_main_loop",0);
		main_loop();
	}

	public static function close()
	{
		var close = nme2.Loader.load("nme_close",0);
		close();
	}

	public static function pollTimers()
	{
	}


	static var nme_get_frame_stage = nme2.Loader.load("nme_get_frame_stage",1);
}


