package nme.net;
#if (!flash)

import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.IOErrorEvent;
import nme.events.ProgressEvent;
import nme.events.HTTPStatusEvent;
import nme.utils.ByteArray;
import nme.Loader;

#if !no_haxe_http
// Not using haxe.http avoids inclusing all the https cpp code
import nme.net.HttpLoader;
#end

#if html5
// ok
#else
#elseif neko
import neko.FileSystem;
import neko.io.File;
#else
import cpp.FileSystem;
import cpp.io.File;
#end

import nme.NativeHandle;
import nme.NativeResource;



@:nativeProperty
class URLLoader extends EventDispatcher 
{
   public var bytesLoaded(default, null):Int;
   public var bytesTotal(default, null):Int;
   public var data:Dynamic;
   public var dataFormat:URLLoaderDataFormat;

   public var nmeHandle:NativeHandle;
   #if !no_haxe_http
   public var httpLoader:HttpLoader;
   #end

   private static var hasCurlLoader = false;
   private static var activeLoaders = new List<URLLoader>();

   public static inline var urlInvalid    = 0;
   public static inline var urlInit       = 1;
   public static inline var urlLoading    = 2;
   public static inline var urlComplete    = 3;
   public static inline var urlError       = 4;
   public static inline var urlClosed      = 5;

   private var state:Int;
   public var nmeOnComplete:Dynamic -> Bool;

   public function new(?request:URLRequest) 
   {
      super();

      nmeHandle = null;
      bytesLoaded = 0;
      bytesTotal = -1;
      state = urlInvalid;
      dataFormat = URLLoaderDataFormat.TEXT;

      if (request != null)
         load(request);
   }

   public function close():Void
   {
      activeLoaders.remove(this);
      if (nmeHandle!=null)
         nme_curl_close(nmeHandle);
      #if !no_haxe_http
      if (httpLoader!=null)
        httpLoader.close();
      #end
      disposeHandler();
   }

   override public function toString()
   {
      #if no_haxe_http
      return 'URLLoader(${nmeHandle!=null?"curl":"null"})';
      #else
      return 'URLLoader(${nmeHandle!=null?"curl":httpLoader!=null?"http":"null"})';
      #end
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

      if (request.allowFile && (pref != "http://" && pref != "https:/"))
      {
         // local file
         try 
         {
            var bytes = ByteArray.readFile(request.url);

            if (bytes == null)
               throw("Could not open file \"" + request.url + "\"");

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
         catch(e:Dynamic) 
         {
            onError(e);
            return;
         }

         nmeDataComplete();
      }
      else 
      {
         request.nmePrepare();

         #if no_haxe_http
         var tryCurl = true;
         #else
         var tryCurl = !request.preferHaxeHttp;
         #end

         if (tryCurl)
         {
            nmeHandle = nme_curl_create(request);
         }

         #if !no_haxe_http
         if (nmeHandle==null)
         {
            httpLoader = new HttpLoader(this,request);
         }
         else
         #end
         {
            hasCurlLoader = true;
         }

         if (nmeHandle==null #if !no_haxe_http && HttpLoader==null #end )
            onError("Could not open URL");
         else
         {
            #if js if (nmeHandle!=null) nme.NativeResource.lockHandler(this); #end
            activeLoaders.push(this);
         }
      }
   }

   private function nmeDataComplete()
   {
      activeLoaders.remove(this);

      if (nmeOnComplete != null) 
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
      disposeHandler();
   }

   public static function nmeLoadPending()
   {
      return !activeLoaders.isEmpty();
   }

   public static function nmePollData()
   {
      if (!activeLoaders.isEmpty()) 
      {
         pollLoaders();

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

   private function onError(msg):Void
   {
      activeLoaders.remove(this);
      dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, true, false, msg));
      disposeHandler();
   }

   private function dispatchHTTPStatus(code:Int):Void
   {
      var evt = new HTTPStatusEvent (HTTPStatusEvent.HTTP_STATUS, false, false, code);
      var headers:Array<String> = getHeaders();

      for(h in headers)
      {
         var idx = h.indexOf(": ");
         if(idx > 0)
            evt.responseHeaders.push(new URLRequestHeader(h.substr(0, idx), h.substr(idx + 2, h.length - idx - 4)));
      }

      dispatchEvent (evt);
   }

   private function update()
   {
      if (nmeHandle!=null #if !no_haxe_http || httpLoader!=null #end )
      {
         var old_loaded = bytesLoaded;
         var old_total = bytesTotal;
         updateLoader();

         if (old_total < 0 && bytesTotal > 0) 
         {
            dispatchEvent(new Event(Event.OPEN));
         }

         if (bytesTotal > 0 && bytesLoaded != old_loaded) 
         {
            dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, bytesLoaded, bytesTotal));
         }

         var code:Int = getCode();

         if (state == urlComplete) 
         {
            dispatchHTTPStatus(code);

            if (code < 400) 
            {

               switch(dataFormat) 
               {
                  case TEXT, VARIABLES:
                     data = getString();
                  default:
                     data = getData();
               }
               nmeDataComplete();

            }
            else 
            {
               // XXX : This should be handled in project/common/CURL.cpp
               var evt = new IOErrorEvent(IOErrorEvent.IO_ERROR, true, false, "HTTP status code " + Std.string(code), code);
               dispatchEvent(evt);
               disposeHandler();
            }

         }
         else if (state == urlError) 
         {
            dispatchHTTPStatus(code);

            var evt = new IOErrorEvent(IOErrorEvent.IO_ERROR, true, false, getErrorMessage(), code);

            dispatchEvent(evt);
            disposeHandler();
         }
      }
   }



   function getErrorMessage() : String
   {
      if (nmeHandle!=null)
         return nme_curl_get_error_message(nmeHandle);
      #if no_haxe_http
      return null;
      #else
      return httpLoader.getErrorMessage();
      #end
   }
   function getData(): ByteArray
   {
      if (nmeHandle!=null)
         return nme_curl_get_data(nmeHandle);
      #if no_haxe_http
      return null;
      #else
      return httpLoader.getData();
      #end
   }
   function getString(): String
   {
      if (nmeHandle!=null)
      {
         var bytes:ByteArray = getData();
         return bytes == null ? "" : bytes.asString();
      }
      #if no_haxe_http
      return "";
      #else
      return httpLoader.getString();
      #end
   }
   function getCode(): Int
   {
      if (nmeHandle!=null)
         return nme_curl_get_code(nmeHandle);
      #if no_haxe_http
      return 400;
      #else
      return httpLoader.getCode();
      #end
   }
   function updateLoader()
   {
      if (nmeHandle!=null)
      {
         nme_curl_update_loader(nmeHandle,this);
      }
      #if !no_haxe_http
      else
      {
         bytesLoaded = httpLoader.bytesLoaded;
         bytesTotal = httpLoader.bytesTotal;
         state = httpLoader.state;
      }
      #end
   }
   function getHeaders() : Array<String>
   {
      if (nmeHandle!=null)
         return nme_curl_get_headers(nmeHandle);
      #if no_haxe_http
      return null;
      #else
      return httpLoader.getHeaders();
      #end
   }


   public function getCookies():Array<String>
   {
      if (nmeHandle!=null)
         return nme_curl_get_cookies(nmeHandle);
      #if no_haxe_http
      return null;
      #else
      return httpLoader==null ? null : httpLoader.getCookies();
      #end
   }

   static function pollLoaders()
   {
      if (hasCurlLoader)
         nme_curl_process_loaders();
   }

   function disposeHandler()
   {
      if (nmeHandle!=null)
         nme.NativeResource.disposeHandler(this);
   }



   // Native Methods
   private static var nme_curl_create = Loader.load("nme_curl_create", 1);
   private static var nme_curl_process_loaders = Loader.load("nme_curl_process_loaders", 0);
   private static var nme_curl_update_loader = Loader.load("nme_curl_update_loader", 2);
   private static var nme_curl_get_code = Loader.load("nme_curl_get_code", 1);
   private static var nme_curl_get_error_message = Loader.load("nme_curl_get_error_message", 1);
   private static var nme_curl_get_data = Loader.load("nme_curl_get_data", 1);
   private static var nme_curl_get_cookies = Loader.load("nme_curl_get_cookies", 1);
   private static var nme_curl_get_headers = Loader.load("nme_curl_get_headers", 1);
   private static var nme_curl_close = Loader.load("nme_curl_close", 1);
   private static var nme_curl_initialize = Loader.load("nme_curl_initialize", 1);
}

#else
typedef URLLoader = flash.net.URLLoader;
#end
