#if emscripten
class ApplicationMain {
	
	public static function main () {
		
		trace ("hello from ApplicationMain");
		
		Reflect.callMethod (::APP_MAIN::, Reflect.field (::APP_MAIN::, "main"), []);
		
	}
	
}
#else



import nme.Assets;

#if (!macro || !haxe3)
class ApplicationMain
{

	#if waxe
	static public var frame : wx.Frame;
	static public var autoShowFrame : Bool = true;
	#if nme
	static public var nmeStage : wx.NMEStage;
	#end
	#end
	
	private static var barA:flash.display.Sprite;
	private static var barB:flash.display.Sprite;
	private static var container:flash.display.Sprite;
	private static var forceHeight:Int;
	private static var forceWidth:Int;
	
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
		
		nme.Lib.create(function()
			{ 
				//if ((::WIN_WIDTH:: == 0 && ::WIN_HEIGHT:: == 0) || ::WIN_FULLSCREEN::)
				//{
					nme.Lib.current.stage.align = nme.display.StageAlign.TOP_LEFT;
					nme.Lib.current.stage.scaleMode = nme.display.StageScaleMode.NO_SCALE;
					nme.Lib.current.loaderInfo = nme.display.LoaderInfo.create (null);
				//}
				
				#if mobile
				
				if (::WIN_WIDTH:: != 0 && ::WIN_HEIGHT:: != 0) {
					
					forceWidth = ::WIN_WIDTH::;
					forceHeight = ::WIN_HEIGHT::;
					
					container = new flash.display.Sprite();
					barA = new flash.display.Sprite();
					barB = new flash.display.Sprite();
					
					flash.Lib.current.stage.addChild (container);
					container.addChild (flash.Lib.current);
					container.addChild (barA);
					container.addChild (barB);
					
					applyScale();
					flash.Lib.current.stage.addEventListener (flash.events.Event.RESIZE, applyScale);
					
				}
				
				#end
				
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
					var instance = Type.createInstance(DocumentClass, []);
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
			::else::
			, null
			::end::
			::if (WIN_WIDTH != 0)::::if (WIN_HEIGHT != 0)::#if mobile
			, ScaledStage
			#end::end::::end::
		);
		#end
		
	}
	
	public static function applyScale(?_) {
		
		var xScale:Float = untyped(flash.Lib.current.stage).nmeStageWidth / forceWidth;
		var yScale:Float = untyped(flash.Lib.current.stage).nmeStageHeight / forceHeight;
		
		if ( xScale < yScale ) {
			
			flash.Lib.current.scaleX = xScale;
			flash.Lib.current.scaleY = xScale;
			flash.Lib.current.x = (untyped(flash.Lib.current.stage).nmeStageWidth - (forceWidth * xScale)) / 2;
			flash.Lib.current.y = (untyped(flash.Lib.current.stage).nmeStageHeight - (forceHeight * xScale)) / 2;
			
		} else {
			
			flash.Lib.current.scaleX = yScale;
			flash.Lib.current.scaleY = yScale;
			flash.Lib.current.x = (untyped(flash.Lib.current.stage).nmeStageWidth - (forceWidth * yScale)) / 2;
			flash.Lib.current.y = (untyped(flash.Lib.current.stage).nmeStageHeight - (forceHeight * yScale)) / 2;
			
		}
		
		if (flash.Lib.current.x > 0) {
			
			barA.graphics.clear();
			barA.graphics.beginFill (0x000000);
			barA.graphics.drawRect (0, 0, flash.Lib.current.x, untyped(flash.Lib.current.stage).nmeStageHeight);
			
			barB.graphics.clear();
			barB.graphics.beginFill (0x000000);
			var x = flash.Lib.current.x + (forceWidth * flash.Lib.current.scaleX);
			barB.graphics.drawRect (x, 0, untyped(flash.Lib.current.stage).nmeStageWidth - x, untyped(flash.Lib.current.stage).nmeStageHeight);
			
		} else {
			
			barA.graphics.clear();
			barA.graphics.beginFill (0x000000);
			barA.graphics.drawRect (0, 0, untyped(flash.Lib.current.stage).nmeStageWidth, flash.Lib.current.y);
			
			barB.graphics.clear();
			barB.graphics.beginFill (0x000000);
			var y = flash.Lib.current.y + (forceHeight * flash.Lib.current.scaleY);
			barB.graphics.drawRect (0, y, untyped(flash.Lib.current.stage).nmeStageWidth, untyped(flash.Lib.current.stage).nmeStageHeight - y);
			
		}
		
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


#if haxe3 @:build(DocumentClass.build()) #end
class DocumentClass extends ::APP_MAIN:: {}


::if (WIN_WIDTH != 0)::::if (WIN_HEIGHT != 0)::
#if mobile
class ScaledStage extends flash.display.Stage {
	
	
	public var nmeStageHeight(get, null):Int;
	public var nmeStageWidth(get, null):Int;
	
	
	public function new (inHandle:Dynamic, inWidth:Int, inHeight:Int) {
		
		super(inHandle, 0, 0);
		
	}
	
	
	private function get_nmeStageHeight():Int {
		return super.get_stageHeight();
	}
	
	private function get_nmeStageWidth():Int {
		return super.get_stageWidth();
	}
	
	
	private override function get_stageHeight():Int 
   {
      return ::WIN_HEIGHT::;
   }
	
   private override function get_stageWidth():Int 
   {
      return ::WIN_WIDTH::;
   }
	
}

#end
::end::::end::


#if haxe_211
typedef Hash<T> = haxe.ds.StringMap<T>;
#end

#else

import haxe.macro.Context;
import haxe.macro.Expr;

class DocumentClass {
	
	macro public static function build ():Array<Field> {
		var classType = Context.getLocalClass().get();
		var searchTypes = classType;
		while (searchTypes.superClass != null) {
			if (searchTypes.pack.length == 2 && searchTypes.pack[1] == "display" && searchTypes.name == "DisplayObject") {
				var fields = Context.getBuildFields();
				var method = macro {
					return nme.Lib.current.stage;
				}
				fields.push ({ name: "get_stage", access: [ APrivate, AOverride ], kind: FFun({ args: [], expr: method, params: [], ret: macro :nme.display.Stage }), pos: Context.currentPos() });
				return fields;
			}
			searchTypes = searchTypes.superClass.t.get();
		}
		return null;
	}
	
}
#end
#end