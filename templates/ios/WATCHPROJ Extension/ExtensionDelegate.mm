//
//  ExtensionDelegate.mm
//  ::WATCH_FILE:: Extension
//
// This class is referred to from the Info.plist and is automatically created by the OS.
//

#import "ExtensionDelegate.h"
#import <HxcppConfig.h>
#import <nme/watchos/App.h>

using namespace nme::watchos;

extern "C" const char *hxRunLibrary();


@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching {
    // Perform any final initialization of your application.
    hx::NativeAttach attach;
    const char *err = hxRunLibrary();
    if (err)
       printf(" Error %s\n", err );

    if (App_obj::instance.mPtr)
       App_obj::instance->applicationDidFinishLaunching();
}

- (void)applicationDidBecomeActive {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    hx::NativeAttach attach;
    if (App_obj::instance.mPtr)
       App_obj::instance->applicationDidBecomeActive();
}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
    hx::NativeAttach attach;
    if (App_obj::instance.mPtr)
       App_obj::instance->applicationWillResignActive();
}

@end
