package nme.text;
#if (cpp || neko)

enum GridFitType {
	NONE;
	PIXEL;
	SUBPIXEL;
}

#else
typedef GridFitType = flash.text.GridFitType;
#end
