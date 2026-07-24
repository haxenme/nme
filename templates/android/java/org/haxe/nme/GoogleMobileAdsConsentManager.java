package org.haxe.nme;

::if NME_ADMOB_APP_ID::

import android.app.Activity;
import android.content.Context;
import com.google.android.ump.ConsentDebugSettings;
import com.google.android.ump.ConsentForm.OnConsentFormDismissedListener;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentInformation.PrivacyOptionsRequirementStatus;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.FormError;
import com.google.android.ump.UserMessagingPlatform;
import android.util.Log;

/**
 * The Google Mobile Ads SDK provides the User Messaging Platform (Google's IAB Certified consent
 * management platform) as one solution to capture consent for users in GDPR impacted countries.
 * This is an example and you can choose another consent management platform to capture consent.
 */
public class GoogleMobileAdsConsentManager {
  private static final String TAG = "NME AdMobConsent";
  private static GoogleMobileAdsConsentManager instance;
  private final ConsentInformation consentInformation;

  /** Private constructor */
  private GoogleMobileAdsConsentManager(Context context) {
    this.consentInformation = UserMessagingPlatform.getConsentInformation(context);
  }

  /** Public constructor */
  public static GoogleMobileAdsConsentManager getInstance(Context context) {
    if (instance == null) {
      instance = new GoogleMobileAdsConsentManager(context);
    }

    return instance;
  }

  /** Interface definition for a callback to be invoked when consent gathering is complete. */
  public interface OnConsentGatheringCompleteListener {
    void consentGatheringComplete(FormError error);
  }

  /** Helper variable to determine if the app can request ads. */
  public boolean canRequestAds() {
    return consentInformation.canRequestAds();
  }

  /** Helper variable to determine if consent is required but not yet obtained. */
  public boolean isConsentRequired() {
    return consentInformation.getConsentStatus()
        == ConsentInformation.ConsentStatus.REQUIRED;
  }

  /** Helper variable to determine if the privacy options form is required. */
  public boolean isPrivacyOptionsRequired() {
    return consentInformation.getPrivacyOptionsRequirementStatus()
        == PrivacyOptionsRequirementStatus.REQUIRED;
  }

  /**
   * Helper method to call the UMP SDK methods to request consent information and load/present a
   * consent form if necessary.
   */
  public void gatherConsent(
      Activity activity, OnConsentGatheringCompleteListener onConsentGatheringCompleteListener) {
    Log.d(TAG,"NME AdMobConsent gatherConsent start consentStatus=" + consentInformation.getConsentStatus());
    // For testing purposes, you can force a DebugGeography of EEA or NOT_EEA.
    ConsentDebugSettings debugSettings =
        new ConsentDebugSettings.Builder(activity)
            ::if NME_TEST_DEVICE_HASHED_ID::
            .setDebugGeography(ConsentDebugSettings.DebugGeography.DEBUG_GEOGRAPHY_EEA)
            .addTestDeviceHashedId("::NME_TEST_DEVICE_HASHED_ID::")
            ::end::
            .build();

    ConsentRequestParameters params =
        new ConsentRequestParameters.Builder().setConsentDebugSettings(debugSettings).build();

    // Requesting an update to consent information should be called on every app launch.
    consentInformation.requestConsentInfoUpdate(
        activity,
        params,
        () ->
            UserMessagingPlatform.loadAndShowConsentFormIfRequired(
                activity,
                formError -> {
                  // Consent has been gathered.
                  if (formError != null)
                     Log.w(TAG,"NME AdMobConsent loadAndShowConsentFormIfRequired error: " + formError.getMessage());
                  else
                     Log.d(TAG,"NME AdMobConsent consent form complete canRequestAds=" + consentInformation.canRequestAds());
                  onConsentGatheringCompleteListener.consentGatheringComplete(formError);
                }),
        requestConsentError -> {
            Log.w(TAG,"NME AdMobConsent requestConsentInfoUpdate error: " + requestConsentError.getMessage());
            onConsentGatheringCompleteListener.consentGatheringComplete(requestConsentError);
            }
        );
  }

  /** Helper method to call the UMP SDK method to present the privacy options form. */
  public void showPrivacyOptionsForm(
      Activity activity, OnConsentFormDismissedListener onConsentFormDismissedListener) {
    Log.d(TAG,"NME AdMobConsent showPrivacyOptionsForm");
    UserMessagingPlatform.showPrivacyOptionsForm(activity, onConsentFormDismissedListener);
  }
}

::else::
public class GoogleMobileAdsConsentManager { }
::end::
