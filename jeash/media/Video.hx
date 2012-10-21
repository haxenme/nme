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

package jeash.media;
import jeash.events.Event;
import haxe.Timer;
import jeash.Html5Dom;
import jeash.display.BitmapData;
import jeash.display.DisplayObject;
import jeash.display.Graphics;
import jeash.display.Stage;
import jeash.geom.Matrix;
import jeash.geom.Point;
import jeash.geom.Rectangle;
import jeash.Lib;
import jeash.net.NetStream;
import js.Dom;
import jeash.media.VideoElement;

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
		
		this.smoothing = false;
		this.deblocking = 0;
		
		//this.addEventListener(Event.ADDED_TO_STAGE, added);
	}

	override public function toString() { return "[Video name=" + this.name + " id=" + _jeashId + "]"; }
	
	/*private function added(e:Event):Void 
	{
		removeEventListener(Event.ADDED_TO_STAGE, added);
	}*/
	
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
		
		jeashGraphics.jeashMediaSurface(ns.jeashVideoElement);

		ns.jeashVideoElement.style.setProperty("width", width + "px", "");
		ns.jeashVideoElement.style.setProperty("height", height + "px", "");

		ns.jeashVideoElement.play();
	}
	
	public function clear():Void
	{
		if (jeashGraphics != null)
			jeash.Lib.jeashRemoveSurface(jeashGraphics.jeashSurface);
		jeashGraphics = new Graphics();
		jeashGraphics.drawRect(0, 0, width, height);
	}

	override public function jeashRender(?inMask:HTMLCanvasElement, ?clipRect:Rectangle)
	{
		if (_matrixInvalid || _matrixChainInvalid){
			jeashValidateMatrix();
		}

		var gfx = jeashGetGraphics();

		if (gfx != null) {
			Lib.jeashSetSurfaceTransform(gfx.jeashSurface, getSurfaceTransform(gfx));
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
