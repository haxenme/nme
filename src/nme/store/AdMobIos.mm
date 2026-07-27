// AdMobIos.mm - compiled by hxcpp as part of the AdMob class.
// Provides a C-linkage entry point so the Xcode-compiled AdMobIos
// template source can call back into the hxcpp runtime.
// No third-party framework headers are included here.

// Forward-declare the C entry points defined in templates/ios/PROJ/Classes/AdMobIos.mm
// (compiled by Xcode with SPM header access).  The hxcpp compiler sees these
// declarations; the linker resolves them at final link time.
extern "C" void loadInterstitialAd(void);
extern "C" void loadRewardedVideo(void);
extern "C" void showInterstitialAd(void);
extern "C" void showRewardedVideo(void);
extern "C" void nmeAdMobRetryInterstitial(void);
extern "C" void nmeAdMobRetryReward(void);

// Bridge: called from the Xcode-compiled AdMobIos.mm to fire events into hxcpp.
extern "C" void c_nmeAdMobOnEvent(const char *event)
{
   nme::store::AdMob_obj::onEvent(event);
}
