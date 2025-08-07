package nme.store;

class AdApi
{
   static var watcher:String->Void;
   static var afterInterstitial:Void->Void;
   static var onRewardWatched:Bool->Void;
   public static var isPreloaded = false;
   public static var rewardReady = false;

   static var onPrivacy:Void->Void;
   // use to wrap static context into instance
   #if android
   function new() {}
   public static var instance = new AdApi();
   // Called by andoid
   @:keep function onAdApi(event:String) onEvent(event);
   @:keep function onPrivacyShown() {
      var cb = onPrivacy;
      onPrivacy = null;
      if (cb!=null) cb();
   }
   #end

   public static function setWatcher(inWatcher:String->Void, preloadInterstitial:Bool, preloadReward:Bool)
   {
      if (!isValid())
         return false;

      watcher = inWatcher;

      #if NME_APPLOVIN_KEY
      return AppLovin.init(preloadInterstitial, preloadReward);
      #elseif NME_ADMOB_APP_ID
      return AdMob.init(preloadInterstitial, preloadReward
      #end
      return false;
   }


   public static function isValid()
   {
      #if NME_APPLOVIN_KEY
      return AppLovin.isValid();
      #elseif NME_ADMOB_APP_ID
      return AdMob.isValid();
      #end
      return false;
   }

   public static function playInterstitial(andThen:Void->Void)
   {
      if (!isPreloaded)
         return false;

      afterInterstitial = andThen;

      var ok = false;
      #if NME_APPLOVIN_KEY
      ok = AppLovin.playInterstitial(andThen);
      #elseif NME_ADMOB_APP_ID
      ok = AdMob.playInterstitial(andThen);
      #end

      if (!ok)
         afterInterstitial = null;
      return ok;
   }

   public static function playReward(onFinsish:Bool->Void)
   {
      if (!rewardReady)
      {
         return false;
      }

      onRewardWatched = onFinsish;

      var ok = false;
      #if NME_APPLOVIN_KEY
      ok = AppLovin.playReward();
      #elseif NME_ADMOB_APP_ID
      ok = AdMob.playReward();
      #end

      if (!ok)
         onRewardWatched = null;
      return ok;

   }

   public static function isPrivacyOptionRequired()
   {
      #if android
      return androidIsPrivacyOptionRequired();
      #else
      return false;
      #end
   }

   public static function showPrivacyOptionsForm(onShown:Void->Void) : Bool
   {
      #if android
      onPrivacy = onShown;
      var waitResult = androidShowPrivacyOptionsForm(instance);
      if (!waitResult)
         onPrivacy = null;
      return waitResult;
      #end
      return false;
   }



   public static function onEvent(e:String)
   {
      //trace("---------------------------AdMob:" + e);
      switch(e)
      {
         case "onInterstitialHidden", "onInterstitialFailedToShow":
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
         // ios
         case "onVideoBegan":
            nme.media.Sound.suspend(true);

         // ios
         case "onVideoEnded":
            nme.media.Sound.suspend(false);

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

  #if android
   static var androidIsPrivacyOptionRequired = JNI.createStaticMethod("org/haxe/nme/GameActivity", "isPrivacyOptionRequired", "()Z");
   static var androidShowPrivacyOptionsForm = JNI.createStaticMethod("org/haxe/nme/GameActivity", "showPrivacyOptionsForm", "(Lorg/haxe/nme/HaxeObject;)Z");
   #end
}

