//
//  InterfaceController.mm
//  WatchApp Extension
//
//
//

#import "InterfaceController.h"
#include "HaxeLink.h"


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



- (void)linkScene:(SKScene *)scene {
    scene.delegate = self;
}


// SKScene delegate
- (void)update:(NSTimeInterval)currentTime forScene:(SKScene *)scene {

   HxCall(HxUpdateScene, 0, currentTime,  (__bridge_retained void *) scene);
}


- (void)didEvaluateActionsForScene:(SKScene *)scene {
   HxCall(HxDidEvaluateActionsForScene);
}

- (void)didSimulatePhysicsForScene:(SKScene *)scene {
   HxCall(HxDidSimulatePhysicsForScene);
}

- (void)didApplyConstraintsForScene:(SKScene *)scene {
   HxCall(HxDidApplyConstraintsForScene);
}

- (void)didFinishUpdateForScene:(SKScene *)scene {
   HxCall(HxDidFinishUpdateForScene);
}


- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    InterfaceController.instance = self;
    HxCall(HxOnAwake);

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    HxCall(HxWillActivate);
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    HxCall(HxDidActivate);
    [super didDeactivate];
}
- (void)onButton:(int)buttonId {
    HxCall(HxOnButton,buttonId);
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



