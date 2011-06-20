package nme.net;

import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.IOErrorEvent;
import nme.events.ProgressEvent;
import nme.utils.ByteArray;

/**
* @author   Hugh Sanderson
* @author   Niel Drummond
* @author   Russell Weir
* @todo open and progress events
* @todo Complete Variables type
**/


#if neko
import neko.FileSystem;
import neko.io.File;
#else
import cpp.FileSystem;
import cpp.io.File;
#end


class URLLoader extends nme.events.EventDispatcher
{
   public var bytesLoaded(default,null):Int;
   public var bytesTotal(default,null):Int;
   public var data:Dynamic;
   public var dataFormat:URLLoaderDataFormat;

   public var nmeHandle:Dynamic;
	var state:Int;

	static inline var urlInvalid = 0;
	static inline var urlInit = 1;
	static inline var urlLoading = 2;
	static inline var urlComplete = 3;
	static inline var urlError = 4;

	static var activeLoaders = new List<URLLoader>();

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

   public function close() { }

   public function load(request:URLRequest)
   {
		state = urlInit;
      var pref = request.url.substr(0,7);
      if(pref!="http://" && pref!="https:/")
		{ // local file
         try {
				var bytes = ByteArray.readFile(request.url);
            switch(dataFormat)
				{
               case TEXT, VARIABLES:
                  data = bytes.asString();
					default:
					   data = bytes;
            }
         } catch(e:Dynamic) {
            onError(e);
            return;
         }
         dispatchEvent( new nme.events.Event(nme.events.Event.COMPLETE) );
      }
		else
		{
		   nmeHandle = nme_curl_create(request.url, request.authType, request.userPassword,
                                     request.cookieString, request.verbose);
			if (nmeHandle==null)
			{
            onError("Could not open URL");
			}
			else
			   activeLoaders.push(this);
		}
   }

	public static function hasActive( ) { return !activeLoaders.isEmpty(); }

   function update()
	{
	   if (nmeHandle!=null)
		{
		   var old_state = state;
		   var old_loaded = bytesLoaded;
		   var old_total = bytesTotal;
		   nme_curl_update_loader(nmeHandle,this);
			if (old_total < 0 && bytesTotal>0)
			{
            dispatchEvent( new nme.events.Event(nme.events.Event.OPEN) );
			}

			if (bytesTotal>0 && bytesLoaded!=old_loaded)
			{
		      //trace("Loaded : " + bytesLoaded + "/" + bytesTotal );
            dispatchEvent(
				   new ProgressEvent(ProgressEvent.PROGRESS,false,false,bytesLoaded,bytesTotal) );
			}
         if (state==urlComplete)
			{
            //trace(getCookies());
				var bytes:ByteArray = nme_curl_get_data(nmeHandle);
				switch(dataFormat)
				{
               case TEXT, VARIABLES:
                  data = bytes.asString();
					default:
					   data = bytes;
            }
				nmeHandle = null;
            dispatchEvent( new nme.events.Event(nme.events.Event.COMPLETE) );
			}
         else if (state==urlError)
			{
            var evt =  new nme.events.IOErrorEvent(nme.events.IOErrorEvent.IO_ERROR,
				        true, false, nme_curl_get_error_message(nmeHandle),nme_curl_get_code(nmeHandle) );
				nmeHandle = null;
            dispatchEvent(evt);
			}
		}
	}

	public static function nmePollData( )
	{
	   if (!activeLoaders.isEmpty())
		{
			nme_curl_process_loaders();
		   var oldLoaders = activeLoaders;
		   activeLoaders = new List<URLLoader>();
	      for(loader in oldLoaders)
		   {
				loader.update();
				if (loader.state == urlLoading)
				   activeLoaders.push(loader);
		   }
		}
	}

   function onError(msg) :Void
	{
      dispatchEvent( new nme.events.IOErrorEvent(nme.events.IOErrorEvent.IO_ERROR, true, false, msg) );
   }

   public function getCookies() : Array<String>
   {
      return nme_curl_get_cookies(nmeHandle);
   }

	public static function nmeLoadPending() { return !activeLoaders.isEmpty(); }


	static var nme_curl_create = nme.Loader.load("nme_curl_create",5);
	static var nme_curl_process_loaders = nme.Loader.load("nme_curl_process_loaders",0);
	static var nme_curl_update_loader = nme.Loader.load("nme_curl_update_loader",2);
	static var nme_curl_get_code = nme.Loader.load("nme_curl_get_code",1);
	static var nme_curl_get_error_message = nme.Loader.load("nme_curl_get_error_message",1);
	static var nme_curl_get_data= nme.Loader.load("nme_curl_get_data",1);
	static var nme_curl_get_cookies= nme.Loader.load("nme_curl_get_cookies",1);

}

