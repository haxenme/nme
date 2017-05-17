package nme.net.http;

import sys.FileSystem;
import haxe.io.Bytes;

class FileServer
{
   var dirs:Array<String>;

   public function new(inDirs:Array<String>)
   {
      dirs = inDirs;
   }

   public function onRequest(request:Request):Bytes
   {
      for(d in dirs)
      {
         var path = d + "/" + request.url;
         if (FileSystem.exists(path))
         {
            var data = sys.io.File.getBytes(path);

            var header = ["HTTP/1.1 200 OK",
                          "Content-Length: " + data.length,
                          //"Content-Type: text/html",
                          "","" ];
            var hData = Bytes.ofString(header.join("\r\n"));
            var result = Bytes.alloc(hData.length + data.length);
            result.blit(0,hData,0,hData.length);
            result.blit(hData.length,data,0,data.length);
            return result;
         }
      }
      trace("Not found: " + request.url );
      return Bytes.ofString("HTTP/1.1 404 Not Found\r\n\r\n");
   }
}


