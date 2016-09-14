package ios.watchconnectivity;
import cpp.objc.*;

@:objc
@:native("WCSession")
@:include("WatchConnectivity/WatchConnectivity.h")
extern class WCSession
{
   public var delegate:Protocol<WCSessionDelegate>;

   public function isSupported():Bool;
   public var defaultSession(default,null):WCSession;
   public function activateSession():Void;
   public var paired(default,null):Bool;
   public var watchAppInstalled(default,null):Bool;
   public var complicationEnabled(default,null):Bool;
   //public var watchDirectoryURL(default,null):NSURL;
   public var reachable(default,null):Bool;


   @:native("updateApplicationContext:error")
   public function updateApplicationContext(applicationContext:StringIdMap,
                                            error:cpp.Pointer<NSError> ):Bool;

   public var applicationContext(default,null):StringIdMap;

   public var receivedApplicationContext(default,null):StringIdMap;

   @:native("sendMessage:replyHandler:errorHandler")
   public function sendMessage(message:StringIdMap, onReply:ObjcBlock< StringIdMap->Void >, onError: ObjcBlock< NSError->Void > ):Void;

   @:native("sendMessageData:replyHandler:errorHandler")
   public function sendMessageData(data:NSData, onReply:ObjcBlock< NSData->Void >, onError: ObjcBlock< NSError->Void > ):Void;

   /*
   public function transferCurrentComplicationUserInfo(data:StringIdMap):WCSessionUserInfoTransfer;
   public function transferUserInfo(userInfo:StringIdMap):WCSessionUserInfoTransfer;
   public var outstandingUserInfoTransfers:NSArray<WCSessionUserInfoTransfer>;
   */
}




