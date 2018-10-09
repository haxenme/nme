package ios.watchconnectivity;
import cpp.objc.*;

@:objc
@:native("WCSession")
@:include("WatchConnectivity/WatchConnectivity.h")
extern class WCSession
{
   public static function isSupported():Bool;
   public static function defaultSession():WCSession;

   public var delegate:Protocol<WCSessionDelegate>;
   public function activateSession():Void;
   public var paired(default,null):Bool;
   public var watchAppInstalled(default,null):Bool;
   public var complicationEnabled(default,null):Bool;
   //public var watchDirectoryURL(default,null):NSURL;
   public var reachable(default,null):Bool;


   @:native("updateApplicationContext:error")
   public function updateApplicationContext(applicationContext:NSDictionary, error:cpp.RawPointer<NSError> ):Bool;

   public var applicationContext(default,null):NSDictionary;

   public var receivedApplicationContext(default,null):NSDictionary;

   @:native("sendMessage:replyHandler:errorHandler")
   public function sendMessage(message:NSDictionary, onReply:ObjcBlock< NSDictionary->Void >, onError: ObjcBlock< NSError->Void > ):Void;

   @:native("sendMessageData:replyHandler:errorHandler")
   public function sendMessageData(data:NSData, onReply:ObjcBlock< NSData->Void >, onError: ObjcBlock< NSError->Void > ):Void;


   /*
   public function transferCurrentComplicationUserInfo(data:NSDictionary):WCSessionUserInfoTransfer;
   public function transferUserInfo(userInfo:NSDictionary):WCSessionUserInfoTransfer;
   public var outstandingUserInfoTransfers:NSArray<WCSessionUserInfoTransfer>;
   */
}




