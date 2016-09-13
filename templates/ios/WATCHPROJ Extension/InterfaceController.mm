//
//  InterfaceController.mm
//  WatchApp Extension
//
//
//

#import <HxcppConfig.h>
#import <nme/watchos/App.h>
#import "InterfaceController.h"

using namespace nme::watchos;

@interface InterfaceController()
@end




@implementation InterfaceController


static __weak InterfaceController *theInstance = nil;

+ (InterfaceController *) instance {
   return theInstance;
}


+ (InterfaceController *) setInstance:(InterfaceController *)i {
   theInstance = i;
   return i;
}



- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    InterfaceController.instance = self;
    if (App_obj::instance.mPtr)
    {
       hx::NativeAttach attach;
       App_obj::instance->onAwake();
    }
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    if (App_obj::instance.mPtr)
    {
       hx::NativeAttach attach;
       App_obj::instance->willActivate();
    }
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    if (App_obj::instance.mPtr)
    {
       hx::NativeAttach attach;
       App_obj::instance->didDeactivate();
    }
    [super didDeactivate];
}
- (void)onButton:(int)buttonId {
    if (App_obj::instance.mPtr)
    {
       hx::NativeAttach attach;
       App_obj::instance->onButton(buttonId);
    }
}
- (IBAction)onButton0 {
    [self onButton:0];
}
- (IBAction)onButton1 {
    [self onButton:1];
}
- (IBAction)onButton2 {
    [self onButton:2];
}
- (IBAction)onButton3 {
    [self onButton:3];
}


@end



