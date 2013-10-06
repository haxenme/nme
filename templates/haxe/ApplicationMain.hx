import nme.Assets;

class ApplicationMain
{

	#if waxe
	static public var frame : wx.Frame;
	static public var autoShowFrame : Bool = true;
	#if nme
	static public var nmeStage : wx.NMEStage;
	#end
	#end
	
	public static function main()
	{
		#if nme
		nme.Lib.setPackage("::APP_COMPANY::", "::APP_FILE::", "::APP_PACKAGE::", "::APP_VERSION::");
		::if (sslCaCert != "")::
		nme.net.URLLoader.initialize(nme.installer.Assets.getResourceName("::sslCaCert::"));
		::end::
		#end
		
		#if waxe
		wx.App.boot(function()
		{
			::if (APP_FRAME != null)::
			frame = wx.::APP_FRAME::.create(null, null, "::APP_TITLE::", null, { width: ::WIN_WIDTH::, height: ::WIN_HEIGHT:: });
			::else::
			frame = wx.Frame.create(null, null, "::APP_TITLE::", null, { width: ::WIN_WIDTH::, height: ::WIN_HEIGHT:: });
			::end::
			#if nme
			var stage = wx.NMEStage.create(frame, null, null, { width: ::WIN_WIDTH::, height: ::WIN_HEIGHT:: });
			#end
			
			::APP_MAIN::.main();
			
			if (autoShowFrame)
			{
				wx.App.setTopWindow(frame);
				frame.shown = true;
			}
		});
		#else
		
		#if ios	
		nme.display.Stage.shouldRotateInterface = function(orientation:Int):Bool
		{
			::if (WIN_ORIENTATION == "portrait")::
			if (orientation == nme.display.Stage.OrientationPortrait || orientation == nme.display.Stage.OrientationPortraitUpsideDown)
			{
				return true;
			}
			return false;
			::elseif (WIN_ORIENTATION == "landscape")::
			if (orientation == nme.display.Stage.OrientationLandscapeLeft || orientation == nme.display.Stage.OrientationLandscapeRight)
			{
				return true;
			}
			return false;
			::else::
			return true;
			::end::
		}
		#end
		
		nme.Lib.create(function()
			{ 
				//if ((::WIN_WIDTH:: == 0 && ::WIN_HEIGHT:: == 0) || ::WIN_FULLSCREEN::)
				//{
					nme.Lib.current.stage.align = nme.display.StageAlign.TOP_LEFT;
					nme.Lib.current.stage.scaleMode = nme.display.StageScaleMode.NO_SCALE;
					nme.Lib.current.loaderInfo = nme.display.LoaderInfo.create (null);
				//}
				
				var hasMain = false;
				
				for (methodName in Type.getClassFields(::APP_MAIN::))
				{
					if (methodName == "main")
					{
						hasMain = true;
						break;
					}
				}
				
				if (hasMain)
				{
					Reflect.callMethod (::APP_MAIN::, Reflect.field (::APP_MAIN::, "main"), []);
				}
				else
				{
					var instance = Type.createInstance(::APP_MAIN::, []);
					#if nme
					if (Std.is (instance, nme.display.DisplayObject)) {
						nme.Lib.current.addChild(cast instance);
					}
					#end
				}
			},
			::WIN_WIDTH::, ::WIN_HEIGHT::, 
			::WIN_FPS::, 
			::WIN_BACKGROUND::,
			(::WIN_HARDWARE:: ? nme.Lib.HARDWARE : 0) |
			(::WIN_ALLOW_SHADERS:: ? nme.Lib.ALLOW_SHADERS : 0) |
			(::WIN_REQUIRE_SHADERS:: ? nme.Lib.REQUIRE_SHADERS : 0) |
			(::WIN_DEPTH_BUFFER:: ? nme.Lib.DEPTH_BUFFER : 0) |
			(::WIN_STENCIL_BUFFER:: ? nme.Lib.STENCIL_BUFFER : 0) |
			(::WIN_RESIZABLE:: ? nme.Lib.RESIZABLE : 0) |
			(::WIN_BORDERLESS:: ? nme.Lib.BORDERLESS : 0) |
			(::WIN_VSYNC:: ? nme.Lib.VSYNC : 0) |
			(::WIN_FULLSCREEN:: ? nme.Lib.FULLSCREEN : 0) |
			(::WIN_ANTIALIASING:: == 4 ? nme.Lib.HW_AA_HIRES : 0) |
			(::WIN_ANTIALIASING:: == 2 ? nme.Lib.HW_AA : 0),
			"::APP_TITLE::"
			::if (WIN_ICON!=null)::
			, getAsset("::WIN_ICON::")
			::end::
		);
		#end
		
	}

   public static function getAsset(inName:String) : Dynamic
   {
      var types = Assets.type;
      if (types.exists(inName))
         switch(types.get(inName))
         {
 	         case BINARY, TEXT: return Assets.getBytes(inName);
	         case FONT: return Assets.getFont(inName);
	         case IMAGE: return Assets.getBitmapData(inName,false);
	         case MUSIC, SOUND: return Assets.getSound(inName);
         }

      throw "Asset does not exist: " + inName;
      return null;
   }
	
	
	#if neko
	public static function __init__ () {
		
		untyped $loader.path = $array ("@executable_path/", $loader.path);
		
	}
	#end
	
	
}


#if haxe_211
typedef Hash<T> = haxe.ds.StringMap<T>;
#end
