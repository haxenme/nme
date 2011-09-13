package nme.display;
#if (cpp || neko)


enum GradientType { RADIAL; LINEAR; }


#else
typedef GradientType = flash.display.GradientType;
#end