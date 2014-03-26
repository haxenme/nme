//
//  ViewController.m
//  IosViewTestApp
//

#import "ViewController.h"
#import "::CLASS_NAME::.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *propName;
@property (weak, nonatomic) IBOutlet UITextField *propValue;
@property (weak) ::CLASS_NAME:: *current::CLASS_NAME::;
@property (weak) id currentEditor;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)applyProperty:(id)sender {
    if (self.currentEditor!=nil)
        [self.currentEditor resignFirstResponder];
         
    NSString *name = self.propName.text;
    NSString *value = self.propValue.text;
    NSLog(@"Set  name %@", name);
    NSLog(@"Set  name %@", value);
    if (self.current::CLASS_NAME::!=nil)
       [self.current::CLASS_NAME:: setProperty:name toValue:value ];

}
- (IBAction)setTextField:(id)sender {
    self.currentEditor = sender;
}
- (IBAction)editingDidFinish:(id)sender {
    self.currentEditor =nil;
    [sender resignFirstResponder];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"GOT SEGUE %@", segue.identifier);
    if ([segue.identifier isEqualToString:@"StartHaxe"])
    {
       self.current::CLASS_NAME:: = (::CLASS_NAME:: *)segue.destinationViewController;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
