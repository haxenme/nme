//#include <ApplicationServices/ApplicationServices.h>
#import <UIKit/UIKit.h>
#include <Utils.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

namespace nme
{

void nmeLog(const char *inMessage)
{
   NSLog(@"%s", inMessage);
}

std::string GetLocalIPAddress()
{
    std::string result = "localhost";
    struct ifaddrs *interfaces = 0;
    struct ifaddrs *temp_addr = 0;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
       // Loop through linked list of interfaces
       temp_addr = interfaces;
       while(temp_addr)
       {
          if (temp_addr->ifa_addr->sa_family == AF_INET)
          {
             // Check if interface is en0 which is the wifi connection on the iPhone
             std::string aName = temp_addr->ifa_name;
             if (aName=="en0")
             {
                // Get NSString from C String
                result = inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr);               
                break;
             }
          }
          temp_addr = temp_addr->ifa_next;
       }
    }
    // Free memory
    freeifaddrs(interfaces);
    return result;
} 


bool LaunchBrowser(const char *inUtf8URL)
{
	#ifndef OBJC_ARC
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    #endif
	NSString *str = [[NSString alloc] initWithUTF8String:inUtf8URL];	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString: str]];
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
	std::string result(language?[language UTF8String]:"");
	#ifndef OBJC_ARC
	//[language release];
	[pool drain];
    #endif
	return result;
}

std::string GetUserPreference(const char *inId)
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	#ifndef OBJC_ARC
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    #endif
	NSString *strId = [[NSString alloc] initWithUTF8String:inId];
	NSString *pref = [userDefaults stringForKey:strId];
	std::string result(pref?[pref UTF8String]:"");
	#ifndef OBJC_ARC
	[strId release];
	[pool drain];
    #endif
	return result;
}
	
bool SetUserPreference(const char *inId, const char *inPreference)
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	#ifndef OBJC_ARC
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    #endif
	NSString *strId = [[NSString alloc] initWithUTF8String:inId];
	NSString *strPref = [[NSString alloc] initWithUTF8String:inPreference];
	[userDefaults setObject:strPref forKey:strId];
	#ifndef OBJC_ARC
	[strId release];
	[strPref release];
	[pool drain];
    #endif
	return true;
}

bool ClearUserPreference(const char *inId)
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	#ifndef OBJC_ARC
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    #endif
	NSString *strId = [[NSString alloc] initWithUTF8String:inId];
	[userDefaults setObject:@"" forKey:strId];
	#ifndef OBJC_ARC
	[strId release];
	[pool drain];
    #endif
	return true;
}

const std::string GetUniqueDeviceIdentifier()
{
	// @todo this is deprecated as of iOS 5. switch this out ASAP for UUID generation into user defaults.
  	//return [[[UIDevice currentDevice] uniqueIdentifier] cStringUsingEncoding:1];
  	return "";
}

const std::string &GetResourcePath()
{
   static bool tried = false;
   static std::string path;
   if (!tried)
   {
      tried = true;
	  #ifndef OBJC_ARC
	  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
      #endif
      NSString *resourcePath = [ [NSBundle mainBundle]  resourcePath];
      path = [resourcePath cStringUsingEncoding:1];
	  #ifndef OBJC_ARC
      [pool release];
	  #endif
      path += "/";
   }

   return path;
}


std::string FileDialogFolder( const std::string &title, const std::string &text ) { return ""; }
std::string FileDialogOpen( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes ) { return ""; }
std::string FileDialogSave( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes ) { return ""; }



int GetDeviceOrientation()
{

   return ( [UIDevice currentDevice].orientation );
}

double CapabilitiesGetPixelAspectRatio()
{
   //CGRect screenBounds = [[UIScreen mainScreen] bounds];
   //return screenBounds.size.width / screenBounds.size.height;
   return 1;
   
}
   
double CapabilitiesGetScreenDPI()
{
   CGFloat screenScale = 1;
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        screenScale = [[UIScreen mainScreen] scale];
    }
    float dpi;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        dpi = 132 * screenScale;
    } else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        dpi = 163 * screenScale;
    } else {
        dpi = 160 * screenScale;
    }
    
   return dpi;
}

double CapabilitiesGetScreenResolutionX()
{
   CGRect screenBounds = [[UIScreen mainScreen] bounds];
   if([[UIScreen mainScreen] respondsToSelector: NSSelectorFromString(@"scale")])
   {
      CGFloat screenScale = [[UIScreen mainScreen] scale];
      CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);
      return screenSize.width;
   }
   return screenBounds.size.width;
}
   
double CapabilitiesGetScreenResolutionY()
{
   CGRect screenBounds = [[UIScreen mainScreen] bounds];
   if([[UIScreen mainScreen] respondsToSelector: NSSelectorFromString(@"scale")])
   {
      CGFloat screenScale = [[UIScreen mainScreen] scale];
      CGSize screenSize = CGSizeMake(screenBounds.size.width * screenScale, screenBounds.size.height * screenScale);
      return screenSize.height;
   }
   return screenBounds.size.height;   
}   




// Since you can't write data in your bundle, I think you need to save user data
// under a different file name to avoid confilcts.
// getPathForResource does not work in sub-directories on iPod 3.1.3
// "resourcePath" is soooo much nicer.
FILE *OpenRead(const char *inName)
{
   FILE *result = 0;

   if (inName[0]=='/')
   {
      result = fopen(inName,"rb");
   }
   else
   {
      std::string asset = GetResourcePath() + gAssetBase + inName;
      //printf("Try asset %s.\n", asset.c_str());
      result = fopen(asset.c_str(),"rb");

      if (!result)
      {
         std::string doc;
       GetSpecialDir(DIR_USER, doc);
       doc += gAssetBase + inName;
         //printf("Try doc %s.\n", doc.c_str());
         result = fopen(doc.c_str(),"rb");
      }
   }
   //printf("%s -> %p\n", inName, result);
   return result;
}



FILE *OpenOverwrite(const char *inName)
{
    std::string asset = gAssetBase + inName;
    NSString *str = [[NSString alloc] initWithUTF8String:asset.c_str()];

    NSString *strWithoutInitialDash;    
    if([str hasPrefix:@"/"]){
     strWithoutInitialDash = [str substringFromIndex:1];
     }
     else {
     strWithoutInitialDash = str;
     }

    //NSLog(@"file name I'm wrinting to = %@", strWithoutInitialDash);
    
    //NSString *path = [[NSBundle mainBundle] pathForResource:str ofType:nil];
    NSString  *path = [[[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingString: @"/"] stringByAppendingString: strWithoutInitialDash];
    //NSLog(@"path name I'm wrinting to = %@", path);
    

   if ( ! [[NSFileManager defaultManager] fileExistsAtPath: [path stringByDeletingLastPathComponent]] ) {
        //NSLog(@"directory doesn't exist, creating it");
      [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES  attributes:nil error:NULL];
   }

    FILE * result = fopen([path cStringUsingEncoding:1],"w");
    #ifndef OBJC_ARC
    [str release];
    #endif
    return result;
}

bool SetClipboardText(const char* text) {
    @try {
        NSString *str = [[NSString alloc] initWithUTF8String:text];
        UIPasteboard *appPasteBoard = [UIPasteboard generalPasteboard];
        appPasteBoard.persistent = YES;
        [appPasteBoard setString: str];
        return true;
    }
    @catch (NSException *exception) {
        return false;
    }
}

bool HasClipboardText(){
    UIPasteboard *appPasteBoard = [UIPasteboard generalPasteboard];
    NSString *textCopied = [appPasteBoard string];
    return [textCopied length] != 0;
}

const char* GetClipboardText(){
    UIPasteboard *appPasteBoard = [UIPasteboard generalPasteboard];
    NSString *textCopied = [appPasteBoard string];
    return [textCopied UTF8String];
}

}
