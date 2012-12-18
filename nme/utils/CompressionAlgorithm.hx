package nme.utils;
#if display


/**
 * The CompressionAlgorithm class defines string constants for the names of
 * compress and uncompress options. These constants are used as values of the
 * <code>algorithm</code> parameter of the <code>ByteArray.compress()</code>
 * and <code>ByteArray.uncompress()</code> methods.
 */
@:fakeEnum(String) extern enum CompressionAlgorithm {

	/**
	 * Defines the string to use for the deflate compression algorithm.
	 */
	DEFLATE;

	/**
	 * Defines the string to use for the zlib compression algorithm.
	 */
	ZLIB;
	
	/**
	 * Defines the string to use for the lzma compression algorithm.
	 */
	LZMA;
}


#elseif (cpp || neko)
typedef CompressionAlgorithm = native.utils.CompressionAlgorithm;
#elseif js
typedef CompressionAlgorithm = browser.utils.CompressionAlgorithm;
#else
typedef CompressionAlgorithm = flash.utils.CompressionAlgorithm;
#end
