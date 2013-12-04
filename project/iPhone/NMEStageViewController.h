#import <UIKit/UIKit.h>

// --- UIStageViewController ----------------------------------------------------------
// The NMEAppDelegate + NMEStageViewController control the application when created in stand-alone mode


@interface NMEStageViewController : UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
- (void)loadView;
@end


