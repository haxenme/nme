package browser;


import browser.display.DisplayObject;
import browser.display.DisplayObjectContainer;
import browser.display.Graphics;
import browser.display.InteractiveObject;
import browser.display.MovieClip;
import browser.display.Stage;
import browser.events.Event;
import browser.events.EventPhase;
import browser.events.KeyboardEvent;
import browser.events.MouseEvent;
import browser.geom.Matrix;
import browser.geom.Point;
import browser.geom.Rectangle;
import browser.net.URLRequest;
import browser.Html5Dom;
import haxe.Template;
import haxe.Timer;


class Lib {
	
	
	public static inline var HTML_ACCELEROMETER_EVENT_TYPE = 'devicemotion';
	public static inline var HTML_ORIENTATION_EVENT_TYPE = 'orientationchange';
	
	public static var current (get_current, null):MovieClip;
	public static inline var document (get_document, null):HTMLDocument;
	public static inline var window (get_window, null):Window;
	
	private static inline var DEFAULT_HEIGHT = 500;
	private static inline var DEFAULT_WIDTH = 500;
	private static var HTML_DIV_EVENT_TYPES = [ 'resize', 'mouseup', 'mouseover', 'mouseout', 'mousemove', 'mousedown', 'mousewheel', 'dblclick', 'click' ];
	private static var HTML_TOUCH_EVENT_TYPES = [ 'touchstart', 'touchmove', 'touchend' ];
	private static var HTML_WINDOW_EVENT_TYPES = [ 'keyup', 'keypress', 'keydown', 'resize' ];
	private static inline var NME_IDENTIFIER = 'haxe:jeash';
	private static inline var VENDOR_HTML_TAG = "data-";
	
	private static var mCurrent:MovieClip;
	private static var mForce2DTransform:Bool;
	private static var mMainClassRoot:MovieClip;
	private static var mMe:Lib;
	private static var mStage:Stage;
	static var starttime:Float = haxe.Timer.stamp();
	
	private var mArgs:Array<String>;
	private var mKilled:Bool;
	private var __scr:HTMLDivElement;
	
	
	private function new (rootElement:HTMLDivElement, width:Int, height:Int) {
		
		mKilled = false;
		
		//var document:HTMLDocument = cast js.Lib.document;
		//__scr = cast document.getElementById(title);
		
		__scr = rootElement;
		if ( __scr == null) throw "Root element not found";
		
		__scr.style.setProperty ("overflow", "hidden", "");
		__scr.style.setProperty ("position", "absolute", ""); // necessary for chrome ctx.isPointInPath
		
		if (__scr.style.getPropertyValue ("width") != "100%") {
			
			__scr.style.width = width + "px";
			
		}
		
		if (__scr.style.getPropertyValue ("height") != "100%") {
			
			__scr.style.height = height + "px";
			
		}
		
	}
	
	
	public static function as<T> (v:Dynamic, c:Class<T>):Null<T> {
		
		return Std.is (v, c) ? v : null;
		
	}
	
	
	public static function getTimer ():Int {
		
		return Std.int ((Timer.stamp () - starttime) * 1000);
		
	}
	
	
	public static function getURL (request:URLRequest, target:String = null) {
		
		if (target == null || target == "_self") {
			
			document.open(request.url);
			
		} else {
			
			switch (target) {
				
				case "_blank": window.open (request.url);
				case "_parent": window.parent.open (request.url);
				case "_top": window.top.open (request.url);
				
			}
			
		}
		
	}
	
	
	public static function nmeAppendSurface (surface:HTMLElement, before:HTMLElement = null, after:HTMLElement = null):Void {
		
		if (mMe.__scr != null) {
			
			surface.style.setProperty ("position", "absolute", "");
			surface.style.setProperty ("left", "0px", "");
			surface.style.setProperty ("top", "0px", "");
			
			surface.style.setProperty ("transform-origin", "0 0", "");
			surface.style.setProperty ("-moz-transform-origin", "0 0", "");
			surface.style.setProperty ("-webkit-transform-origin", "0 0", "");
			surface.style.setProperty ("-o-transform-origin", "0 0", "");
			surface.style.setProperty ("-ms-transform-origin", "0 0", "");
			
			// disable blue selection rectangle, but only for canvas elements
			
			untyped {
				
				try {
					
					if (surface.localName == "canvas")
						surface.onmouseover = surface.onselectstart = function () { return false; }
					
				} catch (e:Dynamic) { }
				
			}
			
			var rootNode = mMe.__scr;
			
			if (before != null) {
				
				rootNode.insertBefore (surface, before);
				
			} else if (after != null && after.nextSibling != null) {
				
				rootNode.insertBefore (surface, after.nextSibling);
				
			} else {
				
				rootNode.appendChild (surface);
				
			}
			
		}
		
	}
	
	
	public static function nmeAppendText (surface:HTMLElement, container:HTMLElement, text:String, wrap:Bool, isHtml:Bool):Void {
		
		for (i in 0...surface.childNodes.length) {
			
			surface.removeChild (surface.childNodes[i]);
			
		}
		
		if (isHtml) {
			
			container.innerHTML = text;
			
		} else {
			
			container.appendChild (cast document.createTextNode (text));
			
		}
		
		container.style.setProperty ("position", "relative", "");
		container.style.setProperty ("cursor", "default", "");
		if (!wrap) container.style.setProperty ("white-space", "nowrap", "");
		
		surface.appendChild (cast container);
		
	}
	
	
	public static function nmeBootstrap ():Void {
		
		if (mMe == null) {
			
			var target:HTMLDivElement = cast document.getElementById (NME_IDENTIFIER);
			
			if (target == null) {
				
				trace ("Error: Cannot find element ID \"" + NME_IDENTIFIER + "\"");
				untyped __js__ ("target.id; // throw error");
				
			}
			
			var agent:String = untyped navigator.userAgent;
			
			if (agent.indexOf ("BlackBerry") > -1 && target.style.height == "100%") {
				
				target.style.height = untyped screen.height + "px";
				
			}
			
			if (agent.indexOf ("Android") > -1) {
				
				var version = Std.parseFloat (agent.substr (agent.indexOf ("Android") + 8, 3));
				
				if (version <= 2.3) {
					
					mForce2DTransform = true;
					
				}
				
			}
			
			Run (target, nmeGetWidth (), nmeGetHeight ());
			
		}
		
	}
	
	
	public static function nmeCopyStyle (src:HTMLElement, tgt:HTMLElement):Void {
		
		tgt.id = src.id;
		
		for (prop in ["left", "top", "transform", "transform-origin", "-moz-transform", "-moz-transform-origin", "-webkit-transform", "-webkit-transform-origin", "-o-transform", "-o-transform-origin", "opacity", "display"]) {
			
			tgt.style.setProperty (prop, src.style.getPropertyValue (prop), "");
			
		}
		
	}
	
	
	public static function nmeCreateSurfaceAnimationCSS<T> (surface:HTMLElement, data:Array<T>, template:Template, templateFunc:T -> Dynamic, fps:Float = 25, discrete:Bool = false, infinite:Bool = false):Dynamic {
		
		// TODO: getSanitizedOrGenerate ID
		
		if (surface.id == null || surface.id == "") {
			
			// generate id ?
			
			Lib.trace ("Failed to create a CSS Style tag for a surface without an id attribute");
			return null;
			
		}
		
		var style:Dynamic = null;
		
		if (surface.getAttribute ("data-nme-anim") != null) {
			
			style = document.getElementById (surface.getAttribute ("data-nme-anim"));
			
		} else {
			
			style = cast mMe.__scr.appendChild (document.createElement ("style"));
			style.sheet.id = "__nme_anim_" + surface.id + "__";
			surface.setAttribute ("data-nme-anim", style.sheet.id);
			
		}
		
		var keyframeStylesheetRule = "";
		
		for (i in 0...data.length) {
			
			var perc = i / (data.length - 1) * 100;
			var frame = data[i];
			keyframeStylesheetRule += perc + "% { " + template.execute (templateFunc (frame)) + " } ";
			
		}
		
		var animationDiscreteRule = if (discrete) "steps(::steps::, end)"; else "";
		var animationInfiniteRule = if (infinite) "infinite"; else "";
		var animationTpl = "";
		
		for (prefix in ["animation", "-moz-animation", "-webkit-animation", "-o-animation", "-ms-animation"]) {
			
			animationTpl += prefix + ": ::id:: ::duration::s " + animationDiscreteRule + " " + animationInfiniteRule  + "; ";
			
		}
		
		var animationStylesheetRule = new Template (animationTpl).execute ( {
			
			id: surface.id,
			duration: data.length / fps,
			steps: 1
			
		});
		
		var rules = (style.sheet.rules != null) ? style.sheet.rules : style.sheet.cssRules;
		
		for (variant in ["", "-moz-", "-webkit-", "-o-", "-ms-"]) {
			
			// a try catch is necessary, because browsers throw exceptions on unknown vendor prefixes.
			
			try {
				
				style.sheet.insertRule ("@" + variant + "keyframes " + surface.id + " {" + keyframeStylesheetRule + "}", rules.length);
				
			} catch (e:Dynamic) { }
			
		}
		
		style.sheet.insertRule ("#" + surface.id + " { " + animationStylesheetRule + " } ", rules.length);
		
		return style;
		
	}
	
	
	public static function nmeDesignMode (mode:Bool):Void {
		
		document.designMode = mode ? 'on' : 'off';
		
	}
	
	
	public dynamic static function nmeDisableFullScreen ():Void {
		
		
		
	}
	
	
	public static function nmeDisableRightClick ():Void {
		
		if (mMe != null) {
			
			untyped {
				
				try {
					
					mMe.__scr.oncontextmenu = function () { return false; }
					
				} catch (e:Dynamic) {
					
					Lib.trace ("Disable right click not supported in this browser.");
					
				}
				
			}
			
		}
		
	}
	
	
	private static function nmeDrawClippedImage (surface:HTMLCanvasElement, tgtCtx:CanvasRenderingContext2D, clipRect:Rectangle = null):Void {
		
		if (clipRect != null) {
			
			if (clipRect.x < 0) { clipRect.width += clipRect.x; clipRect.x = 0; }
			if (clipRect.y < 0) { clipRect.height += clipRect.y; clipRect.y = 0; }
			if (clipRect.width > surface.width - clipRect.x) clipRect.width = surface.width - clipRect.x;
			if (clipRect.height > surface.height - clipRect.y) clipRect.height = surface.height - clipRect.y;
			
			tgtCtx.drawImage (surface, clipRect.x, clipRect.y, clipRect.width, clipRect.height, clipRect.x, clipRect.y, clipRect.width, clipRect.height);
			
		} else {
			
			tgtCtx.drawImage (surface, 0, 0);
			
		}
		
	}
	
	
	public inline static function nmeDrawSurfaceRect (surface:HTMLElement, tgt:HTMLCanvasElement, x:Float, y:Float, rect:Rectangle) {
		
		var tgtCtx = tgt.getContext ('2d');
		
		tgt.width = cast rect.width;
		tgt.height = cast rect.height;
		tgtCtx.drawImage (surface, rect.x, rect.y, rect.width, rect.height, 0, 0, rect.width, rect.height);
		tgt.style.left = (x) + "px";
		tgt.style.top = (y) + "px";
		
	}
	
	
	public static function nmeDrawToSurface (surface:HTMLCanvasElement, tgt:HTMLCanvasElement, matrix:Matrix = null, alpha:Float = 1.0, clipRect:Rectangle = null):Void {
		
		var srcCtx:CanvasRenderingContext2D = surface.getContext ("2d");
		var tgtCtx:CanvasRenderingContext2D = tgt.getContext ("2d");
		
		if (alpha != 1.0) {
			
			tgtCtx.globalAlpha = alpha;
			
		}
		
		if (surface.width > 0 && surface.height > 0) {
			
			if (matrix != null) {
				
				tgtCtx.save ();
				
				if (matrix.a == 1 && matrix.b == 0 && matrix.c == 0 && matrix.d == 1) {
					
					tgtCtx.translate (matrix.tx, matrix.ty);
					
				} else { 
					
					tgtCtx.setTransform (matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);
					
				}
				
				nmeDrawClippedImage (surface, tgtCtx, clipRect);
				tgtCtx.restore ();
				
			} else {
				
				nmeDrawClippedImage (surface, tgtCtx, clipRect);
				
			}
			
		}
		
	}
	
	
	public static function nmeEnableFullScreen ():Void {
		
		if (mMe != null) {
			
			var origWidth = mMe.__scr.style.getPropertyValue ("width");
			var origHeight = mMe.__scr.style.getPropertyValue ("height");
			mMe.__scr.style.setProperty ("width", "100%", "");
			mMe.__scr.style.setProperty ("height", "100%", "");
			
			Lib.nmeDisableFullScreen = function () {
				
				mMe.__scr.style.setProperty ("width", origWidth, "");
				mMe.__scr.style.setProperty ("height", origHeight, "");
				
			}
			
		}
		
	}
	
	
	public static function nmeEnableRightClick ():Void {
		
		if (mMe != null) {
			
			untyped {
				
				try {
					
					mMe.__scr.oncontextmenu = null;
					
				} catch (e:Dynamic) {
					
					Lib.trace ("Enable right click not supported in this browser.");
					
				}
				
			}
			
		}
		
	}
	
	
	public inline static function nmeFullScreenHeight ():Int {
		
		return window.innerHeight;
		
	}
	
	
	public inline static function nmeFullScreenWidth ():Int {
		
		return window.innerWidth;
		
	}
	
	
	public static function nmeGetHeight ():Int {
		
		var tgt:HTMLDivElement = if (Lib.mMe != null) Lib.mMe.__scr; else cast document.getElementById (NME_IDENTIFIER);
		return (tgt != null && tgt.clientHeight > 0) ? tgt.clientHeight:Lib.DEFAULT_HEIGHT;
		
	}
	
	
	public static function nmeGetStage ():Stage {
		
		if (mStage == null) {
			
			var width = nmeGetWidth ();
			var height = nmeGetHeight ();
			
			mStage = new Stage (width, height);
			
		}
		
		return mStage;
		
	}
	
	
	public static function nmeGetWidth ():Int {
		
		var tgt:HTMLDivElement = if (Lib.mMe != null) Lib.mMe.__scr; else cast document.getElementById(NME_IDENTIFIER);
		return (tgt != null && tgt.clientWidth > 0) ? tgt.clientWidth:Lib.DEFAULT_WIDTH;
		
	}
	
	
	public static inline function nmeIsOnStage (surface:HTMLElement):Bool {
		
		var success = false;
		var nodes = mMe.__scr.childNodes;
		
		for (i in 0...nodes.length) {
			
			if (nodes[i] == surface) {
				
				success = true;
				break;
				
			}
			
		}
		
		return success;
		
	}
	
	
	private static function nmeParseColor (str:String, cb:Int -> Int -> Int -> Int):Int {
		
		var re = ~/rgb\(([0-9]*), ?([0-9]*), ?([0-9]*)\)/;
		var hex = ~/#([0-9a-zA-Z][0-9a-zA-Z])([0-9a-zA-Z][0-9a-zA-Z])([0-9a-zA-Z][0-9a-zA-Z])/;
		
		if (re.match(str)) {
			
			var col = 0;
			
			for (pos in 1...4) {
				
				var v = Std.parseInt (re.matched (pos));
				col = cb (col, pos - 1, v);
				
			}
			
			return col;
			
		} else if (hex.match (str)) {
			
			var col = 0;
			
			for (pos in 1...4) {
				
				var v:Int = untyped ("0x" + hex.matched (pos)) & 0xFF;
				v = cb (col, pos - 1, v);
				
			}
			
			return col;
			
		} else {
			
			throw "Cannot parse color '" + str + "'.";
			
		}
		
	}
	
	
	public static function nmeRemoveSurface (surface:HTMLElement):Dynamic {
		
		if (mMe.__scr != null) {
			
			var anim = surface.getAttribute ("data-nme-anim");
			
			if (anim != null) {
				
				var style = document.getElementById (anim);
				if (style != null) mMe.__scr.removeChild (cast style);
				
			}
			
			mMe.__scr.removeChild (surface);
			
		}
		
		return surface;
		
	}
	
	
	public static function nmeSetSurfaceBorder (surface:HTMLElement, color:Int, size:Int):Void {
		
		surface.style.setProperty("border-color", '#' + StringTools.hex (color), "");
		surface.style.setProperty("border-style", 'solid' , "");
		surface.style.setProperty("border-width", size + 'px', "");
		surface.style.setProperty("border-collapse", "collapse", "");
		
	}
	
	
	public static function nmeSetSurfaceClipping (surface:HTMLElement, rect:Rectangle):Void {
		
		//rect(<top>, <right>, <bottom>, <left>)
		//trace("clip: " + "rect(" + rect.top + "px, " + rect.right + "px, " + rect.bottom + "px, " + rect.left + "px)");
		//surface.style.setProperty("clip", "rect(" + rect.top + "px, " + rect.right + "px, " + rect.bottom + "px, " + rect.left + "px)", "");
		
	}
	
	
	public static function nmeSetSurfaceFont (surface:HTMLElement, font:String, bold:Int, size:Float, color:Int, align:String, lineHeight:Int):Void {
		
		surface.style.setProperty ("font-family", font, "");
		surface.style.setProperty ("font-weight", Std.string (bold), "");
		surface.style.setProperty ("color", '#' + StringTools.hex (color), "");
		surface.style.setProperty ("font-size", size + 'px', "");
		surface.style.setProperty ("text-align", align, "");
		surface.style.setProperty ("line-height", lineHeight + 'px', "");
		
	}
	
	
	public static function nmeSetSurfaceOpacity (surface:HTMLElement, alpha:Float):Void {
		
		surface.style.setProperty ("opacity", Std.string (alpha), "");
		
	}
	
	
	public static function nmeSetSurfacePadding (surface:HTMLElement, padding:Float, margin:Float, display:Bool):Void {
		
		surface.style.setProperty ("padding", padding + 'px', "");
		surface.style.setProperty ("margin", margin + 'px' , "");
		surface.style.setProperty ("top", (padding + 2) + "px", "");
		surface.style.setProperty ("right", (padding + 1) + "px", "");
		surface.style.setProperty ("left", (padding + 1) + "px", "");
		surface.style.setProperty ("bottom", (padding + 1) + "px", "");
		surface.style.setProperty ("display", (display ? "inline":"block") , "");
		
	}
	
	
	public static function nmeSetSurfaceTransform (surface:HTMLElement, matrix:Matrix):Void {
		
		if (matrix.a == 1 && matrix.b == 0 && matrix.c == 0 && matrix.d == 1 && surface.getAttribute ("data-nme-anim") == null) {
			
			surface.style.left = matrix.tx + "px";
			surface.style.top = matrix.ty + "px";
			
		} else {
			
			surface.style.left = "0px";
			surface.style.top = "0px";
			surface.style.setProperty ("transform", matrix.toString (), "");
			surface.style.setProperty ("-moz-transform", matrix.toMozString (), "");
			
			if (!mForce2DTransform) {
				
				surface.style.setProperty ("-webkit-transform", matrix.to3DString (), ""); 
				
			} else {
				
				surface.style.setProperty ("-webkit-transform", matrix.toString (), "");
				
			}
			
			surface.style.setProperty ("-o-transform", matrix.toString (), "");
			surface.style.setProperty ("-ms-transform", matrix.toString (), "");
			
		}
		
	}
	
	
	public static function nmeSetSurfaceZIndexAfter (surface1:HTMLElement, surface2:HTMLElement):Void {
		
		var c1:Int = -1;
		var c2:Int = -1;
		var swap:Node;
		
		for (i in 0...mMe.__scr.childNodes.length) {
			
			if (mMe.__scr.childNodes[i] == surface1) {
				
				c1 = i;
				
			} else if (mMe.__scr.childNodes[i] == surface2) {
				
				c2 = i;
				
			}
			
		}
		
		if (c1 != -1 && c2 != -1) {
			
			swap = nmeRemoveSurface (cast mMe.__scr.childNodes[c1]);
			
			if (c2 < mMe.__scr.childNodes.length - 1) {
				
				mMe.__scr.insertBefore (swap, mMe.__scr.childNodes[c2++]);
				
			} else {
				
				mMe.__scr.appendChild (swap);
				
			}
			
		}
		
	}
	
	
	public static function nmeSwapSurface (surface1:HTMLElement, surface2:HTMLElement):Void {
		
		var c1:Int = -1;
		var c2:Int = -1;
		var swap:Node;
		
		for (i in 0...mMe.__scr.childNodes.length) {
			
			if (mMe.__scr.childNodes[i] == surface1) {
				
				c1 = i;
				
			} else if (mMe.__scr.childNodes[i] == surface2) {
				
				c2 = i;
				
			}
			
		}
		
		if (c1 != -1 && c2 != -1) {
			
			swap = nmeRemoveSurface (cast mMe.__scr.childNodes[c1]);
			
			if (c2 > c1) c2--;
			
			if (c2 < mMe.__scr.childNodes.length - 1) {
				
				mMe.__scr.insertBefore (swap, mMe.__scr.childNodes[c2++]);
				
			} else {
				
				mMe.__scr.appendChild (swap);
				
			}
			
			swap = nmeRemoveSurface (cast mMe.__scr.childNodes[c2]);
			
			if (c1 > c2) c1--;
			
			if (c1 < mMe.__scr.childNodes.length - 1) {
				
				mMe.__scr.insertBefore (swap, mMe.__scr.childNodes[c1++]);
				
			} else {
				
				mMe.__scr.appendChild (swap);
				
			}
			
		}
		
	}
	
	
	public static function nmeSetContentEditable (surface:HTMLElement, contentEditable:Bool = true):Void {
		
		surface.setAttribute ("contentEditable", contentEditable ? "true" : "false");
		
	}
	
	
	public static function nmeSetCursor (type:CursorType):Void {
		
		if (mMe != null) {
			
			mMe.__scr.style.cursor = switch (type) {
				
				case Pointer: "pointer";
				case Text: "text";
				default: "default";
				
			}
			
		}
		
	}
	
	
	public static function nmeSetSurfaceAlign (surface:HTMLElement, align:String):Void {
		
		surface.style.setProperty ("text-align", align, "");
		
	}
	
	
	public inline static function nmeSetSurfaceId (surface:HTMLElement, name:String):Void {
		
		var regex = ~/[^a-zA-Z0-9\-]/g;
		surface.id = regex.replace (name, "_");
		
	}
	
	
	public inline static function nmeSetSurfaceRotation (surface:HTMLElement, rotate:Float):Void {
		
		surface.style.setProperty ("transform", "rotate(" + rotate + "deg)", "");
		surface.style.setProperty ("-moz-transform", "rotate(" + rotate + "deg)", "");
		surface.style.setProperty ("-webkit-transform", "rotate(" + rotate + "deg)", "");
		surface.style.setProperty ("-o-transform", "rotate(" + rotate + "deg)", "");
		surface.style.setProperty ("-ms-transform", "rotate(" + rotate + "deg)", "");
		
	}
	
	
	public inline static function nmeSetSurfaceScale (surface:HTMLElement, scale:Float):Void {
		
		surface.style.setProperty ("transform", "scale(" + scale + ")", "");
		surface.style.setProperty ("-moz-transform", "scale(" + scale + ")", "");
		surface.style.setProperty ("-webkit-transform", "scale(" + scale + ")", "");
		surface.style.setProperty ("-o-transform", "scale(" + scale + ")", "");
		surface.style.setProperty ("-ms-transform", "scale(" + scale + ")", "");
		
	}
	
	
	public static function nmeSetSurfaceSpritesheetAnimation (surface:HTMLCanvasElement, spec:Array<Rectangle>, fps:Float):HTMLElement {
		
		if (spec.length == 0) return surface;
		var div:HTMLDivElement = cast document.createElement("div");
		
		// TODO: to be revisited... (see webkit-canvas and -moz-element)
		
		div.style.backgroundImage = "url(" + surface.toDataURL("image/png", {}) + ")";
		div.id = surface.id;
		
		var keyframeTpl = new Template ("background-position: ::left::px ::top::px; width: ::width::px; height: ::height::px; ");
		var templateFunc = function (frame:Rectangle) {
			
			return {
				
				left: - frame.x,
				top: - frame.y,
				width: frame.width,
				height: frame.height
				
			}
			
		}
		
		nmeCreateSurfaceAnimationCSS (div, spec, keyframeTpl, templateFunc, fps, true, true);
		
		if (nmeIsOnStage (surface)) {
			
			Lib.nmeAppendSurface (div);
			Lib.nmeCopyStyle (surface, div);
			Lib.nmeSwapSurface (surface, div);
			Lib.nmeRemoveSurface (surface);
			
		} else {
			
			Lib.nmeCopyStyle (surface, div);
			
		}
		
		return div;
		
	}
	
	
	public inline static function nmeSetSurfaceVisible (surface:HTMLElement, visible:Bool):Void {
		
		if (visible) {
			
			surface.style.setProperty ("display", "block", "");
			
		} else {
			
			surface.style.setProperty ("display", "none", "");
			
		}
		
	}
	
	
	public static function nmeSetTextDimensions (surface:HTMLElement, width:Float, height:Float, align:String):Void {
		
		surface.style.setProperty ("width", width + "px", "");
		surface.style.setProperty ("height", height + "px", "");
		surface.style.setProperty ("overflow", "hidden", "");
		surface.style.setProperty ("text-align", align, "");
		
	}
	
	
	public static function nmeSurfaceHitTest (surface:HTMLElement, x:Float, y:Float):Bool {
		
		for (i in 0...surface.childNodes.length) {
			
			var node:HTMLElement = cast surface.childNodes[i];
			
			if (x >= node.offsetLeft && x <= (node.offsetLeft + node.offsetWidth) && y >= node.offsetTop && y <= (node.offsetTop + node.offsetHeight)) {
				
				return true;
				
			}
			
		}
		
		return false;
		
	}
	
	
	public static function preventDefaultTouchMove ():Void {
		
		document.addEventListener ("touchmove", function (evt:Html5DomEvent):Void {
			
			evt.preventDefault ();
			
		}, false);
		
	}
	
	
	private static function Run (tgt:HTMLDivElement, width:Int, height:Int):Lib {
		
		mMe = new Lib (tgt, width, height);
		
		for (i in 0...tgt.attributes.length) {
			
			var attr:Attr = cast tgt.attributes.item (i);
			
			if (StringTools.startsWith (attr.name, VENDOR_HTML_TAG)) {
				
				if (attr.name == VENDOR_HTML_TAG + "framerate") {
					
					nmeGetStage ().frameRate = Std.parseFloat (attr.value);
					
				}
				
			}
			
		}
		
		if (Reflect.hasField (tgt, "on" + HTML_TOUCH_EVENT_TYPES[0])) {
			
			for (type in HTML_TOUCH_EVENT_TYPES) {
				
				tgt.addEventListener (type, nmeGetStage ().nmeQueueStageEvent, true);
				
			}
			
		}
		
		for (type in HTML_DIV_EVENT_TYPES) {
			
			tgt.addEventListener (type, nmeGetStage ().nmeQueueStageEvent, true);
			
		}
		
		if (Reflect.hasField (window, "on" + HTML_ACCELEROMETER_EVENT_TYPE)) {
			
			window.addEventListener (HTML_ACCELEROMETER_EVENT_TYPE, nmeGetStage ().nmeQueueStageEvent, true);
			
		}
		
		if (Reflect.hasField (window, "on" + HTML_ORIENTATION_EVENT_TYPE)) {
			
			window.addEventListener (HTML_ORIENTATION_EVENT_TYPE, nmeGetStage ().nmeQueueStageEvent, true);
			
		}
		
		for (type in HTML_WINDOW_EVENT_TYPES) {
			
			window.addEventListener (type, nmeGetStage ().nmeQueueStageEvent, false);
			
		}
		
		#if interop
		// search document for data-bindings
		untyped {
			
			if (Lib.document.querySelectorAll != null) {
				
				var parser = new hscript.Parser ();
				
				for (type in HTML_DIV_EVENT_TYPES) {
					
					var allElements = document.querySelectorAll ("[data-nme-binding-" + type.toLowerCase () + "]");
					
					if (allElements != null) {
						
						for (elIdx in 0...allElements.length) {
							
							var el = allElements[elIdx];
							var value = el.getAttribute ("data-nme-binding-" + type);
							
							var program = try {
								
								parser.parseString (value);
								
							} catch (e: Dynamic) {
								
								Lib.trace ("'" + value + "' should be parseable by hscript: " + e);
								
							}
							
							if (program != null) {
								
								var interp = new hscript.Interp ();
								
								interp.variables.set ("stage", nmeGetStage ());
								interp.variables.set ("Lib", Lib);
								interp.variables.set ("createDOMEvent", function (t, e) return new browser.events.DOMEvent (t, e));
								
								el.addEventListener (type, function (e) { 
									
									interp.variables.set ("event", e);
									interp.execute (program);
									
								});
								
							}
							
						}
						
					}
					
				}
				
			}
			
		}
		#end
		
		if (tgt.style.backgroundColor != null && tgt.style.backgroundColor != "") {
			
			nmeGetStage ().backgroundColor = nmeParseColor (tgt.style.backgroundColor, function (res, pos, cur) { 
				
				return if (pos == 0)
					res | (cur << 16);
				else if (pos == 1)
					res | (cur << 8);
				else if (pos == 2)
					res | (cur);
				else
					throw "pos should be 0-2";
				
			}); 
			
		} else {
			
			nmeGetStage ().backgroundColor = 0xFFFFFF;
			
		}
		
		// This ensures that a canvas hitTest hits the root movieclip
		
		Lib.current.graphics.beginFill (nmeGetStage ().backgroundColor);
		Lib.current.graphics.drawRect (0, 0, width, height);
		nmeSetSurfaceId (Lib.current.graphics.nmeSurface, "Root MovieClip");
		nmeGetStage ().nmeUpdateNextWake ();
		
		try {
			
			var winParameters = untyped window.winParameters ();
			
			for (prop in Reflect.fields (winParameters)) {
				
				Reflect.setField (current.loaderInfo.parameters, prop, Reflect.field (winParameters, prop));
				
			}
			
		} catch (e:Dynamic) { }
		
		return mMe;
		
	}
	
	
	public static function setUserScalable (isScalable:Bool = true):Void {
		
		var meta:HTMLMetaElement = cast document.createElement ("meta");
		meta.name = "viewport";
		meta.content = "user-scalable=" + (isScalable ? "yes" : "no");
		
	}
	
	
	public static function trace (arg:Dynamic):Void {
		
		untyped { if (window.console != null) window.console.log (arg); }
		
	}
	
	
	
	
	// Getters & Setters
	
	
	
	
	private static function get_current ():MovieClip {
		
		if (mMainClassRoot == null) {
			
			mMainClassRoot = new MovieClip ();
			mCurrent = mMainClassRoot;
			nmeGetStage ().addChild (mCurrent);
			
		}
		
		return mMainClassRoot;
		
	}
	
	
	private static inline function get_document ():HTMLDocument {
		
		#if haxe_211
		return cast js.Browser.document;
		#else
		return cast js.Lib.document;
		#end
		
	}
	
	
	private static inline function get_window ():Window {
		
		#if haxe_211
		return cast js.Browser.window;
		#else
		return cast js.Lib.window;
		#end
		
	}
	
	
}


private enum CursorType {
	
	Pointer;
	Text;
	Default;
	
}