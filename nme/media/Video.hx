package nme.media;
#if js


import nme.events.Event;
import haxe.Timer;
import Html5Dom;
import nme.display.BitmapData;
import nme.display.DisplayObject;
import nme.display.Graphics;
import nme.display.Stage;
import nme.geom.Matrix;
import nme.geom.Point;
import nme.Lib;
import nme.net.NetStream;
import js.Dom;
import nme.media.VideoElement;

class Video extends DisplayObject {
	
	private var jeashGraphics:Graphics;
	
	private var windowHack:Bool;
	private var netStream:NetStream;
	private var renderHandler:Event->Void;

	private var videoElement(default,null):HTMLMediaElement;
	
	public var deblocking:Int;
	public var smoothing:Bool;
	
	/*
	 * 
	 * todo: netstream/camera
	 * 			check compat with flash events
	 */
	
	public function new(width : Int = 320, height : Int = 240) : Void {
		super();
		
		jeashGraphics = new Graphics();
		jeashGraphics.drawRect(0, 0, width, height);
		
		this.width = width;
		this.height = height;
		
		name = "Video_" + DisplayObject.mNameID++;
		
		this.smoothing = false;
		this.deblocking = 0;
		
		this.addEventListener(Event.ADDED_TO_STAGE, added);
	}
	
	private function added(e:Event):Void 
	{
		removeEventListener(Event.ADDED_TO_STAGE, added);
	}
	
	override function jeashGetGraphics():Graphics
	{ 
		return jeashGraphics; 
	}
	
	/*
	public function attachCamera(camera : jeash.net.Camera) : Void;
	{
		// (html5 <device/> 
		throw "not implemented";
	}
	*/
	
	public function attachNetStream(ns:NetStream) : Void
	{
		this.netStream = ns;
		var scope:Video = this;
		
		jeashGraphics.SetSurface(ns.jeashVideoElement);

		ns.jeashVideoElement.style.setProperty("width", width + "px", "");
		ns.jeashVideoElement.style.setProperty("height", height + "px", "");

		ns.jeashVideoElement.play();
	}
	
	public function clear():Void
	{
		if (jeashGraphics != null)
			Lib.jeashRemoveSurface(jeashGraphics.jeashSurface);
		jeashGraphics = new Graphics();
		jeashGraphics.drawRect(0, 0, width, height);
	}

	override public function jeashRender(parentMatrix:Matrix, ?inMask:HTMLCanvasElement)
	{
		if(mMtxDirty || mMtxChainDirty){
			jeashValidateMatrix();
		}

		var gfx = jeashGetGraphics();

		if (gfx!=null)
		{
			Lib.jeashSetSurfaceTransform(gfx.jeashSurface, mFullMatrix);
		}
	}
	
	override public function jeashGetObjectUnderPoint(point:Point)
	{
		var local = globalToLocal(point);
		if (local.x >= 0 && local.y >= 0 && local.x <= width && local.y <= height)

		{
			// NOTE: bad cast, should be InteractiveObject... 
			return cast this;
		}
		else
			return null;
	}
}

#end