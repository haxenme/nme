package nme.net;
#if display


/**
 * The URLLoaderDataFormat class provides values that specify how downloaded
 * data is received.
 */
@:fakeEnum(String) extern enum URLLoaderDataFormat {

	/**
	 * Specifies that downloaded data is received as raw binary data.
	 */
	BINARY;

	/**
	 * Specifies that downloaded data is received as text.
	 */
	TEXT;

	/**
	 * Specifies that downloaded data is received as URL-encoded variables.
	 */
	VARIABLES;
}


#elseif (cpp || neko)
typedef URLLoaderDataFormat = native.net.URLLoaderDataFormat;
#elseif js
typedef URLLoaderDataFormat = browser.net.URLLoaderDataFormat;
#else
typedef URLLoaderDataFormat = flash.net.URLLoaderDataFormat;
#end
