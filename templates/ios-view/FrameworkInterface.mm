#import <UIKit/UIKit.h>
#define Class HxcppClass
#include <hxcpp.h>

#include <stdio.h>

extern "C" const char *hxRunLibrary();
extern "C" void hxcpp_set_top_of_stack();
	
::foreach ndlls::
::if (registerStatics!="false")::extern "C" int ::name::_register_prims();::end::
::end::

void __::CLASS_NAME::Register() { }

void nmeBoot()
{
   //printf("Starting ...\n" );
   hxcpp_set_top_of_stack();

   ::foreach ndlls::
   ::if (registerStatics):: ::name::_register_prims(); ::end::
   ::end::
   
   //printf("Running\n");

   const char *err = NULL;
   err = hxRunLibrary();
   if (err)
   {
      NSLog(@"Error running application");
   }
}


@interface NMEStageViewController : UIViewController
   - (void) sendOnFrame;
   - (void) setNMEMain:(bool)isMain ;
@end

@interface ::CLASS_NAME:: : NMEStageViewController

@end


@implementation ::CLASS_NAME::

/*
- (void) setText:(NSString *) text
{
   // Example implementation
   Main_obj::setText(text);
}
*/


- (void)loadView
{
   printf("loadView!!!!\n");
   [self setNMEMain:false];
   nmeBoot();
   [super loadView];
}



@end


