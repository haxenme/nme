package native.net;


import native.events.Event;
import native.events.EventDispatcher;
import native.events.IOErrorEvent;
import native.events.ProgressEvent;
import native.events.HTTPStatusEvent;
import native.utils.ByteArray;
import native.Loader;

#if neko
import neko.FileSystem;
import neko.io.File;
#else
import cpp.FileSystem;
import cpp.io.File;
#end


class URLLoader extends EventDispatcher {
	
	
	public var bytesLoaded (default, null):Int;
	public var bytesTotal (default, null):Int;
	public var data:Dynamic;
	public var dataFormat:URLLoaderDataFormat;
	
	/** @private */ private var nmeHandle:Dynamic;
	
	/** @private */ private static var activeLoaders = new List<URLLoader> ();
	private static inline var urlInvalid 	= 0;
	private static inline var urlInit 		= 1;
	private static inline var urlLoading 	= 2;
	private static inline var urlComplete 	= 3;
	private static inline var urlError 		= 4;

	/** @private */ private var state:Int;
	
	/** @private */ public var nmeOnComplete:Dynamic -> Bool;
	
	
	public function new (?request:URLRequest) {
		
		super ();
		
		nmeHandle = 0;
		bytesLoaded = 0;
		bytesTotal = -1;
		state = urlInvalid;
		dataFormat = URLLoaderDataFormat.TEXT;
		
		if (request != null)
			load (request);
		
	}
	
	
	public function close () {
		
		
		
	}
	
	
	public function getCookies ():Array<String> {
		
		return nme_curl_get_cookies (nmeHandle);
		
	}
	
	
	public static function hasActive () {
		
		return !activeLoaders.isEmpty ();
		
	}
	
	
	public static function initialize (inCACertFilePath:String) {
		
		nme_curl_initialize (inCACertFilePath);
		
	}
	
	
	public function load (request:URLRequest) {
		
		state = urlInit;
		var pref = request.url.substr (0, 7);
		
		if (pref != "http://" && pref != "https:/") { // local file
			
			try {
				
				var bytes = ByteArray.readFile (request.url);
				
				if (bytes == null)
					throw ("Could not open file \"" + request.url + "\"");
				
				switch (dataFormat) {
					case TEXT:
						data = bytes.asString ();
					case VARIABLES:
						data = new URLVariables (bytes.asString ());
					default:
						data = bytes;
				}
				
			} catch (e:Dynamic) {
				
				onError (e);
				return;
				
			}
			
         	nmeDataComplete ();
			
		} else {
         	
			request.nmePrepare ();
			nmeHandle = nme_curl_create (request);
			
			if (nmeHandle == null)
				onError ("Could not open URL");
			else
				activeLoaders.push (this);
			
		}
		
	}
	
	
	/** @private */ private function nmeDataComplete () {
		
		activeLoaders.remove (this);
		
		if (nmeOnComplete != null) {
			
			if (nmeOnComplete (data))
				dispatchEvent (new Event (Event.COMPLETE));
			else
				DispatchIOErrorEvent ();
			
		} else {
			
			dispatchEvent (new Event (Event.COMPLETE));
			
		}
		
	}
	
	
	/** @private */ public static function nmeLoadPending () {
		
		return !activeLoaders.isEmpty ();
		
	}
	
	
	/** @private */ public static function nmePollData () {
		
		if (!activeLoaders.isEmpty ()) {
			
			nme_curl_process_loaders ();
			var oldLoaders = activeLoaders;
			activeLoaders = new List<URLLoader> ();
			
			for (loader in oldLoaders) {
				
				loader.update ();
				if (loader.state == urlLoading)
					activeLoaders.push (loader);
				
			}
			
		}
		
	}
	
	
	/** @private */ private function onError (msg):Void {
		
		activeLoaders.remove (this);
		dispatchEvent (new IOErrorEvent (IOErrorEvent.IO_ERROR, true, false, msg));
		
	}
	
	
	/** @private */ private function dispatchHTTPStatus (code:Int):Void {
		
		dispatchEvent (new HTTPStatusEvent (HTTPStatusEvent.HTTP_STATUS, false, false, code));
		
	}
	
	
	/** @private */ private function update () {
		
		if (nmeHandle != null) {
			
			var old_loaded = bytesLoaded;
			var old_total = bytesTotal;
			nme_curl_update_loader (nmeHandle, this);
			
			if (old_total < 0 && bytesTotal > 0) {
				
				dispatchEvent (new Event (Event.OPEN));
				
			}
			
			if (bytesTotal > 0 && bytesLoaded != old_loaded) {
				
				dispatchEvent (new ProgressEvent (ProgressEvent.PROGRESS, false, false, bytesLoaded, bytesTotal));
				
			}
			
			var code:Int = nme_curl_get_code (nmeHandle);
			
			if (state == urlComplete) {
				
				dispatchHTTPStatus (code);
				
				if (code < 400) {
					
					var bytes:ByteArray = nme_curl_get_data (nmeHandle);
					
					switch(dataFormat) {
						case TEXT, VARIABLES:
							data = bytes == null ? "" : bytes.asString ();
						default:
							data = bytes;
					}
					
               		nmeDataComplete ();
					
				} else {
					
					// XXX : This should be handled in project/common/CURL.cpp
					var evt = new IOErrorEvent (IOErrorEvent.IO_ERROR, true, false, "HTTP status code " + Std.string (code), code);
					nmeHandle = null;
					dispatchEvent (evt);
					
				}
				
			} else if (state == urlError) {
				
				dispatchHTTPStatus (code);
				
				var evt = new IOErrorEvent (IOErrorEvent.IO_ERROR, true, false, nme_curl_get_error_message (nmeHandle), code);
				nmeHandle = null;
				dispatchEvent (evt);
				
			}
			
		}
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var nme_curl_create = Loader.load ("nme_curl_create", 1);
	private static var nme_curl_process_loaders = Loader.load ("nme_curl_process_loaders", 0);
	private static var nme_curl_update_loader = Loader.load ("nme_curl_update_loader", 2);
	private static var nme_curl_get_code = Loader.load ("nme_curl_get_code", 1);
	private static var nme_curl_get_error_message = Loader.load ("nme_curl_get_error_message", 1);
	private static var nme_curl_get_data = Loader.load ("nme_curl_get_data", 1);
	private static var nme_curl_get_cookies = Loader.load ("nme_curl_get_cookies", 1);
	private static var nme_curl_initialize = Loader.load ("nme_curl_initialize", 1);
	
	
}