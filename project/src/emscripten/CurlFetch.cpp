#include <URL.h>
#include <Utils.h>
#include <map>
#include <string>

#include "emscripten.h"
#include "emscripten/fetch.h"
#include <sys/stat.h>

namespace nme
{

static int sgAvtiveCount = 0;

static void onsuccess(struct emscripten_fetch_t *fetch);
static void onerror(struct emscripten_fetch_t *fetch);
static void onprogress(struct emscripten_fetch_t *fetch);
static void onreadystatechange(struct emscripten_fetch_t *fetch);

static const bool allowUserAgent = false;

class CurlFetch : public URLLoader
{
   emscripten_fetch_t *fetch;
   URLState state;
   ByteArray data;
   std::string err;
   int status;
   std::vector<char> postData;

public:
   CurlFetch(URLRequest &request)
   {
      state = urlInit;
      status = 400;
      fetch = nullptr;

      emscripten_fetch_attr_t attr;
      emscripten_fetch_attr_init(&attr);
      attr.userData = this;
      attr.onsuccess = onsuccess;
      attr.onprogress = onprogress;
      attr.onerror = onerror;
      attr.onreadystatechange = onreadystatechange;
      attr.attributes = EMSCRIPTEN_FETCH_LOAD_TO_MEMORY;

      strcpy(attr.requestMethod, request.method);

      if (request.postData.Size()>0)
      {
         postData.resize(request.postData.Size());
         memcpy(&postData[0],request.postData.Bytes(), request.postData.Size());
         attr.requestData = &postData[0];
         attr.requestDataSize = postData.size();
      }

      std::string user;
      std::string pass;
      if (request.credentials && request.credentials[0])
      {
         std::string creds(request.credentials);
         auto col = creds.find(":");
         if (col!=std::string::npos)
         {
            user = creds.substr(0,col);
            pass = creds.substr(col+1);
            attr.userName = user.c_str();
            attr.password = pass.c_str();
         }
      }
      std::vector<const char *> allHeaders;
      bool seenCookie = false;
      bool seenAgent = false;
      bool seenContent = false;
      for(int i=0;i<request.headers.size();i++)
      {
         URLRequestHeader &h = request.headers[i];
         const char *value = h.value;
         if (!strcmp(h.name,"User-Agent"))
         {
            if (allowUserAgent)
            {
               seenAgent = true;
               if (request.userAgent && request.userAgent[0])
                  value = request.userAgent;
            }
         }
         else if (!strcmp(h.name,"Cookie"))
         {
            seenCookie = true;
            if (request.cookies && request.cookies[0])
               value = request.cookies;
         }
         else if (!strcmp(h.name,"Content-Type"))
         {
            seenContent = true;
            if (request.contentType && request.contentType[0])
               value = request.contentType;
         }

         allHeaders.push_back(h.name);
         allHeaders.push_back(value);
      }
      if (allowUserAgent && !seenAgent && request.userAgent && request.userAgent[0])
      {
         allHeaders.push_back("User-Agent");
         allHeaders.push_back(request.userAgent);
      }
      if (!seenCookie && request.cookies && request.cookies[0])
      {
         allHeaders.push_back("Cookie");
         allHeaders.push_back(request.cookies);
      }
      if (!seenContent && request.contentType && request.contentType[0])
      {
         allHeaders.push_back("Content-Type");
         allHeaders.push_back(request.contentType);
      }

      if (allHeaders.size())
      {
         allHeaders.push_back(nullptr);
         attr.requestHeaders = &allHeaders[0];
      }


      fetch = emscripten_fetch(&attr, request.url);

      state = urlLoading;
   }

   ~CurlFetch()
   {
      close();
   }

   void onSuccess()
   {
      if (fetch)
      {
         int len = (int)fetch->numBytes;
         if (len)
         {
            data = ByteArray(len);
            memcpy(data.Bytes(), fetch->data, len);
         }
         status = fetch->status;
      }
      state = urlComplete;
   }
   void onError()
   {
      if (fetch)
      {
         status = fetch->status;
         err = fetch->statusText;
      }
      close();
      state = urlError;
   }
   void onProgress() { }

   void onReadyStateChanged()
   {
   }


   void close()
   {
      if (fetch)
      {
         emscripten_fetch_close(fetch);
         fetch = nullptr;
      }
   }
   URLState getState()
   {
      return state;
   }

   int bytesLoaded()
   {
      if (fetch)
         return (int)fetch->dataOffset;
      return 0;
   }
   int bytesTotal()
   {
      if (fetch)
         return (int)fetch->totalBytes;
      return 0;
   }
   int getHttpCode()
   {
      return status;
   }
   const char *getErrorMessage()
   {
      return err.c_str();
   }

   ByteArray releaseData()
   {
      return data;
   }

   void getCookies( std::vector<std::string> &outCookies )
   {
   }

   void getResponseHeaders( std::vector<std::string> &outHeaders )
   {
      if (fetch)
      {
         size_t len = emscripten_fetch_get_response_headers_length(fetch);
         if (len)
         {
            std::vector<char> buf(len);
            emscripten_fetch_get_response_headers(fetch, &buf[0], len);
            char **headers = emscripten_fetch_unpack_response_headers(&buf[0]);
            std::string sep(": ");
            for(char **h = headers; *h; h+=2)
               outHeaders.push_back( h[0] + sep + h[1] );
            emscripten_fetch_free_unpacked_response_headers(headers);
         }
      }
   }

};

static void onsuccess(struct emscripten_fetch_t *fetch) {
   ((CurlFetch *)fetch->userData)->onSuccess();
}
static void onerror(struct emscripten_fetch_t *fetch) {
   ((CurlFetch *)fetch->userData)->onError();
}
static void onprogress(struct emscripten_fetch_t *fetch) {
   ((CurlFetch *)fetch->userData)->onProgress();
}
static void onreadystatechange(struct emscripten_fetch_t *fetch) {
   ((CurlFetch *)fetch->userData)->onReadyStateChanged();
}



URLLoader *URLLoader::create(URLRequest &inRequest)
{
   return new CurlFetch(inRequest);
}

bool URLLoader::processAll()
{
   return sgAvtiveCount > 0;
}
void URLLoader::initialize(const char *inCACertFilePath)
{
}

}  // End namespace nme
