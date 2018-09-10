package nme.net;

#if (!flash)

import nme.events.NetStatusEvent;

@:nativeProperty
class NetConnection extends nme.events.EventDispatcher
{
   public static inline var defaultObjectEncoding : Int = 0;
   public var client : Dynamic;
   public var connected(get,null) : Bool;
   public var objectEncoding(default,null) : Int;
   public var uri(default,null) : String;
   public var connectedProxyType(default,null) : String;
   public var proxyType(get, set): String;
   public var usingTLS(default,null) : Bool;


   public function new() : Void
   {
      super();
      objectEncoding = 0;
      connectedProxyType = "";
      usingTLS = false;
   }
   public function connect(command : String, ?p1 : Dynamic, ?p2 : Dynamic, ?p3 : Dynamic, ?p4 : Dynamic, ?p5 : Dynamic) : Void
   {
      uri = command;
      if (uri==null || uri=="")
         dispatchEvent( new NetStatusEvent(NetStatusEvent.NET_STATUS, false, false,
              { code:"NetConnection.Connect.Success", level:"status" }  ) );
   }
   public function close() : Void
   {
   }
   function get_connected() { return false; }
   function get_proxyType() { return ""; }
   function set_proxyType(inType:String) { return inType; }

   //function addHeader(operation : String, mustUnderstand : Bool = false, ?param : nme.utils.Object) : Void;
   //function call(command : String, responder : Responder, ?p1 : Dynamic, ?p2 : Dynamic, ?p3 : Dynamic, ?p4 : Dynamic, ?p5 : Dynamic) : Void;
}

#else
typedef NetConnection = flash.net.NetConnection;
#end
