#import <AppKit/NSWorkspace.h>
#import <Cocoa/Cocoa.h>
#include <string>

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

}
