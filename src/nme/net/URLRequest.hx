package nme.net;
#if (!flash)

import nme.utils.ByteArray;
import nme.net.URLVariables;

@:nativeProperty
class URLRequest 
{
   public static inline var AUTH_BASIC = 0x0001;
   public static inline var AUTH_DIGEST = 0x0002;
   public static inline var AUTH_GSSNEGOTIATE = 0x0004;
   public static inline var AUTH_NTLM = 0x0008;
   public static inline var AUTH_DIGEST_IE = 0x0010;
   public static inline var AUTH_DIGEST_ANY = 0x000f;

   public var url:String;
   public var userAgent:String;
   public var requestHeaders:Array<URLRequestHeader>;
   public var authType:Int;
   public var cookieString:String;
   public var verbose:Bool;
   public var method:String;
   public var contentType:String;
   public var data:Dynamic;
   public var credentials:String;
   public var followRedirects:Bool;

   /** @private */ public var __bytes:ByteArray;
   /** @private */ public var nmeBytes(get, set):ByteArray;
   
   public function new(?inURL:String) 
   {
      if (inURL != null)
         url = inURL;

      requestHeaders = [];
      method = URLRequestMethod.GET;

      verbose = false;
      cookieString = "";
      authType = 0;
      contentType = "application/x-www-form-urlencoded";
      credentials = "";
      followRedirects = true;
   }

   public function toString() return 'URLRequest($url)';

   public function launchBrowser():Void 
   {
      nme_get_url(url);
   }


   public function basicAuth(inUser:String, inPasswd:String) 
   {
      authType = AUTH_BASIC;
      credentials = inUser + ":" + inPasswd;
   }

   public function digestAuth(inUser:String, inPasswd:String) 
   {
      authType = AUTH_DIGEST;
      credentials = inUser + ":" + inPasswd;
   }

   /** @private */ public function nmePrepare()
   {
      if (data == null) 
      {
         nmeBytes = new ByteArray();
      }
      else if (#if (haxe_ver>="4.1") Std.isOfType #else Std.is #end(data, ByteArray)) 
      {
         nmeBytes = data;

      }
      else if (#if (haxe_ver>="4.1") Std.isOfType #else Std.is #end(data, URLVariablesBase))
      {
         var vars:URLVariables = data;
         var str = vars.toString();
         nmeBytes = new ByteArray();
         nmeBytes.writeUTFBytes(str);

      }
      else if (#if (haxe_ver>="4.1") Std.isOfType #else Std.is #end(data, String)) 
      {
         var str:String = data;
         nmeBytes = new ByteArray();
         nmeBytes.writeUTFBytes(str);

      }
      else if (#if (haxe_ver>="4.1") Std.isOfType #else Std.is #end(data, Dynamic)) 
      {
         var vars:URLVariables = new URLVariables();

         for(i in Reflect.fields(data))
            Reflect.setField(vars, i, Reflect.field(data, i));

         var str = vars.toString();
         nmeBytes = new ByteArray();
         nmeBytes.writeUTFBytes(str);
      }
      else 
      {
         throw "Unknown data type";
      }
   }
   
   private function get_nmeBytes():ByteArray { return __bytes; }
   private function set_nmeBytes(value:ByteArray):ByteArray { return __bytes = value; }

   private static var nme_get_url = Loader.load("nme_get_url", 1);
}

#else
typedef URLRequest = flash.net.URLRequest;
#end
