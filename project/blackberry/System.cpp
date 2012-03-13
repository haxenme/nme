#include <math.h>
#include <stdbool.h>
#include <bps/accelerometer.h>
#include <bps/navigator.h>
#include <sys/platform.h>
#include "bps/event.h"


namespace nme {
	
	
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