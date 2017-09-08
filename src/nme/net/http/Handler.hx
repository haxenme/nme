package nme.net.http;

import haxe.io.Bytes;

class Handler
{
   public var chained:Request->Bytes;
   public var log:String->Void;

   public function new(?inHandler:Handler, ?inLog:String->Void)
   {
      if (inHandler!=null)
      {
         log = inHandler.log;
         chained = inHandler.onRequest; 
      }
      if (inLog!=null)
         log = inLog;
   }


   public function defaultHandler(request:Request):Bytes
   {
      if (chained!=null)
         return chained(request);
      if (log!=null)
         log("404 not found: " + request.url );
      return Bytes.ofString("HTTP/1.1 404 Not Found\r\n\r\n");
   }

   public function onRequest(request:Request):Bytes
   {
      return defaultHandler(request);
   }
}



