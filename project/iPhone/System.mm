//#include <ApplicationServices/ApplicationServices.h>
#import <UIKit/UIKit.h>
#include <Utils.h>

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

const std::string &GetUniqueDeviceIdentifier()
{
  return [[[UIDevice currentDevice] uniqueIdentifier] cStringUsingEncoding:1];
}

const std::string &GetResourcePath()
{
   static bool tried = false;
   static std::string path;
   if (!tried)
   {
      tried = true;
      NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
      NSString *resourcePath = [ [NSBundle mainBundle]  resourcePath];
      path = [resourcePath cStringUsingEncoding:1];
      [pool release];
      path += "/";
   }

   return path;
}


const std::string &GetDocumentsPath()
{
   static bool tried = false;
   static std::string path;
   if (!tried)
   {
      tried = true;
      NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

      NSString *docs = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
      path = [docs cStringUsingEncoding:1];
      [pool release];
      path += "/";
   }

   return path;
}



}
