#import <AppKit/NSWorkspace.h>
#import <Cocoa/Cocoa.h>
#include <string>
#include <vector>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <Utils.h>


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


#if defined(HX_MACOS)
void GetVolumeInfo( std::vector<VolumeInfo> &outInfo )
{
   NSArray *urls = [[NSFileManager defaultManager] mountedVolumeURLsIncludingResourceValuesForKeys:@[NSURLVolumeNameKey] options:0];
   for(NSURL *url in urls)
   {
     @autoreleasepool {
      if ([url isFileURL])
      {
         NSString *p = [url path];

         VolumeInfo info;
         info.path = [p UTF8String];
         NSArray<NSString *> *pathComponents = [url pathComponents];
         info.name = [ [pathComponents lastObject] UTF8String];
         info.removable = false; // todo
         info.writable = true; // todo
         info.fileSystemType = "Hard Drive";
         outInfo.push_back(info);
      }
     }
   }
}
#endif


double CapabilitiesGetScreenDPI()
{
   #ifndef OBJC_ARC
   NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
   #endif
   
   NSScreen *screen = [NSScreen mainScreen];
   NSDictionary *description = [screen deviceDescription];
   NSSize displayPixelSize = [[description objectForKey:NSDeviceSize] sizeValue];
   CGSize displayPhysicalSize = CGDisplayScreenSize(
               [[description objectForKey:@"NSScreenNumber"] unsignedIntValue]);
   double result = ((displayPixelSize.width / displayPhysicalSize.width) + (displayPixelSize.height / displayPhysicalSize.height)) * 0.5 * 25.4;
   
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

namespace {
enum
{
   flagSave            = 0x0001,
   flagPromptOverwrite = 0x0002,
   flagMustExist       = 0x0004,
   flagDirectory       = 0x0008,
   flagMultiSelect     = 0x0010,
   flagHideReadOnly    = 0x0020,

   flagRunningOnMainThread = 0x1000,
};
}


void fillSpec(FileDialogSpec *spec, NSSavePanel *panel, bool ok)
{
   if (ok)
   {
      //NSURL*  theDoc = [[panel URLs] objectAtIndex:0];
      NSURL*  theDoc = [panel URL];
      NSString *pathfile = [theDoc path];
      spec->result = std::string( [pathfile UTF8String] );
   }
   spec->isFinished = true;
   spec->complete();
}

void FileDialogOpen( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes, FileDialogSpec *spec  )
{
   // NSArray *fileTypes = [NSArray arrayWithObjects:@"jpg",@"jpeg",nil];
   NSOpenPanel * panel = [NSOpenPanel openPanel];

   [panel setAllowsMultipleSelection:NO];
   [panel setCanChooseDirectories:NO];
   [panel setCanChooseFiles:YES];
   [panel setFloatingPanel:YES];
   [panel setTitle: [NSString stringWithCString:title.c_str() encoding:[NSString defaultCStringEncoding]] ]; 


   [panel beginWithCompletionHandler:^(NSInteger result){
         fillSpec(spec,panel,result==NSFileHandlingPanelOKButton);
         }];
}

void FileDialogSave( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes, FileDialogSpec *spec )
{
   NSSavePanel *panel = [NSSavePanel savePanel];

   [panel setAllowsOtherFileTypes:YES];
   [panel setExtensionHidden:YES];
   [panel setCanCreateDirectories:YES];
          // [panel setNameFieldStringValue:filename];
   [panel setTitle: [NSString stringWithCString:title.c_str() encoding:[NSString defaultCStringEncoding]] ]; 

   [panel beginWithCompletionHandler:^(NSInteger result){
         fillSpec(spec,panel,result==NSFileHandlingPanelOKButton);
         }];
}

void FileDialogFolder( const std::string &title, const std::string &text, FileDialogSpec *spec )
{
   NSOpenPanel * panel = [NSOpenPanel openPanel];

   [panel setAllowsMultipleSelection:NO];
   [panel setCanChooseDirectories:YES];
   [panel setCanChooseFiles:NO];
   [panel setFloatingPanel:YES];
   [panel setTitle: [NSString stringWithCString:title.c_str() encoding:[NSString defaultCStringEncoding]] ]; 

   [panel beginWithCompletionHandler:^(NSInteger result){
         fillSpec(spec,panel,result==NSFileHandlingPanelOKButton);
         }];
}

void splitTypes(std::vector<std::string> &outTypes, const std::string &str)
{
   const char *ptr = str.c_str();
   size_t len = str.size();
   size_t start = 0;
   for(int i=0;i<len;i++)
   {
      if (ptr[i]=='|')
      {
         outTypes.push_back(std::string(ptr+start, i-start));
         start = i+1;
      }
   }
}


bool FileDialogOpen( nme::FileDialogSpec *inSpec )
{
   if (inSpec->flags & flagDirectory)
   {
      FileDialogFolder(inSpec->title, inSpec->text, inSpec);
   }
   else if ( (inSpec->flags & flagSave))
   {
      std::vector<std::string> types;
      splitTypes(types, inSpec->fileTypes);
      FileDialogSave(inSpec->title, inSpec->text, types, inSpec);
   }
   else
   {
      std::vector<std::string> types;
      splitTypes(types, inSpec->fileTypes);
      FileDialogOpen(inSpec->title, inSpec->text, types, inSpec );
   }
   return true;
}



}
