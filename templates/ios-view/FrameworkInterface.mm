#include "FrameworkHeader.h"
#define Class HxcppClass
#include <hxcpp.h>
#include <Main.h>

extern void nmeCreateNMEView(void *inParent);

extern "C" void register::CLASS_NAME::() { }


@implementation ::CLASS_NAME::


- (id) initWithCoder:(NSCoder*)coder
{    
   printf("::CLASS_NAME:: initWithCoder!\n");
   if ((self = [super initWithCoder:coder]))
   {
      nmeCreateNMEView(self);
      return self;
   }
   return nil;
}

// For when we init programatically...
- (id) initWithFrame:(CGRect)frame
{    
   printf("::CLASS_NAME:: initWithFrame!\n");
   if ((self = [super initWithFrame:frame]))
   {
      nmeCreateNMEView(self);

      self.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                              UIViewAutoresizingFlexibleHeight;
      return self;
   }
   return nil;
}

- (void) setColor:(NSInteger) color24
{
   Main_obj::setColor(color24);
}

- (void) setText:(NSString *) text
{
   Main_obj::setText(text);
}



- (void) activate
{
}

- (void) deactive
{
}




@end


