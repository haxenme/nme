//#include <ApplicationServices/ApplicationServices.h>
#import <UIKit/UIKit.h>
#include <Utils.h>

namespace nme {

bool LaunchBrowser(const char *inUtf8URL)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *str = [[NSString alloc] initWithUTF8String:inUtf8URL];	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString: str]];
	[str release];
	[pool drain];
	return true;
}

std::string GetUserPreference(const char *inId)
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *strId = [[NSString alloc] initWithUTF8String:inId];
	NSString *pref = [userDefaults stringForKey:strId];
	std::string result(pref?[pref UTF8String]:"");
	[strId release];
	[pool drain];
	return result;
}
	
bool SetUserPreference(const char *inId, const char *inPreference)
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *strId = [[NSString alloc] initWithUTF8String:inId];
	NSString *strPref = [[NSString alloc] initWithUTF8String:inPreference];
	[userDefaults setObject:strPref forKey:strId];
	[strId release];
	[strPref release];
	[pool drain];
	return true;
}

bool ClearUserPreference(const char *inId)
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *strId = [[NSString alloc] initWithUTF8String:inId];
	[userDefaults setObject:@"" forKey:strId];
	[strId release];
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
