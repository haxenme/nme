#include <Input.h>


namespace nme
{

#if !defined(IPHONE) && !defined(WEBOS)
bool GetAcceleration(double &outX, double &outY, double &outZ)
{
   return false;
}
#endif


}


