package nme.display;
#if (cpp || neko)


import nme.net.URLRequest;
import nme.display.DisplayObject;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.LoaderInfo;
import nme.display.Shape;
import nme.display.Sprite;
import nme.events.Event;
import nme.events.IOErrorEvent;
import nme.utils.ByteArray;


/**
* @author   Hugh Sanderson
* @author   Niel Drummond
* @author   Russell Weir
* @author   Joshua Harlan Lifton
* @todo init, open, progress events
* @todo Complete LoaderInfo initialization
* @todo Cancel previous load request if new load request is made before completion.
**/
class Loader extends Sprite
{	
	
	public var content(default, null):DisplayObject;
	public var contentLoaderInfo(default, null):LoaderInfo;
	
	private var nmeImage:BitmapData;
	private var nmeSWF:MovieClip;
	

	public function new()
	{	
		super();
		contentLoaderInfo = LoaderInfo.create(this);
		// Make sure we get in first...
		contentLoaderInfo.nmeOnComplete = doLoad;
	}
	
	
	private function doLoad(inBytes:ByteArray)
	{	
      if (inBytes==null)
         return false;
		try
		{	
			nmeImage = BitmapData.loadFromBytes(inBytes);
			
			var bmp = new Bitmap(nmeImage);
			content = bmp;
			contentLoaderInfo.content = bmp;
			
			while (numChildren > 0)
			{	
				removeChildAt(0);
			}
			
			addChild(bmp);
         return true;
		}
		catch (e:Dynamic)
		{	
			//trace("Error " + e);
			return false;	
		}
	}

	
	public function load(request:URLRequest)
	{	
		// No "loader context" in nme
		contentLoaderInfo.load(request);	
	}
	
	
	public function loadBytes(bytes:ByteArray)
	{	
		// No "loader context" in nme
      if (doLoad(bytes))
			contentLoaderInfo.dispatchEvent(new Event(Event.COMPLETE));
      else
			contentLoaderInfo.DispatchIOErrorEvent();
	}
	
	
	public function unload()
	{	
		if (numChildren > 0)
		{	
			while (numChildren > 0)
			{	
				removeChildAt(0);
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
			
			dispatchEvent(new Event(Event.UNLOAD));
		}
	}
	
	
	
	// Event Handlers
	
	
	
	private function onData(event:Event)
	{
      event.stopImmediatePropagation();
		doLoad(contentLoaderInfo.bytes);
	}
	
}


#elseif js

import nme.net.URLRequest;
import nme.display.DisplayObject;
import nme.display.DisplayObjectContainer;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.LoaderInfo;
import nme.display.Shape;
import nme.events.Event;
import nme.events.IOErrorEvent;
import nme.system.LoaderContext;
import nme.geom.Rectangle;

/**
* @author	Hugh Sanderson
* @author	Niel Drummond
* @author	Russell Weir
* @todo init, open, progress, unload (?) events
* @todo Complete LoaderInfo initialization
**/
class Loader extends DisplayObjectContainer
{
	public var content(default,null) : DisplayObject;
	public var contentLoaderInfo(default,null) : LoaderInfo;
	var mImage:BitmapData;
	var mShape:Shape;

	public function new()
	{
		super();
		contentLoaderInfo = LoaderInfo.create(this);
		name = "Loader " + flash.display.DisplayObject.mNameID++;
	}

	public function load(request:URLRequest, ?context:LoaderContext)
	{
		// get the file extension for the content type
		var parts = request.url.split(".");
		var extension : String = if(parts.length == 0) "" else parts[parts.length-1].toLowerCase();

		var transparent = true;
		// set properties on the LoaderInfo object
		untyped {
			contentLoaderInfo.url = request.url;
			contentLoaderInfo.contentType = switch(extension) {
			case "swf": "application/x-shockwave-flash";
			case "jpg","jpeg": transparent = false; "image/jpeg";
			case "png": "image/png";
			case "gif": "image/gif";
			default:
				throw "Unrecognized file " + request.url;
			}
		}

		mImage = new BitmapData(0,0,transparent);

		try {
			contentLoaderInfo.addEventListener(Event.COMPLETE, handleLoad, false, 2147483647);
			mImage.jeashLoadFromFile(request.url, contentLoaderInfo);
			content = new Bitmap(mImage);
			Reflect.setField(contentLoaderInfo, "content", this.content);
			addChild(content);
		} catch(e:Dynamic) {
			trace("Error " + e);
			var evt = new IOErrorEvent(IOErrorEvent.IO_ERROR);
			contentLoaderInfo.dispatchEvent(evt);
			return;
		}

		if (mShape==null)
		{
			mShape = new Shape();
			addChild(mShape);
		}
	}
	
	private function handleLoad(e:Event):Void
	{
		contentLoaderInfo.removeEventListener(Event.COMPLETE, handleLoad);
		jeashInvalidateBounds();
	}
	
	override function BuildBounds()
	{
		super.BuildBounds();
				
		if(mImage!=null)
		{
			var r:Rectangle = new Rectangle(0, 0, mImage.width, mImage.height);		
			
			if (r.width!=0 || r.height!=0)
			{
				if (mBoundsRect.width==0 && mBoundsRect.height==0)
					mBoundsRect = r.clone();
				else
					mBoundsRect.extendBounds(r);
			}
		}
	}
	
}

#else
typedef Loader = flash.display.Loader;
#end
