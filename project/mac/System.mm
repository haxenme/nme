#import <AppKit/NSWorkspace.h>
#import <Cocoa/Cocoa.h>
#include <string>

namespace nme {

bool LaunchBrowser(const char *inUtf8URL)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *str = [[NSString alloc] initWithUTF8String:inUtf8URL];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString: str]];
	[str release];
	[pool drain];
	return true;
}

std::string CapabilitiesGetLanguage()
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
	std::string result = (language?[language UTF8String]:"");
	[pool drain];
	return result;
}

}
