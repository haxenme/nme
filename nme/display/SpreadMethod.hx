package nme.display;
#if display


/**
 * The SpreadMethod class provides values for the <code>spreadMethod</code>
 * parameter in the <code>beginGradientFill()</code> and
 * <code>lineGradientStyle()</code> methods of the Graphics class.
 *
 * <p>The following example shows the same gradient fill using various spread
 * methods:</p>
 */
@:fakeEnum(String) extern enum SpreadMethod {

	/**
	 * Specifies that the gradient use the <i>pad</i> spread method.
	 */
	PAD;

	/**
	 * Specifies that the gradient use the <i>reflect</i> spread method.
	 */
	REFLECT;

	/**
	 * Specifies that the gradient use the <i>repeat</i> spread method.
	 */
	REPEAT;
}


#elseif (cpp || neko)
typedef SpreadMethod = native.display.SpreadMethod;
#elseif js
typedef SpreadMethod = browser.display.SpreadMethod;
#else
typedef SpreadMethod = flash.display.SpreadMethod;
#end
