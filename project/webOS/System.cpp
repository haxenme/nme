#include "PDL.h"
#include <Utils.h>
#include <syslog.h>
#include <string>


namespace nme {
	
	
	bool LaunchBrowser (const char *inUtf8URL) {		
		
		PDL_LaunchBrowser (inUtf8URL);		
		return true;		
		
	}
	
	
	void ExternalInterface_AddCallback (const char *functionName, AutoGCRoot *inCallback) {
		
		// Need to have signature PDL_bool (PDL_JSParameters *params)
		
		//PDL_RegisterJSHandler(functionName, inCallback->get());
		
	}
	
	
	void ExternalInterface_Call (const char *functionName, const char **params, int numParams) {
		
		PDL_CallJS (functionName, params, numParams);
		
	}
	
	
	void ExternalInterface_RegisterCallbacks () {
		
		PDL_JSRegistrationComplete();
		
	}
	
	
	void HapticVibrate (int period, int duration) {
		
		if (PDL_GetPDKVersion () >= 200) {
			
			PDL_Vibrate (period, duration);
			
		}
		
	}
	
	
	std::string GetUserPreference(const char *inId) {
		
		return "";
		
	}
	
	
	bool SetUserPreference(const char *inId, const char *inPreference) {
		
		return false;
		
	}
	
	
	bool ClearUserPreference(const char *inId) {
		
		return false;
		
	}

	

}

