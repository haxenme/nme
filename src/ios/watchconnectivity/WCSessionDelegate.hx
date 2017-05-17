package ios.watchconnectivity;
import cpp.objc.*;

@:headerCode("#import <WatchConnectivity/WatchConnectivity.h>")
@:objcProtocol("WCSessionDelegate")
interface WCSessionDelegate
{
   @:objcProtocol("session:activationDidCompleteWithState:error")
   public function activationCompleted(s:WCSession, state:WCSessionActivationState, error:NSError) : Void;

   @:objcProtocol("session:didReceiveApplicationContext")
   public function onContext(session:WCSession, context:NSDictionary):Void;

   // ios only
   #if iphone
   public function sessionDidBecomeInactive(session:WCSession) : Void;
   public function sessionDidDeactivate(session:WCSession) : Void;
   #end

   public function sessionWatchStateDidChange(session:WCSession):Void;
   public function sessionReachabilityDidChange(session:WCSession):Void;


}

