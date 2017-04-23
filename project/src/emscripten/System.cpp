#include <string>
#include <cstdlib>
#include <vector>

#include <Font.h>

namespace nme {
	
FontFace *FontFace::CreateNative(const TextFormat &inFormat,double inScale)
{
   return 0;
}

	
	std::string CapabilitiesGetLanguage () {
		
		return "en-US";
		
		//char* country = NULL;
		//char* language = NULL;
		//
		//locale_get(&language, &country);
		//
		//return std::string(language) + "-" + std::string(country);
		
	}
	
	
	//double CapabilitiesGetScreenResolutionX() {
		//
		//return 0;
		//
	//}
	
	
	//double CapabilitiesGetScreenResolutionY() {
		//
		//return 0;
		//
	//}
	

	double CapabilitiesGetScreenDPI()
   {
      #ifdef HXCPP_JS_PRIME
      value v = value::global("window")["devicePixelRatio"];
      if (v.isUndefined())
      {
         //printf("Undefined devicePixelRatio\n");
         return 120;
      }
      else
      {
         double pixelScale = v.as<double>();
         //printf("Got actual dpi %f\n", dpi);
         return pixelScale*120.0;
      }
      #else
      return 120;
      #endif
	}
	

	double CapabilitiesGetPixelAspectRatio() {
		
		return 1;
		
	}

	
	//bool GetAcceleration (double &outX, double &outY, double &outZ) {
		//
		//return false;
		//
	//}
	
	
	void HapticVibrate (int period, int duration) {
		
		
		
	}
	
	
	bool LaunchBrowser (const char *inUtf8URL) {
		
		return false;
		//char* err;
		//
		//int result = navigator_invoke (inUtf8URL, &err);
		//
		//bps_free (err);
		//
		//return (result == BPS_SUCCESS);
		
	}
	
	
	std::string FileDialogFolder( const std::string &title, const std::string &text ) {
		return ""; 
	}
	
	std::string FileDialogOpen( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes ) { 
		return ""; 
	}
	
	std::string FileDialogSave( const std::string &title, const std::string &text, const std::vector<std::string> &fileTypes ) { 
		return ""; 
	}
	

}
