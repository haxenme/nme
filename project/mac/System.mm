#import <AppKit/NSWorkspace.h>
#import <Cocoa/Cocoa.h>
#include <string>
#include <sys/types.h>
#include <sys/sysctl.h>

namespace nme {

bool LaunchBrowser(const char *inUtf8URL)
{
	#ifndef OBJC_ARC
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	#endif
	NSString *str = [[NSString alloc] initWithUTF8String:inUtf8URL];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: str]];
	#ifndef OBJC_ARC
	[str release];
	[pool drain];
	#endif
	return true;
}

std::string CapabilitiesGetLanguage()
{
	#ifndef OBJC_ARC
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	#endif
	NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
	std::string result = (language?[language UTF8String]:"");
	#ifndef OBJC_ARC
	[pool drain];
	#endif
	return result;
}

double CapabilitiesGetScreenDPI()
{
	#ifndef OBJC_ARC
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	#endif
	
    double result = 72.0f;
        
	NSScreen *screen = [NSScreen mainScreen];
        
    if (screen)
    {
        CGFloat scaleFactor = [screen userSpaceScaleFactor];
        NSDictionary* deviceDescription = [screen deviceDescription];
        NSSize resolution = [[deviceDescription objectForKey:NSDeviceResolution] sizeValue];
        //printf("size.width: %f size.height: %f sf: %f\n", resolution.width, resolution.height, scaleFactor);
            
        result = scaleFactor * (resolution.width + resolution.height)/2.0;
    }
	
	#ifndef OBJC_ARC
	[pool drain];
	#endif
	return result;
}

double CapabilitiesGetPixelAspectRatio() {
	#ifndef OBJC_ARC
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	#endif
	
	NSScreen *screen = [NSScreen mainScreen];
	NSDictionary *description = [screen deviceDescription];
	NSSize displayPixelSize = [[description objectForKey:NSDeviceSize] sizeValue];
	CGSize displayPhysicalSize = CGDisplayScreenSize(
	            [[description objectForKey:@"NSScreenNumber"] unsignedIntValue]);
	double result = (displayPixelSize.width / displayPhysicalSize.width) / (displayPixelSize.height / displayPhysicalSize.height);
	
	#ifndef OBJC_ARC
	[pool drain];
	#endif
	return result;
}

}