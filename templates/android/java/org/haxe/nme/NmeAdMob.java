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
   static final String TAG = "NmeAdMob";
   static private final AtomicBoolean isMobileAdsInitializeCalled = new AtomicBoolean(false);
   public static GoogleMobileAdsConsentManager googleMobileAdsConsentManager;
   static private InterstitialAd interstitialAd;
   static private boolean adIsLoading = false;
   static private String adLoadingError = null;
   static HaxeObject watcher;

   public static void initializeSdk(GameActivity inGameActivity)
   {
      Log.d(TAG,"initializeSdk");

      sGameActivity = inGameActivity;


      googleMobileAdsConsentManager = GoogleMobileAdsConsentManager.getInstance(sGameActivity.getApplicationContext());
      googleMobileAdsConsentManager.gatherConsent(
           sGameActivity,
           consentError -> {
             if (consentError != null) {
               // Consent not obtained in current session.
               Log.w(
                   TAG,
                   String.format("%s: %s", consentError.getErrorCode(), consentError.getMessage()));
             }

             if (googleMobileAdsConsentManager.canRequestAds()) {
               Log.d(TAG,"canRequestAds now");
               initializeMobileAdsSdk();
             }
             else {
               Log.d(TAG,"cantRequestAds");
             }

             Log.d(TAG,"isPrivacyOptionsRequired " + googleMobileAdsConsentManager.isPrivacyOptionsRequired());
             //if (googleMobileAdsConsentManager.isPrivacyOptionsRequired()) {
               // Regenerate the options menu to include a privacy setting.
             //}
           });

       // This sample attempts to load ads using consent obtained in the previous session.
       if (googleMobileAdsConsentManager.canRequestAds()) {
         Log.d(TAG,"canRequestAds immediate");
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
      if (isMobileAdsInitializeCalled.getAndSet(true))
         return;

       //new Thread(
       //     () -> {
              // Initialize the Google Mobile Ads SDK on a background thread.
              MobileAds.initialize(sGameActivity, initializationStatus -> {

              ::if NME_ADMOB_INTERSTITIAL_ID::
              Log.d(TAG,"initialized.");
              sGameActivity.runOnUiThread(NmeAdMob::adMobPreloadInterstitialSync);
              ::end::

              });

              // Load an ad on the main thread.
              //runOnUiThread(this::loadBanner);
        //    })
        //.start();
  }

   public static boolean setWatcher(final HaxeObject inWatcher, final boolean preloadInterstitial, final boolean preloadReward)
   {
      Log.d(TAG,"setWatcher");
      watcher = inWatcher;
      if (!googleMobileAdsConsentManager.canRequestAds())
         return false;

      // todo: preloadInterstitial, preloadReward
      ::if NME_ADMOB_INTERSTITIAL_ID::
      adMobPreloadInterstitialSync();
      ::end::
      //preloadRewardAsync();

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
  }

  static public boolean showInterstitial()
  {
     // Show the ad if it's ready. Otherwise let the game decide what to do
     if (interstitialAd != null)
     {
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
        return;
      }
      adLoadingError = null;
      adIsLoading = true;
      Log.d(TAG,"request preload");
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
                       Log.d("TAG", "The ad was dismissed.");
                       NmeAdMob.onInterstitialFinished("onInterstitialHidden");
                     }

                     @Override
                     public void onAdFailedToShowFullScreenContent(AdError adError) {
                       // Called when fullscreen content failed to show.
                       // Make sure to set your reference to null so you don't
                       // show it a second time.
                       Log.d("TAG", "The ad failed to show.");
                       NmeAdMob.interstitialAd = null;
                       NmeAdMob.onInterstitialFinished("onInterstitialFailedToShow");
                     }

                     @Override
                     public void onAdShowedFullScreenContent() {
                       // Called when fullscreen content is shown.
                       Log.d("TAG", "The ad was shown.");
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


}


// NME_ADMOB_APP_ID
::end::
