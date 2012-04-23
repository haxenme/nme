package nme.display;
#if code_completion


@:fakeEnum(String) extern enum InterpolationMethod {
	LINEAR_RGB;
	RGB;
}


#elseif (cpp || neko)
typedef InterpolationMethod = neash.display.InterpolationMethod;
#elseif js
typedef InterpolationMethod = jeash.display.InterpolationMethod;
#else
typedef InterpolationMethod = flash.display.InterpolationMethod;
#end