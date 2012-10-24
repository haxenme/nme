import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLVariables;
import flash.net.URLRequestMethod;
import flash.net.URLLoaderDataFormat;
import flash.events.Event;
import flash.events.IEventDispatcher;
import flash.Lib;
import flash.utils.ByteArray;

class LoadFromBytesJpg {
	public function new () {
		var loader:URLLoader = new URLLoader();
		configureListeners(loader);

		var request:URLRequest = new URLRequest("/net/space.jpg");

		loader.dataFormat = URLLoaderDataFormat.BINARY;

		request.method = URLRequestMethod.GET;
		loader.load(request);
	}

	function configureListeners(dispatcher:IEventDispatcher) {
		dispatcher.addEventListener(Event.COMPLETE, completeHandler);
	}

	function completeHandler(event:Event) {
		var tgt:URLLoader = event.target;
		var data:ByteArray = tgt.data;
#if js
		BitmapData.loadFromBytes(data, function (bitmapData) {
			var bitmap = new Bitmap(bitmapData);
			Lib.current.addChild(bitmap);
		});
#end
	}

	static function main () new LoadFromBytesJpg()
}

