#include <Utils.h>
#include <string>
#include <stdlib.h>


using namespace std;


namespace nme {
	
	
	bool LaunchBrowser (const char *inUtf8URL) {
		
		string url = inUtf8URL;
		string command = "xdg-open " + url;
		
		int result = system(command.c_str());
		
		return (result != -1);
		
	}


}
