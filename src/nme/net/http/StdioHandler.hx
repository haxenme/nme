package nme.net.http;

import haxe.io.Bytes;

class StdioHandler extends Handler
{
   public function new(?inHandler:Handler, ?inLog:String->Void)
   {
      super(inHandler,inLog);
   }

   override public function onRequest(request:Request):Bytes
   {
      if (request.method=="POST" && request.url=="/stdio.html")
      {
         var parts = request.body.split("\r\n").join("").split("^");
         var message = parts[3];
         if (log!=null)
         {
            if (message==null)
               log("");
            else
               log( StringTools.urlDecode(message) );
         }

          var header = ["HTTP/1.1 200 OK",
                          "Content-Length: " + 0,
                          //"Content-Type: text/html",
                          "","" ];
          return Bytes.ofString(header.join("\r\n"));
      }
      return defaultHandler(request);
   }
}



