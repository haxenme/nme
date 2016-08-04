//
//  InterfaceController.mm
//  WatchApp Extension
//
//
//

#import "InterfaceController.h"


@interface InterfaceController()
@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}
- (void)onButton:(int)buttonId {
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



