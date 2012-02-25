package nme.net;
#if (cpp || neko)


import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.IOErrorEvent;
import nme.events.ProgressEvent;
import nme.utils.ByteArray;
import nme.Loader;

#if neko
import neko.FileSystem;
import neko.io.File;
#else
import cpp.FileSystem;
import cpp.io.File;
#end


/**
* @author   Hugh Sanderson
* @author   Niel Drummond
* @author   Russell Weir
* @author   Joshua Harlan Lifton
* @todo open and progress events
* @todo Complete Variables type
**/
class URLLoader extends EventDispatcher
{

	public var bytesLoaded(default, null):Int;
	public var bytesTotal(default, null):Int;
	public var data:Dynamic;
	public var dataFormat:URLLoaderDataFormat;
	
	/**
	 * @private
	 */
	public var nmeHandle:Dynamic;
	
	private static var activeLoaders = new List<URLLoader>();
	private static inline var urlInvalid = 0;
	private static inline var urlInit = 1;
	private static inline var urlLoading = 2;
	private static inline var urlComplete = 3;
	private static inline var urlError = 4;
	
	private var state:Int;

   public var nmeOnComplete : Dynamic -> Bool;
	

	public function new(?request:URLRequest)
	{
		super();
		nmeHandle = 0;
		bytesLoaded = 0;
		bytesTotal = -1;
		state = urlInvalid;
		dataFormat = URLLoaderDataFormat.TEXT;
		if(request != null)
			load(request);
	}
	
	
	public function close()
	{
		
	}
	
	
	public function getCookies():Array<String>
	{
		return nme_curl_get_cookies(nmeHandle);
	}
	
	
	public static function hasActive()
	{
		return !activeLoaders.isEmpty();
	}
	
	
	public static function initialize(inCACertFilePath:String)
	{
		nme_curl_initialize(inCACertFilePath);
	}
	
	
	public function load(request:URLRequest)
	{
		state = urlInit;
		var pref = request.url.substr(0, 7);
		if (pref != "http://" && pref != "https:/")
		{ // local file
			try {
				var bytes = ByteArray.readFile(request.url);
				switch(dataFormat)
				{
					case TEXT:
						data = bytes.asString();
					case VARIABLES:
						data = new URLVariables(bytes.asString());
					default:
						data = bytes;
				}
			}
			catch (e:Dynamic)
			{
				onError(e);
				return;
			}

         nmeDataComplete();
		}
		else
		{
         request.nmePrepare();
			nmeHandle = nme_curl_create(request);
			if (nmeHandle == null)
			{
				onError("Could not open URL");
			}
			else
				activeLoaders.push(this);
		}
	}
	
   function nmeDataComplete()
   {
      if (nmeOnComplete!=null)
      {
         if (nmeOnComplete(data))
            dispatchEvent(new Event(Event.COMPLETE));
         else
            DispatchIOErrorEvent();
      }
      else
      {
         dispatchEvent(new Event(Event.COMPLETE));
      }
   }


	
	/**
	 * @private
	 */
	public static function nmeLoadPending()
	{
		return !activeLoaders.isEmpty();
	}
	
	
	/**
	 * @private
	 */
	public static function nmePollData()
	{
		if (!activeLoaders.isEmpty())
		{
			nme_curl_process_loaders();
			var oldLoaders = activeLoaders;
			activeLoaders = new List<URLLoader>();
			for (loader in oldLoaders)
			{
				loader.update();
				if (loader.state == urlLoading)
					activeLoaders.push(loader);
			}
		}
	}
	
	
	private function onError(msg):Void
	{
		dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, true, false, msg));
	}
	
	
	private function update()
	{
		if (nmeHandle != null)
		{
			var old_state = state;
			var old_loaded = bytesLoaded;
			var old_total = bytesTotal;
			nme_curl_update_loader(nmeHandle, this);
			if (old_total < 0 && bytesTotal > 0)
			{
				dispatchEvent(new Event(Event.OPEN));
			}
			
			if (bytesTotal > 0 && bytesLoaded != old_loaded)
			{
				dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, bytesLoaded, bytesTotal));
			}
			
			var code:Int = nme_curl_get_code(nmeHandle);
			if (state == urlComplete)
			{
				if (code < 400) 
				{
					var bytes:ByteArray = nme_curl_get_data(nmeHandle);
					switch(dataFormat)
					{
						case TEXT, VARIABLES:
							data = bytes == null ? "" : bytes.asString();
						default:
							data = bytes;
					}
               nmeDataComplete();
				}
				else 
				{
					// XXX : This should be handled in project/common/CURL.cpp
					var evt = new IOErrorEvent(IOErrorEvent.IO_ERROR, true, false, "HTTP status code " + Std.string(code), code);
					nmeHandle = null;
					dispatchEvent(evt);
				}
			}
			else if (state == urlError)
			{
				var evt = new IOErrorEvent(IOErrorEvent.IO_ERROR,	true, false, nme_curl_get_error_message(nmeHandle), code);
				nmeHandle = null;
				dispatchEvent(evt);
			}
		}
	}
	
	
	
	// Native Methods
	
	
	
	private static var nme_curl_create = Loader.load("nme_curl_create", 1);
	private static var nme_curl_process_loaders = Loader.load("nme_curl_process_loaders", 0);
	private static var nme_curl_update_loader = Loader.load("nme_curl_update_loader", 2);
	private static var nme_curl_get_code = Loader.load("nme_curl_get_code", 1);
	private static var nme_curl_get_error_message = Loader.load("nme_curl_get_error_message", 1);
	private static var nme_curl_get_data = Loader.load("nme_curl_get_data", 1);
	private static var nme_curl_get_cookies = Loader.load("nme_curl_get_cookies", 1);
	private static var nme_curl_initialize = Loader.load("nme_curl_initialize", 1);

}


#elseif js

import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.IOErrorEvent;
import nme.utils.ByteArray;

import Html5Dom;
import js.Dom;
import js.Lib;
import js.XMLHttpRequest;

/**
* @author	Hugh Sanderson
* @author	Niel Drummond
* @author	Russell Weir
* @todo open and progress events
* @todo Complete Variables type
**/
class URLLoader extends flash.events.EventDispatcher
{
	var http:Http;
	public var bytesLoaded:Int;
	public var bytesTotal:Int;
	public var data:Dynamic;
	public var dataFormat:URLLoaderDataFormat;

	public function new(?request:URLRequest)
	{
		super();
		bytesLoaded = 0;
		bytesTotal = 0;
		dataFormat = URLLoaderDataFormat.TEXT;
		if(request != null)
			load(request);
	}

	public function close() { }

	public function load(request:URLRequest)
	{
		http = new Http( request.url );
		http.onData = onData;
		http.onError = onError;
		// TODO: make dataFormat uniform with the flash API
		http.requestUrl( STREAM( (dataFormat == URLLoaderDataFormat.TEXT) ? TEXT : BINARY ) );

	}

	function onData (_) {
		var content = http.getData();
		switch(dataFormat) {
		case BINARY:
			this.data = new ByteArray();
			for( i in 0...content.length ) {
				var c : Int = untyped content["cca"](i) & 0xFF;
				this.data.writeByte(c);
			}
			this.data.position = 0;
		case TEXT:
			this.data = content;
		case VARIABLES:
			throw "Not complete";
		}

		var evt = new Event(Event.COMPLETE);
		dispatchEvent(evt);
	}

	function onError (msg) {
		flash.Lib.trace(msg);
		var evt = new IOErrorEvent(IOErrorEvent.IO_ERROR);
		dispatchEvent(evt);
	}

}

private enum HttpType
{
	IMAGE;
	VIDEO;
	AUDIO;
	STREAM( format:DataFormat );
}

private enum DataFormat
{
	BINARY;
	TEXT;
}

private class Http extends haxe.Http
{

	public function new( url:String )
	{
		super(url);
	}

	function registerEvents( subject:EventTarget )
	{
		untyped subject.onload = onData;
		untyped subject.onerror = onError;
		//subject.addEventListener( "load", cast onData, false );
		//subject.addEventListener( "error", cast onError, false );
	}

	// Always GET, always async
	public function requestUrl( type:HttpType ) : Void
	{
		var self = this;

		switch (type) 
		{
			case STREAM( dataFormat ):
				var xmlHttpRequest : XMLHttpRequest = untyped __new__("XMLHttpRequest");

				switch (dataFormat) {
					case BINARY: untyped xmlHttpRequest.overrideMimeType('text/plain; charset=x-user-defined');
					default:
				}
				
				registerEvents(cast xmlHttpRequest);

				var uri = null;
				for( p in params.keys() )
					uri = StringTools.urlDecode(p)+"="+StringTools.urlEncode(params.get(p));

				try {
					if( uri != null ) {
						var question = url.split("?").length <= 1;
						xmlHttpRequest.open("GET",url+(if( question ) "?" else
									"&")+uri,true);
						uri = null;
					} else
						xmlHttpRequest.open("GET",url,true);
				} catch( e : Dynamic ) {
					throw e.toString();
				}

				xmlHttpRequest.send(uri);
				getData = function () { return xmlHttpRequest.responseText; };
			case IMAGE:
				var image : Image = cast Lib.document.createElement("img");
				registerEvents(cast image);

				image.src = url;
				#if debug
				image.style.display = "none";
				Lib.document.body.appendChild(image);
				#end

				getData = function () { return image; };
				
			case AUDIO:
				var audio : {src:String, style:Style} = cast Lib.document.createElement("audio");
				registerEvents(cast audio);

				audio.src = url;
				#if debug
				Lib.document.body.appendChild(cast audio);
				#end

				getData = function () { return audio; }
				
			case VIDEO:
				var video : {src:String, style:Style} = cast Lib.document.createElement("video");
				registerEvents(cast video);

				video.src = url;
				#if debug
				video.style.display = "none";
				Lib.document.body.appendChild(cast video);
				#end
				
				getData = function () { return video; }
		}

	}
	public dynamic function getData () : Dynamic { }
}

#else
typedef URLLoader = flash.net.URLLoader;
#end
