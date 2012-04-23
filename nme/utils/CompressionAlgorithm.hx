package nme.utils;
#if code_completion


@:fakeEnum(String) extern enum CompressionAlgorithm {
	DEFLATE;
	ZLIB;
}


#elseif (cpp || neko)
typedef CompressionAlgorithm = neash.utils.CompressionAlgorithm;
#elseif js
typedef CompressionAlgorithm = jeash.utils.CompressionAlgorithm;
#else
typedef CompressionAlgorithm = flash.utils.CompressionAlgorithm;
#end