package browser.display;


import browser.display.Bitmap;
import browser.display.BitmapData;
import browser.display.DisplayObject;
import browser.display.LoaderInfo;
import browser.display.Shape;
import browser.events.Event;
import browser.events.IOErrorEvent;
import browser.geom.Rectangle;
import browser.net.URLRequest;
import browser.system.LoaderContext;
import browser.utils.ByteArray;


class Loader extends DisplayObjectContainer {
	
	
	public var content (default, null):DisplayObject;
	public var contentLoaderInfo (default, null):LoaderInfo;
	
	private var mImage:BitmapData;
	private var mShape:Shape;
	
	
	public function new () {
		
		super ();
		
		contentLoaderInfo = LoaderInfo.create (this);
		
	}
	
	
	public function load (request:URLRequest, context:LoaderContext = null):Void {
		
		var extension = "";
		var parts = request.url.split (".");
		
		if (parts.length > 0) {
			
			extension = parts[parts.length - 1].toLowerCase ();
			
		}
		
		var transparent = true;
		
		untyped {
			
			// set properties on the LoaderInfo object
			contentLoaderInfo.url = request.url;
			contentLoaderInfo.contentType = switch (extension) {
				
				case "swf": "application/x-shockwave-flash";
				case "jpg", "jpeg": transparent = false; "image/jpeg";
				case "png": "image/png";
				case "gif": "image/gif";
				default: ""; throw "Unrecognized file " + request.url;
				
			}
			
		}
		
		mImage = new BitmapData (0, 0, transparent);
		
		try {
			
			contentLoaderInfo.addEventListener (Event.COMPLETE, handleLoad, false, 2147483647);
			mImage.nmeLoadFromFile (request.url, contentLoaderInfo);
			content = new Bitmap (mImage);
			Reflect.setField (contentLoaderInfo, "content", this.content);
			addChild (content);
			
		} catch (e:Dynamic) {
			
			trace ("Error " + e);
			var evt = new IOErrorEvent (IOErrorEvent.IO_ERROR);
			contentLoaderInfo.dispatchEvent (evt);
			return;
			
		}
		
		if (mShape == null) {
			
			mShape = new Shape ();
			addChild (mShape);
			
		}
		
	}
	
	
	public function loadBytes (buffer:ByteArray):Void {
		
		try {
			
			contentLoaderInfo.addEventListener (Event.COMPLETE, handleLoad, false, 2147483647);
			
			BitmapData.loadFromBytes (buffer, null, function (bmd:BitmapData):Void {
				
				content = new Bitmap (bmd);
				Reflect.setField (contentLoaderInfo, "content", this.content);
				addChild (content);
				contentLoaderInfo.dispatchEvent (new Event (Event.COMPLETE));
				
			});
			
		} catch (e:Dynamic) {
			
			trace ("Error " + e);
			var evt = new IOErrorEvent (IOErrorEvent.IO_ERROR);
			contentLoaderInfo.dispatchEvent (evt);
			
		}
		
	}
	
	
	override public function toString ():String {
		
		return "[Loader name=" + this.name + " id=" + _nmeId + "]";
		
	}
	
	
	override function validateBounds ():Void {
		
		if (_boundsInvalid) {
			
			super.validateBounds ();
			
			if (mImage != null) {
				
				var r = new Rectangle (0, 0, mImage.width, mImage.height);
				
				if (r.width != 0 || r.height != 0) {
					
					if (nmeBoundsRect.width == 0 && nmeBoundsRect.height == 0) {
						
						nmeBoundsRect = r.clone ();
						
					} else {
						
						nmeBoundsRect.extendBounds (r);
						
					}
					
				}
				
			}
			
			nmeSetDimensions ();
			
		}
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function handleLoad (e:Event):Void {
		
		content.nmeInvalidateBounds ();
		content.nmeRender (null, null);
		contentLoaderInfo.removeEventListener (Event.COMPLETE, handleLoad);
		
	}
	
	
}