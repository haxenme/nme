package nme;
#if (cpp || neko)


import haxe.Timer;
import nme.display.BitmapData;
import nme.display.ManagedStage;
import nme.display.MovieClip;
import nme.display.Stage;
import nme.net.URLRequest;
import nme.Lib;
import nme.Loader;

#if cpp
import cpp.Sys;
#else
import neko.Sys;
#end


class Lib
{
	
	static public var FULLSCREEN = 0x0001;
	static public var BORDERLESS = 0x0002;
	static public var RESIZABLE = 0x0004;
	static public var HARDWARE = 0x0008;
	static public var VSYNC = 0x0010;
	static public var HW_AA = 0x0020;
	static public var HW_AA_HIRES = 0x0060;
	
	public static var current(nmeGetCurrent, null):MovieClip;
	public static var initHeight(default, null):Int;
	public static var initWidth(default, null):Int;
	public static var stage(nmeGetStage, null):Stage;
	
	private static var nmeCurrent:MovieClip = null;
	private static var nmeMainFrame:Dynamic = null;
	private static var nmeStage:Stage = null;
	private static var sIsInit = false;

	static public var company(default,null):String;
	static public var version(default,null):String;
	static public var packageName(default,null):String;
	static public var file(default,null):String;
	
	public static function close()
	{
		var close = Loader.load("nme_close", 0);
		close();
	}
	
	
	public static function create(inOnLoaded:Void->Void, inWidth:Int, inHeight:Int, inFrameRate:Float = 60.0,  inColour:Int = 0xffffff, inFlags:Int = 0x0f, inTitle:String = "NME", ?inIcon:BitmapData)
	{
		if (sIsInit)
		{
			throw("nme.Lib.create called multiple times. This function is automatically called by the project code.");
		}
		sIsInit = true;
		initWidth = inWidth;
		initHeight = inHeight;
		var create_main_frame = Loader.load("nme_create_main_frame", -1);
		create_main_frame(
			function(inFrameHandle:Dynamic) {
				#if android try { #end
				nmeMainFrame = inFrameHandle;
				var stage_handle = nme_get_frame_stage(nmeMainFrame);
				Lib.nmeStage = new Stage(stage_handle, inWidth, inHeight);
				Lib.nmeStage.frameRate = inFrameRate;
				Lib.nmeStage.opaqueBackground = inColour;
				Lib.nmeStage.onQuit = close;
				if (nmeCurrent != null) // Already created...
					Lib.nmeStage.addChild(nmeCurrent);
				inOnLoaded();
				#if android } catch (e:Dynamic) { trace("ERROR: " +  e); } #end
			},
			inWidth, inHeight, inFlags, inTitle, inIcon == null?null:inIcon.nmeHandle);
	}


	public static function createManagedStage(inWidth:Int, inHeight:Int)
	{
		initWidth = inWidth;
		initHeight = inHeight;
		var result = new ManagedStage(inWidth, inHeight);
		nmeStage = result;
		return result;
	}
	
	
	public static function exit()
	{
		var quit = stage.onQuit;
		if (quit != null)
		{
			#if android
			if (quit == close)
			{
				Sys.exit (0);
			}
			#end
			quit();
		}
	}
	
	
	public static function forceClose()
	{
		// Terminates the process straight away, bypassing graceful shutdown
		var terminate = Loader.load("nme_terminate", 0);
		terminate();
	}
	
	
	static public function getTimer():Int
	{
		// Be careful not to blow precision, since storing ms since 1970 can overflow...
		return Std.int(Timer.stamp() * 1000.0);
	}
	
	
	public static function getURL (url:URLRequest, ?target:String):Void
	{	
		nme_get_url (url.url);	
	}
	
	
	/**
	 * @private
	 */
	public static function nmeSetCurrentStage(inStage:Stage)
	{
		nmeStage = inStage;
	}
	
	
	public static function postUICallback(inCallback:Void->Void)
	{
		#if android
		nme_post_ui_callback(inCallback);
		#else
		// May still be worth posting event to come back with the next UI event loop...
		//  (or use timer?)
		inCallback();
		#end
	}
	
	// Is this still used?
	//static public function setAssetBase(inBase:String)
	//{
		//nme_set_asset_base(inBase);
	//}
	//private static var nme_set_asset_base = Loader.load("nme_set_asset_base", 1);
	
	
	public static function setIcon(path:String)
	{
		//Useful only on SDL platforms. Sets the title bar's icon, based on the path given.
		var set_icon = Loader.load("nme_set_icon", 1);
		set_icon(path);
	}

	public static function setPackage(inCompany:String,inFile:String,inPack:String,inVersion:String)
	{
      company = inCompany;
      file = inFile;
      packageName = inPack;
      version = inVersion;
		nme_set_package(inCompany,inFile,inPack,inVersion);
	}
	
	
	// Getters & Setters
	
	static function nmeGetCurrent():MovieClip
	{
		if (nmeCurrent == null)
		{
			nmeCurrent = new MovieClip();
			if (nmeStage != null)
				nmeStage.addChild(nmeCurrent);
		}
		return nmeCurrent;
	}
	
	
	private static function nmeGetStage()
	{
		if (nmeStage == null)
			throw("Error : stage can't be accessed until init is called");
		return nmeStage;
	}
	
	
	
	// Native Methods
	
	
	
	#if android
	private static var nme_post_ui_callback = Loader.load("nme_post_ui_callback", 1);
	#end
	private static var nme_set_package = Loader.load("nme_set_package", 4);
	private static var nme_get_frame_stage = Loader.load("nme_get_frame_stage", 1);
	private static var nme_get_url = Loader.load("nme_get_url", 1);

}


#elseif js


import Html5Dom;
import nme.display.Stage;
import nme.display.MovieClip;
import nme.display.Graphics;
import nme.events.Event;
import nme.events.MouseEvent;
import nme.events.KeyboardEvent;
import nme.events.EventPhase;
import nme.display.DisplayObjectContainer;
import nme.display.DisplayObject;
import nme.display.InteractiveObject;
import nme.text.TextField;
import nme.geom.Rectangle;
import nme.geom.Matrix;
import nme.geom.Point;
import nme.net.URLRequest;

/**
 * @author	Hugh Sanderson
 * @author	Lee Sylvester
 * @author	Niel Drummond
 * @author	Russell Weir
 *
 */
class Lib
{
	var mKilled:Bool;
	static var mMe:Lib;
	static inline var DEFAULT_PRIORITY = ["2d", "swf"];
	public static var context(default,null):String;
	public static var current(jeashGetCurrent,null):MovieClip;
	public static var glContext(default,null):WebGLRenderingContext;
	public static var canvas(jeashGetCanvas,null):HTMLCanvasElement;
	static var mShowCursor = true;
	static var mShowFPS = false;

	var mRequestedWidth:Int;
	var mRequestedHeight:Int;
	var mResizePending:Bool;
	static var mFullscreen:Bool= false;
	public static var mCollectEveryFrame:Bool = false;

	public static var mQuitOnEscape:Bool = true;
	static var mStage:flash.display.Stage;
	static var mMainClassRoot:flash.display.MovieClip;
	static var mCurrent:flash.display.MovieClip;
	static var mRolling:InteractiveObject;
	static var mDownObj:InteractiveObject;
	static var mMouseX:Int;
	static var mMouseY:Int;

	public static var mLastMouse:flash.geom.Point = new flash.geom.Point();

	var __scr : HTMLDivElement;
	var mArgs:Array<String>;

	static inline var VENDOR_HTML_TAG = "data-";
	static inline var HTML_DIV_EVENT_TYPES = [ 'resize', 'mouseup', 'mouseover', 'mouseout', 'mousemove', 'mousedown', 'mousewheel', 'focus', 'dblclick', 'click', 'blur' ];
	static inline var HTML_WINDOW_EVENT_TYPES = [ 'keyup', 'keypress', 'keydown' ];
	static inline var JEASH_IDENTIFIER = 'haxe:jeash';
	static inline var DEFAULT_WIDTH = 500;
	static inline var DEFAULT_HEIGHT = 500;

	var jeashTraceTextField:flash.text.TextField;

	function new(title:String, width:Int, height:Int)
	{
		mKilled = false;
		mRequestedWidth = width;
		mRequestedHeight = height;
		mResizePending = false;

		// ... this should go in Stage.hx
		__scr = cast js.Lib.document.getElementById(title);
		if ( __scr == null ) throw "Element with id '" + title + "' not found";
		__scr.style.setProperty("overflow", "hidden", "");
		__scr.style.setProperty("position", "absolute", ""); // necessary for chrome ctx.isPointInPath
		__scr.appendChild( Lib.canvas );

	}

	static public function trace( arg:Dynamic ) 
	{
		untyped
		{
			if (window.console != null)
				window.console.log(arg);
			else if (mMe.jeashTraceTextField != null)
				mMe.jeashTraceTextField.text += arg + "\n";
		}
	}

	static public function getURL( request:URLRequest, ?target:String )
	{
		var document : HTMLDocument = cast js.Lib.document;
		var window : Window = cast js.Lib.window;
		if (target == null || target == "_self")
		{
			document.open(request.url);
		} else {
			switch (target)
			{
				case "_blank": window.open(request.url);
				case "_parent": window.parent.open(request.url);
				case "_top": window.top.open(request.url);
			}
		}
	}

	static function jeashGetCanvas() : HTMLCanvasElement
	{
		untyped
		{
			if ( Lib.canvas == null )
			{
				if ( document == null ) throw "Document not loaded yet, cannot create root canvas!";
				Lib.canvas = document.createElement("canvas");
				Lib.canvas.id = "Root Surface";
				Lib.context = "2d";

				jeashBootstrap();

				starttime = haxe.Timer.stamp();

			}
			return Lib.canvas;
		}
	}

	static public function jeashGetCurrent() : MovieClip
	{
		Lib.canvas;
		if ( mMainClassRoot == null )
		{
			mMainClassRoot = new MovieClip();
			mCurrent = mMainClassRoot;
			mCurrent.name = "Root MovieClip";

		}
		return mMainClassRoot;
	}

	public static function as<T>( v : Dynamic, c : Class<T> ) : Null<T>
	{
		return Std.is(v,c) ? v : null;
	}

	static var starttime : Float;
	public static function getTimer() : Int { 
		return Std.int((haxe.Timer.stamp() - starttime )*1000); 
	}

	public static function jeashGetStage() { 
		Lib.canvas;
		if ( mStage == null )
		{
			var width = jeashGetWidth();
			var height = jeashGetHeight();
			mStage = new flash.display.Stage(width, height);

			mStage.addChild(jeashGetCurrent());
		}

		return mStage; 
	}

	public static function jeashAppendSurface(surface:HTMLElement, ?before:HTMLElement) {
		if (mMe.__scr != null) {
			surface.style.setProperty("position", "absolute", "");
			surface.style.setProperty("left", "0px", "");
			surface.style.setProperty("top", "0px", "");

			surface.style.setProperty("-moz-transform-origin", "0 0", "");
			surface.style.setProperty("-webkit-transform-origin", "0 0", "");
			surface.style.setProperty("-o-transform-origin", "0 0", "");
			surface.style.setProperty("-ms-transform-origin", "0 0", "");

			// disable blue selection rectangle 
			untyped {
				try {
					surface.onmouseover = surface.onselectstart = function () { return false; }
				} catch (e:Dynamic) {}
			}

			if (before != null)
				mMe.__scr.insertBefore(surface, before);
			else
				mMe.__scr.appendChild(surface);
		}
	}

	public static function jeashSwapSurface(surface1:HTMLElement, surface2:HTMLElement) {
		var c1 : Int = -1;
		var c2 : Int = -1;
		var swap : Node;
		for ( i in 0...mMe.__scr.childNodes.length )
			if ( mMe.__scr.childNodes[i] == surface1 ) c1 = i;
			else if  ( mMe.__scr.childNodes[i] == surface2 ) c2 = i;

		if ( c1 != -1 && c2 != -1 )
		{
			swap = mMe.__scr.removeChild(mMe.__scr.childNodes[c1]);
			if (c2>c1) c2--;
			if (c2 < mMe.__scr.childNodes.length-1)
			{
				mMe.__scr.insertBefore(swap, mMe.__scr.childNodes[c2++]);
			} else {
				mMe.__scr.appendChild(swap);
			}

			swap = mMe.__scr.removeChild(mMe.__scr.childNodes[c2]);
			if (c1>c2) c1--;
			if (c1 < mMe.__scr.childNodes.length-1)
			{
				mMe.__scr.insertBefore(swap, mMe.__scr.childNodes[c1++]);
			} else {
				mMe.__scr.appendChild(swap);
			}
		}
	}

	public static function jeashIsOnStage(surface:HTMLElement) {

		for ( i in 0...mMe.__scr.childNodes.length )
			if ( mMe.__scr.childNodes[i] == surface ) {
				return true;
			}

		return false;
	}

	public static function jeashRemoveSurface(surface:HTMLElement) {
		if (mMe.__scr != null)
		{
			mMe.__scr.removeChild(surface);
		}
	}

	public static function jeashSetSurfaceTransform(surface:HTMLElement, matrix:Matrix) {
		if (matrix.a == 1 && matrix.b == 0 && matrix.c == 0 && matrix.d == 1) {
			surface.style.left = matrix.tx + "px";
			surface.style.top = matrix.ty + "px";
		} else {
			surface.style.setProperty("-moz-transform", matrix.toMozString(), "");
			surface.style.setProperty("-webkit-transform", matrix.toString(), "");
			surface.style.setProperty("-o-transform", matrix.toString(), "");
			surface.style.setProperty("-ms-transform", matrix.toString(), "");
		}
	}

	public static function jeashSetSurfaceOpacity(surface:HTMLElement, alpha:Float) {
		surface.style.setProperty("opacity", Std.string(alpha), "" );
	}

	public static function jeashSetSurfaceFont(surface:HTMLElement, font:String, bold:Int, size:Float, color:Int, align:String, lineHeight:Int) {
		surface.style.setProperty("font-family", font, "");
		surface.style.setProperty("font-weight", Std.string(bold) , "");
		surface.style.setProperty("color", '#' + StringTools.hex(color) , "");
		surface.style.setProperty("font-size", size + 'px', "");
		surface.style.setProperty("text-align", align, "");
		surface.style.setProperty("line-height", lineHeight + 'px', "");
	}

	public static function jeashSetSurfaceBorder(surface:HTMLElement, color:Int, size:Int) {
		surface.style.setProperty("border-color", '#' + StringTools.hex(color) , "");
		surface.style.setProperty("border-style", 'solid' , "");
		surface.style.setProperty("border-width", size + 'px', "");
		surface.style.setProperty("border-collapse", "collapse", "");
	}

	public static function jeashSetSurfacePadding(surface:HTMLElement, padding:Float, margin:Float, display:Bool)
	{
		surface.style.setProperty("padding", padding + 'px', "");
		surface.style.setProperty("margin", margin + 'px' , "");
		surface.style.setProperty("top", (padding+2) + "px", "");
		surface.style.setProperty("right", (padding+1) + "px", "");
		surface.style.setProperty("left", (padding+1) + "px", "");
		surface.style.setProperty("bottom", (padding+1) + "px", "");
		surface.style.setProperty("display", (display ? "inline" : "block") , "");
	}

	public static function jeashAppendText(surface:HTMLElement, container:HTMLElement, text:String, wrap:Bool, isHtml:Bool)
	{
		for ( i in 0...surface.childNodes.length )
			surface.removeChild(surface.childNodes[i]);

		if (isHtml)
			container.innerHTML = text;
		else
			container.appendChild(cast js.Lib.document.createTextNode(text));

		container.style.setProperty("position", "relative", "");
		container.style.setProperty("cursor", "default", "");
		if (!wrap) container.style.setProperty("white-space", "nowrap", "");

		surface.appendChild(cast container);
	}

	public static function jeashSetTextDimensions(surface:HTMLElement, width:Float, height:Float, align:String)
	{
		surface.style.setProperty("width", width + "px", "");
		surface.style.setProperty("height", height + "px", "");
		surface.style.setProperty("overflow", "hidden", "");
		surface.style.setProperty("text-align", align, "");
	}

	public static function jeashSetSurfaceAlign(surface:HTMLElement, align:String)
	{
		surface.style.setProperty("text-align", align, "");
	}

	public static function jeashSurfaceHitTest(surface:HTMLElement, x:Float, y:Float)
	{
		for ( i in 0...surface.childNodes.length )
		{
			var node : HTMLElement = cast surface.childNodes[i];
			if ( x >= node.offsetLeft && x <= (node.offsetLeft + node.offsetWidth) && y >= node.offsetTop && y <= (node.offsetTop + node.offsetHeight) ) return true;
		}
		return false;
	}

	public static function jeashCopyStyle(src:HTMLElement, tgt:HTMLElement) 
	{
		tgt.id = src.id;
		for (prop in ["left", "top", "-moz-transform", "-moz-transform-origin", "-webkit-transform", "-webkit-transform-origin", "-o-transform", "-o-transform-origin", "opacity", "display"])
			tgt.style.setProperty(prop, src.style.getPropertyValue(prop), "");
		
	}

	public static function jeashDrawToSurface(surface:HTMLCanvasElement, tgt:HTMLCanvasElement, matrix:Matrix = null, alpha:Float = 1.0) {
		var srcCtx = surface.getContext("2d");
		var tgtCtx = tgt.getContext("2d");

		if (alpha != 1.0)
			tgtCtx.globalAlpha = alpha;

		if (surface.width > 0 && surface.height > 0)
			if (matrix != null) {
				tgtCtx.save();
				if (matrix.a == 1 && matrix.b == 0 && matrix.c == 0 && matrix.d == 1) 
					tgtCtx.translate(matrix.tx, matrix.ty);
				else 
					tgtCtx.setTransform(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);
				tgtCtx.drawImage(surface, 0, 0);
				tgtCtx.restore();
			} else
				tgtCtx.drawImage(surface, 0, 0);
	}

	public static function jeashDisableRightClick() {
		if (mMe != null)
			untyped {
				try {
					mMe.__scr.oncontextmenu = function () { return false; }
				} catch (e:Dynamic) {
					flash.Lib.trace("Disable right click not supported in this browser.");
				}
			}
	}

	public static function jeashEnableRightClick()
	{
		if (mMe != null)
			untyped {
				try {
					mMe.__scr.oncontextmenu = null;
				} catch (e:Dynamic) {}
			}
	}

	public static function jeashEnableFullScreen()
	{
		if (mMe != null)
		{
			var origWidth = mMe.__scr.style.getPropertyValue("width");
			var origHeight = mMe.__scr.style.getPropertyValue("height");
			mMe.__scr.style.setProperty("width", "100%", "");
			mMe.__scr.style.setProperty("height", "100%", "");
			Lib.jeashDisableFullScreen = function () {
				mMe.__scr.style.setProperty("width", origWidth, "");
				mMe.__scr.style.setProperty("height", origHeight, "");
			}
		}
	}

	public dynamic static function jeashDisableFullScreen() {}
	public inline static function jeashFullScreenWidth() 
	{ 
		var window : Window = cast js.Lib.window;
		return window.innerWidth; 
	}
	public inline static function jeashFullScreenHeight() { 
		var window : Window = cast js.Lib.window;
		return window.innerHeight; 
	}

	public static function jeashSetCursor(hand:Bool) {
		if (mMe != null) 
			if (hand) 
				mMe.__scr.style.setProperty("cursor", "pointer", "");
			else
				mMe.__scr.style.setProperty("cursor", "default", "");
	}

	public inline static function jeashSetSurfaceVisible(surface:HTMLElement, visible:Bool) {
		if (visible) 
			surface.style.setProperty("display", "block", "");
		else
			surface.style.setProperty("display", "none", "");
	}

	public inline static function jeashSetSurfaceId(surface:HTMLElement, name:String) { surface.id = name; }

	public inline static function jeashDrawSurfaceRect(surface:HTMLElement, tgt:HTMLCanvasElement, x:Float, y:Float, rect:Rectangle) {
		var tgtCtx = tgt.getContext('2d');
		tgt.width = cast rect.width;
		tgt.height = cast rect.height;
		tgtCtx.drawImage(surface, rect.x, rect.y, rect.width, rect.height, 0, 0, rect.width, rect.height);
		tgt.style.left = (x) + "px";
		tgt.style.top = (y) + "px";
	}

	public inline static function jeashSetSurfaceScale(surface:HTMLElement, scale:Float) {
		surface.style.setProperty("-moz-transform", "scale(" + scale + ")", "");
		surface.style.setProperty("-webkit-transform", "scale(" + scale + ")", "");
		surface.style.setProperty("-o-transform", "scale(" + scale + ")", "");
		surface.style.setProperty("-ms-transform", "scale(" + scale + ")", "");
	}

	public inline static function jeashSetSurfaceRotation(surface:HTMLElement, rotate:Float) {
		surface.style.setProperty("-moz-transform", "rotate(" + rotate + "deg)", "");
		surface.style.setProperty("-webkit-transform", "rotate(" + rotate + "deg)", "");
		surface.style.setProperty("-o-transform", "rotate(" + rotate + "deg)", "");
		surface.style.setProperty("-ms-transform", "rotate(" + rotate + "deg)", "");
	}

	static function Run( tgt:HTMLDivElement, width:Int, height:Int ) 
	{
			mMe = new Lib( tgt.id, width, height );

			Lib.canvas.width = width;
			Lib.canvas.height = height;

			if ( !StringTools.startsWith(Lib.context, "swf") )
			{
				for ( i in 0...tgt.attributes.length)
				{
					var attr : Attr = cast tgt.attributes.item(i);
					if (StringTools.startsWith(attr.name, VENDOR_HTML_TAG))
					{
						switch (attr.name)
						{
							case VENDOR_HTML_TAG + 'framerate':
								jeashGetStage().frameRate = Std.parseFloat(attr.value);
							default:
						}
					}
				}

				for (type in HTML_DIV_EVENT_TYPES) 
					tgt.addEventListener(type, jeashGetStage().jeashProcessStageEvent, true);

				for (type in HTML_WINDOW_EVENT_TYPES) 

				{
					var window : Window = cast js.Lib.window;
					window.addEventListener(type, jeashGetStage().jeashProcessStageEvent, true);
				}

				jeashGetStage().backgroundColor = if (tgt.style.backgroundColor != null && tgt.style.backgroundColor != "")
					ParseColor( tgt.style.backgroundColor, function (res, pos, cur) { 
							return switch (pos) {
							case 0: res | (cur << 16);
							case 1: res | (cur << 8);
							case 2: res | (cur);
							}
							}); else 0xFFFFFF;

				// This ensures that a canvas hitTest hits the root movieclip
				Lib.current.graphics.beginFill(jeashGetStage().backgroundColor);
				Lib.current.graphics.drawRect(0, 0, width, height);
				Lib.current.graphics.jeashSurface.id = "Root MovieClip";

				mMe.jeashTraceTextField = new TextField();
				mMe.jeashTraceTextField.width = jeashGetStage().stageWidth;
				mMe.jeashTraceTextField.wordWrap = true;
				Lib.current.addChild(mMe.jeashTraceTextField);

				jeashGetStage().jeashUpdateNextWake();
			}

			return mMe;
	}

	static function ParseColor( str:String, cb: Int -> Int -> Int -> Int) 
	{
		var re = ~/rgb\(([0-9]*), ?([0-9]*), ?([0-9]*)\)/;
		var hex = ~/#([0-9a-zA-Z][0-9a-zA-Z])([0-9a-zA-Z][0-9a-zA-Z])([0-9a-zA-Z][0-9a-zA-Z])/;
		if ( re.match(str) )
		{
			var col = 0;
			for ( pos in 1...4 )
			{
				var v = Std.parseInt(re.matched(pos));
				col = cb(col,pos-1,v);
			}
			return col;
		} else if ( hex.match(str) ) {
			var col = 0;
			for ( pos in 1...4 )
			{
				var v : Int = untyped ("0x" + hex.matched(pos)) & 0xFF;
				v = cb(col,pos-1,v);
			}
			return col;
		} else {
			throw "Cannot parse color '" + str + "'.";
		}
	}

	static function jeashGetWidth()
	{
		var tgt : HTMLDivElement = cast js.Lib.document.getElementById(JEASH_IDENTIFIER);
		return tgt.clientWidth > 0 ? tgt.clientWidth : Lib.DEFAULT_WIDTH;
	}

	static function jeashGetHeight()
	{
		var tgt : HTMLDivElement = cast js.Lib.document.getElementById(JEASH_IDENTIFIER);
		return tgt.clientHeight > 0 ? tgt.clientHeight : Lib.DEFAULT_HEIGHT;
	}

	static function jeashBootstrap()
	{
		var tgt : HTMLDivElement = cast js.Lib.document.getElementById(JEASH_IDENTIFIER);
		var lib = Run(tgt, jeashGetWidth(), jeashGetHeight());
		return lib;
	}

}


#else
typedef Lib = flash.Lib;
#end
