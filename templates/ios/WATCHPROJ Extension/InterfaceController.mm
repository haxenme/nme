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

#ifdef NME_SPRITEKIT
- (void)crownDidRotate:(WKCrownSequencer *)crownSequencer rotationalDelta:(double)rotationalDelta
{
   if (App_obj::instance.mPtr)
   {
      double rps = crownSequencer.rotationsPerSecond;
      hx::NativeAttach attach;
      App_obj::instance->crownDidRotate(rotationalDelta, rps);
   }
}

- (void)crownDidBecomeIdle:(WKCrownSequencer *)crownSequencer
{
   if (App_obj::instance.mPtr)
   {
      hx::NativeAttach attach;
      App_obj::instance->crownDidBecomeIdle();
   }
}

#endif

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    InterfaceController.instance = self;
    #ifdef NME_SPRITEKIT
    printf("awakeWithContext spritekit...\n");
    self.crownSequencer.delegate = self;
    [self.crownSequencer focus];
    #else
    printf("awakeWithContext non-spritekit\n");
    #endif
 
    if (App_obj::instance.mPtr)
    {
       hx::NativeAttach attach;
       Dynamic obj = _hx_objc_to_dynamic(context);
       App_obj::instance->onAwake(obj);
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

- (IBAction)handleLongPress:(WKLongPressGestureRecognizer*)gestureRecognizer {
    if (App_obj::instance.mPtr)
    {
       hx::NativeAttach attach;
       App_obj::instance->onLongPressState(gestureRecognizer);
    }
}

- (IBAction)handlePan:(WKPanGestureRecognizer*)gestureRecognizer {
    if (App_obj::instance.mPtr)
    {
       hx::NativeAttach attach;
       App_obj::instance->onPanState(gestureRecognizer);
    }
}

- (IBAction)handleSwipe:(WKSwipeGestureRecognizer*)gestureRecognizer {
    if (App_obj::instance.mPtr)
    {
       hx::NativeAttach attach;
       App_obj::instance->onSwipeState(gestureRecognizer);
    }
}

- (IBAction)handleTap:(WKTapGestureRecognizer*)gestureRecognizer {
    // Why is this not the same as self.tapRecognizer ?
    if (App_obj::instance.mPtr)
    {
       hx::NativeAttach attach;
       App_obj::instance->onTapState(gestureRecognizer);
    }
}




@end



