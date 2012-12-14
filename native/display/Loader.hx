package native.display;


import native.net.URLRequest;
import native.display.DisplayObject;
import native.display.Bitmap;
import native.display.BitmapData;
import native.display.LoaderInfo;
import native.display.Shape;
import native.display.Sprite;
import native.events.Event;
import native.events.IOErrorEvent;
import native.utils.ByteArray;


class Loader extends Sprite {
	
	
	public var content (default, null):DisplayObject;
	public var contentLoaderInfo (default, null):LoaderInfo;
	
	/** @private */ private var nmeImage:BitmapData;
	/** @private */ private var nmeSWF:MovieClip;
	
	
	public function new () {
		
		super ();
		
		contentLoaderInfo = LoaderInfo.create (this);
		// Make sure we get in first...
		contentLoaderInfo.nmeOnComplete = doLoad;
		
	}
	
	
	private function doLoad (inBytes:ByteArray) {

		if (inBytes == null)
			return false;
		
		try {
			
			nmeImage = BitmapData.loadFromBytes (inBytes);
			var bmp = new Bitmap (nmeImage);
			content = bmp;
			contentLoaderInfo.content = bmp;
			
			while (numChildren > 0) {
				
				removeChildAt (0);
				
			}
			
			addChild (bmp);
			return true;
			
		} catch (e:Dynamic) {	
			
			//trace("Error " + e);
			return false;
			
		}
		
	}
	
	
	public function load (request:URLRequest) {
		
		// No "loader context" in nme
		contentLoaderInfo.load (request);
		
	}
	
	
	public function loadBytes (bytes:ByteArray) {
		
		// No "loader context" in nme
		if (doLoad (bytes))
			contentLoaderInfo.dispatchEvent (new Event (Event.COMPLETE));
		else
			contentLoaderInfo.DispatchIOErrorEvent ();
		
	}
	
	
	public function unload () {
		
		if (numChildren > 0) {
			
			while (numChildren > 0) {
				
				removeChildAt (0);
				
			}
			
			untyped
			{
				contentLoaderInfo.url = null;
				contentLoaderInfo.contentType = null;
				contentLoaderInfo.content = null;
				contentLoaderInfo.bytesLoaded = contentLoaderInfo.bytesTotal = 0;
				contentLoaderInfo.width = 0;
				contentLoaderInfo.height = 0;	
			}
			
			dispatchEvent (new Event (Event.UNLOAD));
			
		}
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function onData (event:Event) {
		
		event.stopImmediatePropagation ();
		doLoad (contentLoaderInfo.bytes);
		
	}
	
	
}