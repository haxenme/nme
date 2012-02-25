package nme.display;
#if (cpp || neko)


enum InterpolationMethod
{	
	RGB;
	LINEAR_RGB;	
}


#else
typedef InterpolationMethod = flash.display.InterpolationMethod;
#end