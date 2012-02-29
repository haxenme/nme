package nme.display;

#if (cpp || neko)

typedef InterpolationMethod = neash.display.InterpolationMethod;

#elseif js

typedef InterpolationMethod = jeash.display.InterpolationMethod;

#else

typedef InterpolationMethod = flash.display.InterpolationMethod;

#end