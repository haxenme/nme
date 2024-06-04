package nme.net;

import nme.events.Event;
import nme.events.EventDispatcher;
import nme.events.IOErrorEvent;
import nme.events.ProgressEvent;
import nme.events.HTTPStatusEvent;
import nme.utils.ByteArray;
import haxe.Http;
#if haxe4
import sys.thread.Mutex;
import sys.thread.Thread;
#else
import cpp.vm.Mutex;
import cpp.vm.Thread;
#end

private class OutputWatcher extends haxe.io.BytesOutput
{
   var loader:HttpLoader;
   public function new(inLoader:HttpLoader)
   {
      loader = inLoader;
      super();
   }

   override public function prepare(nbytes:Int)
   {
      super.prepare(nbytes);
      loader.onBytesTotal(nbytes);
   }

   override function writeBytes(buf:haxe.io.Bytes, pos:Int, len:Int):Int
   {
      var result = super.writeBytes(buf, pos, len);
      loader.onBytesLoaded(b.length);
      return result;
   }
}

class HttpLoader
{
   static var jobs:Array<Void->Void>;
   static var mutex:Mutex;
   static var workers = 0;


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
      state = URLLoader.urlLoading;
      code = 0;

      http = new Http(inRequest.url);
      http.onError = onError;
      http.onStatus = onStatus;

      for(header in urlRequest.requestHeaders)
         http.addHeader(header.name, header.value);

      if (urlRequest.userAgent!="")
         http.setHeader("User-Agent", urlRequest.userAgent);

      var isPost = urlRequest.method==URLRequestMethod.POST;
      if (isPost)
         http.setPostBytes(urlRequest.nmeBytes);

      runAsync(run);
   }

   public function run()
   {
      var output = new OutputWatcher(this);

      var isPost = urlRequest.method==URLRequestMethod.POST;
      http.customRequest(isPost, output);

      if (state!=URLLoader.urlError)
      {
         var bytes = output.getBytes();

         bytesLoaded = bytesTotal = bytes.length;

         var encoding =  http.responseHeaders.get("Content-Encoding");
         if (encoding=="gzip")
         {
            var decoded = false;
            try
            {
               if (bytes.length>10 && bytes.get(0)==0x1f && bytes.get(1)==0x8b)
               {
                  var u = new haxe.zip.Uncompress(15|32);
                  var tmp = haxe.io.Bytes.alloc(1<<16);
                  u.setFlushMode(haxe.zip.FlushMode.SYNC);
                  var b = new haxe.io.BytesBuffer();
                  var pos = 0;
                  while (true) {
                     var r = u.execute(bytes, pos, tmp, 0);
                     b.addBytes(tmp, 0, r.write);
                     pos += r.read;
                     if (r.done)
                       break;
                  }
                  u.close();
                  bytes = b.getBytes();
                  decoded = bytes!=null;
               }
            }
            catch(e:Dynamic)
            {
               trace(e);
            }

            if (!decoded)
               onError("Bad GZip data");
         }

         if (urlLoader.dataFormat== URLLoaderDataFormat.BINARY)
         {
            byteData = ByteArray.fromBytes(bytes);
         }
         else
         {
            #if neko
            stringData = neko.Lib.stringReference(bytes);
            #else
            #if haxe4
            stringData = bytes.getString(0, bytes.length, UTF8);
            #else
            stringData = bytes.getString(0, bytes.length);
            #end
            #end
         }

         state = URLLoader.urlComplete;
      }
      else
      {
         //trace(" -> error");
      }
   }

   public function onBytesLoaded(count:Int)
   {
      if (count>bytesTotal)
         bytesTotal = count;
      bytesLoaded = count;
   }


   public function onBytesTotal(count:Int)
   {
      bytesTotal = count;
   }

   function onError(e:String)
   {
      errorMessage = e;
      if (code==0)
         code = 400;
      state = URLLoader.urlError;
   }

   function onStatus(inStatus:Int)
   {
      code = inStatus;
   }


   public static function runAsync(job:Void->Void)
   {
      if (jobs==null)
      {
         jobs = [];
         mutex = new Mutex();
      }

      mutex.acquire();
      jobs.push(job);
      if ( (workers<2 && jobs.length>1) || (workers==0) )
      {
         workers++;
         Thread.create(threadLoop);
      }
      mutex.release();
   }

   static function threadLoop()
   {
      while(true)
      {
         mutex.acquire();
         if (jobs.length==0)
         {
            workers--;
            mutex.release();
            return;
         }
         var job = jobs.shift();
         mutex.release();

         job();
      }
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
      if (headerMap==null)
         return [];
      return [ for(h in headerMap.keys()) h + ": " + headerMap.get(h) ];
   }

   public function getCookies():Array<String> return cookies;
}

