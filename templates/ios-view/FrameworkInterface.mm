#include "FrameworkHeader.h"
#define Class HxcppClass
#include <hxcpp.h>

#include <stdio.h>

extern "C" const char *hxRunLibrary();
extern "C" void hxcpp_set_top_of_stack();
	
::foreach ndlls::
::if (registerStatics!="false")::extern "C" int ::name::_register_prims();::end::
::end::

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
      return -1;
   }
}


@interface NMEStageViewController : UIViewController
   - (void) sendOnFrame;
@end


@implementation ::CLASS_NAME:: (NMEStageViewController)

/*
- (void) setText:(NSString *) text
{
   // Example implementation
   Main_obj::setText(text);
}
*/


- (void)loadView
{
   nmeBoot();
   [self sendOnFrame];
}



@end


