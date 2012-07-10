#include <math.h>
#include <stdbool.h>
#include <bps/accelerometer.h>
#include <bps/locale.h>
#include <bps/navigator.h>
#include <sys/platform.h>
#include "bps/event.h"
#include <string>


namespace nme {
	
	
	std::string CapabilitiesGetLanguage () {
		
		char* country = NULL;
		char* language = NULL;
		
		locale_get(&language, &country);
		
		return std::string(language) + "-" + std::string(country);
		
	}
	
	
	double CapabilitiesGetScreenResolutionX() {
		
		return 1024;
		
	}
	

	double CapabilitiesGetScreenResolutionY() {
		
		return 600;
		
	}
	

	double CapabilitiesGetScreenDPI() {
		
		return 170;
		
	}
	

	double CapabilitiesGetPixelAspectRatio() {
		
		return 	CapabilitiesGetScreenResolutionX() / CapabilitiesGetScreenResolutionY();
		
	}

	
	bool GetAcceleration (double &outX, double &outY, double &outZ) {
		
		return (accelerometer_read_forces (&outX, &outY, &outZ) == BPS_SUCCESS);
		
	}
	
	
	void HapticVibrate (int period, int duration) {
		
		
		
	}
	
	
	bool LaunchBrowser (const char *inUtf8URL) {
		
		char* err;
		
		int result = navigator_invoke (inUtf8URL, &err);
		
		bps_free (err);
		
		return (result == BPS_SUCCESS);
		
	}


}