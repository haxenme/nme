package nme.display;
#if (cpp || neko || js)


enum InterpolationMethod
{	
	RGB;
	LINEAR_RGB;	
}


#else
typedef InterpolationMethod = flash.display.InterpolationMethod;
#end