package nme.net;

import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.IOErrorEvent;
import nme.events.ProgressEvent;
import nme.events.HTTPStatusEvent;
import nme.utils.ByteArray;
import haxe.Http;

class HttpLoader
{
   var urlLoader:URLLoader;
   var urlRequest:URLRequest;
   var errorMessage:String;
   var code:Int;
   var cookies:Array<String>;

   var byteData:ByteArray;
   var stringData:String;

   public var bytesLoaded(default,null):Int;
   public var bytesTotal(default,null):Int;
   public var state(default,null):Int;
   var http:Http;

   public function new(inLoader:URLLoader, inRequest:URLRequest)
   {
      urlLoader = inLoader;
      urlRequest = inRequest;
      bytesLoaded = 0;
      bytesTotal = 0;
      state = URLLoader.urlInit;

      http = new Http(inRequest.url);
      http.onError = onError;
      if (urlLoader.dataFormat== URLLoaderDataFormat.BINARY)
         http.onBytes = onBytes;
      else
         http.onData = onString;
      http.onStatus = onStatus;

      for(header in urlRequest.requestHeaders)
         http.addHeader(header.name, header.value);

      if (urlRequest.userAgent!="")
         http.setHeader("User-Agent", urlRequest.userAgent);

      var isPost = urlRequest.method==URLRequestMethod.POST;
      if (isPost)
         http.setPostBytes(urlRequest.nmeBytes);

      http.request(isPost);
   }

   function onError(e:String)
   {
      errorMessage = e;
      state = URLLoader.urlError;
      code = 400;
   }

   function onString(data:String)
   {
      stringData = data;
   }

   function onBytes(data:haxe.io.Bytes)
   {
      byteData = ByteArray.fromBytes(data);
   }
   function onStatus(inStatus:Int)
   {
      code = inStatus;
   }


   public static function pollAll()
   {
   }

   public function getErrorMessage() return errorMessage;
   public function getData(): ByteArray return byteData;
   public function getString(): String return stringData;
   public function getCode(): Int return code;
   public function getHeaders() : Array<String>
   {
      var headerMap = http.responseHeaders;
      return [ for(h in headerMap.keys()) h + ": " + headerMap.get(h) ];
   }

   public function getCookies():Array<String> return cookies;
}

