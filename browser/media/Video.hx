package browser.media;
#if js


import browser.display.BitmapData;
import browser.display.DisplayObject;
import browser.display.Graphics;
import browser.display.InteractiveObject;
import browser.display.Stage;
import browser.events.Event;
import browser.geom.Matrix;
import browser.geom.Point;
import browser.geom.Rectangle;
import browser.media.VideoElement;
import browser.net.NetStream;
import browser.Lib;
import js.html.CanvasElement;
import js.html.MediaElement;


class Video extends DisplayObject {
	
	
	public var deblocking:Int;
	public var smoothing:Bool;
	
	private var netStream:NetStream;
	private var nmeGraphics:Graphics;
	private var renderHandler:Event->Void;
	private var videoElement(default, null):MediaElement;
	private var windowHack:Bool;
	
	
	public function new(width:Int = 320, height:Int = 240):Void {
		
		super();
		
		/*
		 * todo: netstream/camera
		 * 			check compat with flash events
		 */
		
		nmeGraphics = new Graphics();
		nmeGraphics.drawRect(0, 0, width, height);
		
		this.width = width;
		this.height = height;
		
		this.smoothing = false;
		this.deblocking = 0;
		
		//this.addEventListener(Event.ADDED_TO_STAGE, added);
		
	}
	
	
	/*private function added(e:Event):Void 
	{
		removeEventListener(Event.ADDED_TO_STAGE, added);
	}*/
	
	
	/*public function attachCamera(camera:browser.net.Camera):Void;
	{
		// (html5 <device/> 
		throw "not implemented";
	}*/
	
	
	public function attachNetStream(ns:NetStream):Void {
		
		this.netStream = ns;
		var scope:Video = this;
		
		nmeGraphics.nmeMediaSurface(ns.nmeVideoElement);
		
		ns.nmeVideoElement.style.setProperty("width", width + "px", "");
		ns.nmeVideoElement.style.setProperty("height", height + "px", "");
		ns.nmeVideoElement.addEventListener("error", ns.nmeNotFound, false);
		ns.nmeVideoElement.addEventListener("waiting", ns.nmeBufferEmpty, false);
		ns.nmeVideoElement.addEventListener("ended", ns.nmeBufferStop, false);
		ns.nmeVideoElement.addEventListener("play", ns.nmeBufferStart, false);	
		ns.nmeVideoElement.play();
		
	}
	
	
	public function clear():Void {
		
		if (nmeGraphics != null) {
			
			Lib.nmeRemoveSurface(nmeGraphics.nmeSurface);
			
		}
		
		nmeGraphics = new Graphics();
		nmeGraphics.drawRect(0, 0, width, height);
		
	}
	
	
	override public function nmeGetObjectUnderPoint(point:Point):InteractiveObject {
		
		var local = globalToLocal(point);
		
		if (local.x >= 0 && local.y >= 0 && local.x <= width && local.y <= height) {
			
			// NOTE: bad cast, should be InteractiveObject... 
			return cast this;
			
		} else {
			
			return null;
			
		}
		
	}
	
	
	override public function nmeRender(inMask:CanvasElement = null, clipRect:Rectangle = null):Void {
		
		if (_matrixInvalid || _matrixChainInvalid) {
			
			nmeValidateMatrix();
			
		}
		
		var gfx = nmeGetGraphics();
		if (gfx != null) {
			
			Lib.nmeSetSurfaceTransform(gfx.nmeSurface, getSurfaceTransform(gfx));
			
		}
		
	}
	
	
	override public function toString():String {
		
		return "[Video name=" + this.name + " id=" + _nmeId + "]";
		
	}
}


#end