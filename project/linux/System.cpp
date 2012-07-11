#include <Utils.h>
#include <string>
#include <stdlib.h>
#include <clocale>


using namespace std;


namespace nme {
	
	
	std::string CapabilitiesGetLanguage () {
		
		const char* locale = getenv ("LANG");
		
		if (locale == NULL) {
			
			locale = setlocale (LC_ALL, "");
			
		}
		
		if (locale != NULL) {
			
			return std::string (locale);
			
		}
		
		return NULL;
		
	}
	
	
	bool LaunchBrowser (const char *inUtf8URL) {
		
		string url = inUtf8URL;
		string command = "xdg-open " + url;
		
		int result = system(command.c_str());
		
		return (result != -1);
		
	}
	
	
	


}
