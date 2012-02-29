package nme.display;

#if (cpp || neko)

typedef GradientType = neash.display.GradientType;

#elseif js

typedef GradientType = jeash.display.GradientType;

#else

typedef GradientType = flash.display.GradientType;

#end