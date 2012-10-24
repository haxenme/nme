import flash.display.Sprite;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLVariables;
import flash.net.URLRequestMethod;
import flash.events.Event;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.events.HTTPStatusEvent;
import flash.events.IOErrorEvent;
import flash.events.IEventDispatcher;
import flash.errors.Error;
import flash.Lib;

class PostUrl extends Sprite {

	public function new() {
		super();
		var loader:URLLoader = new URLLoader();

		configureListeners(loader);

		var request:URLRequest = new URLRequest("/");

		var variables : URLVariables = new URLVariables();  
		variables.foo = "bar";  
		variables.mum = "love";  
		request.data = variables;  

	        request.method = URLRequestMethod.POST;
		loader.load(request);
	}

	function configureListeners(dispatcher:IEventDispatcher) {
		dispatcher.addEventListener(Event.COMPLETE, completeHandler);
		dispatcher.addEventListener(Event.OPEN, openHandler);
		dispatcher.addEventListener(ProgressEvent.PROGRESS, progressHandler);
		dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
		dispatcher.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
		dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
	}

	function completeHandler(event:Event) {
		var tgt:URLLoader = event.target;
		trace('Should be: { "foo" : "bar", "mum" : "love" }');
		trace('Actually is: ' + tgt.data);
#if js untyped window.phantomTestResult = tgt.data; #end
	}

	function openHandler(event:Event) {
		trace("openHandler: " + event);
	}

	function progressHandler(event:ProgressEvent) {
		trace("progressHandler loaded:" + event.bytesLoaded + " total: " + event.bytesTotal);
	}

	function securityErrorHandler(event:SecurityErrorEvent) {
		trace("securityErrorHandler: " + event);
	}

	function httpStatusHandler(event:HTTPStatusEvent) {
		trace("httpStatusHandler: " + event);
	}

	function ioErrorHandler(event:IOErrorEvent) {
		trace("ioErrorHandler: " + event);
		Lib.trace(event);
	}

	static function main () Lib.current.addChild(new PostUrl())
}
