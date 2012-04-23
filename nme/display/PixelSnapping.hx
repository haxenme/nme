package nme.display;
#if code_completion


@:fakeEnum(String) extern enum PixelSnapping {
	ALWAYS;
	AUTO;
	NEVER;
}


#elseif (cpp || neko)
typedef PixelSnapping = neash.display.PixelSnapping;
#elseif js
typedef PixelSnapping = jeash.display.PixelSnapping;
#else
typedef PixelSnapping = flash.display.PixelSnapping;
#end