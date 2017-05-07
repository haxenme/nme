#ifndef NME_UTILS_H
#define NME_UTILS_H

#include <nme/NmeCffi.h>
#include <string>
#include <vector>
#include <nme/QuickVec.h>


#ifdef BLACKBERRY
#include <bps/event.h>
#endif

void NmeLog(const char *inFmt, ...);

#ifdef ANDROID
#include <android/log.h>

#ifdef VERBOSE
#define VLOG(args...) __android_log_print(ANDROID_LOG_INFO, "NME",args)
#else
#define VLOG(args...)
#endif

#define ELOG(args...) __android_log_print(ANDROID_LOG_ERROR, "NME",args)

#elif defined(TIZEN)

extern "C" __attribute__ ((visibility("default"))) void AppLogInternal(const char* pFunction, int lineNumber, const char* pFormat, ...);
extern "C" __attribute__ ((visibility("default"))) void AppLogDebugInternal(const char* pFunction, int lineNumber, const char* pFormat, ...);

#ifdef VERBOSE
#define VLOG(...) AppLogInternal(__PRETTY_FUNCTION__, __LINE__, __VA_ARGS__)
#else
#define VLOG(...)
#endif

#define ELOG(...) AppLogDebugInternal(__PRETTY_FUNCTION__, __LINE__, __VA_ARGS__)

#else

#include <stdio.h>

#ifdef _MSC_VER
#include <stdio.h>
#include <stdarg.h>

inline void DoLog(const char *inFormat,...)
{
  va_list args;
  va_start(args, inFormat);
  vprintf (inFormat, args);
  printf("\n");
  va_end (args);
}
inline void DontLog(const char *inFormat,...) { }

#ifdef VERBOSE

#define VLOG DoLog
#else
#define VLOG DontLog
#endif
#define ELOG DoLog

#else

#ifndef VERBOSE
#define VLOG(args...) { printf(args); printf("\n"); }
#else
#define VLOG(args...)
#endif

#define ELOG(args...) { printf(args); printf("\n"); }

#endif

#endif




namespace nme
{

bool nmeCoInitialize();

extern void nmeLog(const char *inMessage);

bool InitOGLFunctions();

extern std::string gAssetBase;
extern std::string gCompany;
extern std::string gPackage;
extern std::string gVersion;
extern std::string gFile;

const std::string GetUniqueDeviceIdentifier();
std::string GetLocalIPAddress();
const std::string &GetResourcePath();


enum ScreenFormat
{
   PIXELFORMAT_UNKNOWN,
   PIXELFORMAT_INDEX1LSB,
   PIXELFORMAT_INDEX1MSB,
   PIXELFORMAT_INDEX4LSB,
   PIXELFORMAT_INDEX4MSB,
   PIXELFORMAT_INDEX8,
   PIXELFORMAT_RGB332,
   PIXELFORMAT_RGB444,
   PIXELFORMAT_RGB555,
   PIXELFORMAT_BGR555,
   PIXELFORMAT_ARGB4444,
   PIXELFORMAT_RGBA4444,
   PIXELFORMAT_ABGR4444,
   PIXELFORMAT_BGRA4444,
   PIXELFORMAT_ARGB1555,
   PIXELFORMAT_RGBA5551,
   PIXELFORMAT_ABGR1555,
   PIXELFORMAT_BGRA5551,
   PIXELFORMAT_RGB565,
   PIXELFORMAT_BGR565,
   PIXELFORMAT_RGB24,
   PIXELFORMAT_BGR24,
   PIXELFORMAT_RGB888,
   PIXELFORMAT_RGBX8888,
   PIXELFORMAT_BGR888,
   PIXELFORMAT_BGRX8888,
   PIXELFORMAT_ARGB8888,
   PIXELFORMAT_RGBA8888,
   PIXELFORMAT_ABGR8888,
   PIXELFORMAT_BGRA8888,
   PIXELFORMAT_ARGB2101010,
   PIXELFORMAT_YV12,
   PIXELFORMAT_IYUV,
   PIXELFORMAT_YUY2,
   PIXELFORMAT_UYVY,
   PIXELFORMAT_YVYU
};

struct ScreenMode
{
   int width;
   int height;
   ScreenFormat format;
   int refreshRate;
};


enum SpecialDir
{
   DIR_APP,
   DIR_STORAGE,
   DIR_DESKTOP,
   DIR_DOCS,
   DIR_USER,

   DIR_SIZE
};
void GetSpecialDir(SpecialDir inDir,std::string &outDir);

#ifdef ANDROID
class WString
{
public:
   WString() : mLength(0), mString(0) { }
   WString(const WString &inRHS);
   WString(const wchar_t *inStr);
   WString(const wchar_t *inStr,int inLen);
   ~WString();

   inline int length() const { return mLength; }
   inline int size() const { return mLength; }
   void resize(int inLength);
   
   int compare ( const WString& str ) const { return wcscmp (mString, str.mString); };

   WString &operator=(const WString &inRHS);
   inline wchar_t &operator[](int inIndex) { return mString[inIndex]; }
   inline const wchar_t &operator[](int inIndex) const { return mString[inIndex]; }
   const wchar_t *c_str() const { return mString ? mString : L""; }

   WString &operator +=(const WString &inRHS);
   WString operator +(const WString &inRHS) const;
   bool operator<(const WString &inRHS) const;
   bool operator>(const WString &inRHS) const;
   bool operator==(const WString &inRHS) const;
   bool operator!=(const WString &inRHS) const;

   WString substr(int inPos,int inLen) const;


private:
   wchar_t *mString;
   int     mLength;
};
#else
#define HXCPP_NATIVE_WSTRING
typedef std::wstring WString;
#endif

int DecodeAdvanceUTF8(const unsigned char * &ioPtr);

WString IntToWide(int value);
WString ColorToWide(int value);

void SetIcon( const char *path );

int GetDeviceOrientation();
int GetNormalOrientation();
double CapabilitiesGetPixelAspectRatio ();
double CapabilitiesGetScreenDPI ();
double CapabilitiesGetScreenResolutionX ();
double CapabilitiesGetScreenResolutionY ();
QuickVec<int>* CapabilitiesGetScreenResolutions ();
QuickVec<ScreenMode>* CapabilitiesGetScreenModes ();
bool SetClipboardText(const char* text);
bool HasClipboardText();
const char* GetClipboardText();
std::string CapabilitiesGetLanguage();

std::string FileDialogOpen( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes );
std::string FileDialogSave( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes );
std::string FileDialogFolder( const std::string &title, const std::string &text );

bool LaunchBrowser(const char *inUtf8URL);

void ExternalInterface_AddCallback (const char *functionName, AutoGCRoot *inCallback);
void ExternalInterface_Call (const char *functionName, const char **params, int numParams);
void ExternalInterface_RegisterCallbacks ();

void HapticVibrate(int period, int duration);

bool SetUserPreference(const char *inId, const char *inPreference);
std::string GetUserPreference(const char *inId);
bool ClearUserPreference(const char *inId);

#ifdef HX_WINDOWS
typedef wchar_t OSChar;
#define val_os_string val_wstring

FILE *OpenRead(const char *inUtf8Name);
FILE *OpenRead(const wchar_t *inName);

#define OpenOverwrite(x) _wfopen(x,L"wb") // [ddc]

#else
typedef char OSChar;
#ifdef HXCPP_JS_PRIME
#define val_os_string(x) (x).as<std::string>().c_str()
#else
#define val_os_string val_string
#endif

#if defined(IPHONE)
FILE *OpenRead(const char *inName);
FILE *OpenOverwrite(const char *inName); // [ddc]
extern int gFixedOrientation;

#elif defined(HX_MACOS)
} // close namespace nme
extern "C" FILE *OpenRead(const char *inName);
extern "C" bool GetBundleFilename(const char *inName, char *outBuffer,int inBufSize);
extern "C" FILE *OpenOverwrite(const char *inName);
namespace nme {
#else
#ifdef TIZEN
extern int gFixedOrientation;
#endif
#define OpenRead(x) fopen(x,"rb")
#define OpenOverwrite(x) fopen(x,"wb") // [ddc]
#endif

#endif


std::string GetExeName();


std::string WideToUTF8(const WString &inWideString);
WString UTF8ToWide(const std::string &inWideString);

double GetTimeStamp();

struct VolumeInfo
{
   std::string path;
   std::string name;
   bool        writable;
   bool        removable;
   std::string fileSystemType;
   std::string drive;
};

void GetVolumeInfo( std::vector<VolumeInfo> &outInfo );

#ifdef HXCPP_JS_PRIME
struct ByteStream
{
   QuickVec<unsigned char> data;

   inline int addInt(int inVal)
   {
      data.append((unsigned char *)&inVal,4);
      return inVal;
   }

   void toValue(value &outValue);
};

struct OutputStream : public ByteStream
{
   value handleArray;
   int   count;

   OutputStream() : handleArray(value::object()), count(0)
   {
   }

   inline void append(const void *inData, int inBytes)
   {
      data.append((unsigned char *)inData, inBytes);
   }
   template<typename T>
   void add(const T& inData)
   {
      data.append((unsigned char *)&inData, sizeof(T));
   }
   template<typename T,int N>
   void addVec(const QuickVec<T,N> &inData)
   {
      addInt(inData.size());
      append(inData.ByteData(), inData.ByteCount());
   }

   bool addBool(bool inValue)
   {
      add(inValue);
      return inValue;
   }
   void addObject(Object *inObj)
   {
      if (addBool(inObj))
         addHandle( inObj->toAbstract() );
   }

   inline void addHandle(const value &inHandle)
   {
      handleArray.set(count++, inHandle);
   }

   void toValue(value &outValue);
};


struct InputStream
{
   const unsigned char *ptr;
   int len;
   int count;
   value handleArray;
   value abstract;

   InputStream(const unsigned char *inPtr, int inLength, value inHandles, value inAbstract)
       : ptr(inPtr), len(inLength), handleArray(inHandles), abstract(inAbstract)
   {
      count = 0;
   }

   void linkAbstract(Object *inObject);

   inline int getInt()
   {
      int result;
      memcpy(&result,ptr,4);
      ptr+=4;
      len-=4;
      return result;
   }
   inline const unsigned char *getBytes(int inLen)
   {
      const unsigned char *result = ptr;
      ptr+=inLen;
      len-=inLen;
      return result;
   }

   template<typename T>
   void get(T& outData)
   {
      memcpy(&outData, ptr, sizeof(T));
      ptr+=sizeof(T);
      len-=sizeof(T);
   }
   template<typename T>
   void getVec(QuickVec<T> &outData)
   {
      int n = getInt();
      outData.resize(n);
      int size = n*sizeof(T);
      memcpy(outData.ByteData(), getBytes(size),size);
   }

   bool getBool()
   {
      bool result=false;
      get(result);
      return result;
   }
   template<typename T>
   void getObject(T *&outObject,bool inAddRef=true)
   {
      if (getBool())
      {
         value v = getHandle();
         if (v.isNull() || v.isUndefined())
            printf("Bad handle?\n");
         Object *obj = Object::toObject(v);
         outObject = dynamic_cast<T*>(obj);
         if (obj && !outObject)
         {
            printf("got object, but wrong type %p\n", obj);
         }
         else if (inAddRef)
            obj->IncRef();
      }
      else
      {
         outObject = 0;
      }
   }

   inline value getHandle()
   {
      return handleArray[count++];
   }

};

#endif

}


#endif
