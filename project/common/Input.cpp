#include <Input.h>


namespace nme
{

#if !defined(IPHONE) && !defined(WEBOS) && !defined(ANDROID)
bool GetAcceleration(double &outX, double &outY, double &outZ)
{
   return false;
}
#endif


}


