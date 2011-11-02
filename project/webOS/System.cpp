#include "PDL.h"
#include <syslog.h>
#include <string>


namespace nme {
	
	
	bool LaunchBrowser (const char *inUtf8URL) {		
		
		PDL_LaunchBrowser (inUtf8URL);		
		return true;		
		
	}
	
	
	void ExternalInterface_Call (const char *functionName, const char **params, int numParams) {
		
		//syslog (LOG_INFO, "Calling JS");
		
		PDL_JSRegistrationComplete();
		//PDL_CallJS("ready", NULL, 0);
		PDL_CallJS (functionName, params, numParams);
		
		/*PDL_RegisterJSHandler("setRotationSpeed", setRotationSpeed);
		PDL_RegisterJSHandler("setAngle", setRotationSpeed);
		PDL_RegisterJSHandler("pause", pause);
		PDL_RegisterJSHandler("resume", resume);*/
		
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

