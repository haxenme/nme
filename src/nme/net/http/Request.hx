package nme.net.http;

import haxe.io.Bytes;

class Request
{
   public var method:String;
   public var url:String;
   public var version:String;
   public var body:String;
   public var headers:Map<String,String>;

   public function new(inHeaders:haxe.ds.StringMap<String>, inBody:String)
   {
      headers = inHeaders;
      body = inBody;
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


