package nme.display;
#if code_completion


@:fakeEnum(String) extern enum BlendMode {
	ADD;
	ALPHA;
	DARKEN;
	DIFFERENCE;
	ERASE;
	HARDLIGHT;
	INVERT;
	LAYER;
	LIGHTEN;
	MULTIPLY;
	NORMAL;
	OVERLAY;
	SCREEN;
	SHADER;
	SUBTRACT;
}


#elseif (cpp || neko)
typedef BlendMode = neash.display.BlendMode;
#elseif js
typedef BlendMode = jeash.display.BlendMode;
#else
typedef BlendMode = flash.display.BlendMode;
#end