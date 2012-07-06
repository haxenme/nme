/**
 * Copyright (c) 2010, Jeash contributors.
 * 
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

package jeash;

import jeash.Html5Dom;
import jeash.display.Stage;
import jeash.display.MovieClip;
import jeash.display.Graphics;
import jeash.events.Event;
import jeash.events.MouseEvent;
import jeash.events.KeyboardEvent;
import jeash.events.EventPhase;
import jeash.display.DisplayObjectContainer;
import jeash.display.DisplayObject;
import jeash.display.InteractiveObject;
import jeash.geom.Rectangle;
import jeash.geom.Matrix;
import jeash.geom.Point;
import jeash.net.URLRequest;

class Lib {
	var mKilled:Bool;
	static var mMe:Lib;
	public static var current(jeashGetCurrent,null):MovieClip;

	static var mStage:jeash.display.Stage;
	static var mMainClassRoot:jeash.display.MovieClip;
	static var mCurrent:jeash.display.MovieClip;

	public static var mLastMouse:jeash.geom.Point = new jeash.geom.Point();

	var __scr : HTMLDivElement;
	var mArgs:Array<String>;

	static inline var VENDOR_HTML_TAG = "data-";
	static var HTML_DIV_EVENT_TYPES = [ 'resize', 'mouseup', 'mouseover', 'mouseout', 'mousemove', 'mousedown', 'mousewheel', 'dblclick', 'click' ];
	static var HTML_WINDOW_EVENT_TYPES = [ 'keyup', 'keypress', 'keydown', 'resize' ];
	static var HTML_TOUCH_EVENT_TYPES = [ 'touchstart', 'touchmove', 'touchend' ];
	public static inline var HTML_ACCELEROMETER_EVENT_TYPE = 'devicemotion';
	public static inline var HTML_ORIENTATION_EVENT_TYPE = 'orientationchange';

	static inline var JEASH_IDENTIFIER = 'haxe:jeash';
	static inline var DEFAULT_WIDTH = 500;
	static inline var DEFAULT_HEIGHT = 500;

	function new(title:String, width:Int, height:Int)
	{
		mKilled = false;

		__scr = cast js.Lib.document.getElementById(title);
		if ( __scr == null ) throw "Element with id '" + title + "' not found";
		__scr.style.setProperty("overflow", "hidden", "");
		__scr.style.setProperty("position", "absolute", ""); // necessary for chrome ctx.isPointInPath
		if (__scr.style.getPropertyValue("width") != "100%")
			__scr.style.width = width + "px";
		if (__scr.style.getPropertyValue("height") != "100%")
			__scr.style.height = height + "px";
	}

	static public function trace( arg:Dynamic ) {
		untyped {
			if (window.console != null) window.console.log(arg);
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

	static public function jeashGetCurrent() : MovieClip
	{
		if ( mMainClassRoot == null )
		{
			mMainClassRoot = new MovieClip();
			mCurrent = mMainClassRoot;
			mCurrent.name = "Root MovieClip";
			jeashGetStage().addChild(mCurrent);

		}
		return mMainClassRoot;
	}

	public static function as<T>( v : Dynamic, c : Class<T> ) : Null<T>
	{
		return Std.is(v,c) ? v : null;
	}

	static var starttime : Float = haxe.Timer.stamp();
	public static function getTimer() : Int { 
		return Std.int((haxe.Timer.stamp() - starttime )*1000); 
	}

	public static function jeashGetStage() { 
		if ( mStage == null )
		{
			var width = jeashGetWidth();
			var height = jeashGetHeight();
			mStage = new jeash.display.Stage(width, height);

			//mStage.addChild(jeashGetCurrent());
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

			// disable blue selection rectangle, but only for canvas elements
			untyped {
				try {
					if (surface.localName == "canvas")
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
			swap = jeashRemoveSurface(cast mMe.__scr.childNodes[c1]);
			if (c2>c1) c2--;
			if (c2 < mMe.__scr.childNodes.length-1)
			{
				mMe.__scr.insertBefore(swap, mMe.__scr.childNodes[c2++]);
			} else {
				mMe.__scr.appendChild(swap);
			}

			swap = jeashRemoveSurface(cast mMe.__scr.childNodes[c2]);
			if (c1>c2) c1--;
			if (c1 < mMe.__scr.childNodes.length-1)
			{
				mMe.__scr.insertBefore(swap, mMe.__scr.childNodes[c1++]);
			} else {
				mMe.__scr.appendChild(swap);
			}
		}
	}

	public static function jeashSetSurfaceZIndexAfter(surface1:HTMLElement, surface2:HTMLElement) {
		var c1 : Int = -1;
		var c2 : Int = -1;
		var swap : Node;
		for ( i in 0...mMe.__scr.childNodes.length )
			if ( mMe.__scr.childNodes[i] == surface1 ) c1 = i;
			else if  ( mMe.__scr.childNodes[i] == surface2 ) c2 = i;

		if ( c1 != -1 && c2 != -1 )
		{
			swap = jeashRemoveSurface(cast mMe.__scr.childNodes[c1]);
			if (c2 < mMe.__scr.childNodes.length-1)
			{
				mMe.__scr.insertBefore(swap, mMe.__scr.childNodes[c2++]);
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
		if (mMe.__scr != null) {
			var anim = surface.getAttribute("data-jeash-anim");
			if (anim != null) {
			       var style = js.Lib.document.getElementById(anim);
			       if (style != null) mMe.__scr.removeChild(cast style);
			}
			mMe.__scr.removeChild(surface);
		}
		return surface;
	}

	public static function jeashSetSurfaceTransform(surface:HTMLElement, matrix:Matrix) {
		if (matrix.a == 1 && matrix.b == 0 && matrix.c == 0 && matrix.d == 1 && surface.getAttribute("data-jeash-anim") == null) {
			surface.style.left = matrix.tx + "px";
			surface.style.top = matrix.ty + "px";
		} else {
			surface.style.left = "0px"; surface.style.top = "0px";
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

	public static function jeashSetContentEditable(surface:HTMLElement, contentEditable:Bool = true) {
		surface.setAttribute("contentEditable", contentEditable ? "true" : "false");
	}

	public static function jeashDesignMode(mode:Bool) {
		var document:HTMLDocument = cast js.Lib.document;
		document.designMode = mode ? 'on' : 'off';
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

	public static function jeashDrawToSurface(surface:HTMLCanvasElement, tgt:HTMLCanvasElement, matrix:Matrix = null, alpha:Float = 1.0, ?clipRect:Rectangle) {
		var srcCtx : CanvasRenderingContext2D = surface.getContext("2d");
		var tgtCtx : CanvasRenderingContext2D = tgt.getContext("2d");

		if (alpha != 1.0)
			tgtCtx.globalAlpha = alpha;

		if (surface.width > 0 && surface.height > 0)
			if (matrix != null) {
				tgtCtx.save();
				if (matrix.a == 1 && matrix.b == 0 && matrix.c == 0 && matrix.d == 1) 
					tgtCtx.translate(matrix.tx, matrix.ty);
				else 
					tgtCtx.setTransform(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);
				jeashDrawClippedImage(surface, tgtCtx, clipRect);
				tgtCtx.restore();
			} else {
				jeashDrawClippedImage(surface, tgtCtx, clipRect);
			}
	}

	static function jeashDrawClippedImage(surface:HTMLCanvasElement, tgtCtx:CanvasRenderingContext2D, ?clipRect:Rectangle) {
		if (clipRect != null) {
			if (clipRect.x < 0) { clipRect.width += clipRect.x; clipRect.x = 0; }
			if (clipRect.y < 0) { clipRect.height += clipRect.y; clipRect.y = 0; }
			if (clipRect.width > surface.width - clipRect.x) clipRect.width = surface.width - clipRect.x;
			if (clipRect.height > surface.height - clipRect.y) clipRect.height = surface.height - clipRect.y;
			tgtCtx.drawImage(surface, clipRect.x, clipRect.y, clipRect.width, clipRect.height, clipRect.x, clipRect.y, clipRect.width, clipRect.height);
		} else
			tgtCtx.drawImage(surface, 0, 0);
	}

	public static function jeashDisableRightClick() {
		if (mMe != null)
			untyped {
				try {
					mMe.__scr.oncontextmenu = function () { return false; }
				} catch (e:Dynamic) {
					jeash.Lib.trace("Disable right click not supported in this browser.");
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

	public static function jeashSetCursor(type:CursorType) {
		if (mMe != null) 
			mMe.__scr.style.cursor = switch (type) {
				case Pointer: "pointer";
				case Text: "text";
				default: "default";
			}
	}

	public inline static function jeashSetSurfaceVisible(surface:HTMLElement, visible:Bool) {
		if (visible) 
			surface.style.setProperty("display", "block", "");
		else
			surface.style.setProperty("display", "none", "");
	}

	public inline static function jeashSetSurfaceId(surface:HTMLElement, name:String) { 
		var regex = ~/[^a-zA-Z0-9\-]/g;
		surface.id = regex.replace(name, "_"); 
	}

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

	public static function jeashCreateSurfaceAnimationCSS<T>(surface:HTMLElement, data:Array<T>, template:haxe.Template, templateFunc:T -> Dynamic, fps:Float = 25, discrete:Bool = false, infinite:Bool = false) {
		var document:HTMLDocument = cast js.Lib.document;

		// TODO: getSanitizedOrGenerate ID
		if (surface.id == null || surface.id == "") {
			// generate id ?
			Lib.trace("Failed to create a CSS Style tag for a surface without an id attribute");
			return;
		}

		var style: Dynamic = null;
	       	if (surface.getAttribute("data-jeash-anim") != null) {
			style = document.getElementById(surface.getAttribute("data-jeash-anim"));
		} else {
			style = cast mMe.__scr.appendChild(document.createElement("style"));
			style.sheet.id = "__jeash_anim_" + surface.id + "__";
			surface.setAttribute("data-jeash-anim", style.sheet.id);
		}
		
		var keyframeStylesheetRule = "";
		for (i in 0...data.length) {
			var perc = i/(data.length-1) * 100;
			var frame = data[i];
			keyframeStylesheetRule += perc + "% { " + template.execute(templateFunc(frame)) + " } ";
		}

		var animationDiscreteRule = if (discrete) "steps(::steps::, end)"; else "";
		var animationInfiniteRule = if (infinite) "infinite"; else "";
		var animationTpl = "";
		for (prefix in ["-animation", "-moz-animation", "-webkit-animation", "-o-animation", "-ms-animation"])
		       animationTpl += prefix + ": ::id:: ::duration::s " + animationDiscreteRule + " " + animationInfiniteRule  + "; ";
		var animationStylesheetRule = new haxe.Template(animationTpl).execute({
			id: surface.id,
			duration: data.length/fps,
			steps: 1
		});
			
		var rules = (style.sheet.rules != null) ? style.sheet.rules : style.sheet.cssRules;
		for (variant in ["", "-moz-", "-webkit-", "-o-", "-ms-"])
			// a try catch is necessary, because browsers throw exceptions on unknown vendor prefixes.
			try {
				style.sheet.insertRule("@" + variant + "keyframes " + surface.id + " {" + keyframeStylesheetRule + "}", rules.length);
			} catch (e:Dynamic) { }
		style.sheet.insertRule("#" + surface.id + " { " + animationStylesheetRule + " } ", rules.length);

		return style;
	}

	public static function jeashSetSurfaceSpritesheetAnimation(surface:HTMLCanvasElement, spec:Array<Rectangle>, fps:Float) : HTMLElement {
		if (spec.length == 0) return surface;
		var document:HTMLDocument = cast js.Lib.document;
		var div:HTMLDivElement = cast document.createElement("div");

		// TODO: to be revisited... (see webkit-canvas and -moz-element)
		div.style.backgroundImage = "url(" + surface.toDataURL("image/png", {}) + ")";
		div.id = surface.id;

		var keyframeTpl = new haxe.Template("background-position: ::left::px ::top::px; width: ::width::px; height: ::height::px; ");
		var templateFunc = function (frame:Rectangle) {
			return {
				left: - frame.x,
				top: - frame.y,
				width: frame.width,
				height: frame.height
			}
		}

		jeashCreateSurfaceAnimationCSS(div, spec, keyframeTpl, templateFunc, fps, true, true);

		if (jeashIsOnStage(surface)) {
			Lib.jeashAppendSurface(div);
			Lib.jeashCopyStyle(surface, div);
			Lib.jeashSwapSurface(surface, div);
			Lib.jeashRemoveSurface(surface);
		} else {
			Lib.jeashCopyStyle(surface, div);
		}

		return div;
	}

	static function Run( tgt:HTMLDivElement, width:Int, height:Int ) 
	{
			mMe = new Lib( tgt.id, width, height );

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

			if (Reflect.hasField(tgt, "on" + HTML_TOUCH_EVENT_TYPES[0])) {
				for (type in HTML_TOUCH_EVENT_TYPES) {
					tgt.addEventListener(type, jeashGetStage().jeashQueueStageEvent, true);
				}
			}

			for (type in HTML_DIV_EVENT_TYPES) 
				tgt.addEventListener(type, jeashGetStage().jeashQueueStageEvent, true);

			var window : Window = cast js.Lib.window;

			if (Reflect.hasField(window, "on" + HTML_ACCELEROMETER_EVENT_TYPE))
				window.addEventListener(HTML_ACCELEROMETER_EVENT_TYPE, jeashGetStage().jeashQueueStageEvent, true);

			if (Reflect.hasField(window, "on" + HTML_ORIENTATION_EVENT_TYPE))
				window.addEventListener(HTML_ORIENTATION_EVENT_TYPE, jeashGetStage().jeashQueueStageEvent, true);

			for (type in HTML_WINDOW_EVENT_TYPES) {
				window.addEventListener(type, jeashGetStage().jeashQueueStageEvent, false);
			}

			jeashGetStage().backgroundColor = if (tgt.style.backgroundColor != null && tgt.style.backgroundColor != "")
				jeashParseColor( tgt.style.backgroundColor, function (res, pos, cur) { 
						return switch (pos) {
						case 0: res | (cur << 16);
						case 1: res | (cur << 8);
						case 2: res | (cur);
						}
						}); else 0xFFFFFF;

			// This ensures that a canvas hitTest hits the root movieclip
			Lib.current.graphics.beginFill(jeashGetStage().backgroundColor);
			Lib.current.graphics.drawRect(0, 0, width, height);
			jeashSetSurfaceId(Lib.current.graphics.jeashSurface, "Root MovieClip");

			jeashGetStage().jeashUpdateNextWake();

			return mMe;
	}

	static function jeashParseColor( str:String, cb: Int -> Int -> Int -> Int) {
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

	static public function jeashGetWidth() {
		var tgt : HTMLDivElement = if (Lib.mMe != null) Lib.mMe.__scr; else cast js.Lib.document.getElementById(JEASH_IDENTIFIER);
		return tgt.clientWidth > 0 ? tgt.clientWidth : Lib.DEFAULT_WIDTH;
	}

	static public function jeashGetHeight() {
		var tgt : HTMLDivElement = if (Lib.mMe != null) Lib.mMe.__scr; else cast js.Lib.document.getElementById(JEASH_IDENTIFIER);
		return tgt.clientHeight > 0 ? tgt.clientHeight : Lib.DEFAULT_HEIGHT;
	}

	public static function jeashBootstrap() {
		if (mMe == null) {
			var tgt : HTMLDivElement = cast js.Lib.document.getElementById(JEASH_IDENTIFIER);
			Run(tgt, jeashGetWidth(), jeashGetHeight());
		}
	}

}

private enum CursorType {
	Pointer;
	Text;
	Default;
}
