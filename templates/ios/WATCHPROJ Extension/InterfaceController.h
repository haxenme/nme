//
//  InterfaceController.h
//  WatchOsProductName Extension
//
//  Created by Hugh Sanderson on 3/08/2016.
//
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
::if (NME_WATCH_SPRITEKIT)::
#import <SpriteKit/SpriteKit.h>
#define NME_SPRITEKIT
::end::

@interface InterfaceController : WKInterfaceController ::if (NME_WATCH_SPRITEKIT):: < SKSceneDelegate, WKCrownDelegate > ::end::

+ (InterfaceController *) instance;


// Currenly, only connected in SpriteKit mode
@property (unsafe_unretained, nonatomic) IBOutlet WKSwipeGestureRecognizer *swipeRecognizer;
@property (unsafe_unretained, nonatomic) IBOutlet WKTapGestureRecognizer *tapRecognizer;
// Initially disabled ...
@property (unsafe_unretained, nonatomic) IBOutlet WKLongPressGestureRecognizer *longPressRecognizer;
@property (unsafe_unretained, nonatomic) IBOutlet WKPanGestureRecognizer *panRecognizer;




::if (NME_WATCH_SPRITEKIT)::
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceSKScene *skScene;

::else::
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *mainGroup;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *label0;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *image0;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *label1;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *buttonGroup;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *buttonRow0;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *button0;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *button1;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceGroup *buttonRow1;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *button2;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *button3;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *image1;


::end::


@end
