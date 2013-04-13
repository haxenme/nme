import flash.display.DisplayObject;
import flash.display.Loader;
import flash.display.Sprite;
import flash.events.Event;
import flash.net.URLRequest;
import flash.Lib;
import flash.geom.Rectangle;
import flash.display.Bitmap;

class BitmapURLLoader extends Sprite {
	static function main () {
		Lib.current.addChild(new BitmapURLLoader());
	}

	function new () {
		super();

		var img = "6za6I.png";

		var loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, complete);
		var request = new URLRequest(img);
		loader.load(request);
		addChild(loader);
		trace("Not loaded yet: " + loader.content.width);
	}

	function complete(e) {

		var b : Bitmap = e.target.content;
		var bd = b.bitmapData;
		var frameWidth = 50;

		var w1 = bd.width;
		var w2 = b.width;
		trace("BitmapData width: " + w1);
		trace("Should be the same: " + w2);
		#if js
			untyped window.phantomTestResult = w2;
		#end
	}
}

