#import <Foundation/Foundation.h>

void NmeLog(const char *inFmt, ...)
{
   NSString *str = [[NSString alloc] initWithUTF8String:inFmt];

   va_list args;
   va_start(args, inFmt);
   NSLogv(str, args);
   va_end(args);

	#ifndef OBJC_ARC
	[str release];
   #endif
}

