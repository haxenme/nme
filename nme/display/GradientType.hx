package nme.display;
#if (cpp || neko || js)


enum GradientType
{	
	RADIAL; 
	LINEAR;	
}


#else
typedef GradientType = flash.display.GradientType;
#end