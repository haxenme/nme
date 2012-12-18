package nme.display;
#if display


/**
 * The CapsStyle class is an enumeration of constant values that specify the
 * caps style to use in drawing lines. The constants are provided for use as
 * values in the <code>caps</code> parameter of the
 * <code>nme.display.Graphics.lineStyle()</code> method. You can specify the
 * following three types of caps:
 */
@:fakeEnum(String) extern enum CapsStyle {

	/**
	 * Used to specify no caps in the <code>caps</code> parameter of the
	 * <code>nme.display.Graphics.lineStyle()</code> method.
	 */
	NONE;

	/**
	 * Used to specify round caps in the <code>caps</code> parameter of the
	 * <code>nme.display.Graphics.lineStyle()</code> method.
	 */
	ROUND;

	/**
	 * Used to specify square caps in the <code>caps</code> parameter of the
	 * <code>nme.display.Graphics.lineStyle()</code> method.
	 */
	SQUARE;
}


#elseif (cpp || neko)
typedef CapsStyle = native.display.CapsStyle;
#elseif js
typedef CapsStyle = browser.display.CapsStyle;
#else
typedef CapsStyle = flash.display.CapsStyle;
#end
