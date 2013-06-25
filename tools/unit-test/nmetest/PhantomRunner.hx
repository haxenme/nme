package nmetest;

import js.phantomjs.*;
import js.*;

class PhantomRunner {
	public static function main():Void {
		var port = 8080;
		var server = WebServer.create();
		server.listen(port, function(request:Request, response:Response):Void {
			var fullpath = Phantom.libraryPath + request.url;
			if (FileSystem.exists(fullpath)) {
				response.statusCode = 200;
				response.write(FileSystem.read(fullpath));
				response.close();
			} else {
				response.statusCode = 404;
				response.close();
			}
		});
		
		var page = WebPage.create();
		page.onConsoleMessage = function(msg:String):Void {
			if (StringTools.startsWith(msg, "success:")) {
				var success = msg.substr("success:".length) == "true";
				Phantom.exit(success ? 0 : 1);
			} else {
				Browser.window.console.log(msg);
			}
		}
		
		page.open('http://localhost:$port/' + Phantom.args[0], function(status:String):Void {
			if (status != "success") {
				Phantom.exit(1);
			}
		});
		
	}
}