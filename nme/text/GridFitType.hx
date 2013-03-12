package nme.text;
#if display


@:fakeEnum(String) extern enum GridFitType {
	NONE;
	PIXEL;
	SUBPIXEL;
}


#elseif (cpp || neko)
typedef GridFitType = native.text.GridFitType;
#elseif js
typedef GridFitType = browser.text.GridFitType;
#else
typedef GridFitType = flash.text.GridFitType;
#end
