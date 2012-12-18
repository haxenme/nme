package nme.display;
#if display


/**
 * Defines the values to use for specifying path-drawing commands.
 *
 * <p>The values in this class are used by the
 * <code>Graphics.drawPath()</code> method, or stored in the
 * <code>commands</code> vector of a GraphicsPath object.</p>
 */
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
typedef GraphicsPathCommand = native.display.GraphicsPathCommand;
#elseif js
typedef GraphicsPathCommand = browser.display.GraphicsPathCommand;
#else
typedef GraphicsPathCommand = flash.display.GraphicsPathCommand;
#end
