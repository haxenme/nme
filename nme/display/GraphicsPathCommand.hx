package nme.display;
#if code_completion


@:fakeEnum(Int) extern enum GraphicsPathCommand {
	NO_OP;
	MOVE_TO;
	LINE_TO;
	CURVE_TO;
	WIDE_MOVE_TO;
	WIDE_LINE_TO;
	CUBIC_CURVE_TO;
}


#elseif (cpp || neko)
typedef GraphicsPathCommand = neash.display.GraphicsPathCommand;
#elseif js
typedef GraphicsPathCommand = jeash.display.GraphicsPathCommand;
#else
typedef GraphicsPathCommand = flash.display.GraphicsPathCommand;
#end