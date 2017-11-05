#ifndef HX_WINRT
#include <windows.h>
#include <shlobj.h> 
#include <Utils.h>

#include <stdio.h>
#include <string>
#include <vector>
#include <NMEThread.h>

namespace nme {
 
   static bool nmeIsCoInit = false;
   static bool nmeIsCoInitOk = false;
   bool nmeCoInitialize()
   {
      if (!IsMainThread())
         return CoInitialize(0)==S_OK;

      if (!nmeIsCoInit)
      {
         nmeIsCoInit = true;
         HRESULT result = CoInitialize(0);
         nmeIsCoInitOk = result==S_OK || result==S_FALSE || result==RPC_E_CHANGED_MODE;
      }
      return nmeIsCoInitOk;
   }

   bool LaunchBrowser(const char *inUtf8URL)
   {
      int result;
      result=(int)(size_t)ShellExecute(NULL, "open", inUtf8URL, NULL, NULL, SW_SHOWDEFAULT);
      return (result>32);
   }

   std::string CapabilitiesGetLanguage()
   {
      char locale[8];
      #ifdef __MINGW32__
      typedef WINBASEAPI LANGID WINAPI (*GetSystemDefaultUILanguageFunc)();
      GetSystemDefaultUILanguageFunc GetSystemDefaultUILanguage = 
         (GetSystemDefaultUILanguageFunc)GetProcAddress( LoadLibraryA("kernel32.dll"), "GetSystemDefaultUILanguage");
      if (!GetSystemDefaultUILanguage)
         return "en";
      #endif
      int lang_len = GetLocaleInfo(GetSystemDefaultUILanguage(), LOCALE_SISO639LANGNAME, locale, sizeof(locale));
      return std::string(locale, lang_len);
   }
   
   bool SetDPIAware()
   {
      HMODULE usr32 = LoadLibrary("user32.dll");
      if(!usr32) return false;
      
      BOOL (*addr)() = (BOOL (*)())GetProcAddress(usr32, "SetProcessDPIAware");
      return addr ? addr() : false;
   }

   bool dpiAware = SetDPIAware();

   double CapabilitiesGetScreenDPI()
   {
      HDC screen = GetDC(NULL);
      /* It reports 72... :(
      double hSize = GetDeviceCaps(screen, HORZSIZE);
      double vSize = GetDeviceCaps(screen, VERTSIZE);
      double hRes = GetDeviceCaps(screen, HORZRES);
      double vRes = GetDeviceCaps(screen, VERTRES);
      double hPixelsPerInch = hRes / hSize * 25.4;
      double vPixelsPerInch = vRes / vSize * 25.4;
      */
      double hPixelsPerInch = GetDeviceCaps(screen,LOGPIXELSX);
      double vPixelsPerInch = GetDeviceCaps(screen,LOGPIXELSY);
      ReleaseDC(NULL, screen);
      return (hPixelsPerInch + vPixelsPerInch) * 0.5;
   }

   double CapabilitiesGetPixelAspectRatio() {
      HDC screen = GetDC(NULL);
      double hPixelsPerInch = GetDeviceCaps(screen,LOGPIXELSX);
      double vPixelsPerInch = GetDeviceCaps(screen,LOGPIXELSY);
      ReleaseDC(NULL, screen);
      return hPixelsPerInch / vPixelsPerInch;
   }


   /*
   std::string FileDialogFolder( const std::string &title, const std::string &text ) {

      char path[MAX_PATH];
       BROWSEINFO bi = { 0 };
       bi.lpszTitle = ("All Folders Automatically Recursed.");
       LPITEMIDLIST pidl = SHBrowseForFolder ( &bi );

       if ( pidl != 0 ) {
           // get the name of the folder and put it in path
           SHGetPathFromIDList ( pidl, path );


           // free memory used
           IMalloc * imalloc = 0;
           if ( SUCCEEDED( SHGetMalloc ( &imalloc )) )
           {
               imalloc->Free ( pidl );
               imalloc->Release ( );
           }

           return std::string(path);
       }
      
      return ""; 
   }
   */

HWND GetApplicationWindow();

static unsigned __stdcall dialog_proc( void *inSpec )
{
   FileDialogSpec *spec = (FileDialogSpec *)inSpec;

   OPENFILENAME ofn;
   char path[MAX_PATH] = "";

   ZeroMemory(&ofn, sizeof(ofn));

   ofn.hwndOwner = GetApplicationWindow();
   ofn.lStructSize = sizeof(ofn);
   int len = spec->fileTypes.size();
   std::vector<char> buf(len+2);
   const char *ptr = spec->fileTypes.c_str();
   for(int i=0;i<len;i++)
      buf[i] = ptr[i]=='|' ? '\0' : ptr[i];
   buf[len] = '\0';
   ofn.lpstrFilter = &buf[0];
   //ofn.lpstrFilter = "All Files (*.*)\0*.*\0";
   ofn.lpstrFile = path;
   ofn.lpstrTitle = spec->title.c_str();
   ofn.nMaxFile = MAX_PATH;
   ofn.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY | OFN_ALLOWMULTISELECT;
   ofn.lpstrDefExt = "*";

   if (GetOpenFileName(&ofn))
   {
      spec->result =  std::string( ofn.lpstrFile ); 
   }
   spec->isFinished = true;
   // ping windows thread.

   return 0;
}


bool FileDialogOpen( FileDialogSpec *inSpec )
{
   return _beginthreadex( 0, 0, dialog_proc, (void *)inSpec, 0, 0);
}

   /*
   std::string FileDialogSave( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes ) { 

      OPENFILENAME ofn;
       char path[1024] = "";

       ZeroMemory(&ofn, sizeof(ofn));

       ofn.lStructSize = sizeof(ofn);
       ofn.lpstrFilter = "All Files (*.*)\0*.*\0";
       ofn.lpstrFile = path;
       ofn.lpstrTitle = title.c_str();
       ofn.nMaxFile = MAX_PATH;
       ofn.Flags = OFN_EXPLORER | OFN_FILEMUSTEXIST | OFN_HIDEREADONLY | OFN_ALLOWMULTISELECT;
       ofn.lpstrDefExt = "*";

       if(GetSaveFileName(&ofn))  {
         return std::string( ofn.lpstrFile ); 
       }

      return ""; 
   }
   */

}
#else

#include <ppltasks.h>

#include <windows.h>
#include <shlobj.h> 

#include <stdio.h>
#include <string>
#include <vector>
#include <NMEThread.h>

namespace nme {
 
   static bool nmeIsCoInit = false;
   static bool nmeIsCoInitOk = false;
   bool nmeCoInitialize()
   {
      if (!IsMainThread())
         return CoInitializeEx(NULL,0)==S_OK;

      if (!nmeIsCoInit)
      {
         nmeIsCoInit = true;
         HRESULT result = CoInitializeEx(NULL,0);
         nmeIsCoInitOk = result==S_OK || result==S_FALSE || result==RPC_E_CHANGED_MODE;
      }
      return nmeIsCoInitOk;
   }

   bool LaunchBrowser(const char *inUtf8URL)
   {
      if (inUtf8URL==NULL)
        return false;

      int inLen = strlen(inUtf8URL);
      if (inLen<=0)
        return false;

      //char* to wchar_t* to Platform::String
      wchar_t* wc = new wchar_t[inLen+1];
      mbstowcs (wc, inUtf8URL, inLen+1);
      auto platformStringUri = ref new Platform::String(wc, inLen);
      delete[] wc;

      bool hasScheme = 
        strncmp( inUtf8URL, "http:", 5 ) == 0   ||
        strncmp( inUtf8URL, "mailto:", 7 ) == 0 || 
        strncmp( inUtf8URL, "ms-", 3 ) == 0     || 
        strncmp( inUtf8URL, "bingmaps:", 9 ) == 0 ; 

      auto uri = hasScheme? ref new Windows::Foundation::Uri(platformStringUri) : 
                            ref new Windows::Foundation::Uri((ref new Platform::String(L"http://"))+platformStringUri);

      // Set to true to show a warning
      auto launchOptions = ref new Windows::System::LauncherOptions();
      launchOptions->TreatAsUntrusted = false;

      concurrency::task<bool> launchUriOperation(Windows::System::Launcher::LaunchUriAsync(uri,launchOptions));
      launchUriOperation.then([](bool success)
      {
          //OutputDebugString( success ? "URL LAUNCH OK" : "URL LAUNCH FAIL" );
      }); 
      return true;
   }

   std::string CapabilitiesGetLanguage()
   {
      Platform::String^ rtstr = ( Windows::System::UserProfile::GlobalizationPreferences::Languages )->GetAt(0);
      //Platform::String to std::string
      std::wstring wsstr( rtstr->Begin() );
      std::string sstr( wsstr.begin(), wsstr.end() );
      return sstr;
   }
   
   bool SetDPIAware()
   {
      return true;
   }
   bool dpiAware = SetDPIAware();

   double CapabilitiesGetScreenDPI()
   {
      auto displayInformation = Windows::Graphics::Display::DisplayInformation::GetForCurrentView();
      return (double)displayInformation->LogicalDpi;
   }

   double CapabilitiesGetPixelAspectRatio() {
      auto displayInformation = Windows::Graphics::Display::DisplayInformation::GetForCurrentView();
      double hPixelsPerInch = (double)displayInformation->RawDpiX;
      double vPixelsPerInch = (double)displayInformation->RawDpiY;
      return hPixelsPerInch / vPixelsPerInch;
   }

}
#endif
