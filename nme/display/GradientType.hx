package nme.display;
#if code_completion


@:fakeEnum(String) extern enum GradientType {
	LINEAR;
	RADIAL;
}


#elseif (cpp || neko)
typedef GradientType = neash.display.GradientType;
#elseif js
typedef GradientType = jeash.display.GradientType;
#else
typedef GradientType = flash.display.GradientType;
#end