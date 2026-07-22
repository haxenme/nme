package nme.net.http;

import haxe.io.Bytes;

class Request
{
   public var method:String;
   public var url:String;
   public var filePath(get,never):String;
   public var params(get,never):Map<String,String>;
   public var version:String;
   public var body:String;
   public var headers:Map<String,String>;

   public function new(inHeaders:haxe.ds.StringMap<String>, inBody:String)
   {
      headers = inHeaders;
      body = inBody;
   }

   function get_filePath() : String
   {
      var q = url.indexOf("?");
      return q >= 0 ? url.substr(0, q) : url;
   }

   function get_params() : Map<String,String>
   {
      var result = new Map<String,String>();
      var q = url.indexOf("?");
      if (q >= 0)
         for (pair in url.substr(q+1).split("&"))
         {
            var eq = pair.indexOf("=");
            if (eq >= 0)
               result.set(pair.substr(0,eq), pair.substr(eq+1));
            else if (pair.length > 0)
               result.set(pair, "");
         }
      return result;
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


