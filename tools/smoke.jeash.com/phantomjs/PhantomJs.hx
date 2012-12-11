extern class WebPage {
	var clipRect:{ top:Int, left:Int, width:Int, height:Int };
	var content:String;
	var libraryPath:String;
	var settings:{ javascriptEnabled:Bool, loadImages:Bool, localToRemoteUrlAccessEnabled:Bool, userAgent:String, userName:String, password:String, XSSAuditingEnabled:Bool, webSecurityEnabled:Bool };
	var viewportSize:{ width:Int, height:Int };
	function new ():Void;
	function evaluate(func:Dynamic):Dynamic;
	function includeJs(URL:String, callb:Void -> Void):Void;
	function injectJs(filename:String):Bool;
	function open(URL:String, ?optional_callback:String -> Void):Void;
	function release():Void;
	function render(fileName:String):Void;
	function renderBase64(format:String):String;
	@:overload (function (type:String, key:Int):Void {})
	function sendEvent(type:String, x:Int, y:Int):Void;
	function uploadFile(selector:String, fileName:String):Void;
	dynamic function onAlert(msg:String):Void;
	dynamic function onConsoleMessage(msg:String):Void;
	dynamic function onError(msg:String, trace:Array<String>):Void;
	dynamic function onInitialized():Void;
	dynamic function onLoadFinished(status:String):Void;
	dynamic function onLoadStarted():Void;
	dynamic function onResourceRequested(request:WebServerRequest):Void;
	dynamic function onResourceReceived(request:WebServerRequest):Void;
}

interface WebServerRequest {
	var method:String;
	var url:String;
	var httpVersion:String;
	var port:String;
}

@native("phantom") extern class Phantom {
	var args:Array<String>;
	var libraryPath:String;
	var scriptName:String;
	var version:{ major:Int, minor:Int, patch:Int };
	function exit(returnValue:Int = 0):Void;
	function injectJs(filename:String):Bool;
}
