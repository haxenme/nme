package nme.text;
#if display


/**
 * The TextFormatAlign class provides values for text alignment in the
 * TextFormat class.
 */
@:fakeEnum(String) extern enum TextFormatAlign {

	/**
	 * Constant; centers the text in the text field. Use the syntax
	 * <code>TextFormatAlign.CENTER</code>.
	 */
	CENTER;

	/**
	 * Constant; justifies text within the text field. Use the syntax
	 * <code>TextFormatAlign.JUSTIFY</code>.
	 */
	JUSTIFY;

	/**
	 * Constant; aligns text to the left within the text field. Use the syntax
	 * <code>TextFormatAlign.LEFT</code>.
	 */
	LEFT;

	/**
	 * Constant; aligns text to the right within the text field. Use the syntax
	 * <code>TextFormatAlign.RIGHT</code>.
	 */
	RIGHT;
}


#elseif (cpp || neko)
typedef TextFormatAlign = native.text.TextFormatAlign;
#elseif js
typedef TextFormatAlign = browser.text.TextFormatAlign;
#else
typedef TextFormatAlign = flash.text.TextFormatAlign;
#end
