package nme.watchos;

import cpp.objc.*;
import ios.watchconnectivity.WCSession;
import ios.watchconnectivity.WCSessionDelegate;
import ios.watchconnectivity.WCSessionActivationState;


class App implements WCSessionDelegate
{
   public static var instance(default,null):App;

   public function new()
   {
      instance = this;
   }

   public function activateWCSession()
   {
      if (WCSession.isSupported())
      {
          trace("Setting default");
          var session = WCSession.defaultSession();
          session.delegate = this;
          session.activateSession();
      }
      else
         trace("WCSession not supported");
   }


   // From ExtensionDelegate
   public function applicationDidFinishLaunching()
   {
      trace("applicationDidFinishLaunching");
   }

   public function applicationDidBecomeActive()
   {
      trace("applicationDidBecomeActive");
   }

   public function applicationWillResignActive()
   {
      trace("applicationWillResignActive");
   }



   // From InterfaceController...
   // public static function setInterfaceController(controller:ios.watchkit.InterfaceController)

   public function onAwake()
   {
      trace("onAwake");
   }

   public function willActivate()
   {
      trace("willActivate");
   }


   public function didDeactivate()
   {
      trace("didDeactivate");
   }


   public function onButton(buttonId:Int)
   {
      trace('buttonId $buttonId');
   }


   // WCSessionDelegate
   public function activationCompleted(s:WCSession, state:WCSessionActivationState, error:NSError)
   {
      trace("activationCompleted " + state);
   }

   public function onContext(session:WCSession, context:StringIdMap):Void
   {
      var ctx:Dynamic = context;
      trace("didReceiveApplicationContext " + ctx);
   }

   // ios only
   #if iphone
   public function sessionDidBecomeInactive(session:WCSession) : Void;
   public function sessionDidDeactivate(session:WCSession) : Void;
   #end

   public function sessionWatchStateDidChange(session:WCSession):Void
   {
      trace("sessionWatchStateDidChange");
   }

   public function sessionReachabilityDidChange(session:WCSession):Void
   {
      trace("sessionWatchStateDidChange");
   }

}

