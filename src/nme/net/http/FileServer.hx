package nme.net.http;
using StringTools;

import sys.FileSystem;
import haxe.io.Bytes;

class FileServer extends Handler
{
   var dirs:Array<String>;
   var verbose:Bool;

   public function new(inDirs:Array<String>, ?inHandler:Handler, inVerbose=false)
   {
      super(inHandler);
      dirs = inDirs;
      verbose = inVerbose;
   }

   override public function onRequest(request:Request):Bytes
   {
      for(d in dirs)
      {
         var path = d + "/" + request.url;
         if (FileSystem.exists(path))
         {
            var data = sys.io.File.getBytes(path);

            var header = ["HTTP/1.1 200 OK",
                          "Content-Length: " + data.length
                          ];

            //"Content-Type: text/html",
            if (path.endsWith(".wasm"))
               header.push("Content-Type: application/wasm");
            header.push("");
            header.push("");
            var hData = Bytes.ofString(header.join("\r\n"));
            var result = Bytes.alloc(hData.length + data.length);
            result.blit(0,hData,0,hData.length);
            result.blit(hData.length,data,0,data.length);
            if (verbose && log!=null)
               log("file: " + request.url + " x " + data.length);
            return result;
         }
      }
      return defaultHandler(request);
   }
}


