#include "PDL.h"
#include <syslog.h>


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
	

}

