package nme.store;

#if ios
@:fileXml('tag="nme-haxe"')
@:cppInclude('./AppLovinIos.mm')
#end
class AppLovin
{
   static var watcher:String->Void;
   static var afterInterstitial:Void->Void;
   static var onRewardWatched:Bool->Void;
   public static var isPreloaded = false;
   public static var rewardReady = false;

   function new() {}
   @:keep function onAppLovin(event:String) onEvent(event);

   public static function setWatcher(inWatcher:String->Void, andPreload:Bool)
   {
      #if android
      androidSetWatcher( new AppLovin(), andPreload );
      #elseif ios
      //trace("--- setWatcher ---");

      watcher = inWatcher;
      if (andPreload)
      {
         loadInterstitialAd();
         loadRewardedVideo();
      }
      #end
   }

   public static function onEvent(e:String)
   {
      //trace("---------------------------AppLovin:" + e);
      switch(e)
      {
         case "onInterstitialHidden":
            nme.media.Sound.suspend(false);
            if (afterInterstitial!=null)
            {
               var func = afterInterstitial;
               afterInterstitial = null;
               //trace("onInterstitialHidden -> " + func);
               func();
            }
         case "onInterstitialPreloaded":
            isPreloaded = true;
         #if ios
         case "onVideoBegan":
            nme.media.Sound.suspend(true);

         case "onVideoEnded":
            nme.media.Sound.suspend(false);
         #end

         case "onInterstitialPreloadFailed":
            isPreloaded = false;

         case "onRewardPreloaded":
            rewardReady = true;

         case "onRewardPreloadFailed":
            rewardReady = false;

         case "onRewardHidden":
            nme.media.Sound.suspend(false);

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
      #elseif ios
      afterInterstitial = inAfterInterstitial;
      showInterstitialAd();
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
      #elseif ios
      onRewardWatched = inRewardWatched;
      showRewardedVideo();
      #else
      if (inRewardWatched!=null)
         inRewardWatched(false);
      #end
   }

   #if android
   static var androidSetWatcher = JNI.createStaticMethod("org/haxe/nme/NmeAppLovin", "setWatcher", "(Lorg/haxe/nme/HaxeObject;Z)V");
   static var androidPlayInterstitial = JNI.createStaticMethod("org/haxe/nme/NmeAppLovin", "playInterstitial", "()V");
   static var androidPlayReward = JNI.createStaticMethod("org/haxe/nme/NmeAppLovin", "playReward", "()V");
   #elseif ios
   @:native("loadInterstitialAd")
   extern static function loadInterstitialAd() : Void;
   @:native("loadRewardedVideo")
   extern static function loadRewardedVideo() : Void;
   @:native("showRewardedVideo")
   extern static function showRewardedVideo() : Void;
   @:native("showInterstitialAd")
   extern static function showInterstitialAd() : Void;
   #end
}


