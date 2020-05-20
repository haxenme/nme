package nme.store;

class AppLovin
{
   static var watcher:String->Void;
   static var afterInterstitial:Void->Void;
   static var onRewardWatched:Bool->Void;
   public static var isPreloaded = false;
   public static var rewardReady = false;

   function new() {}
   @:keep function onAppLovin(event:String) onEvent(event);

   public static function setWatcher(watcher:String->Void, andPreload:Bool)
   {
      #if android
      androidSetWatcher( new AppLovin(), andPreload );
      #end
   }

   public static function onEvent(e:String)
   {
      trace("AppLovin:" + e);
      switch(e)
      {
         case "onInterstitialHidden":
            if (afterInterstitial!=null)
            {
               var func = afterInterstitial;
               afterInterstitial = null;
               //trace("onInterstitialHidden -> " + func);
               func();
            }
         case "onInterstitialPreloaded":
            isPreloaded = true;

         case "onInterstitialPreloadFailed":
            isPreloaded = false;

         case "onRewardPreloaded":
            rewardReady = true;

         case "onRewardPreloadFailed":
            rewardReady = false;

         case "onRewardVerified":
            if (onRewardWatched!=null)
            {
               var func = onRewardWatched;
               onRewardWatched = null;
               func(true);
            }
            //else
           //    trace("no onReward callback");

         case "onRewardOverQuota", "onRewardRejected", "onRewardFailed",
              "onRewardCaneled", "rewardNotAvailable":
            if (onRewardWatched!=null)
            {
               var func = onRewardWatched;
               onRewardWatched = null;
               func(false);
            }
      }
      if (watcher!=null)
         watcher(e);
   }

   public static function playInterstitial(?inAfterInterstitial:Void->Void)
   {
      #if android
      afterInterstitial = inAfterInterstitial;
      androidPlayInterstitial();
      #else
      if (inAfterInterstitial!=null)
         inAfterInterstitial();
      #end
   }

   public static function playReward(inRewardWatched:Bool->Void)
   {
      #if android
      onRewardWatched = inRewardWatched;
      androidPlayReward();
      #else
      if (inRewardWatched!=null)
         inRewardWatched(false);
      #end
   }


   #if android
   static var androidSetWatcher = JNI.createStaticMethod("org/haxe/nme/NmeAppLovin", "setWatcher", "(Lorg/haxe/nme/HaxeObject;Z)V");
   static var androidPlayInterstitial = JNI.createStaticMethod("org/haxe/nme/NmeAppLovin", "playInterstitial", "()V");
   static var androidPlayReward = JNI.createStaticMethod("org/haxe/nme/NmeAppLovin", "playReward", "()V");
   #end
}


