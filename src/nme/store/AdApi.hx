package nme.store;

class AdApi
{
   static var watcher:String->Void;
   static var afterInterstitial:Void->Void;
   static var onRewardWatched:Bool->Void;
   public static var isPreloaded = false;
   public static var rewardReady = false;

   static var onPrivacy:Void->Void;
   static var interstitialRetryDelay = 30.0; // seconds; doubles on each failure, capped at 300s
   static var interstitialRetryTimer:haxe.Timer = null;
   static var rewardRetryDelay = 30.0;
   static var rewardRetryTimer:haxe.Timer = null;
   static var _consentGranted = false;      // true once canRequestAds was confirmed (SDK initialized)
   static var _consentUnavailable = false;  // true if consent explicitly required but not granted
   #if desktop
   static var hostMuteTestState:Bool = false;
   static var hostMuteTimer:haxe.Timer = null;
   #end
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
      trace("NME AdApi setWatcher preloadInterstitial=" + preloadInterstitial + " preloadReward=" + preloadReward);
      watcher = inWatcher;

      if (!isValid())
         return false;

      #if NME_APPLOVIN_KEY
      return AppLovin.init(preloadInterstitial, preloadReward);
      #elseif NME_ADMOB_APP_ID
      return AdMob.init(preloadInterstitial, preloadReward);
      #elseif NME_CRAZYGAMES_SDK
      return CrazyGames.init(preloadInterstitial, preloadReward);
      #end
      return false;
   }


   public static function isValid()
   {
      #if NME_APPLOVIN_KEY
      return AppLovin.isValid();
      #elseif NME_ADMOB_APP_ID
      return AdMob.isValid();
      #elseif NME_CRAZYGAMES_SDK
      return CrazyGames.isValid();
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
      ok = AppLovin.playInterstitial();
      #elseif NME_ADMOB_APP_ID
      ok = AdMob.playInterstitial();
      #elseif NME_CRAZYGAMES_SDK
      ok = CrazyGames.playInterstitial();
      #end

      if (!ok)
         afterInterstitial = null;
      return ok;
   }

   public static function hasAdNetwork()
   {
      #if NME_APPLOVIN_KEY
      return true;
      #elseif NME_ADMOB_APP_ID
      return true;
      #elseif NME_CRAZYGAMES_SDK
      return true;
      #end
      return false;
   }

   public static function playReward(onFinsish:Bool->Void) : Void
   {
      var ok = false;

      if (rewardReady)
      {
         rewardReady = false;
         onRewardWatched = onFinsish;

         #if NME_APPLOVIN_KEY
         ok = AppLovin.playReward();
         #elseif NME_ADMOB_APP_ID
         ok = AdMob.playReward();
         #elseif NME_CRAZYGAMES_SDK
         ok = CrazyGames.playReward();
         #end
         trace("NME AdApi playReward ok=" + ok);
      }
      else
      {
         trace("NME AdApi playReward called but rewardReady=" + rewardReady);
      }

      if (!ok)
      {
         onRewardWatched = null;
         onFinsish(false);
      }
   }

   public static function getMuteAudio():Bool
   {
      #if NME_CRAZYGAMES_SDK
      return CrazyGames.getMuteAudio();
      #end
      #if desktop
      var v = Sys.getEnv("NME_HOST_MUTE");
      if (v == "test") {
         if (hostMuteTimer == null) {
            hostMuteTimer = new haxe.Timer(5000);
            hostMuteTimer.run = function() {
               hostMuteTestState = !hostMuteTestState;
               onEvent("onSettingsChanged");
            };
         }
         return hostMuteTestState;
      }
      if (v != null && v != "0") return true;
      #end
      return false;
   }

   public static function reportGameplayStart():Void
   {
      #if NME_CRAZYGAMES_SDK
      CrazyGames.reportGameplayStart();
      #end
   }

   public static function reportGameplayStop():Void
   {
      #if NME_CRAZYGAMES_SDK
      CrazyGames.reportGameplayStop();
      #end
   }

   public static function happytime():Void
   {
      #if NME_CRAZYGAMES_SDK
      CrazyGames.happytime();
      #end
   }

   public static function reportGameCompletedPercentage(pct:Int):Void
   {
      #if NME_CRAZYGAMES_SDK
      CrazyGames.reportGameCompletedPercentage(pct);
      #end
   }

   public static function setGameContext(context:{}):Void
   {
      #if NME_CRAZYGAMES_SDK
      CrazyGames.setGameContext(context);
      #end
   }

   public static function clearGameContext():Void
   {
      #if NME_CRAZYGAMES_SDK
      CrazyGames.clearGameContext();
      #end
   }

   // Schedules a background retry with exponential backoff. No consent dialog shown.
   static function scheduleInterstitialRetry() {
      if (interstitialRetryTimer != null || !hasAdNetwork()) return;
      trace("NME AdApi scheduling interstitial retry in " + interstitialRetryDelay + "s");
      var delay = interstitialRetryDelay;
      interstitialRetryTimer = haxe.Timer.delay(function() {
         interstitialRetryTimer = null;
         interstitialRetryDelay = Math.min(delay * 2, 300.0);
         retryInterstitialLoad();
      }, Std.int(delay * 1000));
   }

   static function scheduleRewardRetry() {
      if (rewardRetryTimer != null || !hasAdNetwork() || _consentUnavailable) return;
      trace("NME AdApi scheduling reward retry in " + rewardRetryDelay + "s");
      var delay = rewardRetryDelay;
      rewardRetryTimer = haxe.Timer.delay(function() {
         rewardRetryTimer = null;
         rewardRetryDelay = Math.min(delay * 2, 300.0);
         retryRewardBackground();
      }, Std.int(delay * 1000));
   }

   // Retry interstitial preload without showing a consent dialog.
   // Called automatically by the retry timer; can also be called at game checkpoints.
   public static function retryInterstitialLoad() {
      trace("NME AdApi retryInterstitialLoad isPreloaded=" + isPreloaded);
      if (isPreloaded) return;
      #if NME_ADMOB_APP_ID
      AdMob.retryInterstitialLoad();
      #end
   }

   // Background retry for reward ad — no consent dialog.
   static function retryRewardBackground() {
      if (rewardReady) return;
      #if NME_ADMOB_APP_ID
      AdMob.retryRewardBackground();
      #end
   }

   // Cancel any pending interstitial retry timer and immediately attempt a preload.
   // Call at game checkpoints where an interstitial will soon be needed.
   public static function primeInterstitial() {
      if (isPreloaded) return;
      if (interstitialRetryTimer != null) { interstitialRetryTimer.stop(); interstitialRetryTimer = null; }
      interstitialRetryDelay = 30.0;
      retryInterstitialLoad();
   }

   // Cancel any pending reward retry timer and immediately attempt a preload.
   // Call before showing the "earn reward" option so the ad is ready when the user taps.
   public static function primeReward() {
      if (rewardReady) return;
      if (rewardRetryTimer != null) { rewardRetryTimer.stop(); rewardRetryTimer = null; }
      rewardRetryDelay = 30.0;
      retryRewardBackground();
   }

   // Call at a user-initiated moment (e.g., showing the "earn reward" prompt).
   // May show a consent dialog — acceptable here since the user initiated it.
   // Result arrives via watcher: onRewardPreloaded / onRewardPreloadFailed.
   public static function requestRewardLoad() {
      trace("NME AdApi requestRewardLoad rewardReady=" + rewardReady);
      if (rewardReady) return;
      #if NME_ADMOB_APP_ID
      AdMob.requestRewardLoad();
      #end
   }

   // Returns the current state of reward ad availability for display logic.
   public static function getRewardState():AdApiRewardState {
      if (!hasAdNetwork()) return ApiUndefined;
      if (_consentUnavailable) return ApiNoConsent;
      if (!_consentGranted) return ApiNotReady;
      if (rewardReady) return ApiRewardReady;
      return ApiRewardNotLoaded;
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
            interstitialRetryDelay = 30.0; // reset backoff for next ad cycle

         case "onSdkInitialized":
            // MobileAds.initialize complete — consent was granted and SDK is running
            _consentGranted = true;
            _consentUnavailable = false;

         case "onConsentNetworkError":
            // Could not reach consent server — suggest checking network, keep retrying
            isPreloaded = false;
            scheduleInterstitialRetry();

         case "onConsentUnavailable":
            // Consent required but not granted — user must take action, stop retrying
            _consentUnavailable = true;
            isPreloaded = false;
            rewardReady = false;
         // ios
         case "onVideoBegan":
            nme.media.Sound.suspend(true);

         // ios
         case "onVideoEnded":
            nme.media.Sound.suspend(false);

         case "onInterstitialPreloadFailed":
            isPreloaded = false;
            scheduleInterstitialRetry();

         case "onRewardPreloaded":
            rewardReady = true;
            rewardRetryDelay = 30.0; // reset backoff for next ad cycle

         case "onRewardPreloadFailed":
            rewardReady = false;
            scheduleRewardRetry();

         case "onRewardHidden":
            nme.media.Sound.suspend(false);

         case "onRewardDisplayed":
            nme.media.Sound.suspend(true);

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

