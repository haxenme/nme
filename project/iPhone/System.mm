//#include <ApplicationServices/ApplicationServices.h>
#import <UIKit/UIKit.h>


namespace nme {

bool LaunchBrowser(const char *inUtf8URL)
{
	// TODO: figure out how to convert to an url string i can use 
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *str = [[NSString alloc] initWithUTF8String:inUtf8URL];	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString: str]];
	[str release];
	[pool drain];
	return true;
}

}
