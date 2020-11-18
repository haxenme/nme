#include <Utils.h>

#ifdef HX_WINDOWS
#include <windows.h>
#include <Shlobj.h>
#include <time.h>
#elif defined(EPPC)
#include <time.h>
#include <stdint.h>
#else
  #include <sys/time.h>
  #include <stdint.h>
  #ifdef HX_LINUX
    #include<unistd.h>
    #include<stdio.h>
  #endif
  #ifndef EMSCRIPTEN
    typedef uint64_t __int64;
  #endif
#endif

#ifdef HX_MACOS
#include <mach/mach_time.h>  
#include <mach-o/dyld.h>
#include <CoreServices/CoreServices.h>
#endif

#ifdef ANDROID
#include <android/log.h>
#endif

#ifdef TIZEN
#include <FSystem.h>
#endif

#ifdef IPHONE
#include <QuartzCore/QuartzCore.h>
#endif

#include "ByteArray.h"

namespace nme
{

#if defined(IPHONE)
std::string gAssetBase = "assets/";
#else
std::string gAssetBase = "";
#endif

std::string gCompany = "nme";
std::string gPackage = "org.haxe.nme";
std::string gVersion = "1.0.0";
std::string gFile = "Application";


ByteArray ByteArray::FromFile(const OSChar *inFilename)
{
   FILE *file = OpenRead(inFilename);
   if (!file)
   {
      #ifdef ANDROID
      return AndroidGetAssetBytes(inFilename);
      #endif
      return ByteArray();
   }

   fseek(file,0,SEEK_END);
   int len = ftell(file);
   fseek(file,0,SEEK_SET);

   ByteArray result(len);
   int status = fread(result.Bytes(),len,1,file);
   fclose(file);

   return result;
}


#ifdef HX_WINDOWS

FILE *OpenRead(const wchar_t *inName)
{
   return _wfopen(inName,L"rb");
}

FILE *OpenRead(const char *inUtf8Name)
{
   WString wide = UTF8ToWide(inUtf8Name);
   return OpenRead( wide.c_str() );
}


ByteArray ByteArray::FromFile(const char *inFilename)
{
   FILE *file = fopen(inFilename,"rb");
   if (!file)
      return ByteArray();

   fseek(file,0,SEEK_END);
   int len = ftell(file);
   fseek(file,0,SEEK_SET);

   ByteArray result(len);
   fread(result.Bytes(),len,1,file);
   fclose(file);

   return result;
}
#endif


std::string GetExeName()
{
   #ifdef HX_WINDOWS
     char path[MAX_PATH] = "";
     #ifndef HX_WINRT
     GetModuleFileName(0,path,MAX_PATH);
     #endif
     return path;
   #elif defined(HX_MACOS)
     char path[1024] = "";
     uint32_t size = sizeof(path);
     _NSGetExecutablePath(path, &size);
     char absPath[1024] = "";
     realpath(path,absPath);
     return absPath;
   #elif defined(HX_LINUX)
     char path[1024];
     char link[1024];
     pid_t pid = getpid();
     sprintf(path,"/proc/%d/exe",pid);
     int len = readlink(path,link,1024);
     if (len>0 && len<1023)
     {
        link[len] = '\0';
        return link;
     }
   #endif
   return "";
}




#ifndef HX_WINDOWS

std::string WideToUTF8(const WString &inWideString)
{
  int len = 0;
  const wchar_t *chars = inWideString.c_str();
  for(int i=0;i<inWideString.length();i++)
   {
      int c = chars[i];
      if( c <= 0x7F ) len++;
      else if( c <= 0x7FF ) len+=2;
      else if( c <= 0xFFFF ) len+=3;
      else len+= 4;
   }


   std::string result;
   result.resize(len);
   unsigned char *data =  (unsigned char *) &result[0];
   for(int i=0;i<inWideString.length();i++)
   {
      int c = chars[i];
      if( c <= 0x7F )
         *data++ = c;
      else if( c <= 0x7FF )
      {
         *data++ = 0xC0 | (c >> 6);
         *data++ = 0x80 | (c & 63);
      }
      else if( c <= 0xFFFF )
      {
         *data++ = 0xE0 | (c >> 12);
         *data++ = 0x80 | ((c >> 6) & 63);
         *data++ = 0x80 | (c & 63);
      }
      else
      {
         *data++ = 0xF0 | (c >> 18);
         *data++ = 0x80 | ((c >> 12) & 63);
         *data++ = 0x80 | ((c >> 6) & 63);
         *data++ = 0x80 | (c & 63);
      }
   }

   return result;
}

#else
#include <windows.h>

std::string WideToUTF8(const WString &inWideString)
{
  int len = WideCharToMultiByte( CP_UTF8, 0, inWideString.c_str(), inWideString.length(),
	  0, 0, 0, 0);

  if (len<1)
	  return std::string();

  std::string result;
  result.resize(len);
  WideCharToMultiByte( CP_UTF8, 0, inWideString.c_str(), inWideString.length(),
      &result[0], len, 0, 0 );


  return result;
}

#endif

void NumberToWide(WString &outResult, bool inNegative, unsigned int value, int inBase)
{
   const char *chars = "0123456789ABCDEF";
   wchar_t buffer[16];
   int pos = 0;

   if (value==0)
   {
      buffer[pos++]=chars[0];
   }
   else
   {
      if (inNegative)
         buffer[pos++] = '-';

      char reverseDigits[16];
      int rpos = 0;
      while(value>0)
      {
         reverseDigits[rpos++] = chars[value%inBase];
         value /= inBase;
      }
      while(rpos>0)
         buffer[pos++] = reverseDigits[--rpos];
   }

   outResult = WString( buffer, pos );
}

WString IntToWide(int value)
{
   WString result;
   NumberToWide(result, value<0, abs(value), 10);
   return result;
}

WString ColorToWide(int value)
{
   WString result;
   NumberToWide(result, false, (unsigned int)value, 16);
   return result;
}


static double t0 = 0;
double  GetTimeStamp()
{
#ifdef _WIN32
   static __int64 t0=0;
   static double period=0;
   __int64 now;

   if (QueryPerformanceCounter((LARGE_INTEGER*)&now))
   {
      if (t0==0)
      {
         t0 = now;
         __int64 freq;
         QueryPerformanceFrequency((LARGE_INTEGER*)&freq);
         if (freq!=0)
            period = 1.0/freq;
      }
      if (period!=0)
         return (now-t0)*period;
   }

   return (double)clock() / ( (double)CLOCKS_PER_SEC);
#elif defined(HX_MACOS)
   static double time_scale = 0.0;
   if (time_scale==0.0)
   {
      mach_timebase_info_data_t info;
      mach_timebase_info(&info);  
      time_scale = 1e-9 * (double)info.numer / info.denom;
   }
   double r =  mach_absolute_time() * time_scale;  
   return mach_absolute_time() * time_scale;  
#else
   #if  defined(IPHONE)
      double t = CACurrentMediaTime(); 
   #elif defined(GPH) || defined(HX_LINUX) || defined(EMSCRIPTEN)
	     struct timeval tv;
        if( gettimeofday(&tv,NULL) )
          return 0;
        double t =  ( tv.tv_sec + ((double)tv.tv_usec) / 1000000.0 );
   #elif defined(EPPC)
		time_t tod;
		time(&tod);
		double t = (double)tod;
   #else
	    struct timespec ts;
       clock_gettime(CLOCK_MONOTONIC, &ts);
       double t =  ( ts.tv_sec + ((double)ts.tv_nsec)*1e-9  );
   #endif
    if (t0==0) t0 = t;
    return t-t0;
#endif
}

#ifdef HX_MACOS
std::string ToStdString(const HFSUniStr255 &inStr)
{
   std::wstring buf;
   buf.resize(inStr.length);
   for(int i=0;i<inStr.length;i++)
      buf[i] = inStr.unicode[i];
   return WideToUTF8(buf);
}
#endif

// Mac version is in System.mm
#ifndef HX_MACOS
void GetVolumeInfo( std::vector<VolumeInfo> &outInfo )
{
#ifdef HX_WINRT
   // Do nothing
#elif defined(HX_WINDOWS)
   DWORD drives = GetLogicalDrives();
   for(int i=0;i<26;i++)
   {
      if (drives & (1<<i) )
      {
         char buf[4] = "x:\\";
         buf[0] = i + 'a';
         unsigned int type =  GetDriveTypeA(buf);
         if (type>1)
         {
            VolumeInfo info;
            info.path = buf;
            info.drive = buf;
            info.name = "C Drive";
            info.name[0] = i + 'A';
            info.removable = type == DRIVE_REMOVABLE;
            info.writable = true; // todo
            info.fileSystemType = (type == DRIVE_CDROM) ? "CDROM" :
                               (type == DRIVE_REMOTE) ? "Network" :
                               (type == DRIVE_RAMDISK) ? "RAMDISK" :
                               "Hard Drive";
            outInfo.push_back(info);
         }
      }
   }
#endif
}
#endif


#if !defined(HX_MACOS) && !defined(IPHONE)
void GetSpecialDir(SpecialDir inDir,std::string &outDir)
{
#if (defined(HX_WINRT) && !defined(__cplusplus_winrt))
    OutputDebugString("Utils.cpp GetSpecialDir not implemented, compile with ABI=-ZW for winrt");
#elif defined(HX_WINRT) && defined(__cplusplus_winrt)
   std::wstring result;
   Windows::Storage::StorageFolder ^folder = nullptr;

   switch(inDir)
   {
      case DIR_APP:
         folder = Windows::ApplicationModel::Package::Current->InstalledLocation;
         break;

      case DIR_STORAGE:
         folder = Windows::Storage::ApplicationData::Current->LocalFolder;
         break;

      case DIR_USER:
         folder = Windows::Storage::ApplicationData::Current->RoamingFolder;
         break;

      case DIR_DESKTOP:
         folder = Windows::Storage::KnownFolders::HomeGroup;
         break;

      case DIR_DOCS:
         folder = Windows::Storage::KnownFolders::DocumentsLibrary;
   }
   if (folder!=nullptr)
      outDir = WideToUTF8(folder->Path->Data());
#elif defined(HX_WINDOWS)
   char result[MAX_PATH] = ""; 
   if (inDir==DIR_APP)
   {
      GetModuleFileName(0,result,MAX_PATH);
      result[MAX_PATH-1] = '\0';
      int len = strlen(result);
      for(int i=len;i>0;i--)
         if (result[i]=='\\')
         {
            result[i] = '\0';
            break;
         }
      outDir =result;
   }
   else
   {
      #ifdef __MINGW32__
      #ifndef CSIDL_MYDOCUMENTS
        #define CSIDL_MYDOCUMENTS CSIDL_PERSONAL
      #endif
      #ifndef SHGFP_TYPE_CURRENT
        #define SHGFP_TYPE_CURRENT 0
      #endif
      #endif

      int id_lut[] = { 0, CSIDL_APPDATA, CSIDL_DESKTOPDIRECTORY, CSIDL_MYDOCUMENTS, CSIDL_PROFILE, 0 };
      SHGetFolderPath(NULL, id_lut[inDir], NULL, SHGFP_TYPE_CURRENT, result);
      outDir = result;
      if (inDir==DIR_STORAGE)
      {
         // TODO: Make directory...
         outDir += "\\" + gCompany + "\\" + gFile;
      }
   }
#elif defined(BLACKBERRY)
	if (inDir == DIR_APP)
	{
		outDir = "app/native";
	}
	else if (inDir == DIR_STORAGE)
	{
		outDir = "data";
	}
	else if (inDir == DIR_USER)
	{
		outDir = ".";
	}
	else if (inDir == DIR_DOCS || inDir == DIR_DESKTOP)
	{
		outDir = "shared/documents";
	}
#elif defined(TIZEN)
   if (inDir == DIR_APP)
   {
      outDir = "../";
   }
   else if (inDir == DIR_STORAGE)
   {
      outDir = "../data";
   }
   else if (inDir == DIR_USER || inDir == DIR_DOCS || inDir == DIR_DESKTOP)
   {
      std::wstring dir = std::wstring (Tizen::System::Environment::GetExternalStoragePath ().GetPointer ());
      outDir = std::string (dir.begin (), dir.end ());
   }
#elif defined(WEBOS)
	if (inDir == DIR_APP)
	{
		outDir = ".";
	}
	else if (inDir == DIR_STORAGE)
	{
		outDir = ".";
	}
	else if (inDir == DIR_USER || inDir == DIR_DESKTOP)
	{
		outDir = "/media/internal";
	}
	else if (inDir == DIR_DOCS)
	{
		outDir = "/media/internal/documents";
	}
#elif defined(HX_LINUX)
	if (inDir == DIR_APP)
	{
		outDir = ".";
	}
	else if (inDir == DIR_STORAGE)
	{
		if (getenv("XDG_CONFIG_HOME") != NULL)
		{
			outDir = std::string(getenv ("XDG_CONFIG_HOME")) + "/" + gPackage;
		}
		else
		{
			outDir = std::string(getenv ("HOME")) + "/.config/" + gPackage;
		}
	}
	else if (inDir == DIR_USER)
	{
		outDir = getenv ("HOME");
	}
	else if (inDir == DIR_DOCS)
	{
      std::string home = getenv("HOME");
		outDir = home + "/Documents";
	}
	else if (inDir == DIR_DESKTOP)
	{
      std::string home = getenv("HOME");
		outDir = home + "/Desktop";
	}
#endif
}
#endif


int DecodeAdvanceUTF8(const unsigned char * &ioPtr)
{
   int c = *ioPtr++;
   if( c < 0x80 )
   {
      return c;
   }
   else if( c < 0xE0 )
   {
      return ((c & 0x3F) << 6) | ((*ioPtr++) & 0x7F);
   }
   else if( c < 0xF0 )
   {
      int c2 = *ioPtr++;
      return  ((c & 0x1F) << 12) | ((c2 & 0x7F) << 6) | ( (*ioPtr++) & 0x7F);
   }

   int c2 = *ioPtr++;
   int c3 = *ioPtr++;
   return ((c & 0x0F) << 18) | ((c2 & 0x7F) << 12) | ((c3 & 0x7F) << 6) | ((*ioPtr++) & 0x7F);
}

WString UTF8ToWide(const std::string &inUtf8)
{
   const unsigned char *ptr = (const unsigned char *)inUtf8.c_str();
   const unsigned char *end = ptr + inUtf8.size();
   int chars = 0;
   while(ptr<end)
   {
      DecodeAdvanceUTF8(ptr);
      chars++;
   }

   WString result;
   result.resize(chars);

   ptr = (const unsigned char *)inUtf8.c_str();
   chars = 0;
   while(ptr<end)
      result[chars++] = DecodeAdvanceUTF8(ptr);
   return result;
}





}
