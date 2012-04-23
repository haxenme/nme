package nme.display;
#if code_completion


@:fakeEnum(String) extern enum GraphicsPathWinding {
	EVEN_ODD;
	NON_ZERO;
}


#elseif (cpp || neko)
typedef GraphicsPathWinding = neash.display.GraphicsPathWinding;
#elseif js
typedef GraphicsPathWinding = jeash.display.GraphicsPathWinding;
#else
typedef GraphicsPathWinding = flash.display.GraphicsPathWinding;
#end