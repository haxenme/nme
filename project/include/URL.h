#ifndef NME_URL_H
#define NME_URL_H

#include "Object.h"
#include "ByteArray.h"
#include <vector>
#include <string>
#include <hx/CFFI.h>


namespace nme
{

enum URLState
{
	urlInvalid,
	urlInit,
	urlLoading,
	urlComplete,
	urlError,
};

class URLLoader : public Object
{
	public:
		static URLLoader *create(const char *inURL, int inAuthType, const char *inUserPasswd,
                               const char *inCookies, bool inDebug);
		static bool processAll();
		static void initialize(const char *inCACertFilePath);

		virtual ~URLLoader() { };
		virtual URLState getState()=0;
		virtual int      bytesLoaded()=0;
		virtual int      bytesTotal()=0;
		virtual int      getHttpCode()=0;
		virtual const char *getErrorMessage()=0;
		virtual ByteArray releaseData()=0;
      virtual void     getCookies( std::vector<std::string> &outCookies )=0;
};

}



#endif


