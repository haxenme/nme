import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLVariables;
import flash.net.URLRequestMethod;
import flash.events.Event;
import flash.events.IEventDispatcher;
import flash.Lib;

class GetUrl {

	public function new() {
		var loader:URLLoader = new URLLoader();
		configureListeners(loader);

		var request:URLRequest = new URLRequest("/");

		var variables : URLVariables = new URLVariables();  
		variables.foo = "bar";  
		variables.mum = "love";  
		request.data = variables;  

		request.method = URLRequestMethod.GET;
		loader.load(request);
	}

	function configureListeners(dispatcher:IEventDispatcher) {
		dispatcher.addEventListener(Event.COMPLETE, completeHandler);
	}

	function completeHandler(event:Event) {
		var tgt:URLLoader = event.target;
		trace('Should be: { "foo" : "bar", "mum" : "love" }');
		trace('Actually is: ' + tgt.data);
		#if js untyped window.phantomTestResult = tgt.data; #end
	}

	static function main () new GetUrl()
}

