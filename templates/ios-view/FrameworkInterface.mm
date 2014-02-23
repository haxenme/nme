#import <UIKit/UIKit.h>
// Problems with objc 'Class' definition
#define Class HxcppClass
#include <hxcpp.h>
#include <nme/Lib.h>
#include <nme/display/MovieClip.h>
#include <Reflect.h>

#include <stdio.h>

extern "C" const char *hxRunLibrary();
extern "C" void hxcpp_set_top_of_stack();


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

- (void) setProperty:(NSString *)name toValue:(NSString*)value
{
   NSLog(@"Ios setProperty %@ = %@", name, value );
   // Since the template system uses :: as delimiters, use 'using' to avoid putting
   //  multiple delimiters on a single line(or split line)
   using namespace nme;
   Dynamic child0 = Lib_obj::nmeCurrent->getChildAt(0);
   if (child0!=null())
   {
      Dynamic field =  Reflect_obj::field(child0,HX_CSTRING("setProperty"));
      if (field!=null())
      {
         Array<Dynamic> args = Array_obj<Dynamic>::__new(2,2);
         // You can create haxe strings from NSString * like this:
         args[0] = String(name);
         args[1] = String(value);
         Reflect_obj::callMethod(child0, field, args);
      }
   }
}


- (void)loadView
{
   //printf("loadView!!!!\n");
   [self setNMEMain:false];
   nmeBoot();
   [super loadView];
}



@end


