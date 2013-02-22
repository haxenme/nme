package nme.display;
#if display


/**
 * Indicates the end of a graphics fill. Use a GraphicsEndFill object with the
 * <code>Graphics.drawGraphicsData()</code> method.
 *
 * <p> Drawing a GraphicsEndFill object is the equivalent of calling the
 * <code>Graphics.endFill()</code> method. </p>
 */
extern class GraphicsEndFill implements IGraphicsData/* #if !haxe3 , #end implements IGraphicsFill*/ {

	/**
	 * Creates an object to use with the <code>Graphics.drawGraphicsData()</code>
	 * method to end the fill, explicitly.
	 */
	function new() : Void;
}


#elseif (cpp || neko)
typedef GraphicsEndFill = native.display.GraphicsEndFill;
#elseif js
typedef GraphicsEndFill = browser.display.GraphicsEndFill;
#else
typedef GraphicsEndFill = flash.display.GraphicsEndFill;
#end
