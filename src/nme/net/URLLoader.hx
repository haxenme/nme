package nme.net;
#if (!flash)

import haxe.Http;
import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.IOErrorEvent;
import nme.events.ProgressEvent;
import nme.events.HTTPStatusEvent;
import nme.utils.ByteArray;

#if html5
// ok
#elseif neko
import neko.vm.Thread;
import neko.vm.Deque;
#else
import cpp.vm.Thread;
import cpp.vm.Deque;
#end

typedef WorkerCommand = {
    var code: Int;
    var urlLoader: URLLoader;
    var error: String;
    var status: Int;
    var headers: Map<String,String>;
    var data: Dynamic;
    var total: Int;
    var len: Int;
}

@:nativeProperty
class URLLoader extends EventDispatcher 
{
   public var bytesLoaded(default, null):Int;
   public var bytesTotal(default, null):Int;
   public var data:Dynamic;
   public var dataFormat:URLLoaderDataFormat;

    /** @private */ private var http: Http;
    /** @private */ private var thread: Thread;
   /** @private */ private static var activeLoaders = new Array<URLLoader>();
    /** @private */ private static var wCommands: Deque<WorkerCommand> = new Deque<WorkerCommand>();

   /** @private */ private var cookies:Array<String>;
   /** @private */ private var activeRequest:URLRequest;
   /** @private */ public var nmeOnComplete:Dynamic -> Bool;
   public function new(?request:URLRequest) 
   {
      super();

      bytesLoaded = 0;
      bytesTotal = -1;
      dataFormat = URLLoaderDataFormat.TEXT;

      if (request != null)
         load(request);
   }

   public function close() 
   {
       if(activeLoaders.indexOf(this) >= 0) {//still active
           this.thread.sendMessage("close");//terminate signal
           http.cancel();
       }
   }

   public function getCookies():Array<String> 
   {
      return cookies;
   }

    public static function closeAll() {
        for(loader in activeLoaders)
            loader.close();
    }

    public static function hasActive()
   {
      return activeLoaders.length != 0;
   }

   private function redirect(url: String) {
       if(url == null || url.length == 0 || activeRequest == null)
           return;

       var redirectRequest = new URLRequest(url);

       redirectRequest.userAgent = activeRequest.userAgent;
       redirectRequest.requestHeaders = activeRequest.requestHeaders;
       redirectRequest.authType = activeRequest.authType;
       redirectRequest.cookieString = activeRequest.cookieString;
       redirectRequest.verbose = activeRequest.verbose;
       redirectRequest.method = activeRequest.method;
       redirectRequest.contentType = activeRequest.contentType;
       redirectRequest.credentials = activeRequest.credentials;
       redirectRequest.followRedirects = activeRequest.followRedirects;

       load(redirectRequest);
   }

   public function load(request:URLRequest)
   {
      activeRequest = request;
      var pref = request.url.substr(0, 7);

      if (pref != "http://" && pref != "https:/") { // local file

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

         } catch(e:Dynamic) 
         {
            onError(e);
            return;
         }

            nmeDataComplete();

      }
      else
      {
         http = new Http(request.url, request.method);
         if(request.userAgent != null && request.userAgent.length > 0)
              http.setHeader("User-Agent", request.userAgent);
         if(request.contentType != null && request.contentType.length > 0)
             http.setHeader("Content-Type", request.contentType);

         var auth: String = "Anonymous";
         if (request.authType == URLRequest.AUTH_BASIC)
             auth = "Basic";
         else if (request.authType == URLRequest.AUTH_DIGEST)
             auth = "Digest";
         else if (request.authType == URLRequest.AUTH_GSSNEGOTIATE)
             auth = "Negotiate";
         else if (request.authType == URLRequest.AUTH_NTLM)
             auth = "NTLM";
         else if (request.authType == URLRequest.AUTH_DIGEST_IE)
             auth = "Digest";
         else if (request.authType == URLRequest.AUTH_DIGEST_ANY)
             auth = "Digest";

         if(request.credentials != null && request.credentials.length > 0)
             http.setHeader("Authorization", auth + " " + request.credentials);

         if(request.cookieString != null && request.cookieString.length > 0) {
             cookies = request.cookieString.split(";");
             http.setHeader("Cookie", request.cookieString);   //n=v; n=v;...
         }

         if(request.requestHeaders != null)
             for(requestHeader in request.requestHeaders)
                 http.setHeader(requestHeader.name, requestHeader.value);

         var post: Bool = request.method == URLRequestMethod.POST || request.method == URLRequestMethod.PUT;
         if(post)
            http.setPostData(request.data);
         else
             for(i in Reflect.fields(request.data))
                http.setParameter(i, Reflect.field(request.data, i));

         activeLoaders.push(this);

         thread = Thread.create(function(){
            var urlLoader: URLLoader = Thread.readMessage(true);
            var request: URLRequest = Thread.readMessage(true);
            var disableEventsAndStop: Bool = false;

            urlLoader.http.onError = function(error: String) {
                if(disableEventsAndStop)
                    return;
                disableEventsAndStop = true;
                wCommands.add({code: 0, urlLoader: urlLoader, error: error, status: 0, headers: null, data: null, total: 0, len: 0});
            }
            urlLoader.http.onStatus = function(status: Int) {
                if(disableEventsAndStop)
                    return;
                if(Thread.readMessage(false)=="close")
                    disableEventsAndStop = true;
                else {
                    if(status == 301 && request.followRedirects)
                        disableEventsAndStop = true;
                    wCommands.add({code: 1, urlLoader: urlLoader, error: null, status: status, headers: urlLoader.http.responseHeaders, data: null, total: 0, len: 0});
                    if(status >= 400){
                        disableEventsAndStop = true;
                        wCommands.add({code: 0, urlLoader: urlLoader, error: "HTTP status code " + status, status: status, headers: urlLoader.http.responseHeaders, data: null, total: 0, len: 0});
                    }
                }
            }
            urlLoader.http.onData = function(data: Dynamic) {
                if(disableEventsAndStop)
                    return;
                if(Thread.readMessage(false)=="close")
                    disableEventsAndStop = true;
                else {}
                    wCommands.add({code: 2, urlLoader: urlLoader, error: null, status: 0, headers: urlLoader.http.responseHeaders, data: data, total: 0, len: 0});
            }
            urlLoader.http.onResponseProgress = function(total: Int, len: Int): Bool {
                if(disableEventsAndStop)
                    return false;
                if(Thread.readMessage(false)=="close") {
                    disableEventsAndStop = true;
                    return false;
                }
                wCommands.add({code: 3, urlLoader: urlLoader, error: null, status: 0, headers: urlLoader.http.responseHeaders, data: null, total: total, len: len});
                return true;
            }
            try {
                urlLoader.http.request(post);
            } catch (error: String) {
                if(!disableEventsAndStop)
                    wCommands.add({code: 0, urlLoader: urlLoader, error: error, status: 0, headers: null, data: null, total: 0, len: 0});
                return;
            }
            //send remove from active signal
            wCommands.add({code: 4, urlLoader: urlLoader, error: null, status: 0, headers: urlLoader.http.responseHeaders, data: null, total: 0, len: 0});
         });
         thread.sendMessage(this);
         thread.sendMessage(request);
      }
   }

   /** @private */ private function nmeDataComplete() {
      activeLoaders.remove(this);

      if (nmeOnComplete != null) 
      {
         if (nmeOnComplete(data))
            dispatchEvent(new Event(Event.COMPLETE));
         else
            DispatchIOErrorEvent();

      } else 
      {
         dispatchEvent(new Event(Event.COMPLETE));
      }
   }

   /** @private */ public static function nmeLoadPending() {
      return activeLoaders.length != 0;
   }

   /** @private */ public static function nmePollData() {
      if (activeLoaders.length != 0)
      {
          var wCommand: WorkerCommand = wCommands.pop(false);
          if(wCommand != null) {
            if(wCommand.code == 0) {//error
                wCommand.urlLoader.onError(wCommand.error);
            } else if(wCommand.code == 1) {//status
                if(wCommand.status == 301 && wCommand.urlLoader.activeRequest.followRedirects)
                    wCommand.urlLoader.redirect(wCommand.headers.get("Location"));
                else {
                    var evt = new HTTPStatusEvent (HTTPStatusEvent.HTTP_STATUS, false, false, wCommand.status);
                    for(name in wCommand.headers.keys())
                    {
                        if(name != null && name.length > 0)
                            evt.responseHeaders.push(new URLRequestHeader(name, wCommand.headers.get(name)));
                    }

                    wCommand.urlLoader.dispatchEvent (evt);
                }
            } else if(wCommand.code == 2) {//completes
                switch(wCommand.urlLoader.dataFormat)
                {
                    case TEXT:
                        wCommand.urlLoader.data = wCommand.data;
                    case VARIABLES:
                        wCommand.urlLoader.data = new URLVariables(wCommand.data);
                    default:
                        wCommand.urlLoader.data =  ByteArray.fromBytes(haxe.io.Bytes.ofString(wCommand.data));
                }
                wCommand.urlLoader.nmeDataComplete();
            } else if(wCommand.code == 3) {//progress
                wCommand.urlLoader.bytesTotal = wCommand.total;
                wCommand.urlLoader.bytesLoaded = wCommand.len;
                wCommand.urlLoader.dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, wCommand.len,wCommand.total));
            } else //code = 4 or unspecified thread about to complete
                activeLoaders.remove(wCommand.urlLoader);//if still avtive
          }
      }
   }

   /** @private */ private function onError(msg):Void {
      activeLoaders.remove(this);
      dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, true, false, msg));
   }
}

#else
typedef URLLoader = flash.net.URLLoader;
#end
