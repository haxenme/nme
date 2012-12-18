package nme.display;
#if display


/**
 * The GraphicsPathWinding class provides values for the
 * <code>nme.display.GraphicsPath.winding</code> property and the
 * <code>nme.display.Graphics.drawPath()</code> method to determine the
 * direction to draw a path. A clockwise path is positively wound, and a
 * counter-clockwise path is negatively wound:
 *
 * <p> When paths intersect or overlap, the winding direction determines the
 * rules for filling the areas created by the intersection or overlap:</p>
 */
@:fakeEnum(String) extern enum GraphicsPathWinding {
	EVEN_ODD;
	NON_ZERO;
}


#elseif (cpp || neko)
typedef GraphicsPathWinding = native.display.GraphicsPathWinding;
#elseif js
typedef GraphicsPathWinding = browser.display.GraphicsPathWinding;
#else
typedef GraphicsPathWinding = flash.display.GraphicsPathWinding;
#end
