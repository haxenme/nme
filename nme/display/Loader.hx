package nme.display;

import nme.net.URLRequest;
import nme.display.DisplayObject;
import nme.display.Bitmap;
import nme.display.BitmapData;
import nme.display.LoaderInfo;
import nme.display.Shape;
import nme.events.Event;
import nme.events.IOErrorEvent;

/**
* @author	Hugh Sanderson
* @author	Niel Drummond
* @author	Russell Weir
* @todo init, open, progress, unload (?) events
* @todo Complete LoaderInfo initialization
**/
class Loader extends nme.display.Sprite
{
	public var content(default,null) : DisplayObject;
	public var contentLoaderInfo(default,null) : LoaderInfo;
	var nmeImage:BitmapData;
	var nmeSWF:MovieClip;

	public function new()
	{
		super();
		contentLoaderInfo = LoaderInfo.create(this);
	}

	// No "loader context" in nme
	public function load(request:URLRequest)
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
			case "png": "image/gif";
			case "gif": "image/png";
			default:
				throw "Unrecognized file " + request.url;
			}
		}

		nmeImage = new BitmapData(0,0,transparent);

		try {
			nmeImage = BitmapData.load(request.url);
			content = new Bitmap(nmeImage);
			var bmp:Bitmap  = cast content;
			untyped contentLoaderInfo.content = this.content;
		} catch(e:Dynamic) {
			//trace("Error " + e);
			contentLoaderInfo.DispatchIOErrorEvent();
			return;
		}

		contentLoaderInfo.DispatchCompleteEvent();
	}

}

