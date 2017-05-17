package nme.net.http;

import haxe.io.Bytes;

class Request
{
   public var method:String;
   public var url:String;
   public var version:String;
   public var body:String;
   public var headers:Map<String,String>;

   public function new(data:haxe.io.Bytes)
   {
      var parts = data.toString().split("\r\n");
      var req = "";
      for(i in 0...parts.length)
      {
         if (parts[i]=="")
         {
             var rest = i+1;
             if (rest<parts.length)
             {
                body = parts.slice(rest).join("\r\n");
                break;
             }
         }
         else if (i==0)
         {
            var reqs = parts[i].split(" ");
            method = reqs[0];
            url = StringTools.urlDecode(reqs[1]);
            version = reqs[2];
         }
         else
         {
            var header = parts[i];
            var col = header.indexOf(':');
            if (col>0)
            {
               if (headers==null)
                  headers = new Map<String,String>();
               headers.set(header.substr(0,col), header.substr(col+2));
            }
         }
      }
   }

   public function getHeader(name:String) : String
   {
      return headers==null ? null : headers.get(name);
   }

   public function isKeepAlive()
   {
      return getHeader("Connection")=="Keep-Alive";
   }
}


