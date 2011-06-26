#import <AppKit/NSWorkspace.h>
#import <Cocoa/Cocoa.h>

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

}
