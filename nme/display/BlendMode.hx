package nme.display;


#if flash
@:native ("flash.display.BlendMode")
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
#else



enum BlendMode
{
   NORMAL;
   LAYER;
   MULTIPLY;
   SCREEN;
   LIGHTEN;
   DARKEN;
   DIFFERENCE;
   ADD;
   SUBTRACT;
   INVERT;
   ALPHA;
   ERASE;
   OVERLAY;
   HARDLIGHT;
}
#end