#include <windows.h>
#include <stdio.h>

namespace nme {

bool LaunchBrowser(const char *inUtf8URL)
{
	int result;
	result=(int)ShellExecute(NULL, "open", inUtf8URL,NULL,NULL,SW_SHOWDEFAULT);
	return (result>32);
}

}
