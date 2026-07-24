package org.haxe.nme;

::if NME_ADMOB_APP_ID::

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.RequestConfiguration;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;
import androidx.annotation.NonNull;
import org.haxe.nme.GoogleMobileAdsConsentManager;
import java.util.concurrent.atomic.AtomicBoolean;

import org.haxe.nme.HaxeObject;

import android.content.Context;
import java.util.Map;
import android.util.Log;


class NmeAdMob
{
   static GameActivity sGameActivity;
   static final String TAG = "NME AdMob";
   static private final AtomicBoolean isMobileAdsInitializeCalled = new AtomicBoolean(false);
   public static GoogleMobileAdsConsentManager googleMobileAdsConsentManager;
   static private InterstitialAd interstitialAd;
   static private boolean adIsLoading = false;
   static private String adLoadingError = null;
   static private RewardedAd rewardedAd;
   static private boolean rewardIsLoading = false;
   static HaxeObject watcher;

   public static void initializeSdk(GameActivity inGameActivity)
   {
      Log.d(TAG,"NME AdMob initializeSdk appId=::NME_ADMOB_APP_ID::");

      sGameActivity = inGameActivity;


      googleMobileAdsConsentManager = GoogleMobileAdsConsentManager.getInstance(sGameActivity.getApplicationContext());
      Log.d(TAG,"NME AdMob canRequestAds (pre-gather)=" + googleMobileAdsConsentManager.canRequestAds());
      googleMobileAdsConsentManager.gatherConsent(
           sGameActivity,
           consentError -> {
             if (consentError != null) {
               Log.w(TAG,"NME AdMob consentError " + String.format("%s: %s", consentError.getErrorCode(), consentError.getMessage()));
             } else {
               Log.d(TAG,"NME AdMob consentGathered ok");
             }

             Log.d(TAG,"NME AdMob post-gather canRequestAds=" + googleMobileAdsConsentManager.canRequestAds()
                 + " isPrivacyOptionsRequired=" + googleMobileAdsConsentManager.isPrivacyOptionsRequired());

             if (googleMobileAdsConsentManager.canRequestAds()) {
               Log.d(TAG,"NME AdMob canRequestAds now -> initializeMobileAdsSdk");
               initializeMobileAdsSdk();
             }
             else {
               if (consentError != null) {
                 Log.d(TAG,"NME AdMob cantRequestAds - network error (code " + consentError.getErrorCode() + ")");
                 send("onConsentNetworkError");
               } else {
                 Log.d(TAG,"NME AdMob cantRequestAds - consent required but not granted");
                 send("onConsentUnavailable");
               }
             }
           });

       // This sample attempts to load ads using consent obtained in the previous session.
       if (googleMobileAdsConsentManager.canRequestAds()) {
         Log.d(TAG,"NME AdMob canRequestAds immediate -> initializeMobileAdsSdk");
         initializeMobileAdsSdk();
       }

   }

   static void send(final String message)
   {
       GameActivity.sendHaxe( new Runnable() {
         @Override public void run() {
            if (watcher!=null)
               watcher.call1("onAdApi", message);
         } } );
   }



   static private void initializeMobileAdsSdk( )
   {
      if (isMobileAdsInitializeCalled.getAndSet(true)) {
         Log.d(TAG,"NME AdMob initializeMobileAdsSdk already called, skipping");
         return;
      }

      Log.d(TAG,"NME AdMob initializeMobileAdsSdk starting MobileAds.initialize");
      // Notify Haxe immediately that consent is confirmed — don't wait for the ~10s
      // MobileAds.initialize to complete before getRewardState() becomes accurate.
      send("onSdkInitialized");
       //new Thread(
       //     () -> {
              // Initialize the Google Mobile Ads SDK on a background thread.
              MobileAds.initialize(sGameActivity, initializationStatus -> {

              Log.d(TAG,"NME AdMob MobileAds.initialize complete");
              ::if NME_ADMOB_INTERSTITIAL_ID::
              Log.d(TAG,"NME AdMob preloading interstitial on UI thread");
              sGameActivity.runOnUiThread(NmeAdMob::adMobPreloadInterstitialSync);
              ::end::
              ::if NME_ADMOB_REWARD_ID::
              Log.d(TAG,"NME AdMob preloading reward ad on UI thread");
              sGameActivity.runOnUiThread(NmeAdMob::adMobPreloadRewardSync);
              ::end::

              });

              // Load an ad on the main thread.
              //runOnUiThread(this::loadBanner);
        //    })
        //.start();
  }

   public static boolean setWatcher(final HaxeObject inWatcher, final boolean preloadInterstitial, final boolean preloadReward)
   {
      // watcher must be set BEFORE initializeSdk runs so callbacks find it immediately.
      watcher = inWatcher;
      if (googleMobileAdsConsentManager == null) {
         Log.d(TAG,"NME AdMob setWatcher: posting initializeSdk to UI thread (first call)");
         GameActivity.queueRunnable(() -> initializeSdk(sGameActivity));
         return false;
      }
      Log.d(TAG,"NME AdMob setWatcher preloadInterstitial=" + preloadInterstitial + " preloadReward=" + preloadReward
          + " canRequestAds=" + googleMobileAdsConsentManager.canRequestAds());
      if (!googleMobileAdsConsentManager.canRequestAds()) {
         Log.d(TAG,"NME AdMob setWatcher: canRequestAds=false, waiting for consent callback");
         return false;
      }

      ::if NME_ADMOB_INTERSTITIAL_ID::
      if (preloadInterstitial) adMobPreloadInterstitialSync();
      ::end::
      ::if NME_ADMOB_REWARD_ID::
      if (preloadReward) adMobPreloadRewardSync();
      ::end::

      return true;
   }

  public static void playInterstitial( )
  {
     GameActivity.queueRunnable( new Runnable() {
        @Override public void run() {
            playInterstitialAndroidThread();
        } } );
  }

  public static void playInterstitialAndroidThread( )
  {
     showInterstitial();
  }

  public static void playReward( )
  {
     GameActivity.queueRunnable( new Runnable() {
        @Override public void run() {
            showReward();
        } } );
  }

  static public boolean showReward()
  {
     Log.d(TAG,"NME AdMob showReward hasAd=" + (rewardedAd!=null));
     if (rewardedAd != null) {
        Log.d(TAG,"NME AdMob calling rewardedAd.show");
        rewardedAd.show(sGameActivity, rewardItem -> {
           Log.d(TAG,"NME AdMob user earned reward: " + rewardItem.getAmount() + " " + rewardItem.getType());
           send("onRewardVerified");
        });
        return true;
     } else {
        if (googleMobileAdsConsentManager != null && googleMobileAdsConsentManager.canRequestAds())
           adMobPreloadRewardSync();
        return false;
     }
  }

  public static void retryInterstitialLoad()
  {
     if (googleMobileAdsConsentManager == null) {
        Log.d(TAG,"NME AdMob retryInterstitialLoad: consent manager not ready yet");
        return;
     }
     Log.d(TAG,"NME AdMob retryInterstitialLoad canRequestAds=" + googleMobileAdsConsentManager.canRequestAds());
     if (googleMobileAdsConsentManager.canRequestAds()) {
        initializeMobileAdsSdk();
        sGameActivity.runOnUiThread(NmeAdMob::adMobPreloadInterstitialSync);
     } else if (googleMobileAdsConsentManager.isConsentRequired()) {
        Log.d(TAG,"NME AdMob retryInterstitialLoad: consent required but not obtained");
        send("onConsentUnavailable");
     } else {
        // Status is UNKNOWN — still can't reach consent server
        Log.d(TAG,"NME AdMob retryInterstitialLoad: consent status unknown (network unavailable)");
        send("onConsentNetworkError");
     }
  }

  public static void retryRewardLoad()
  {
     if (googleMobileAdsConsentManager == null) {
        Log.d(TAG,"NME AdMob retryRewardLoad: consent manager not ready yet");
        return;
     }
     Log.d(TAG,"NME AdMob retryRewardLoad canRequestAds=" + googleMobileAdsConsentManager.canRequestAds());
     if (googleMobileAdsConsentManager.canRequestAds()) {
        initializeMobileAdsSdk();
        sGameActivity.runOnUiThread(NmeAdMob::adMobPreloadRewardSync);
     } else {
        // Re-gather consent — consent dialog acceptable here (user-initiated earn-reward flow)
        googleMobileAdsConsentManager.gatherConsent(sGameActivity, consentError -> {
           if (consentError != null)
              Log.w(TAG,"NME AdMob retryRewardLoad consentError: " + consentError.getMessage());
           Log.d(TAG,"NME AdMob retryRewardLoad post-consent canRequestAds=" + googleMobileAdsConsentManager.canRequestAds());
           if (googleMobileAdsConsentManager.canRequestAds()) {
              initializeMobileAdsSdk();
              sGameActivity.runOnUiThread(NmeAdMob::adMobPreloadRewardSync);
           } else {
              send("onRewardPreloadFailed");
           }
        });
     }
  }

  public static void retryRewardBackground()
  {
     if (googleMobileAdsConsentManager == null) {
        Log.d(TAG,"NME AdMob retryRewardBackground: consent manager not ready yet");
        return;
     }
     Log.d(TAG,"NME AdMob retryRewardBackground canRequestAds=" + googleMobileAdsConsentManager.canRequestAds());
     if (googleMobileAdsConsentManager.canRequestAds()) {
        initializeMobileAdsSdk();
        sGameActivity.runOnUiThread(NmeAdMob::adMobPreloadRewardSync);
     } else {
        Log.d(TAG,"NME AdMob retryRewardBackground: no consent");
        send("onRewardPreloadFailed");
     }
  }

  static public boolean showInterstitial()
  {
     Log.d(TAG,"NME AdMob showInterstitial hasAd=" + (interstitialAd!=null));
     // Show the ad if it's ready. Otherwise let the game decide what to do
     if (interstitialAd != null)
     {
        Log.d(TAG,"NME AdMob calling interstitialAd.show");
        interstitialAd.show(sGameActivity);
        return true;
     }
     else
     {
        if (googleMobileAdsConsentManager.canRequestAds())
           adMobPreloadInterstitialSync();
        return false;
     }
  }

  static public void onInterstitialFinished(String result)
  {
     Log.d(TAG,"NME AdMob onInterstitialFinished result=" + result + " interstitialAd=" + (interstitialAd!=null));
     send(result);

     if (interstitialAd==null && googleMobileAdsConsentManager.canRequestAds() )
         adMobPreloadInterstitialSync();
  }


   static public void adMobPreloadInterstitialSync()
   {
      ::if NME_REAL_ADS::
      String adId = "::NME_ADMOB_INTERSTITIAL_ID::";
      ::else::
      String adId = "ca-app-pub-3940256099942544/1033173712";
      ::end::

      // Request a new ad if one isn't already loaded.
      if (adIsLoading || interstitialAd != null) {
        Log.d(TAG,"NME AdMob preload skipped adIsLoading=" + adIsLoading + " hasAd=" + (interstitialAd!=null));
        return;
      }
      adLoadingError = null;
      adIsLoading = true;
      Log.d(TAG,"NME AdMob requesting preload adId=" + adId);
      AdRequest adRequest = new AdRequest.Builder().build();
      InterstitialAd.load(
         sGameActivity,
         adId,
         adRequest,
         new InterstitialAdLoadCallback() {
             @Override
             public void onAdLoaded(@NonNull InterstitialAd interstitialAd) {
               // The mInterstitialAd reference will be null until
               // an ad is loaded.
               NmeAdMob.interstitialAd = interstitialAd;
               adIsLoading = false;
               Log.i(TAG, "onAdLoaded");
               NmeAdMob.send("onInterstitialPreloaded");
               interstitialAd.setFullScreenContentCallback(
                   new FullScreenContentCallback() {
                     @Override
                     public void onAdDismissedFullScreenContent() {
                       // Called when fullscreen content is dismissed.
                       // Make sure to set your reference to null so you don't
                       // show it a second time.
                       Log.d(TAG, "NME AdMob interstitial dismissed");
                       NmeAdMob.interstitialAd = null;
                       NmeAdMob.onInterstitialFinished("onInterstitialHidden");
                     }

                     @Override
                     public void onAdFailedToShowFullScreenContent(AdError adError) {
                       // Called when fullscreen content failed to show.
                       // Make sure to set your reference to null so you don't
                       // show it a second time.
                       Log.d(TAG, "NME AdMob interstitial failed to show: " + adError.getMessage());
                       NmeAdMob.interstitialAd = null;
                       NmeAdMob.onInterstitialFinished("onInterstitialFailedToShow");
                     }

                     @Override
                     public void onAdShowedFullScreenContent() {
                       // Called when fullscreen content is shown.
                       Log.d(TAG, "NME AdMob interstitial shown");
                       NmeAdMob.onInterstitialFinished("onInterstitialDisplayed");
                     }
                   });
             }

             @Override
             public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
               // Handle the error
               Log.i(TAG, loadAdError.getMessage());
               interstitialAd = null;
               adIsLoading = false;
               adLoadingError = 
                   String.format(
                       java.util.Locale.US,
                       "domain: %s, code: %d, message: %s",
                       loadAdError.getDomain(),
                       loadAdError.getCode(),
                       loadAdError.getMessage());

               NmeAdMob.send("onInterstitialPreloadFailed");
             }
         });
   }


   static public void adMobPreloadRewardSync()
   {
      ::if NME_ADMOB_REWARD_ID::
      ::if NME_REAL_ADS::
      String adId = "::NME_ADMOB_REWARD_ID::";
      ::else::
      String adId = "ca-app-pub-3940256099942544/5224354917"; // Google test rewarded ad
      ::end::

      if (rewardIsLoading || rewardedAd != null) {
         Log.d(TAG,"NME AdMob reward preload skipped rewardIsLoading=" + rewardIsLoading + " hasAd=" + (rewardedAd!=null));
         return;
      }
      rewardIsLoading = true;
      Log.d(TAG,"NME AdMob requesting reward preload adId=" + adId);
      AdRequest adRequest = new AdRequest.Builder().build();
      RewardedAd.load(sGameActivity, adId, adRequest, new RewardedAdLoadCallback() {
         @Override
         public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
            Log.w(TAG,"NME AdMob reward onAdFailedToLoad: " + loadAdError.getMessage());
            NmeAdMob.rewardedAd = null;
            rewardIsLoading = false;
            send("onRewardPreloadFailed");
         }
         @Override
         public void onAdLoaded(@NonNull RewardedAd ad) {
            NmeAdMob.rewardedAd = ad;
            rewardIsLoading = false;
            Log.d(TAG,"NME AdMob reward onAdLoaded");
            send("onRewardPreloaded");
            ad.setFullScreenContentCallback(new FullScreenContentCallback() {
               @Override
               public void onAdDismissedFullScreenContent() {
                  Log.d(TAG,"NME AdMob reward dismissed");
                  NmeAdMob.rewardedAd = null;
                  send("onRewardHidden");
                  adMobPreloadRewardSync(); // preload next
               }
               @Override
               public void onAdFailedToShowFullScreenContent(AdError adError) {
                  Log.d(TAG,"NME AdMob reward failed to show: " + adError.getMessage());
                  NmeAdMob.rewardedAd = null;
                  send("onRewardFailed");
               }
               @Override
               public void onAdShowedFullScreenContent() {
                  Log.d(TAG,"NME AdMob reward shown");
                  send("onRewardDisplayed");
               }
            });
         }
      });
      ::else::
      Log.d(TAG,"NME AdMob reward preload skipped - NME_ADMOB_REWARD_ID not configured");
      send("onRewardPreloadFailed");
      ::end::
   }


}


// NME_ADMOB_APP_ID
::end::
