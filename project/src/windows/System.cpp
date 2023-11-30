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



HWND GetApplicationWindow();

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

static unsigned __stdcall dialog_proc( void *inSpec )
{
   FileDialogSpec *spec = (FileDialogSpec *)inSpec;
   if (spec->flags & flagDirectory)
   {

      IFileDialog *dlg = 0;
      if (SUCCEEDED(CoCreateInstance(CLSID_FileOpenDialog, NULL, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&dlg))))
      {
         dlg->SetTitle(UTF8ToWide(spec->title).c_str());

         if (spec->defaultPath[0])
         {
            IShellItem *item = 0;
            SHCreateItemFromParsingName(UTF8ToWide(spec->defaultPath).c_str(), 0, IID_IShellItem,(void **)&item);
            if (item)
            {
               dlg->SetDefaultFolder(item);
               item->Release();
            }
         }

         DWORD dwOptions;
         if (SUCCEEDED(dlg->GetOptions(&dwOptions)))
         {
            dlg->SetOptions(dwOptions | FOS_PICKFOLDERS);
            if (SUCCEEDED(dlg->Show(NULL)))
            {
                IShellItem *item = 0;
                if (SUCCEEDED(dlg->GetResult(&item)))
                {
                   wchar_t *path = 0;
                   if(SUCCEEDED(item->GetDisplayName(SIGDN_DESKTOPABSOLUTEPARSING, &path)))
                      spec->result =  WideToUTF8(path);
                   item->Release();
                }
            }
         }
         dlg->Release();
      }
   }
   else
   {
      OPENFILENAME ofn;
      std::vector<char> path(1024*1024);

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
      ofn.Flags = OFN_EXPLORER | OFN_NOCHANGEDIR;
      if (spec->flags & flagMustExist)
         ofn.Flags |= OFN_FILEMUSTEXIST;
      if (spec->flags & flagHideReadOnly)
         ofn.Flags |= OFN_HIDEREADONLY;
      if (spec->flags & flagMultiSelect)
         ofn.Flags |= OFN_ALLOWMULTISELECT;
      if (spec->flags & flagPromptOverwrite)
         ofn.Flags |= OFN_OVERWRITEPROMPT;
      //ofn.lpstrFilter = "All Files (*.*)\0*.*\0";
      ofn.lpstrFile = &path[0];
      ofn.lpstrTitle = spec->title.c_str();
      ofn.nMaxFile = path.size();
      ofn.lpstrDefExt = "*";

      const char *path0 = spec->defaultPath.c_str();
      if (*path0)
      {
         const char *lastWord = path0;
         bool hasDot = false;
         for(const char *p=lastWord; *p; p++)
         {
            if (*p=='\\' || *p=='/')
            {
               lastWord = p + 1;
               hasDot = false;
            }
            else if (*p=='.')
               hasDot = true;
         }
         if (lastWord && hasDot)
         {
            size_t len = spec->defaultPath.size();
            memcpy(ofn.lpstrFile, spec->defaultPath.c_str(), len );
            for(size_t i=0; i<len; i++)
               if (ofn.lpstrFile[i]=='/')
                  ofn.lpstrFile[i]='\\';
            ofn.nFileOffset = (WORD)(lastWord-path0);
         }
         else
            ofn.lpstrInitialDir = path0;
      }

      bool result = (spec->flags & flagSave) ? GetSaveFileName(&ofn) : GetOpenFileName(&ofn);
      if (result)
      {
         if (spec->flags & flagMultiSelect)
         {
            const char *ptr = ofn.lpstrFile;
            while(ptr[0] || ptr[1])
               ptr++;
            ptr++;
            int len = ptr- ofn.lpstrFile;
            spec->result =  std::string( ofn.lpstrFile, len ); 
         }
         else
            spec->result =  std::string( ofn.lpstrFile ); 
      }
   }

   spec->isFinished = true;
   if (spec->flags & flagRunningOnMainThread)
      spec->complete();
   // ping windows event.

   return 0;
}


bool FileDialogOpen( FileDialogSpec *inSpec )
{
   // Do not run in thread
   if (gNativeWindowHandle)
   {
      inSpec->flags |= flagRunningOnMainThread;
      dialog_proc(inSpec);
      return true;
   }
   else
   {
      return _beginthreadex( 0, 0, dialog_proc, (void *)inSpec, 0, 0);
   }
}


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
